//provide pc to MemCtrl and accept inst
//accept pc from ifetch and provide inst
`include "defines.v"
`ifndef icache
`define icache
module icache(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire rollback,

    //MemCtrl
    input wire [31:0] MC_val,
    input wire MC_val_sgn,
    output wire [31:0]  Mc_addr,
    output wire Mc_addr_sgn, //true means really miss while false means no

    //Ifetch
    input wire pc_change,
    input wire [31:0] IF_addr,
    input wire IF_addr_sgn,
    output reg [31:0] IF_val,
    output reg IF_val_sgn
);
    //将32位pc强行分成tag【17：10】和index【9：2】部分
    //注意地址的后两位没影响，因为instruction的地址都是4位为单位的
    //index为cache中cache line位置，tag用来进一步对比
    //所以block num=2^(9-2+1)=256； 
    reg [`BLOCKNUM] valid;
    reg [31:0] val[`BLOCKNUM];
    reg [`ICTAG] tag[`BLOCKNUM];

    wire [31:0] pc = IF_addr;
    wire [7:0] index = pc[`ICINDEX];
    wire miss= !valid[index] || tag[index]!=pc[`ICTAG];
    wire [31:0] cur_ins = val[index];

    //ifetch向icache取指令没有命中，现在向mem传信号读入对应指令到cache
    assign Mc_addr_sgn = miss && !MC_val_sgn && IF_addr_sgn;
    assign Mc_addr = pc;

    always @(posedge clk) begin
        if(rst) begin
            valid <= 0;
            IF_val_sgn <= `FALSE;
            IF_val <=0;
        end
        else if(!rdy || !IF_addr_sgn ||rollback) begin
            IF_val_sgn <=`FALSE;        
        end
        else begin
            if(!miss && pc_change) begin
                // if(Mc_addr==4564) $display("hit!!");
                IF_val <= cur_ins;
                IF_val_sgn <= `TRUE;
            end 
            else begin
                IF_val <= MC_val;
                IF_val_sgn <= MC_val_sgn;
            end
            if(MC_val_sgn)begin
                valid[index] <= `TRUE;
                val[index] <= MC_val;
                tag[index] <= pc[`ICTAG];                
            end

        end
    end
    


endmodule
`endif
