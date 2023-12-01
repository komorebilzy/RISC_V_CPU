ifetch将取出来的指令传给rob

rob为指令赋予一个编号entry
rob根据指令与reg交互，取出源寄存器数值，判断目的寄存器是否空缺
rob将处理好的指令传给rs

rs确定op vj vk qj qk rd 等信息
rs与alu交互执行指令

执行后后通过CDB传信号给rob
rob再按照编号顺序提交最终结果，与reg或者mem交互