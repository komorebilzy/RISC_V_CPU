`include "defines.v"
//优先级顺序：store > load > fetch
`ifndef mem_ctrl 
`define mem_ctrl
module memory_control(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,
    //from icache
    input wire [31:0] pc_in,
    input wire pc_miss_sgn,
    output reg finish_ins,
    output reg [31:0] ins_out,

    //store form ROB
    input wire [31:0] store_data_in,
    input wire [31:0] store_addr_in,
    input wire [5:0] store_op,
    input wire store_sgn,
    output wire begin_real_store,
    output reg finish_store,

    //load from LSB
    input wire [31:0] load_addr,
    input wire [5:0] load_op,
    input wire load_sgn,
    output wire begin_real_load,
    output reg finish_load,
    output reg [31:0] load_data,

    //RAM
    input wire [7:0] mem_din,
    output reg [7:0] mem_dout,
    output reg [31:0] mem_addr,
    output reg mem_rw  //0 for read and 1 for write
);

reg [2:0] ins_offset;  
reg [2:0] store_offset;
reg [2:0] load_offset;
reg [31:0] addr_record;

reg is_idle;
reg is_storing;
reg is_loading;
reg is_fetching;

assign begin_real_store= is_storing;
assign begin_real_load=is_loading;

always @(posedge clk) begin
    if(rst || rollback)begin
        is_idle <= `TRUE;
        is_storing <= `FALSE;
        is_loading <= `FALSE;
        is_fetching <= `FALSE;
        ins_offset <= 0;
        store_offset <=0;
        load_offset <= 0;
        addr_record <= 0;

        finish_ins <=  `FALSE;
        finish_store <= `FALSE;
        finish_load <= `FALSE;
        load_data <= 0;

        mem_dout <= 0;
        mem_addr <= 0;
    end
    else if(!rdy) begin
        //pause
    end
    else begin
        if (is_idle)begin
            finish_ins <=  `FALSE;
            finish_store <= `FALSE;
            finish_load <= `FALSE;
            if(store_sgn)begin
                is_storing <= `TRUE;
                is_idle<=  `FALSE;
                addr_record <= store_addr_in;
                case(store_op)
                    `SB: begin   store_offset<= 3'b001;   end
                    `SH: begin   store_offset<= 3'b010;   end
                    `SW: begin   store_offset<= 3'b100;   end
                endcase
            end
            else if(load_sgn)begin
                is_loading <= `TRUE;
                is_idle<=  `FALSE;  
                load_data <= 0; 
                mem_addr <= load_addr;
                mem_rw <= 0;
                case(load_op)
                    `LB : begin   load_offset<= 3'b001;   end
                    `LBU: begin   load_offset<= 3'b001;   end
                    `LH: begin   load_offset<= 3'b010;   end
                    `LHU: begin   load_offset<= 3'b010;   end
                    `LW: begin   load_offset<= 3'b100;   end
                endcase        
            end
            else if(pc_miss_sgn)begin
                is_fetching <= `TRUE;
                is_idle <=  `FALSE;
                ins_offset <= 0;
                mem_addr <= pc_in;
                mem_rw <= 0;
            end 
        end
        else begin
            if(is_storing)begin
                mem_rw <= 1;  //big bug:应该在此处修改mem_rw状态而不是在前面的store_sgn，否则会把正在读取的地址的数据修改掉
                if(store_op==`SW)begin
                    if(store_offset==4) mem_dout <= store_data_in[7:0];
                    else if(store_offset==3) mem_dout <= store_data_in[15:8];
                    else if(store_offset==2) mem_dout <= store_data_in[23:16];
                    else if(store_offset==1) mem_dout <= store_data_in[31:24];
                    else begin
                        is_storing <= `FALSE;
                        finish_store <=  `TRUE;
                        is_idle <= `TRUE;
                    end
                    store_offset <= store_offset - 1 ;
                    mem_addr <= addr_record;
                    addr_record <= addr_record + 1;
                end
                else if(store_op==`SH)begin
                    // $display("offset ",store_offset," data ",store_data_in[7:0]," ",store_data_in[15:8],"addr ",addr_record);
                    if(store_offset==2) mem_dout <= store_data_in[7:0];
                    else if(store_offset==1) mem_dout <= store_data_in[15:8];
                    else begin
                        is_storing <= `FALSE;
                        finish_store <=  `TRUE;
                        is_idle <= `TRUE;
                    end
                    store_offset <= store_offset - 1 ;
                    mem_addr <= addr_record;
                    addr_record <= addr_record + 1;
                end
                else if(store_op==`SB)begin
                    // $display("wwww",store_data_in);
                    if(store_offset==1) begin
                        // $display("real store",store_data_in[7:0]," mem_dout ",mem_dout);
                        mem_dout <= store_data_in[7:0];
                    end
                    else begin
                        // $display("no use store",store_data_in[7:0]," mem_dout ",mem_dout);
                        is_storing <= `FALSE;
                        finish_store <=  `TRUE;
                        is_idle <= `TRUE;
                    end
                    store_offset <= store_offset - 1 ;
                    mem_addr <= addr_record;
                end
            end

            else if(is_loading)begin
                if(load_op==`LW)begin
                    if(load_offset==3) load_data[7:0] <= mem_din;
                    else if(load_offset==2) load_data[15:8] <= mem_din;       
                    else if(load_offset==1)  load_data[23:16] <= mem_din;  
                    else if(load_offset==0) begin
                        load_data[31:24] <= mem_din;
                        is_loading <= `FALSE;
                        finish_load <=  `TRUE;
                        is_idle <= `TRUE;
                    end
                    load_offset <= load_offset - 1 ;
                    mem_addr <= mem_addr + 1;
                end
                else if(load_op==`LH || load_op== `LHU)begin
                    if(load_offset==1)  load_data[7:0] <= mem_din;
                    else if(load_offset==0) begin
                        load_data[15:8] <= mem_din;
                        if(load_op==`LH) load_data[31:16]={16{load_data[15]}};
                        is_loading <= `FALSE;
                        finish_load <=  `TRUE;
                        is_idle <= `TRUE;
                    end
                    load_offset <= load_offset - 1 ;
                    mem_addr <= mem_addr + 1;
                end
                else if(load_op==`LB || load_op== `LBU)begin
                        // $display("mem_addr is ",mem_din);

                    if(load_offset==0)begin
                        load_data[7:0] <= mem_din;
                        if(load_op==`LB) load_data[31:8]={24{load_data[7]}};
                        is_loading <= `FALSE;
                        finish_load <=  `TRUE;
                        is_idle <= `TRUE;
                    end
                    else load_offset <= load_offset - 1;
                        
                end
            end
            else if(is_fetching)begin
                if(ins_offset==1) ins_out[7:0] <= mem_din;
                else if(ins_offset==2) ins_out[15:8] <=mem_din;
                else if(ins_offset==3) ins_out[23:16] <=mem_din;
                else if(ins_offset==4)begin
                    ins_out[31:24] <=mem_din;
                    is_fetching <= `FALSE;
                    finish_ins <= `TRUE;
                    is_idle <= `TRUE;
                end 
                if(ins_offset<4)begin
                    ins_offset <= ins_offset + 1;
                    mem_addr <= mem_addr + 1;
                end
            end
        end  
    end
end



endmodule
`endif