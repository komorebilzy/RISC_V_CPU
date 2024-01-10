// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "defines.v"
`include "icache.v"
`include "memory_control.v"
`include "ifetch.v"
`include "regfile.v"
`include "rob.v"
`include "rs.v"
`include "alu.v"
`include "lsb.v"
module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

//memctrl
wire [31:0] icache_pc_in;
wire icache_pc_miss;
wire icache_finish_ins;
wire [31:0] icache_ins_out;
wire [31:0] rob_store_data;
wire [31:0] rob_store_addr;
wire [5:0] rob_store_op;
wire rob_store_sgn;
wire rob_store_finish;
wire begin_real_store;
wire [31:0] lsb_load_addr;
wire [5:0] lsb_load_op;
wire lsb_load_sgn;
wire lsb_load_finish;
wire [31:0] lsb_load_data;

//icache-ifetch
wire [31:0] IF_addr;
wire IF_addr_sgn;
wire [31:0] IF_val;
wire IF_val_sgn;

//ifetch
wire [5:0] rob_entry_idle;
wire [31:0] rob_pc_predict;
wire rob_update;
wire rob_is_branch_ins;
wire [31:0] rob_pc_update;
wire rob_is_jalr;
wire [6:0] hash_idex_pc;
wire rollback;

wire [5:0] issue_entry;
wire  [31:0] issue_pc;
wire [5:0] issue_rd;
wire [5:0] issue_rs1;
wire [5:0] issue_rs2;
wire [31:0] issue_imm;
wire [5:0] issue_op;
wire issue_ins;
wire issue_is_load_store;

//issue
wire [31:0] issue_Vj_out;
wire [31:0] issue_Vk_out;
wire [`ROBENTRY] issue_Qj_out;
wire [`ROBENTRY] issue_Qk_out;

//regfile
wire reg_commit_sgn;
wire [`ROBENTRY] rob_commit_entry;
wire [5:0] rob_commit_des;
wire [31:0] rob_commit_result;


//rs
wire rs_full;

wire lsb_full;

wire rob_full;
wire lsb_load_broadcast;
wire [`ROBENTRY] load_entry_out;
wire [31:0] load_result;
wire lsb_store_broadcast;
wire [`ROBENTRY] store_entry_out;
wire [31:0] store_addr;
wire [31:0] store_result;
// wire [31:0] lsb_pc_out;

//alu
wire calculate;
wire [5:0] alu_op_in;
wire [31:0] alu_lhs_in;
wire [31:0] alu_rhs_in;
wire [31:0] alu_imm_in;
wire [31:0] alu_pc_in;
wire [`ROBENTRY] alu_entry_in;
wire [5:0] alu_entry_out;
wire [31:0] alu_result_out;
wire [31:0] alu_pc_out;
wire [31:0] alu_pc_init_out;
wire alu_broadcast;

memory_control u_memory_control(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .rollback(rollback),
  .pc_in(icache_pc_in),
  .pc_miss_sgn(icache_pc_miss),
  .finish_ins(icache_finish_ins),
  .ins_out(icache_ins_out),
  .store_data_in(rob_store_data),
  .store_addr_in(rob_store_addr),
  .store_op(rob_store_op),
  .store_sgn(rob_store_sgn),
  .begin_real_store(begin_real_store),
  .finish_store(rob_store_finish),
  .load_addr(lsb_load_addr),
  .load_op(lsb_load_op),
  .load_sgn(lsb_load_sgn),
  .finish_load(lsb_load_finish),
  .load_data(lsb_load_data),
  .mem_din(mem_din),
  .mem_dout(mem_dout),
  .mem_addr(mem_a),
  .mem_rw(mem_wr)
);

icache u_icache(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .rollback(rollback),
  .MC_val(icache_ins_out),
  .MC_val_sgn(icache_finish_ins),
  .Mc_addr(icache_pc_in),
  .Mc_addr_sgn(icache_pc_miss),
  .IF_addr(IF_addr),
  .IF_addr_sgn(IF_addr_sgn),
  .IF_val(IF_val),
  .IF_val_sgn(IF_val_sgn)
);

ifetch u_ifetch(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .IC_ins_sgn(IF_val_sgn),
  .IC_ins(IF_val),
  .IC_addr(IF_addr),
  .IC_addr_sgn(IF_addr_sgn),
  .entry_idle(rob_entry_idle),
  .pc_predict(rob_pc_predict),
  .update(rob_update),
  .is_branch_ins(rob_is_branch_ins),
  .pc_update(rob_pc_update),
  .is_jalr(rob_is_jalr),
  .hash_idex_pc(hash_idex_pc),
  .rollback(rollback),
  .entry_rob(issue_entry),
  .pc(issue_pc),
  .rd(issue_rd),
  .rs1(issue_rs1),
  .rs2(issue_rs2),
  .imm(issue_imm),
  .op(issue_op),
  .issue_ins(issue_ins),
  .is_load_store(issue_is_load_store)
);

regfile u_regfile(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .rd(issue_rd),
  .rs1(issue_rs1),
  .rs2(issue_rs2),
  .rob_new_entry(issue_entry),
  .issue_sgn(issue_ins),
  .Vj(issue_Vj_out),
  .Vk(issue_Vk_out),
  .Qj(issue_Qj_out),
  .Qk(issue_Qk_out),
  
  .rob_entry(rob_commit_entry),
  .rob_des(rob_commit_des),
  .rob_result(rob_commit_result),
  .commit_sgn(reg_commit_sgn)
);

