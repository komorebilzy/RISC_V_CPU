//accept inst from ifetch,acquire V Q from regfile,assign entry and V Q imm to RS or LSB
module issue(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire [5:0] entry_rob,
    input wire [31:0] pc,  
    input wire [5:0] rd,
    input wire [5:0] rs1,
    input wire [5:0] rs2,
    input wire [31:0] imm,
    input wire [5:0] op,
    input wire is_load_store,

    //to regfile
    output wire [5:0] rs1_to_reg,
    output wire [5:0] rs2_to_reg,
    output wire [5:0] rd_to_reg,
    input wire [31:0] Vj_from_reg,
    input wire [31:0] Vk_from_reg,
    input wire [`ROBENTRY] Qj_from_reg,
    input wire [`ROBENTRY] Qk_from_reg,

    //to rs lsb rob
    output wire is_ls,
    output wire is_rs,
    // output wire [31:0] pc_now_in,
    // output wire [`ROBENTRY] entry_out,
    output wire [31:0] Vj,
    output wire [31:0] Vk,
    output wire [`ROBENTRY] Qj,
    output wire [`ROBENTRY] Qk,
    // output wire [31:0] imm_out,
    // output wire [5:0] op_out,
    // output wire [5:0] rd_out,
);

assign rs1_to_reg=rs1;
assign rs2_to_reg=rs2;
assign rd_to_reg=rd;
// assign imm_out = imm;
// assign pc_now_in =pc;
// assign rd_out = rd;
// assign op_out = op;
// assign entry_out = entry_rob;
assign Vj = Vj_from_reg;
assign Vk = Vk_from_reg;
assign Qj = Qj_from_reg;
assign Qk = Qk_from_reg;
assign is_ls = is_load_store;
assign is_rs = !is_load_store;


endmodule