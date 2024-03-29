`include "defines.v"
`ifndef regfile
`define regfile
module regfile(
        input wire clk,
        input wire rst,
        input wire rdy,
        input wire rollback,

        //issue阶段
        //from decoder
        input  wire [5:0] rd,
        input wire [5:0] rs1,
        input wire [5:0] rs2,

        //ifetch
        input wire [`ROBENTRY] rob_new_entry,
        input wire issue_sgn,

        //to rs
        output wire [`ROBENTRY] Qj,
        output wire [`ROBENTRY] Qk,
        output wire [31:0] Vj,
        output wire [31:0] Vk,

        //commit阶段
        //from rob
        input wire[`ROBENTRY] rob_entry,  //指令编号
        input wire [5:0] rob_des,   //rd对应地址
        input wire[31:0] rob_result,
        input wire commit_sgn
    );
    reg [31:0] value[31:0];
    reg [`ROBENTRY] reorder[31:0];
    reg busy [31:0];

    //commit的时候forwarding
    assign Qj = rs1 ==`NULL ? `ENTRY_NULL : (busy[rs1] ?((commit_sgn && reorder[rs1]==rob_entry) ? `ENTRY_NULL:reorder[rs1])  : `ENTRY_NULL);
    assign Qk = rs2 ==`NULL ? `ENTRY_NULL : (busy[rs2] ? ((commit_sgn && reorder[rs2]==rob_entry) ? `ENTRY_NULL:reorder[rs2]) : `ENTRY_NULL);
    assign Vj = rs1 ==`NULL ? 32'b0 : (busy[rs1] ?((commit_sgn && reorder[rs1]==rob_entry) ? rob_result:32'b0) : value[rs1]);
    assign Vk = rs2 ==`NULL ? 32'b0 : (busy[rs2] ? ((commit_sgn && reorder[rs2]==rob_entry) ? rob_result:32'b0): value[rs2]);


    integer i;
    always @(posedge clk)begin
        //清空
        if(rst)begin 
            for(i=0;i<32;i=i+1)begin
                value[i] <= 0;
                reorder[i] <= `ENTRY_NULL;
                busy[i] <= `FALSE;                
            end
        end
        else if(rollback)begin
            for(i=0;i<32;i=i+1)begin
                reorder[i] <= `ENTRY_NULL;
                busy[i] <= `FALSE;                
            end
        end

        else if(rdy==`FALSE)begin
            //pause
        end

        else begin
            //debug:若有两条指令，一个commit一个issue且rd相同，我们应该选择新的issue,所以吧commit放前面
            //commit 阶段
            if(commit_sgn && rob_des!=`NULL && rob_des!=0) begin
                value[rob_des] <= rob_result;
                if(reorder[rob_des]==rob_entry)begin
                    busy[rob_des] <= `FALSE;
                    reorder[rob_des] <= `ENTRY_NULL;
                end
            end
            //issue 阶段
            if(issue_sgn && rd!=`NULL && rd!=0)begin
                busy[rd] <= `TRUE;
                reorder[rd] <= rob_new_entry;
            end
        end
    end
endmodule
`endif
