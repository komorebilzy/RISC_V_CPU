`define ICSIZE 255:0  //ICache的大小
`define ICSIZESCALAR 256
`define BLOCKNUM 15:0   //ICACHE中BLOCK num
`define ICINDEX 9:6   //inedx
`define ICOFFSET 5:2
`define ICTAG 31:10    //tag
`define INSTRLEN 31:0  //instruction
`define ADDR 31:0      //地址的长度为32位
`define DATALEN 31:0   //data 最长情况下的数据为32位
`define BYTELEN 7:0
`define READ 1'b0
`define WRITE 1'b1 

`define REGSIZE 31:0    //寄存器个数有32个
`define REGINDEX 4:0    //总共有32个寄存器，因此寄存器下标0~31，用5位即可
`define IMMLEN 31:0     //立即数的长度
`define ROBENTRY 5:0
`define NULL 6'd32
`define ENTRY_NULL 6'd32

`define EMPTY 3'b000
`define WAITING 3'b001
`define READY 3'b010  

`define OPLEN 5:0//判断一个计算指令类型的长度
`define OPCODE 6:0//是decoder中的opode所在的地方
`define FUNC3 14:12
`define FUNC7 31:25
`define PREDICTORINDEX 7:0   //预测器index
`define PREDICTORHASH 9:2    //预测器hash
`define TRUE 1'b1
`define FALSE 1'b0

`define R_type 7'b0110011
`define S_type 7'b0100011
`define B_type 7'b1100011
`define I_type 7'b0100011
`define L_type 7'b0000011
`define Lui_type 7'b0110111
`define Auipc_type 7'b0010111
`define Jal_type 7'b1101111
`define Jalr_type 7'b1100111

//instruction
//Load and store
`define LB 6'd0
`define LH 6'd1
`define LW 6'd2
`define LBU 6'd3
`define LHU 6'd4

`define SB 6'd5
`define SH 6'd6
`define SW 6'd7
//U 
`define LUI 6'd8
`define AUIPC 6'd9
//I
`define SUB 6'd10
`define ADD 6'd11
`define ADDI 6'd12
`define XOR 6'd13
`define XORI 6'd14
`define OR 6'd15
`define ORI 6'd16
`define AND 6'd17
`define ANDI 6'd18
`define SLL 6'd19
`define SLLI 6'd20
`define SRL 6'd21
`define SRLI 6'd22
`define SRA 6'd23
`define SRAI 6'd24
`define SLTI 6'd25
`define SLT 6'd26
`define SLTIU 6'd27
`define SLTU 6'd28
//B
`define BEQ 6'd29
`define BNE 6'd30
`define BLT 6'd31
`define BGE 6'd32
`define BLTU 6'd33
`define BGEU 6'd34
//J
`define JAL 6'd35
`define JALR 6'd36

`define B_OP       6'd40
`define L_OP       6'd41
`define S_OP       6'd42
`define I_OP       6'd43
`define R_OP       6'd44
