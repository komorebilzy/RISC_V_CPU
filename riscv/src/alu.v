`include "defines.v"
`ifndef alu
`define alu
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
    output wire [5:0] CDB_ROB_name,
    output reg [31:0] result,
    output reg [31:0] CDB_pc_init,
    output reg [31:0] CDB_pc,
    output wire CDB_sgn
);
   
    wire [4:0] shamt;            
    assign shamt = imm[4:0];    //bug:此时的imm已经是处理好的imm，i型指令的imm！所以不是[24:20]，而是[4:0]
    assign CDB_sgn = RS_sgn;
    assign CDB_ROB_name = ROB_entry;

    always @(*) begin
        result = 0;
        CDB_pc_init =0;
        CDB_pc =0;
        if(RS_sgn && !rst &&rdy)begin
            
            CDB_pc_init = pc;
            CDB_pc = pc + 4;
            result = 0;
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
                `SLLI  : begin
                    // $display("pc ",CDB_pc_init," lhs ",lhs," imm ",shamt);
                    result = lhs << shamt;
                end
                `SRL   : result = lhs >>> rhs[4:0];
                `SRLI  : result = lhs >>> shamt;
                `SRA   : result = lhs >> rhs[4:0];
                `SRAI  : result = lhs >> shamt;
                `SLT   : result = $signed(lhs) < $signed(rhs);
                `SLTI  : result = $signed(lhs) < $signed(imm);
                `SLTU  : result = lhs < rhs;
                `SLTIU : result = lhs < rhs;

                `LUI : result = imm;
                `AUIPC : result = pc + imm;
                `BEQ   : begin
                    // $display("beq||| ",lhs ," ",rhs);
                    if(lhs == rhs)begin
                        result = 1;
                        CDB_pc = pc + imm;
                    end
                    else begin
                        result = 0;
                    end
                end
                `BNE   : begin
                    // $display("bne!!!!!!!!");
                    if(lhs != rhs)begin
                        result = 1;
                        CDB_pc = pc + imm;
                    end
                    else begin
                        result = 0;
                    end
                end 
                `BLT   : begin
                    if($signed(lhs) < $signed(rhs))begin
                        result = 1;
                        CDB_pc = pc + imm;
                    end
                    else begin
                        result = 0;
                    end
                end 
                `BGE   : begin
                    if($signed(lhs) >= $signed(rhs))begin
                        result = 1;
                        CDB_pc = pc + imm;
                    end
                    else begin
                        result = 0;
                    end
                end 
                `BLTU  : begin
                    if(lhs < rhs)begin
                        result = 1;
                        CDB_pc = pc + imm;
                    end
                    else begin
                        result = 0;
                    end
                end 
                `BGEU  : begin
                    if(lhs >= rhs)begin
                        result = 1;
                        CDB_pc = pc + imm;
                    end
                    else begin
                        result = 0;
                    end
                end 
                `JAL:begin
                    result = pc+4;
                    CDB_pc = pc + imm;
                end
                `JALR  : begin
                    result = pc + 4;
                    CDB_pc = (lhs + imm) & ~(32'b1); 
                    // $display("pc ",pc," lhs ",lhs," imm ",imm);
                end
                default:begin
                    result = 0;
                    CDB_pc = 0;
                end 
            endcase
            $display(CDB_ROB_name," result ",result);
        end
    end

endmodule
`endif