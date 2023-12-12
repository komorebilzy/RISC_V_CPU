`include "defines.v"

module rob(
    input wire clk,
    input wire rst,
    input wire rdy,

    //issue
    input wire get_instruction;
    input wire inst,
    input wire value,
    input wire op,
    input wire rd,
    input wire pc,
    output reg [`ROBENTRY] entry_out,
    output wire rob_full,

    //exe
    input wire rs_broadcast,
    input wire [`ROBENTRY] rs_entry_out,
    input wire [31:0] rs_result,
    input wire [31:0] rs_pc_out,

    input reg lsb_load_broadcast,
    input reg [`ROBENTRY] load_entry_out,
    input reg [31:0] load_result,
    input reg lsb_store_broadcast,
    input reg [`ROBENTRY] store_entry_out,

    //commit 
    //to regdfile
    output wire commit_sgn,
    output wire[`ROBENTRY] rob_entry,  //指令编号
    output wire [5:0] rob_des,   //rd对应地址
    output wire[31:0] rob_result,

    input wire finish_store;
);
    parameter ROB_SIZE = 32;
    reg ready [ROB_SIZE-1:0];
    reg [`ROBENTRY] entry [ROB_SIZE-1:0];
    reg [31:0] inst [ROB_SIZE-1:0];
    reg [31:0] value [ROB_SIZE-1:0];
    reg [5:0] op [ROB_SIZE-1:0];
    reg [5:0] rd [ROB_SIZE-1:0];
    reg [31:0] pc [ROB_SIZE-1:0];
    reg [5:0] head,tail;
    reg [5:0] next_head,next_tail;
    wire empty,full;
    wire is_storing;

    assign next_head = (head + 1) % ROB_SIZE;
    assign next_tail = (tail + 1)% ROB_SIZE;
    assign empty = (head==tail);
    assign full=(next_head==tail);
    assign rob_full=full;

    integer i;

    always @(posedge clk) begin
        if(clk || rob_full) begin
            for(i=0; i < ROB_SIZE; i=i+1) begin
                ready[i] <= 0;
                entry[i] <= `ENTRY_NULL;
                inst[i] <= 0;
                value[i] <= 0;
                op[i] <= 0;
                rd[i] <= 0;
                pc[i] <= 0;
            end
            head <= 0;
            tail <= 0;
            is_storng <= 0;
            entry_out <= `ENTRY_NULL;
            commit_sgn <= 0;
            rob_entry <= `ENTRY_NULL;
            rob_des <= 0;
            rob_result <= 0;
        end

        else if(!rdy)begin

        end
        else begin
            if(get_instruction)begin
                ready[next_tail] <= `FALSE;
                entry[next_tail] <= next_tail;
                inst[next_tail] <= inst;
                value[next_tail] <= value;
                op[next_tail] <= op;
                rd[next_tail] <= rd;
                pc[next_tail] <= pc;
                tail <= next_tail;
            end

            if(!empty && !is_storing && ready[next_head])begin
                commit_sgn <=  `TRUE;
                rob_entry <= entry[next_head];
                rob_des <= rd[next_head];
                rob_result <= value[next_head];
                entry[next_head] <= `ENTRY_NULL;
                ready[next_head] <= `FALSE;

                //here predictor
                if(op[next_head]>=`SB && op[next_head]<=`SW) is_storing <= `TRUE;
                else head <= next_head;
            end
            else begin
                commit_sgn <= `FALSE;
            end

            if(finish_store) begin
                is_storing <= `FALSE;
                head <= next_head;
            end 

            if(lsb_load_broadcast)begin
                for(i=0;i<32;i=i+1)begin
                    if(entry[i]==load_entry)begin
                        ready[i] <= `TRUE;
                        value[i] <= load_result;
                    end
                end
            end

            if(lsb_store_broadcast)begin
                for(i=0;i<32;i=i+1)begin
                    if(entry[i]==store_entry)begin
                        ready[i] <= `TRUE;
                    end
                end
            end

            if(rs_broadcast)begin
                for(i=0;i<32;i=i+1)begin
                    if(entry[i]==rs_entry_out)begin
                        ready[i] <= `TRUE;
                        value[i] <= rs_result;
                        pc[i] <= rs_pc_out;
                    end
                end
            end
        end
    end

endmodule