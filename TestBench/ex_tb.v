`include "defines.v"
`timescale 1ns / 1ps

module ex_tb;
    reg                rst;

    // 译码阶段送到执行阶段的信息
    reg[`AluOpBus]     aluop_i;
    reg[`AluSelBus]    alusel_i;
    reg[`RegBus]       reg1_i;
    reg[`RegBus]       reg2_i;
    reg[`RegAddrBus]   wd_i;
    reg                wreg_i;

    // HILO模块给出的HI、LO寄存器的值
    reg[`RegBus]       hi_i;
    reg[`RegBus]       lo_i;
    
    // 回写阶段的指令是否要写HI、LO，用于检测HI、LO寄存器带来的数据相关问题
    reg[`RegBus]       wb_hi_i;
    reg[`RegBus]       wb_lo_i;
    reg                wb_whilo_i;

    // 访存阶段的指令是否要写HI、LO，用于检测HI、LO寄存器带来的数据相关问题
    reg[`RegBus]       mem_hi_i;
    reg[`RegBus]       mem_lo_i;
    reg                mem_whilo_i;

    // 增加的输入接口
    reg[`DoubleRegBus] hilo_temp_i;
    reg[1:0]           cnt_i;

    // 处于执行阶段的转移指令要保存的返回地址
    reg[`RegBus]       link_address_i;
    
    // 当前执行阶段的指令是否位于延迟槽
    reg                is_in_delayslot_i;

    // 处于执行阶段的指令对HI、LO寄存器的写操作请求
    wire[`RegBus]        hi_o;
    wire[`RegBus]        lo_o;
    wire                 whilo_o;

    // 执行的结果
    wire[`RegAddrBus]    wd_o;
    wire                 wreg_o;
    wire[`RegBus]        wdata_o;

    wire[`DoubleRegBus]  hilo_temp_o;
    wire[1:0]            cnt_o;

    wire                 stallreq_from_ex;

    ex ex0(
        .rst(rst),
        .aluop_i(aluop_i),
        .alusel_i(alusel_i),
        .reg1_i(reg1_i),
        .reg2_i(reg2_i),
        .wd_i(wd_i),
        .wreg_i(wreg_i),
        .hi_i(hi_i),
        .lo_i(lo_i),
        .wb_hi_i(wb_hi_i),
        .wb_lo_i(wb_lo_i),
        .wb_whilo_i(wb_whilo_i),
        .mem_hi_i(mem_hi_i),
        .mem_lo_i(mem_lo_i),
        .mem_whilo_i(mem_whilo_i),
        .hilo_temp_i(hilo_temp_i),
        .cnt_i(cnt_i),
        .link_address_i(link_address_i),
        .is_in_delay_slot_i(is_in_delayslot_i),
        .hi_o(hi_o),
        .lo_o(lo_o),
        .whilo_o(whilo_o),
        .wd_o(wd_o),
        .wreg_o(wreg_o),
        .wdata_o(wdata_o),
        .hilo_temp_o(hilo_temp_o),
        .cnt_o(cnt_o),
        .stallreq_from_ex(stallreq_from_ex)
    );

    initial
    begin
        rst = `RstEnable;
        #195 rst = `RstDisable;
        #1000 $stop;
    end
    
    initial
    begin
        
    end
    
    initial
    begin
        
    end
endmodule