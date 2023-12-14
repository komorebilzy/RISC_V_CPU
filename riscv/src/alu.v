`include "defines.v"

module alu(
    input wire clk,
    input wire rst,
    input wire rdy,

    //RS
    input wire RS_sgn,
    input wire [5:0] RS_opcode,
    input wire [31:0] lhs,
    input wire [31:0] rhs,
    input wire [31:0] imm,
    input wire [31:0] pc,
    input wire [`ROBENTRY] ROB_entry,
    
    //CDB
    output wire [3:0] CDB_ROB_name,
    output wire [31:0] result,
    output wire [31:0] CDB_pc,
    output wire CDB_sgn,

    //IF
);
   
    wire [4:0] shamt;
    assign shamt = imm[24:20]; 
    assign CDB_sgn = RS_sgn;
    assign CDB_ROB_name = ROB_entry;

    always @(*) begin
        if(RS_sgn)begin
            CDB_pc <= 0;
            CDB_result <= 0;
            case(RS_opcode)
                `ADD   : result = lhs + rhs;
                `ADDI  : result = lhs + imm;
                `SUB   : result = lhs - rhs;
                `XOR   : result = lhs ^ rhs;
                `XORI  : result = lhs ^ imm;
                `OR    : result = lhs | rhs;
                `ORI   : result = lhs | imm;
                `AND   : result = lhs & rhs;
                `ANDI  : result = lhs & imm;

                `SLL   : result = lhs << rhs[4:0];
                `SLLI  : result = lhs << shamt;
                `SRL   : result = lhs >>> rhs[4:0];
                `SRLI  : result = lhs >>> shamt;
                `SRA   : result = lhs >> rhs[4:0];
                `SRAI  : result = lhs >> shamt;
                `SLT   : result = $signed(lhs) < $signed(rhs);
                `SLTI  : result = $signed(lhs) < $signed(imm);
                `SLTU  : result = lhs < rhs;
                `SLTIU : result = lhs < rhs;
                `BEQ   : begin
                    if(lhs == rhs)begin
                        result = 1;
                        CDB_pc = pc + imm;
                    end
                    else begin
                        result = 0;
                        CDB_pc = pc + 4;
                    end
                end
                `BNE   : begin
                    if(lhs != rhs)begin
                        result = 1;
                        CDB_pc = pc + imm;
                    end
                    else begin
                        result = 0;
                        CDB_pc = pc + 4;
                    end
                end 
                `BLT   : begin
                    if($signed(lhs) < $signed(rhs))begin
                        result = 1;
                        CDB_pc = pc + imm;
                    end
                    else begin
                        result = 0;
                        CDB_pc = pc + 4;
                    end
                end 
                `BGE   : begin
                    if($signed(lhs) >= $signed(rhs))begin
                        result = 1;
                        CDB_pc = pc + imm;
                    end
                    else begin
                        result = 0;
                        CDB_pc = pc + 4;
                    end
                end 
                `BLTU  : begin
                    if(lhs < rhs)begin
                        result = 1;
                        CDB_pc = pc + imm;
                    end
                    else begin
                        result = 0;
                        CDB_pc = pc + 4;
                    end
                end 
                `BGEU  : begin
                    if(lhs >= rhs)begin
                        result = 1;
                        CDB_pc = pc + imm;
                    end
                    else begin
                        result = 0;
                        CDB_pc = pc + 4;
                    end
                end 
                `JAL:begin
                    result = pc+4;
                    CDB_pc = imm;
                end
                `JALR  : begin
                    result = pc + 4;
                    CDB_pc = (lhs + imm) & ~(32'b1); 
                end  
                //lhs=x[rs1] rhs=signed_extended offset
                default:begin
                    result = 0;
                    CDB_pc = 0;
                end 

            endcase
        end
    end

endmodule