alu u_alu(
  .clk(clk_in),
  .rdy(rdy_in),
  .rst(rst_in),

  .RS_sgn(calculate_sgn),
  .RS_opcode(alu_op_in),
  .lhs(alu_lhs_in),
  .rhs(alu_rhs_in),
  .imm(alu_imm_in),
  .pc(alu_pc_in),
  .ROB_entry(alu_entry_in),
  .CDB_ROB_name(alu_entry_out),
  .result(alu_result_out),
  .CDB_pc_init(alu_pc_init_out),
  .CDB_pc(alu_pc_out),
  .CDB_sgn(alu_broadcast)
);


rs u_rs(
  .clk(clk_in),
  .rdy(rdy_in),
  .rst(rst_in),
  .get_instruction(issue_ins),
  .is_load_store(issue_is_load_store),
  .pc_now_in(issue_pc),
  .entry_in(issue_entry),
  .rollback(rollbcak),
  .rs_full(rs_full),
  .Vj_in(issue_Vj_out),
  .Vk_in(issue_Vk_out),
  .Qj_in(issue_Qj_out),
  .Qk_in(issue_Qk_out),
  .imm_in(issue_imm),
  .op_in(issue_op),
  .rd_in(issue_rd),

  .calculate_sgn(calculate_sgn),
  .op_out(alu_op_in),
  .Vj_out(alu_lhs_in),
  .Vk_out(alu_rhs_in),
  .imm_out(alu_imm_in),
  .pc_out(alu_pc_in),
  .entry_out(alu_entry_in),
  .alu_broadcast(alu_broadcast),
  .alu_entry(alu_entry_out),
  .alu_result(alu_result_out),
  .alu_pc_out(alu_pc_out),
  .alu_pc_init(alu_pc_init_out),

  .lsb_broadcast(lsb_load_broadcast),
  .lsb_result(load_result),
  .lsb_entry(load_entry_out),
  .rob_commit(reg_commit_sgn),
  .rob_entry(rob_commit_entry),
  .rob_result(rob_commit_result)
);

lsb u_lsb(
  .clk(clk_in),
  .rdy(rdy_in),
  .rst(rst_in),
  .get_instruction(issue_ins),
  .is_load_store(issue_is_load_store),
  .pc_now_in(issue_pc),
  .entry_in(issue_entry),
  .rollback(rollbcak),
  .lsb_full(lsb_full),
  .Vj_in(issue_Vj_out),
  .Vk_in(issue_Vk_out),
  .Qj_in(issue_Qj_out),
  .Qk_in(issue_Qk_out),
  .imm_in(issue_imm),
  .op_in(issue_op),
  .rd_in(issue_rd),

  .alu_broadcast(alu_broadcast),
  .alu_entry(alu_entry_out),
  .alu_result(alu_result_out),

  .lsb_load_broadcast(lsb_load_broadcast),
  .load_entry_out(load_entry_out),
  .load_result(load_result),
  .lsb_store_broadcast(lsb_store_broadcast),
  .store_entry_out(store_entry_out),
  .store_addr(store_addr),
  .store_result(store_result),
  // .pc_out(lsb_pc_out),

  .rob_commit(reg_commit_sgn),
  .rob_entry(rob_commit_entry),
  .rob_result(rob_commit_result),

  .mem_valid(lsb_load_finish),
  .mem_res(lsb_load_data),
  .load_store_sgn(lsb_load_sgn),
  .load_store_op(lsb_load_op),
  .load_store_addr(lsb_load_addr),
  .finish_store(rob_store_finish)

);

rob u_rob(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .get_instruction(issue_ins),
  .op_in(issue_op),
  .rd_in(issue_rd),
  .pc_pred(rob_pc_predict),
  .entry_out(rob_entry_idle),
  .rob_full(rob_full),
  .rollback(rollback),

  .rs_broadcast(alu_broadcast),
  .rs_entry_out(alu_entry_out),
  .rs_result(alu_result_out),
  .rs_pc_out(alu_pc_out),
  .rs_pc_init(alu_pc_init_out),
  .lsb_load_broadcast(lsb_load_broadcast),
  .load_entry_out(load_entry_out),
  .load_result(load_result),
  .lsb_store_broadcast(lsb_store_broadcast),
  .store_entry_out(store_entry_out),
  .store_addr(store_addr),
  .store_result(store_result),
  // .lsb_pc_out(lsb_pc_out),

  .rob_store_sgn(rob_store_sgn),
  .rob_store_op(rob_store_op),
  .rob_store_addr(rob_store_addr),
  .rob_store_data(rob_store_data),
  .begin_real_store(begin_real_store),
  .finish_store(rob_store_finish),

  .commit_sgn(reg_commit_sgn),
  .rob_entry(rob_commit_entry),
  .rob_des(rob_commit_des),
  .rob_result(rob_commit_result),

  .is_branch_ins(rob_is_branch_ins),
  .update(rob_update),
  .pc_update(rob_pc_update),
  .is_jalr(rob_is_jalr),
  .hash_idex_pc(hash_idex_pc)
);


endmodule