`include "defines.v"
`timescale 1ns / 1ps

module id_tb;
    reg                 rst;
    reg[`InstAddrBus]   pc_i;
    reg[`InstBus]       inst_i;

    // 处于执行阶段的指令的运算结果
    reg                 ex_wreg_i;
    reg[`RegBus]        ex_wdata_i;
    reg[`RegAddrBus]    ex_wd_i;

    // 处于访存阶段的指令的运算结果
    reg                 mem_wreg_i;
    reg[`RegBus]        mem_wdata_i;
    reg[`RegAddrBus]    mem_wd_i;

    // 读取Regfile的值
    reg[`RegBus]        reg1_data_i;
    reg[`RegBus]        reg2_data_i;

    // 如果上一条指令是转移指令，那么下一条指令在译码的时候is_in_delayslot为true
    reg                 is_in_delayslot_i;

    // 输出到Regfile的信息
    wire                reg1_read_o;
    wire                reg2_read_o;
    wire[`RegAddrBus]   reg1_addr_o;
    wire[`RegAddrBus]   reg2_addr_o;

    // 送到执行阶段的信息
    wire[`AluOpBus]     aluop_o;
    wire[`AluSelBus]    alusel_o;
    wire[`RegBus]       reg1_o;
    wire[`RegBus]       reg2_o;
    wire[`RegAddrBus]   wd_o;
    wire                wreg_o;

    wire                next_inst_in_delayslot_o;

    wire                branch_flag_o;
    wire[`RegBus]       branch_target_address_o;
    wire[`RegBus]       link_addr_o;
    wire                is_in_delayslot_o;

    wire                stallreq;

    id id0(
        .rst(rst),
        .pc_i(pc_i),
        .inst_i(inst_i),
        .ex_wreg_i(ex_wreg_i),
        .ex_wdata_i(ex_wdata_i),
        .ex_wd_i(ex_wd_i),
        .mem_wreg_i(mem_wreg_i),
        .mem_wdata_i(mem_wdata_i),
        .mem_wd_i(mem_wd_i),
        .reg1_data_i(reg1_data_i),
        .reg2_data_i(reg2_data_i),
        .is_in_delayslot_i(is_in_delayslot_i),
        .reg1_read_o(reg1_read_o),
        .reg2_read_o(reg2_read_o),
        .reg1_addr_o(reg1_addr_o),
        .reg2_addr_o(reg2_addr_o),
        .aluop_o(aluop_o),
        .alusel_o(alusel_o),
        .reg1_o(reg1_o),
        .reg2_o(reg2_o),
        .wd_o(wd_o),
        .wreg_o(wreg_o),
        .next_inst_in_delayslot_o(next_inst_in_delayslot_o),
        .branch_flag_o(branch_flag_o),
        .branch_target_address_o(branch_target_address_o),
        .link_addr_o(link_addr_o),
        .is_in_delayslot_o(is_in_delayslot_o),
        .stallreq(stallreq)
    );
    
    initial
    begin
        rst = `RstEnable;
        #5 rst = `RstDisable;
        #1000 $stop;
    end
    
    initial
    begin
        pc_i <= `ZeroWord;
        inst_i <= `ZeroWord;
        ex_wreg_i <= `WriteDisable;
        ex_wdata_i <= `ZeroWord;
        ex_wd_i <= `NOPRegAddr;
        mem_wreg_i <= `WriteDisable;
        mem_wdata_i <= `ZeroWord;
        mem_wd_i <= `NOPRegAddr;
        reg1_data_i <= `ZeroWord;
        reg2_data_i <= `ZeroWord;
        is_in_delayslot_i <= `NotInDelaySlot;
    end
    
    initial
    begin
        #10 reg1_data_i <= 32'h1;
        reg2_data_i <= 32'h2;
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_OR};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_AND};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_XOR};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_NOR};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_SLLV};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_SRLV};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_SRAV};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_SYNC};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_NOR};
        
        #10 inst_i <= {6'h0, 5'h1, 15'h0, `EXE_MTHI};
        
        #10 inst_i <= {6'h0, 10'h0, 5'h1, 5'h0, `EXE_MTLO};
        
        #10 inst_i <= {6'h0, 10'h0, 5'h1, 5'h0, `EXE_MTHI};
        
        #10 inst_i <= {6'h0, 5'h1, 15'h0, `EXE_MTHI};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_MOVN};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_MOVZ};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_SLT};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_SLTU};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_ADD};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_ADDU};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_SUB};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h3, 5'h0, `EXE_SUBU};
        
        #10 inst_i <= {6'h0, 5'h1, 5'h2, 5'h0, 5'h0, `EXE_MULT};
    end
endmodule