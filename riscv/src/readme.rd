ifetch将取出来的指令传给rob

rob为指令赋予一个编号entry
rob根据指令与reg交互，取出源寄存器数值，判断目的寄存器是否空缺
rob将处理好的指令传给rs

rs确定op vj vk qj qk rd 等信息
rs与alu交互执行指令

执行后后通过CDB传信号给rob
rob再按照编号顺序提交最终结果，与reg或者mem交互


在Verilog中，assign 语句不能直接用于给寄存器赋值，而 always 语句可以用于给线（wire）和寄存器（reg）赋值。
assign 语句：
assign 语句用于连接逻辑（combinational logic），它通常用于将一个表达式的结果赋值给一个线（wire）。
assign 语句只能用于声明线（wire），不能用于声明或更新寄存器（reg）。
assign 语句执行连续赋值，在每个时间步骤都会根据输入信号的值立即计算输出。
always 语句：

always 语句:
可以用于给线（wire）和寄存器（reg）赋值。
当 always 语句包含时钟触发条件时（如 posedge clk 或 negedge clk），它被视为时序逻辑（sequential logic）。
在时序逻辑中，always 块中的代码只在指定的时钟边沿触发时才执行，用于实现状态存储、寄存器更新和时序逻辑操作。
因此，assign 语句主要用于连接逻辑的赋值，而 always 语句可以用于线和寄存器的赋值，并且适用于时钟触发的时序逻辑。

always@(*) 和 always@(posedge clk) 是在Verilog中用于描述 always 块的不同触发条件。
always@(*) 表示在任何信号变化时都会触发 always 块内的代码执行。
当 always@(*) 块中的任何一个敏感信号（sensitive signal）发生变化时，这个块内的代码将立即执行。
这种形式的 always 块通常用于组合逻辑或需要在输入信号变化时立即更新的逻辑。
always@(posedge clk) 表示仅在时钟上升沿（positive edge）时触发 always 块内的代码执行。
当时钟信号 clk 的上升沿到来时，该块内的代码将被触发和执行。
这种形式的 always 块通常用于时序逻辑，在时钟边沿进行状态存储、寄存器更新和时序逻辑操作。
总结起来，always@(*) 在任何敏感信号变化时触发执行，适用于组合逻辑。而 always@(posedge clk) 在时钟上升沿触发执行，主要用于时序逻辑和状态存储。具体使用哪种触发条件取决于设计需求和所要实现的功能。