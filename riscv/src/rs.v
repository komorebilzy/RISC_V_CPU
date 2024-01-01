`include "defines.v"
`ifndef rs
`define rs
module rs(
    input wire clk,
    input wire rst,
    input wire rdy,
//issue
    input wire get_instruction,
    input wire is_load_store,
    input wire [31:0] pc_now_in,
    input wire [`ROBENTRY] entry_in,
    output wire rs_full,

    input wire rollback, //predict is wrong

    //from regfile
    input wire [31:0] Vj_in,
    input wire [31:0] Vk_in,
    input wire [`ROBENTRY] Qj_in,
    input wire [`ROBENTRY] Qk_in,

    //from decoder
    input wire [31:0] imm_in,
    input wire [5:0] op_in,
    input wire [5:0] rd_in,


//execute
    //to alu 
    output reg calculate_sgn,
    output reg [5:0] op_out,
    output reg [31:0] Vj_out,
    output reg [31:0] Vk_out,
    output reg [31:0] imm_out,
    output reg [31:0] pc_out,
    // output reg [31:0] inst_out,
    output reg [`ROBENTRY] entry_out,
    
    //from CDB
    input wire alu_broadcast,
    input wire [`ROBENTRY] alu_entry,
    input wire [31:0] alu_result,
    input wire [31:0] alu_pc_out,
    input wire [31:0] alu_pc_init,

    //todo from lsb
    input wire lsb_broadcast,
    input wire [31:0] lsb_result,
    input wire [`ROBENTRY] lsb_entry,

//commit
    //from rob
    input wire rob_commit,
    input wire [`ROBENTRY] rob_entry,
    input wire [31:0] rob_result
);
    parameter RS_SIZE=32;
    reg [2:0] state [RS_SIZE-1:0];
    reg [5:0] op [RS_SIZE-1:0];
    reg [31:0] Vj [RS_SIZE-1:0];
    reg [31:0] Vk [RS_SIZE-1:0];
    reg [`ROBENTRY] Qj [RS_SIZE-1:0];
    reg [`ROBENTRY] Qk [RS_SIZE-1:0];
    reg [`ROBENTRY] entry [RS_SIZE-1:0];
    reg [31:0] imm [RS_SIZE-1:0];
    reg [31:0] rs_pc [RS_SIZE-1:0];

    //记录当前state
    reg [`ROBENTRY] cur_rs_empty;
    reg [`ROBENTRY] cur_rs_ready;

    assign rs_full =  cur_rs_empty == `ENTRY_NULL;
    integer i;
    always @(posedge clk)begin
        if(rst || rollback)begin
            for(i = 0; i < RS_SIZE; i = i + 1)begin
                state[i] <= `EMPTY;
                op[i] <= 0;
                Vj[i] <= 0;
                Vk[i] <= 0;
                Qj[i] <= `ENTRY_NULL;
                Qk[i] <= `ENTRY_NULL;
                entry[i] <= `ENTRY_NULL;
                imm[i] <= 0;
                rs_pc[i] <= 0;
            end
            calculate_sgn <= 0;
            op_out <= 0;
            Vj_out <= 0;
            Vk_out <= 0;
            imm_out <= 0;
            pc_out <= 0;
            // inst_out <= 0;
            entry_out <= `ENTRY_NULL;    
        end
        else if(!rdy) begin
            //pause
        end
        else begin
            //issue
            if(get_instruction && !is_load_store)begin
                state[cur_rs_empty] <= `WAITING;
                op[cur_rs_empty] <= op_in;
                entry[cur_rs_empty] <= entry_in;
                imm[cur_rs_empty] <= imm_in;
                rs_pc[cur_rs_empty] <= pc_now_in;

                Qj[cur_rs_empty] <= Qj_in;
                Vj[cur_rs_empty] <= Vj_in;
                Qk[cur_rs_empty] <= Qk_in;
                Vk[cur_rs_empty] <= Vk_in;
            end

            //update the state to ready
            for(i = 0; i < RS_SIZE; i = i + 1)begin
                if(state[i] == `WAITING && Qj[i] == `ENTRY_NULL && Qk[i] == `ENTRY_NULL)
                state[i] <= `READY;
            end

            //execute
            if(alu_broadcast)begin
                for(i = 0; i < RS_SIZE; i = i + 1)begin
                    if(state[i] == `WAITING) begin
                        if(Qj[i]==alu_entry)begin
                            Qj[i] <= `ENTRY_NULL;
                            Vj[i] <= alu_result;
                        end
                        else if(Qk[i]==alu_entry)begin
                            Qk[i] <= `ENTRY_NULL;
                            Vk[i] <= alu_result;
                        end
                    end
                end
            end

            if(lsb_broadcast)begin
                for(i = 0; i < RS_SIZE; i = i + 1)begin
                    if(state[i]==`WAITING) begin
                        if(Qj[i]==lsb_entry)begin
                            Qj[i] <= `ENTRY_NULL;
                            Vj[i] <= lsb_result;
                        end
                        else if(Qk[i]==lsb_entry)begin
                            Qk[i] <= `ENTRY_NULL;
                            Vk[i] <= lsb_result;
                        end
                    end
                end
            end

            if (cur_rs_ready != `ENTRY_NULL)begin // find waiting
                calculate_sgn   <= `TRUE;
                op_out   <= op       [cur_rs_ready];
                Vj_out   <= Vj       [cur_rs_ready];
                Vk_out   <= Vk       [cur_rs_ready];
                imm_out  <= imm      [cur_rs_ready];
                pc_out   <= rs_pc    [cur_rs_ready];
                // inst_out <= inst     [cur_rs_ready];
                entry_out <= entry   [cur_rs_ready];
                state[cur_rs_ready] <= `EMPTY;
            end
            else begin
                calculate_sgn <= `FALSE;
            end

            //COMMIT
            if(rob_commit)begin
                for(i = 0; i < RS_SIZE; i = i + 1)begin
                    if(state[i]==`WAITING) begin
                        if(Qj[i]==rob_entry)begin
                            Qj[i] <= `ENTRY_NULL;
                            Vj[i] <= rob_result;
                        end
                        else if(Qk[i]==rob_entry)begin
                            Qk[i] <= `ENTRY_NULL;
                            Vk[i] <= rob_result;
                        end
                    end
                end
            end
        end
    end

    integer j, k;
    always @(*)begin //随时改变,乱序执行 所以没必要按顺序找
        cur_rs_empty = `ENTRY_NULL;
        for(j = RS_SIZE-1 ; j >= 0; j = j - 1)begin
            if(state[j] == `EMPTY)begin
                cur_rs_empty = j;
                // break;  we cannot use break in if's body
            end
        end

        cur_rs_ready = `ENTRY_NULL;
        for(k = RS_SIZE -1 ; k  >= 0 ; k = k - 1)begin
            if(state[k] == `READY)begin
                cur_rs_ready = k;
                // break;
            end
        end
    end

endmodule
`endif