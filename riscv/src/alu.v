`include "defines.v"

module alu(
    input wire clk,
    input wire rst,
    input wire rdy,

    //RS
    input wire RS_sgn,
    input wire [5:0] RS_opcode,
    input wire [31:0] RS_lhs,
    input wire [31:0] RS_rhs,
    input wire [31:0] RS_imm,
    input wire [31:0] RS_pc,
    input wire [`ROBENTRY] RS_ROB_entry,
    
    //CDB
    output wire [3:0] CDB_ROB_name,
    output wire [31:0] CDB_result,
    output wire CDB_sgn,

    //LSB不需要再经过alu 地址计算直接在本地即可
    // input wire LSB_sgn,
    // input wire [5:0] LSB_opcode,
    // input wire [31:0] LSB_lhs,
    // input wire [31:0] LSB_rhs,
    // input wire [31:0] LSB_imm,
    // input wire [31:0] LSB_pc,
    // input wire [`ROBENTRY] RS_ROB_entry,

    //IF
);
    wire [31:0] lhs=RS_lhs;
    wire [31:0] rhs=RS_rhs;
    reg [31:0] result;
    reg [3:0] ROB_name;
    reg sgn;

    assign CDB_result =result;
    assign CDB_ROB_name=ROB_name;
    assign CDB_sgn= sgn;

    always @(*) begin
        if(RS_sgn)begin
            case(RS_opcode)
                `ADD   : result = lhs + rhs;
                `ADDI  : result = lhs + rhs;
                `SUB   : result = lhs - rhs;
                `XOR   : result = lhs ^ rhs;
                `XORI  : result = lhs ^ rhs;
                `OR    : result = lhs | rhs;
                `ORI   : result = lhs | rhs;
                `AND   : result = lhs & rhs;
                `ANDI  : result = lhs & rhs;
                //对于riscv 仅当shamt=pc[25:20]中shamt[5]=0时指令有效
                `SLL   : result = lhs << rhs[4:0];
                `SLLI  : result = lhs << rhs[4:0];
                `SRL   : result = lhs >> rhs[4:0];
                `SRLI  : result = lhs >> rhs[4:0];
                `SRA   : result = $signed(lhs) >> rhs[4:0];
                `SRAI  : result = $signed(lhs) >> rhs[4:0];
                `SLT   : result = $signed(lhs) < $signed(rhs);
                `SLTI  : result = $signed(lhs) < $signed(rhs);
                `SLTU  : result = lhs < rhs;
                `SLTIU : result = lhs < rhs;
                `BEQ   : result = lhs == rhs;
                `BNE   : result = lhs != rhs;
                `BLT   : result = $signed(lhs) < $signed(rhs);
                `BGE   : result = $signed(lhs) >= $signed(rhs);
                `BLTU  : result = lhs < rhs;
                `BGEU  : result = lhs >= rhs; 
                `JALR  : result = (lhs + rhs) & ~(32'b1);   
                //lhs=x[rs1] rhs=signed_extended offset
                `L_OP  : result = lhs+rhs;
                `S_OP  : result = lhs+rhs;
                default: result = 0;

            endcase
        end

        else 
    end

endmodule