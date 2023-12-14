`include "defines.v"

module rob(
    input wire clk,
    input wire rst,
    input wire rdy,

    //issue
    input wire get_instruction,
    input wire inst_in,
    input wire value_in,
    input wire op_in,
    input wire rd_in,
    input wire pc_in,
    output reg [`ROBENTRY] entry_out,
    output wire rob_full,

    //exe
    input wire rs_broadcast,
    input wire [`ROBENTRY] rs_entry_out,
    input wire [31:0] rs_result,
    input wire [31:0] rs_pc_out,

    input wire lsb_load_broadcast,
    input wire [`ROBENTRY] load_entry_out,
    input wire [31:0] load_result,
    input wire lsb_store_broadcast,
    input wire [`ROBENTRY] store_entry_out,
    input wire [31:0] store_addr,
    input wire [31:0] store_result,

    
    //commit 
    //to mem
    output reg  rob_store_sgn,
    output reg [4:0]  rob_store_op,
    output reg [31:0] rob_store_addr,
    output reg [31:0] rob_store_data,

    //to regdfile
    output reg commit_sgn,
    output reg [`ROBENTRY] rob_entry,  //指令编号
    output reg [5:0] rob_des,   //rd对应地址
    output reg [31:0] rob_result,

    input wire finish_store
);
    parameter ROB_SIZE = 32;
    reg ready [ROB_SIZE-1:0];
    reg [`ROBENTRY] entry [ROB_SIZE-1:0];
    reg [31:0] inst [ROB_SIZE-1:0];
    reg [31:0] value [ROB_SIZE-1:0];
    reg [31:0] addr [ROB_SIZE-1:0];
    reg [5:0] op [ROB_SIZE-1:0];
    reg [5:0] rd [ROB_SIZE-1:0];
    reg [31:0] pc [ROB_SIZE-1:0];
    reg [5:0] head,tail;
    wire [5:0] next_head,next_tail;
    wire empty,full;
    reg is_storing;

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
                addr[i] <= 0;
                op[i] <= 0;
                rd[i] <= 0;
                pc[i] <= 0;
            end
            head <= 0;
            tail <= 0;
            entry_out <= `ENTRY_NULL;
            rob_store_sgn <= `FALSE;
            rob_store_op <= 0;
            rob_store_addr <= 0;
            rob_store_data <= 0;
            commit_sgn <= 0;
            rob_entry <= `ENTRY_NULL;
            rob_des <= 0;
            rob_result <= 0;
            is_storing <= `FALSE;
        end

        else if(!rdy)begin

        end
        else begin
            if(get_instruction)begin
                ready[next_tail] <= `FALSE;
                entry[next_tail] <= next_tail;
                inst[next_tail] <= inst_in;
                value[next_tail] <= value_in;
                op[next_tail] <= op_in;
                rd[next_tail] <= rd_in;
                pc[next_tail] <= pc_in;
                tail <= next_tail;
            end

            if(!empty && ready[next_head] && !is_storing )begin
                //here predictor
                if(op[next_head]<`SB && op[next_head]>`SW)begin
                    commit_sgn <=  `TRUE;
                    rob_store_sgn <= `FALSE;
                    rob_entry <= entry[next_head];
                    rob_des <= rd[next_head];
                    rob_result <= value[next_head];
                    entry[next_head] <= `ENTRY_NULL;
                    ready[next_head] <= `FALSE;
                    head <= next_head;
                end
                else begin
                    rob_store_sgn <= `TRUE;
                    commit_sgn <=  `FALSE;
                    rob_store_op <= op[next_head];
                    rob_store_addr <= value[next_head];
                    rob_store_data <= addr[next_head];
                    entry[next_head] <= `ENTRY_NULL;
                    ready[next_head] <= `FALSE;
                    is_storing <= `TRUE;
                    
                end
            end
            else begin
                rob_store_sgn <= `FALSE;
                commit_sgn <=  `FALSE;
            end

            if(finish_store) begin
                is_storing <= `FALSE;
                head <= next_head;
            end 

            if(lsb_load_broadcast)begin
                for(i=0;i<32;i=i+1)begin
                    if(entry[i]==load_entry_out)begin
                        ready[i] <= `TRUE;
                        value[i] <= load_result;
                    end
                end
            end

            if(lsb_store_broadcast)begin
                for(i=0;i<32;i=i+1)begin
                    if(entry[i]==store_entry_out)begin
                        ready[i] <= `TRUE;
                        addr[i] <= store_addr;
                        value[i] <= store_result;
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