`include "defines.v"
`ifndef rob
`define rob
module rob(
    input wire clk,
    input wire rst,
    input wire rdy,

    //issue
    input wire get_instruction,
    input wire [5:0]op_in,
    input wire [5:0]rd_in,
    input wire [31:0]pc_pred,
    output wire [`ROBENTRY] entry_out,
    output wire rob_full,  
    input wire rollback,

    //exe
    input wire rs_broadcast,
    input wire [`ROBENTRY] rs_entry_out,
    input wire [31:0] rs_result,
    input wire [31:0] rs_pc_out,
    input wire [31:0] rs_pc_init,

    input wire lsb_load_broadcast,
    input wire [`ROBENTRY] load_entry_out,
    input wire [31:0] load_result,
    input wire lsb_store_broadcast,
    input wire [`ROBENTRY] store_entry_out,
    input wire [31:0] store_addr,
    input wire [31:0] store_result,
    // input wire [31:0] lsb_pc_out,

    
    //commit 
    //to mem
    output reg  rob_store_sgn,
    output reg [5:0]  rob_store_op,
    output reg [31:0] rob_store_addr,
    output reg [31:0] rob_store_data,
    //from mem
    input wire begin_real_store,
    input wire finish_store,

    //to regfile
    output reg commit_sgn,
    output reg [`ROBENTRY] rob_entry,  //指令编号
    output reg [5:0] rob_des,   //rd对应地址
    output reg [31:0] rob_result,

    //to ifetch
    output reg is_branch_ins,
    output reg update,
    output reg [31:0] pc_update,
    output reg [6:0] hash_idex_pc
);
    parameter ROB_SIZE = 32; 
    reg ready [ROB_SIZE-1:0];
    reg [`ROBENTRY] entry [ROB_SIZE-1:0];
    reg [31:0] value [ROB_SIZE-1:0];
    reg [31:0] addr [ROB_SIZE-1:0];
    reg [5:0] op [ROB_SIZE-1:0];
    reg [5:0] rd [ROB_SIZE-1:0];
    reg [31:0] pc_predict [ROB_SIZE-1:0];
    reg [31:0] pc_real[ROB_SIZE-1:0];
    reg [31:0] pc_init[ROB_SIZE-1:0];
    reg [5:0] head,tail;
    wire [5:0] next_head,next_tail;
    wire empty,full;
    reg is_storing;

    assign next_head = (head + 1) % ROB_SIZE;
    assign next_tail = (tail + 1) % ROB_SIZE;
    assign empty = (head==tail);
    assign full=(next_tail==head);
    assign rob_full=full;
    assign entry_out = next_tail;

    integer i;

    always @(posedge clk) begin
        if(rst || rollback) begin
            for(i=0; i < ROB_SIZE; i=i+1) begin
                ready[i] <= 0;
                entry[i] <= `ENTRY_NULL;
                value[i] <= 0;
                addr[i] <= 0;
                op[i] <= 0;
                rd[i] <= 0;
                pc_predict[i] <= 0;
                pc_real[i] <=0;
                pc_init[i] <= 0;
            end
            head <= 0;
            tail <= 0;
            rob_store_sgn <= `FALSE;
            rob_store_op <= 0;
            rob_store_addr <= 0;
            rob_store_data <= 0;
            commit_sgn <= 0;
            rob_entry <= `ENTRY_NULL;
            rob_des <= 0;
            rob_result <= 0;
            is_storing <= `FALSE;
            is_branch_ins <= `FALSE;
            update <= `FALSE;
            pc_update <= 0;
            hash_idex_pc <=0;
        end

        else if(!rdy)begin

        end
        else begin
            if(get_instruction)begin
                // $display("the value of next_tail",next_tail);
                ready[next_tail] <= `FALSE;
                entry[next_tail] <= next_tail;
                op[next_tail] <= op_in;
                rd[next_tail] <= rd_in;
                pc_predict[next_tail] <= pc_pred;
                tail <= next_tail;
            end

            if(!empty && ready[next_head] && !is_storing)begin
                //here predictor
                if(op[next_head]>=`BEQ &&op[next_head]<=`BGEU && pc_real[next_head] != pc_predict[next_head]) begin
                    // $display("predic false,the value of next_head",next_head);
                    // $display(" the value of op",op[next_head]);
                    // $display(" the value of pc_real",pc_real[next_head]," ",pc_predict[next_head]);
                    is_branch_ins <= `TRUE;
                    update <= `TRUE;
                    pc_update <= pc_real[next_head];
                    hash_idex_pc <= pc_init[next_head][6:0];
                end 
                else begin
                    // $display("ready and need commit,the value of next_head",next_head);
                    // $display(" the value of op",op[next_head]);
                    // $display(" the value of pc_real",pc_real[next_head]);
                    if(op[next_head]>=`BEQ && op[next_head]<=`BGEU)begin
                        is_branch_ins <= `TRUE;
                        update <= `FALSE;
                    end
                    if(op[next_head]<`SB || op[next_head]>`SW)begin
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
                    //     $display("ready and need commit,store the value of next_head",next_head);
                    // $display(" the value of op",op[next_head]);
                    // $display(" the address",addr[next_head]);
                    // $display(" the value",value[next_head]);
                        rob_store_sgn <= `TRUE;
                        commit_sgn <=  `FALSE;
                        rob_store_op <= op[next_head];
                        rob_store_addr <= addr[next_head];
                        rob_store_data <= value[next_head];
                        entry[next_head] <= `ENTRY_NULL;
                        ready[next_head] <= `FALSE;
                        is_storing <= `TRUE;                    
                    end
                end
            end
            else if(begin_real_store) rob_store_sgn <= `FALSE;
            else begin
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
                        // pc_real[i] <= lsb_pc_out;
                    end
                end
            end

            if(lsb_store_broadcast)begin
                for(i=0;i<32;i=i+1)begin
                    if(entry[i]==store_entry_out)begin
                        ready[i] <= `TRUE;
                        addr[i] <= store_addr;
                        value[i] <= store_result;
                        // pc_real[i] <= lsb_pc_out;
                        // $display(" lsb_store_broadcast",i," ",lsb_pc_out);
                    end
                end
            end

            if(rs_broadcast)begin
                for(i=0;i<32;i=i+1)begin
                    if(entry[i]==rs_entry_out)begin
                        ready[i] <= `TRUE;
                        value[i] <= rs_result;
                        pc_real[i] <= rs_pc_out;
                        pc_init[i] <= rs_pc_init;
                        // $display(" rs_broadcast",rs_pc_out);
                    end
                end
            end
        end
    end

endmodule
`endif