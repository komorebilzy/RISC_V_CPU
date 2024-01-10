//解析指令 得到op,rs1,rs2,rd,imm等
`include "defines.v"
`ifndef decoder
`define decoder
module decoder(
    input wire [31:0] inst,

    output reg is_load_store,
    output reg [5:0] rd,
    output reg [5:0] rs1,
    output reg [5:0] rs2,
    output reg [31:0] imm,
    output reg [5:0] op
);

wire [2:0] func3=inst[14:12]; //R I S B type
wire [6:0] func7=inst[31:25]; //R type
wire [6:0] opcode=inst[6:0];

wire [31:0] immI={{20{inst[31]}},inst[31:20]};
wire [31:0] immS={{20{inst[31]}},inst[31:25],inst[11:7]};
wire [31:0] immB={{20{inst[31]}},{inst[7]},inst[30:25],inst[11:8],1'b0};
wire [31:0] immU={inst[31:12],12'b0};
wire [31:0] immJ={{12{inst[31]}},inst[19:12],{inst[20]},inst[30:21],1'b0};


//here it is 组合逻辑
always @(*) begin
    is_load_store = (opcode==`L_type)||(opcode==`S_type);

    rd={1'b0,inst[11:7]};
    rs1={1'b0,inst[19:15]};
    rs2={1'b0,inst[24:20]};
    imm=32'b0;

    case(opcode)
        `R_type:begin 
            case(func3)
                3'b000:case(func7)
                    7'b0000000:op=`ADD;
                    default:op=`SUB;
                 endcase
                3'b001:op=`SLL;
                3'b010:op=`SLT;
                3'b011:op=`SLTU;
                3'b100:op=`XOR;
                3'b101:case(func7)
                    7'b0000000:op=`SRL;
                    default:op=`SRA;
                 endcase
                3'b110:op=`OR;
                3'b111:op=`AND;
            endcase
        end

        `L_type:begin
            imm=immI;
            rs2=`NULL;
            case(func3)
            3'b000: op=`LB;
            3'b001: op=`LH;
            3'b010: op=`LW;
            3'b100: op=`LBU;
            3'b101: op=`LHU;
        endcase
        end

        `S_type:begin
            imm=immS;
            rd=`NULL;
            case(func3)
                3'b000: op=`SB;
                3'b001: op=`SH;
                3'b010: op=`SW;
            endcase
        end

        `B_type:begin
            imm=immB;
            rd=`NULL;
            case(func3)
            3'b000: op=`BEQ;
            3'b001: op=`BNE;
            3'b100: op=`BLT;
            3'b101: op=`BGE;
            3'b110: op=`BLTU;
            3'b111: op=`BGEU;
        endcase
        end

        `I_type:begin
            imm=immI;
            rs2=`NULL;
            case(func3)
            3'b000:op=`ADDI;
            3'b010:op=`SLTI;
            3'b011:op=`SLTIU;
            3'b100:op=`XORI;
            3'b110:op=`ORI;
            3'b111:op=`ANDI;
            3'b001:op=`SLLI;
            3'b101:case(func7)
                    7'b0000000:op=`SRLI;
                    default:op=`SRAI;
                 endcase
        endcase
        end
        
        `Jal_type:begin
            imm=immJ;
            rs1=`NULL;
            rs2=`NULL;
            op=`JAL;
        end

        `Jalr_type:begin
            imm=immI;
            rs2=`NULL;
            op=`JALR;
        end

        `Lui_type:begin 
            imm=immU;
            rs1=`NULL;
            rs2=`NULL;
            op=`LUI;
        end

        `Auipc_type:begin
            imm=immU;
            rs1=`NULL;
            rs2=`NULL;
            op=`AUIPC;
        end
    endcase


end

endmodule
`endif


