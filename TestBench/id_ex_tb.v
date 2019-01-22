`include "defines.v"
`timescale 1ns / 1ps

module id_ex_tb;
    reg                 clk;
    reg                 rst;

    reg[5:0]            stall;

    // 从译码阶段传递过来的信息
    reg[`AluOpBus]      id_aluop;
    reg[`AluSelBus]     id_alusel;
    reg[`RegBus]        id_reg1;
    reg[`RegBus]        id_reg2;
    reg[`RegAddrBus]    id_wd;
    reg                 id_wreg;

    reg[`RegBus]        id_link_address;
    reg                 id_is_in_delayslot;
    reg                 next_inst_in_delayslot_i;

    // 传递到执行阶段的信息
    wire[`AluOpBus]     ex_aluop;
    wire[`AluSelBus]    ex_alusel;
    wire[`RegBus]       ex_reg1;
    wire[`RegBus]       ex_reg2;
    wire[`RegAddrBus]   ex_wd;
    wire                ex_wreg;

    wire[`RegBus]       ex_link_address;
    wire                ex_is_in_delayslot;
    wire                is_in_delayslot_o;

    id_ex id_ex0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .id_aluop(id_aluop),
        .id_alusel(id_alusel),
        .id_reg1(id_reg1),
        .id_reg2(id_reg2),
        .id_wd(id_wd),
        .id_wreg(id_wreg),
        .id_link_address(id_link_address),
        .id_is_in_delayslot(id_is_in_delayslot),
        .next_inst_in_delayslot_i(next_inst_in_delayslot_i),
        .ex_aluop(ex_aluop),
        .ex_alusel(ex_alusel),
        .ex_reg1(ex_reg1),
        .ex_reg2(ex_reg2),
        .ex_wd(ex_wd),
        .ex_wreg(ex_wreg),
        .ex_link_address(ex_link_address),
        .ex_is_in_delayslot(ex_is_in_delayslot),
        .is_in_delayslot_o(is_in_delayslot_o)
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
        id_aluop <= 8'h0;
        id_alusel <= 3'h0;
        id_reg1 <= 32'h0;
        id_reg2 <= 32'h0;
        id_wd <= 32'h0;
        id_wreg <= 1'b0;
        id_link_address <= 32'h0;
        id_is_in_delayslot <= 1'b0;
        next_inst_in_delayslot_i <= 1'b0;
    end
    
    initial
    begin
        #200
        id_aluop <= 8'h1;
        id_alusel <= 3'h1;
        id_reg1 <= 32'h1;
        id_reg2 <= 32'h1;
        id_wd <= 32'h1;
        id_wreg <= 1'b1;
        id_link_address <= 32'h1;
        id_is_in_delayslot <= 1'b1;
        next_inst_in_delayslot_i <= 1'b1;
        
        #10
        stall <= 6'b000111;
        id_aluop <= 8'h2;
        id_alusel <= 3'h2;
        id_reg1 <= 32'h2;
        id_reg2 <= 32'h2;
        id_wd <= 32'h2;
        id_wreg <= 1'b1;
        id_link_address <= 32'h2;
        id_is_in_delayslot <= 1'b1;
        next_inst_in_delayslot_i <= 1'b1;
    end
endmodule