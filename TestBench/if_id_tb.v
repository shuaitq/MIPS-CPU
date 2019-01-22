`include "defines.v"
`timescale 1ns / 1ps

module if_id_tb;
    reg                 clk;
    reg                 rst;

    reg[5:0]            stall;

    // 来自取指阶段的信号，其中宏定义InstBus表示指令宽度，为32
    reg[`InstAddrBus]   if_pc;
    reg[`InstBus]       if_inst;

    // 对应译码阶段的信息
    wire[`InstAddrBus]  id_pc;
    wire[`InstBus]      id_inst;

    if_id if_id0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .if_pc(if_pc),
        .if_inst(if_inst),
        .id_pc(id_pc),
        .id_inst(id_inst)
    );

    initial
    begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end
    
    initial
    begin
        rst = `RstEnable;
        #195 rst = `RstDisable;
        #1000 $stop;
    end
    
    initial
    begin
        stall <= 6'b000000;
        if_pc <= `ZeroWord;
        if_inst <= `ZeroWord;
    end
    
    initial
    begin
        #250 stall <= 6'b000111;
        if_pc <= 32'b00000000000000010000000000000000;
        if_inst <= 32'b00000000000000000000000010000000;
        
        #50 stall <= 6'b000000;
        
        #50 if_pc <= 32'b00000000000000000000000000000001;
        if_inst <= 32'b00000000000000000000000000000010;
        
        #50 rst <= `RstEnable;
    end
endmodule