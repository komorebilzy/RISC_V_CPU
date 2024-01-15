//instruction fetch
`include "defines.v"
`include "decoder.v"
`ifndef ifetch
`define ifetch

`define    stronglyNotTaken     2'b00
`define    weaklyNotTaken       2'b01
`define    weaklyTaken          2'b10
`define    stronglyTaken        2'b11
module ifetch(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire full,

    //from icache
    input wire IC_ins_sgn,
    input wire [31:0] IC_ins,
    output wire [31:0] IC_addr,
    output reg IC_addr_sgn,

    input wire [5:0] entry_idle,

    //for ROB
    output reg [31:0] pc_predict,
    output reg [31:0] pc_to_rob,
    input wire update,
    input wire is_branch_ins,
    input wire is_jalr,
    input wire [31:0] pc_update,
    input wire [6:0] hash_idex_pc,
    
    output wire rollback,
    
    output wire [5:0] entry_rob,
    output reg [31:0] pc,
    output reg [5:0] issue_rd,
    output reg [5:0] issue_rs1,
    output reg [5:0] issue_rs2,
    output reg [31:0] issue_imm,
    output reg [5:0] issue_op,
    output reg issue_ins,
    output reg is_load_store
);

reg [1:0] predict_cnt[127:0];
reg [31:0] pc_now;

assign rollback = update;
assign IC_addr = pc_now;
assign entry_rob = entry_idle;
wire [6:0]hash_idex_now = pc_now[6:0];
wire is_ls;
wire [5:0] rs1,rs2,rd,op;
wire [31:0] imm;
reg tmp;

decoder u_decoder(
    .inst(IC_ins),
    .is_load_store(is_ls),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .imm(imm),
    .op(op)
);

//bug:when it is full,change both the IC_addr_sgn and tmp immediately

integer i;
always@(posedge clk)begin
    if(rst)begin
        for(i=0;i<128;i=i+1)begin
            predict_cnt[i] <= `weaklyNotTaken;
        end
        pc_now <= 0;
        IC_addr_sgn <= `TRUE;
        issue_ins <= 0;
        issue_rd <= `NULL;
        issue_rs1 <= `NULL;
        issue_rs2 <= `NULL;
        issue_imm <= `NULL;
        issue_op <= 0;
        pc_to_rob <= 0;
        pc<=0;
        is_load_store <= 0;
        tmp <= 0;
    end
    else if(!rdy || full)begin
        IC_addr_sgn <= `FALSE;
        tmp <= 1;
        //pause
    end
    else if(update)begin
        IC_addr_sgn <= `TRUE;
        pc_now <= pc_update;
        issue_ins <= `FALSE;
        tmp <= 0;
        
        if(predict_cnt[hash_idex_pc] == `weaklyTaken|| predict_cnt[hash_idex_pc]==`stronglyTaken) predict_cnt[hash_idex_pc] <= predict_cnt[hash_idex_pc]-1;
        else predict_cnt[hash_idex_pc] <= predict_cnt[hash_idex_pc]+1;
    end
    
    //tmp : a small trick to fix the problem of 连续发射，leaving it at least 2 clks before next issue
    //过于密集的issue会导致一条指令Qj Qk读不到前一条指令的rd依赖
    else begin
        if(IC_ins_sgn)begin
            // $display(pc_now," ",IC_ins," ",$realtime);
            pc<=pc_now;
            issue_rd <= rd;
            issue_rs1 <= rs1;
            issue_rs2 <= rs2;
            issue_imm <= imm;
            issue_op <= op;
            is_load_store<= is_ls;
            pc_to_rob <= IC_ins;
            issue_ins <= `TRUE;
            if(op== `JALR)begin
                IC_addr_sgn <= `FALSE;
            end
            else begin
                tmp<=1;
                IC_addr_sgn <= `FALSE;
                if(op==`JAL) pc_now <= pc_now + imm;
                else if(op>=`BEQ && op<=`BGEU) begin
                    if(predict_cnt[hash_idex_now]==`weaklyTaken || predict_cnt[hash_idex_now]==`stronglyTaken) begin
                        pc_now <= pc_now + imm;
                        pc_predict <= pc_now + imm;
                    end
                    else begin
                        pc_now <= pc_now + 4;
                        pc_predict <= pc_now + 4;
                    end
                end
                else pc_now <= pc_now + 4;
            end   
        end
        else begin
            issue_ins <= `FALSE;
            if(is_jalr) begin
                pc_now <= pc_update;
                IC_addr_sgn <= `TRUE;
            end
            else if(tmp==1)begin
                tmp<=0;
                IC_addr_sgn <= `TRUE;
            end
            else IC_addr_sgn <= `FALSE; 
        end

        if(is_branch_ins)begin
            if(predict_cnt[hash_idex_pc] == `weaklyTaken) predict_cnt[hash_idex_pc]<=predict_cnt[hash_idex_pc] + 1;
            else if(predict_cnt[hash_idex_pc] == `weaklyNotTaken) predict_cnt[hash_idex_pc]<=predict_cnt[hash_idex_pc] - 1;
        end
    end
end


endmodule
`endif