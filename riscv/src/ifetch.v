//instruction fetch
`include "defines.v"
module iftch(
    input wire clk,
    input wire rst,
    input wire rdy,

    //from icache
    input wire IC_ins_sgn,
    input wire [31:0] IC_ins,
    output wire [31:0] IC_addr,
    output wire IC_addr_sgn,

    //from ROB
    input wire ROB_jp_wrong,
    input wire [31:0] ROB_jp_tar,
    input wire ROB_full,
    input wire ROB_jump_sgn,
    input wire ROB_need_jump,
    
    //from LSB
    input wire LSB_full,

    //from ALU
    input wire ALU_sgn,
    input wire [31:0] ALU_pc,

);
endmodule