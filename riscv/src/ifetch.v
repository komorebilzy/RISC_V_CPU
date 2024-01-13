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
    input wire rob_full,
    input wire lsb_full,

    //from icache
    input wire IC_ins_sgn,
    input wire [31:0] IC_ins,
    output reg pc_change,
    output wire [31:0] IC_addr,
    output wire IC_addr_sgn,

    input wire [5:0] entry_idle,

    //for ROB
    output reg [31:0] pc_predict,
    input wire update,
    input wire is_branch_ins,
    input wire is_jalr,
    input wire [31:0] pc_update,
    input wire [6:0] hash_idex_pc,
    
    output wire rollback,
    
    output wire [5:0] entry_rob,
    output wire [31:0] pc,
    output wire [5:0] rd,
    output wire [5:0] rs1,
    output wire [5:0] rs2,
    output wire [31:0] imm,
    output wire [5:0] op,
    output wire issue_ins,
    output wire is_load_store
);

reg [1:0] predict_cnt[127:0];
reg [31:0] pc_now;
reg stop_fetching;

assign rollback = update;
// assign pc_predict = pc_now;
assign IC_addr = pc_now;
assign IC_addr_sgn = !stop_fetching;
assign entry_rob = entry_idle;
wire [6:0]hash_idex_now = pc_now[6:0] ;

decoder u_decoder(
    .inst(IC_ins),
    .is_load_store(is_load_store),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .imm(imm),
    .op(op)
);

assign issue_ins=IC_ins_sgn && !rollback;
assign pc= pc_now;
always @(*) begin
     if(predict_cnt[hash_idex_now]==`weaklyTaken || predict_cnt[hash_idex_now]==`stronglyTaken) begin
        // $display("jump");
         pc_predict = pc_now + imm;
     end
     else begin
        // $display("not jump");
        pc_predict = pc_now + 4;
     end
end

integer i;
always@(posedge clk)begin
    if(rst)begin
        for(i=0;i<128;i=i+1)begin
            predict_cnt[i] <= `weaklyNotTaken;
        end
        pc_now <= 0;
        stop_fetching <= `FALSE;
        pc_change <= `FALSE;
    end
    else if(!rdy || rob_full || lsb_full )begin
        stop_fetching <= `TRUE;
        //pause
    end
    else if(update)begin
        stop_fetching <= `FALSE;
        pc_change <= `TRUE;
        pc_now <= pc_update;
        if(predict_cnt[hash_idex_pc] == `weaklyTaken|| predict_cnt[hash_idex_pc]==`stronglyTaken) predict_cnt[hash_idex_pc] <= predict_cnt[hash_idex_pc]-1;
        else predict_cnt[hash_idex_pc] <= predict_cnt[hash_idex_pc]+1;
    end
    
    else begin
        if(IC_ins_sgn)begin
            // if(pc_now==4616) $display("pc ",pc_now," real_hash ",hash_idex_now);
            // $display(pc_now," ",);
            // $display(pc_now," ",IC_ins," ",op," ",rd);
            if(op!= `JALR) pc_change <=  `TRUE;
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
        else begin
            if(is_jalr) begin
                pc_change <=  `TRUE;
                pc_now <= pc_update;
                stop_fetching <= `FALSE;
            end
            else pc_change <=  `FALSE;
        end

        if(is_branch_ins)begin
            if(predict_cnt[hash_idex_pc] == `weaklyTaken) predict_cnt[hash_idex_pc]<=predict_cnt[hash_idex_pc] + 1;
            else if(predict_cnt[hash_idex_pc] == `weaklyNotTaken) predict_cnt[hash_idex_pc]<=predict_cnt[hash_idex_pc] - 1;
        end
    end
end


endmodule
`endif