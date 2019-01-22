`include "defines.v"
`timescale 1ns / 1ps

module pc_reg_tb;
    wire[`InstAddrBus]  pc;
    wire                ce;
    
    reg                 clk;
    reg                 rst;

    // 来自控制模块的信息
    reg[5:0]            stall;
    
    // 来自译码阶段ID模块的信息
    reg                 branch_flag_i;
    reg[`RegBus]        branch_target_address_i;

    pc_reg pc_reg0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .branch_flag_i(branch_flag_i),
        .branch_target_address_i(branch_target_address_i),
        .pc(pc),
        .ce(ce)
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
        branch_flag_i <= `NotBranch;
        branch_target_address_i <= `ZeroWord;
    end
    
    initial
    begin
//        #200;
//        #50;
        #250 stall <= 6'b000111;
        branch_flag_i <= `Branch;
        branch_target_address_i <= 32'b00000000000000000000000000010000;
//        #50;
        #50 stall <= 6'b000001;
//        #50;
        #50 branch_flag_i <= `NotBranch;
        branch_target_address_i <= `ZeroWord;
        stall <= 6'b000000;
//        #10;
        #10 branch_flag_i <= `Branch;
        branch_target_address_i <= 32'b00000000000000000001000000000000;
//        #50;
        #50 branch_flag_i <= `NotBranch;
        branch_target_address_i <= 32'b00000000000000000001000000000000;
        #50 branch_flag_i <= `NotBranch;
    end
endmodule