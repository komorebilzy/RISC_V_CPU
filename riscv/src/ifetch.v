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

    //from icache
    input wire IC_ins_sgn,
    input wire [31:0] IC_ins,
    output wire [31:0] IC_addr,
    output wire IC_addr_sgn,

    input wire [5:0] entry_idle,

    //for ROB
    output wire [31:0] pc_predict,
    input wire update,
    input wire is_branch_ins,
    input wire is_jalr,
    input wire [31:0] pc_update,
    input wire [6:0] hash_idex_pc,
    
    output wire rollback,
    
    output wire [5:0] entry_rob,
    output reg [31:0] pc,
    output wire [5:0] rd,
    output wire [5:0] rs1,
    output wire [5:0] rs2,
    output wire [31:0] imm,
    output wire [5:0] op,
    output reg issue_ins,
    output wire is_load_store
);

reg [1:0] predict_cnt[127:0];
reg [31:0] pc_now;
reg stop_fetching;

assign rollback = update;
assign pc_predict = pc_now;
assign IC_addr = pc_now;
assign IC_addr_sgn = !stop_fetching;
assign entry_rob = entry_idle;
wire hash_idex_now =pc_now[6:0];

decoder u_decoder(
    .inst(IC_ins),
    .is_load_store(is_load_store),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .imm(imm),
    .op(op)
);

integer i;
always@(posedge clk)begin
    if(rst)begin
        for(i=0;i<128;i=i+1)begin
            predict_cnt[i] <= `weaklyNotTaken;
        end
        pc_now <= 0;
        stop_fetching <= `FALSE;
        issue_ins <= `FALSE;
    end
    else if(!rdy)begin
        stop_fetching <= `TRUE;
        //pause
    end
    else if(rollback)begin
        stop_fetching <= `FALSE;
        issue_ins <= `FALSE;
        pc_now <= pc_update;
        if(predict_cnt[hash_idex_pc] != `stronglyTaken) predict_cnt[hash_idex_pc] <= predict_cnt[hash_idex_pc]+1;
    end
    
    else begin
        if(IC_ins_sgn)begin
            $display(pc_now," ",IC_ins," ",op);
            pc <= pc_now; 
            issue_ins <=  `TRUE;
            if(op==`JAL) pc_now <= pc_now + imm;
            else if(op==`JALR) stop_fetching <= `TRUE;
            else if(op>=`BEQ && op<=`BGEU) begin
                if(predict_cnt[hash_idex_now]==`weaklyTaken || predict_cnt[hash_idex_now]==`stronglyTaken) begin
                    pc_now <= pc_now + imm;
                end
                else pc_now <= pc_now + 4;
            end
            else pc_now <= pc_now + 4;
        end
        else
            issue_ins <=  `FALSE;

        if(is_branch_ins)begin
            if(update==`TRUE && predict_cnt[hash_idex_pc] != `stronglyTaken) predict_cnt[hash_idex_pc]<=predict_cnt[hash_idex_pc]+1;
            else if(update==`FALSE && predict_cnt[hash_idex_pc] != `stronglyNotTaken) predict_cnt[hash_idex_pc]<=predict_cnt[hash_idex_pc]-1;
        end

        if(is_jalr) begin
            pc_now <= pc_update;
            stop_fetching <= `FALSE;
        end

    end
end


endmodule
`endif