`include "defines.v"
`ifndef lsb
`define lsb
module lsb(
    input wire clk,
    input wire rst,
    input wire rdy,

//issue
    input wire get_instruction,
    input wire is_load_store,
    input wire [31:0] pc_now_in,
    input wire [`ROBENTRY] entry_in,
    output wire lsb_full,

    input wire rollback,  //predict is wrong

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
    //from CDB
    input wire alu_broadcast,
    input wire [`ROBENTRY] alu_entry,
    input wire [31:0] alu_result,
    
    //to rob by broadcast
    output reg lsb_load_broadcast,
    output reg [`ROBENTRY] load_entry_out,
    output reg [31:0] load_result,

    output reg lsb_store_broadcast,
    output reg [`ROBENTRY] store_entry_out,
    output reg [31:0] store_addr,
    output reg [31:0] store_result,
    // output wire [31:0] pc_out,

//commit
    //from rob
    input wire rob_commit,
    input wire [`ROBENTRY] rob_entry,
    input wire [31:0] rob_result,

    //MEMCTRL
    input wire        mem_valid,
    input wire [31:0] mem_res,
    output reg        load_store_sgn,
    // output reg        load_or_store,
    output reg [5:0]  load_store_op,
    output reg [31:0] load_store_addr,
    input wire begin_real_load,
    // output reg [31:0] load_store_data

    //from mem,只有当前面的store操作都执行完才能进行下一步的load操作
    input wire finish_store
);
    parameter LSB_SIZE=32;
    reg [5:0] op [LSB_SIZE-1:0];
    reg [31:0] Vj [LSB_SIZE-1:0];
    reg [31:0] Vk [LSB_SIZE-1:0];
    reg [`ROBENTRY] Qj [LSB_SIZE-1:0];
    reg [`ROBENTRY] Qk [LSB_SIZE-1:0];
    reg [`ROBENTRY] entry [LSB_SIZE-1:0];
    reg [31:0] imm [LSB_SIZE-1:0];
    reg [2:0] state [LSB_SIZE-1:0]; 

    //LSB必须顺序访问，否则访问内存可能会出错
    reg [5:0] head,tail;
    wire [5:0] next_head,next_tail;
    wire empty,full;

    assign next_head = (head+1) % LSB_SIZE;
    assign next_tail = (tail+1) % LSB_SIZE;
    assign empty = (head==tail);
    assign full=(head==next_tail);
    assign lsb_full=full;

    integer i;
    always @(posedge clk)begin
        // if(lsb_full==1) $display("full");
        // if(rollback) $display("rollback ",next_tail);
        if(rst || rollback)begin
            for(i = 0; i < LSB_SIZE; i = i + 1)begin
                op[i] <= 0;
                Vj[i] <= 0;
                Vk[i] <= 0;
                Qj[i] <= `ENTRY_NULL;
                Qk[i] <= `ENTRY_NULL;
                entry[i] <= `ENTRY_NULL;
                imm[i] <= 0;
                state[i] <= `EMPTY;
            end
            head  <= 0;
            tail  <= 0;
            load_store_sgn <= 0;
            load_store_addr   <= 0;
            load_store_op     <= 0;
            lsb_load_broadcast<= 0;
            load_entry_out    <= 0;
            load_result       <= 0;
            lsb_store_broadcast<=0;
            store_entry_out   <= 0;
            store_addr        <= 0;
            store_result      <= 0;
        end
        else if(!rdy) begin
            //pause
        end
        else begin
            //issue
            if(get_instruction && is_load_store)begin
                // $display(next_tail);
                // $display(pc_now_in," ",next_tail);
                op[next_tail] <= op_in;
                entry[next_tail] <= entry_in;
                imm[next_tail] <= imm_in;
                Qj[next_tail] <= Qj_in;
                Vj[next_tail] <= Vj_in;
                Qk[next_tail] <= Qk_in;
                Vk[next_tail] <= Vk_in;
                state[next_tail] <= `WAITING;
                tail <= next_tail;
            end

            //execute
            if(alu_broadcast)begin
                for(i = 0; i < LSB_SIZE; i = i + 1)begin
                    if(state[i] == `WAITING) begin
                        if(Qj[i]==alu_entry)begin
                            Qj[i] <= `ENTRY_NULL;
                            Vj[i] <= alu_result;
                        end
                        else if(Qk[i]==alu_entry)begin
                            // if(i==9) $display("alu ",alu_result," ",alu_entry);
                            Qk[i] <= `ENTRY_NULL;
                            Vk[i] <= alu_result;
                        end
                    end
                end
            end

            if(lsb_load_broadcast)begin
                for(i = 0; i < LSB_SIZE; i = i + 1)begin
                    if(state[i]==`WAITING) begin
                        if(Qj[i]==load_entry_out)begin
                            Qj[i] <= `ENTRY_NULL;
                            Vj[i] <= load_result;
                        end
                        else if(Qk[i]==load_entry_out)begin
                            // if(i==10) $display("lsb_load");
                            Qk[i] <= `ENTRY_NULL;
                            Vk[i] <= load_result;
                        end
                    end
                end
                lsb_load_broadcast <=`FALSE;
            end

            if(rob_commit)begin
                for(i = 0; i < LSB_SIZE; i = i + 1)begin
                    if(state[i]==`WAITING) begin
                        if(Qj[i]==rob_entry)begin
                            Qj[i] <= `ENTRY_NULL;
                            Vj[i] <= rob_result;
                        end
                        else if(Qk[i]==rob_entry)begin
                            // if(i==10) $display("rob_commit");
                            Qk[i] <= `ENTRY_NULL;
                            Vk[i] <= rob_result;
                        end
                    end
                end
            end
            
            case(state[next_head])
            `WAITING: begin
                if(Qj[next_head] == `ENTRY_NULL && Qk[next_head] == `ENTRY_NULL)begin
                    if(op[next_head]>=`LB && op[next_head]<=`LHU)begin
                        state[next_head] <= `LOAD_FINISHED;
                        load_store_sgn <= `TRUE;
                        load_store_op <= op[next_head];
                        load_store_addr <= Vj[next_head] + imm[next_head];
                    end
                    else begin
                        // if(next_head==8) $display("entry[next_head] ",entry[next_head]);
                        state[next_head] <= `IS_STORING;
                        //it is to rob
                        lsb_store_broadcast <= `TRUE;
                        store_entry_out <= entry[next_head];
                        store_addr <= Vj[next_head] + imm[next_head];
                        store_result <= Vk[next_head];
                    end
                end
                    
            end

            `LOAD_FINISHED: begin
                if(begin_real_load)
                    load_store_sgn <= `FALSE;
                if(mem_valid) begin
                    // $display(entry[next_head], " mem_result ",mem_res);
                    lsb_load_broadcast <= `TRUE;
                    load_entry_out <= entry[next_head];
                    load_result <= mem_res;
                    state[next_head] <= `EMPTY;
                    head <= next_head;
                end
            end

            `IS_STORING :begin
                if(finish_store)begin                    
                    lsb_store_broadcast <= `FALSE;
                    state[next_head] <= `EMPTY;
                    head <= next_head;
                end
            end
            endcase
        end
    end

endmodule
`endif