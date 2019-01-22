`include "defines.v"

module ex(
    input   wire                rst,

    // 译码阶段送到执行阶段的信息
    input   wire[`AluOpBus]     aluop_i,
    input   wire[`AluSelBus]    alusel_i,
    input   wire[`RegBus]       reg1_i,
    input   wire[`RegBus]       reg2_i,
    input   wire[`RegAddrBus]   wd_i,
    input   wire                wreg_i,
    input   wire[`RegBus]       inst_i,

    // HILO模块给出的HI、LO寄存器的值
    input   wire[`RegBus]       hi_i,
    input   wire[`RegBus]       lo_i,
    
    // 回写阶段的指令是否要写HI、LO，用于检测HI、LO寄存器带来的数据相关问题
    input   wire[`RegBus]       wb_hi_i,
    input   wire[`RegBus]       wb_lo_i,
    input   wire                wb_whilo_i,

    // 访存阶段的指令是否要写HI、LO，用于检测HI、LO寄存器带来的数据相关问题
    input   wire[`RegBus]       mem_hi_i,
    input   wire[`RegBus]       mem_lo_i,
    input   wire                mem_whilo_i,

    // 增加的输入接口
    input   wire[`DoubleRegBus] hilo_temp_i,
    input   wire[1:0]           cnt_i,

    // 处于执行阶段的转移指令要保存的返回地址
    input   wire[`RegBus]       link_address_i,
    
    // 当前执行阶段的指令是否位于延迟槽
    input   wire                is_in_delayslot_i,

    // 处于执行阶段的指令对HI、LO寄存器的写操作请求
    output  reg[`RegBus]        hi_o,
    output  reg[`RegBus]        lo_o,
    output  reg                 whilo_o,

    // 执行的结果
    output  reg[`RegAddrBus]    wd_o,
    output  reg                 wreg_o,
    output  reg[`RegBus]        wdata_o,

    output  reg[`DoubleRegBus]  hilo_temp_o,
    output  reg[1:0]            cnt_o,
    
    output  wire[`AluOpBus]     aluop_o,
    output  wire[`RegBus]       mem_addr_o,
    output  wire[`RegBus]       reg2_o,

    output  reg                 stallreq_from_ex
);

    reg[`RegBus] logicout;                  // 逻辑运算的结果
    reg[`RegBus] shiftres;                  // 移位运算的结果
    reg[`RegBus] moveres;                   // 移动操作的结果
    reg[`RegBus] arithmeticres;             // 算术运算的结果
    reg[`DoubleRegBus] mulres;              // 保存乘法结果，宽度为64位
    reg[`RegBus] HI;                        // 保存HI寄存器的最新值
    reg[`RegBus] LO;                        // 保存LO寄存器的最新值
    wire[`RegBus] reg2_i_mux;               // 保存输入的第二个操作数reg2_i的补码
    wire[`RegBus] reg1_i_not;               // 保存输入的第一个操作数reg1_i取反后的值
    wire[`RegBus] result_sum;               // 保存加法结果
    wire ov_sum;                            // 保存溢出情况
    wire reg1_eq_reg2;                      // 第一个操作数是否等于第二个操作数
    wire reg1_lt_reg2;                      // 第一个操作数是否小于第二个操作数
    wire[`RegBus] opdata1_mult;             // 乘法操作中的被乘数
    wire[`RegBus] opdata2_mult;             // 乘法操作中的乘数
    wire[`DoubleRegBus] hilo_temp;          // 临时保存乘法结果，宽度为64位
    reg[`DoubleRegBus] hilo_temp1;
    reg stallreq_for_madd_msub;
	
	// aluop_o传递到访存阶段，用于加载、存储指令
    assign aluop_o = aluop_i;
    
    assign mem_addr_o = reg1_i + {{16{inst_i[15]}}, inst_i[15:0]};
    
    assign reg2_o = reg2_i;

    // 进行逻辑运算
    always @(*)
    begin
        if(rst == `RstEnable)
        begin
            logicout <= `ZeroWord;
        end
        else
        begin
            case(aluop_i)
                `EXE_OR_OP:                 // 逻辑或运算
                begin
                    logicout <= reg1_i | reg2_i;
                end
                `EXE_AND_OP:                // 逻辑与运算
                begin
                    logicout <= reg1_i & reg2_i;
                end
                `EXE_NOR_OP:                // 逻辑或非运算
                begin
                    logicout <= ~(reg1_i | reg2_i);
                end
                `EXE_XOR_OP:                // 逻辑异或运算
                begin
                    logicout <= reg1_i ^ reg2_i;
                end
                default:
                begin
                    logicout <= `ZeroWord;
                end
            endcase
        end
    end

    // 进行移位运算
    always @(*)
    begin
        if(rst == `RstEnable)
        begin
            shiftres <= `ZeroWord;
        end
        else
        begin
            case(aluop_i)
                `EXE_SLL_OP:                    // 逻辑左移
                begin
                    shiftres <= reg2_i << reg1_i[4:0];
                end
                `EXE_SRL_OP:                    // 逻辑右移
                begin
                    shiftres <= reg2_i >> reg1_i[4:0];
                end
                `EXE_SRA_OP:                    // 算术右移
                begin
                    shiftres <= ({32{reg2_i[31]}} << (6'd32 - {1'b0, reg1_i[4:0]})) | reg2_i >> reg1_i[4:0];
                end
                default:
                begin
                    shiftres <= `ZeroWord;
                end
            endcase
        end
    end

    // 如果是减法或者有符号比较运算，那么reg2_i_mux等于第二个操作数
    // reg2_i的补码，否则reg2_i_mux就等于第二个操作数reg2_i
    assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) ||
                         (aluop_i == `EXE_SUBU_OP) ||
                         (aluop_i == `EXE_SLT_OP)) ?
                         (~reg2_i) + 1 : reg2_i;

    // 1.加法运算
    //   直接就是加法结果
    // 2.减法运算
    //   通过对reg2_i求补码，所以是减法结果
    // 3.比较运算
    //   通过减法，然后判断结果是否大于0来判断
    assign result_sum = reg1_i + reg2_i_mux;

    // 判断溢出
    // 1.两个正数相加为负数
    // 1.两个负数相加为正数
    assign ov_sum = ((!reg1_i[31] && !reg2_i[31]) && result_sum[31]) ||
                    ((reg1_i[31] && reg2_i[31]) && (!result_sum[31]));

    // 计算操作数1是否小于操作数2
    // A.有符号数比较
    //   1.reg1_i为负，reg2_i为正，显然小于
    //   2.reg1_i为正，reg2_i为正，并且reg1_i减去reg2_i的值小于0，显然小于
    //   3.reg1_i为负，reg2_i为负，并且reg1_i减去reg2_i的值小于0，显然小于
    // B.无符号数比较，直接比较reg1_i与reg2_i
    assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP) ?
                          ((reg1_i[31] && !reg2_i[31]) ||
                          (!reg1_i[31] && !reg2_i[31] && result_sum[31]) ||
                          (reg1_i[31] && reg2_i[31] && result_sum[31]))
                          : (reg1_i < reg2_i);

    // 对操作数1取反
    assign reg1_i_not = ~reg1_i;

    // 进行算术运算
    always @(*)
    begin
        if(rst == `RstEnable)
        begin
            arithmeticres <= `ZeroWord;
        end
        else
        begin
            case(aluop_i)
                `EXE_SLT_OP,
                `EXE_SLTU_OP:
                begin
                    arithmeticres <= reg1_lt_reg2;
                end
                `EXE_ADD_OP,
                `EXE_ADDU_OP,
                `EXE_ADDI_OP,
                `EXE_ADDIU_OP:
                begin
                    arithmeticres <= result_sum;
                end
                `EXE_SUB_OP,
                `EXE_SUBU_OP:
                begin
                    arithmeticres <= result_sum;
                end
                `EXE_CLZ_OP:
                begin
                    arithmeticres <= reg1_i[31] ? 0 : reg1_i[30] ? 1 : reg1_i[29] ? 2 :
                                     reg1_i[28] ? 3 : reg1_i[27] ? 4 : reg1_i[26] ? 5 :
                                     reg1_i[25] ? 6 : reg1_i[24] ? 7 : reg1_i[23] ? 8 :
                                     reg1_i[22] ? 9 : reg1_i[21] ? 10 : reg1_i[20] ? 11 :
                                     reg1_i[19] ? 12 : reg1_i[18] ? 13 : reg1_i[17] ? 14 :
                                     reg1_i[16] ? 15 : reg1_i[15] ? 16 : reg1_i[14] ? 17 :
                                     reg1_i[13] ? 18 : reg1_i[12] ? 19 : reg1_i[11] ? 20 :
                                     reg1_i[10] ? 21 : reg1_i[9] ? 22 : reg1_i[8] ? 23 :
                                     reg1_i[7] ? 24 : reg1_i[6] ? 25 : reg1_i[5] ? 26 :
                                     reg1_i[4] ? 27 : reg1_i[3] ? 28 : reg1_i[2] ? 29 :
                                     reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32;
                end
                `EXE_CLO_OP:
                begin
                    arithmeticres <= (reg1_i_not[31] ? 0 : reg1_i_not[30] ? 1 : reg1_i_not[29] ? 2 :
                                      reg1_i_not[28] ? 3 : reg1_i_not[27] ? 4 : reg1_i_not[26] ? 5 :
                                      reg1_i_not[25] ? 6 : reg1_i_not[24] ? 7 : reg1_i_not[23] ? 8 :
                                      reg1_i_not[22] ? 9 : reg1_i_not[21] ? 10 : reg1_i_not[20] ? 11 :
                                      reg1_i_not[19] ? 12 : reg1_i_not[18] ? 13 : reg1_i_not[17] ? 14 :
                                      reg1_i_not[16] ? 15 : reg1_i_not[15] ? 16 : reg1_i_not[14] ? 17 :
                                      reg1_i_not[13] ? 18 : reg1_i_not[12] ? 19 : reg1_i_not[11] ? 20 :
                                      reg1_i_not[10] ? 21 : reg1_i_not[9] ? 22 : reg1_i_not[8] ? 23 :
                                      reg1_i_not[7] ? 24 : reg1_i_not[6] ? 25 : reg1_i_not[5] ? 26 :
                                      reg1_i_not[4] ? 27 : reg1_i_not[3] ? 28 : reg1_i_not[2] ? 29 :
                                      reg1_i_not[1] ? 30 : reg1_i_not[0] ? 31 : 32);
                end
                default:
                begin
                    arithmeticres <= `ZeroWord;
                end
            endcase
        end
    end

    // 取得乘法运算的被乘数，如果是有符号乘法且被乘数是负数，那么取补码
    assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) ||
                            (aluop_i == `EXE_MULT_OP) ||
                            (aluop_i == `EXE_MADD_OP) ||
                            (aluop_i == `EXE_MSUB_OP)) &&
                            (reg1_i[31] == 1'b1)) ? (~reg1_i) + 1 : reg1_i;

    // 取得乘法运算的乘数，如果是有符号乘法且乘数是负数，那么取补码
    assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) ||
                            (aluop_i == `EXE_MULT_OP) ||
                            (aluop_i == `EXE_MADD_OP) ||
                            (aluop_i == `EXE_MSUB_OP)) &&
                            (reg2_i[31] == 1'b1)) ? (~reg2_i) + 1 : reg2_i;

    // 得到临时乘法结果，保存在变量hilo_temp中
    assign hilo_temp = opdata1_mult * opdata2_mult;

    // 对临时乘法结果进行修正，最终的乘法结果保存在变量nulres中
    // A.如果是有符号乘法指令mult、mul，那么需要修正临时乘法结果
    //   1.如果被乘数与乘数一正一负，那么需要对hilo_temp取补码，作为最终的乘法结果，赋值给变量mulres
    //   2.如果被乘数与乘数同号，那么hilo_temp的值就作为最终的乘法结果，赋值给变量mulres
    // B.如果是无符号乘法指令multu，那么hilo_temp的值就作为最终的乘法结果，赋值给变量mulres
    always @(*)
    begin
        if(rst == `RstEnable)
        begin
            mulres <= {`ZeroWord, `ZeroWord};
        end
        else if((aluop_i == `EXE_MULT_OP) ||
                (aluop_i == `EXE_MUL_OP) ||
                (aluop_i == `EXE_MADD_OP) ||
                (aluop_i == `EXE_MSUB_OP))
        begin
            if(reg1_i[31] ^ reg2_i[31] == 1'b1)
            begin
                mulres <= ~hilo_temp + 1;
            end
            else
            begin
                mulres <= hilo_temp;
            end
        end
        else
        begin
            mulres <= hilo_temp;
        end
    end

    // 得到最新的HI、LO寄存器的值，此处要解决数据相关问题
    always @(*)
    begin
        if(rst == `RstEnable)
        begin
            {HI, LO} <= {`ZeroWord, `ZeroWord};
        end
        else if(mem_whilo_i == `WriteEnable)    // 访存阶段的指令要写HI、LO寄存器
        begin
            {HI, LO} <= {mem_hi_i, mem_lo_i};
        end
        else if(wb_whilo_i == `WriteEnable)     // 回写阶段的指令要写HI、LO寄存器
        begin
            {HI, LO} <= {wb_hi_i, wb_lo_i};
        end
        else
        begin
            {HI, LO} <= {hi_i, lo_i};
        end
    end

    // MADD、MADDU、MSUB、MSUBU指令
    always @(*)
    begin
        if(rst == `RstEnable)
        begin
            hilo_temp_o <= {`ZeroWord, `ZeroWord};
            cnt_o <= 2'b00;
            stallreq_for_madd_msub <= `NoStop;
        end
        else
        begin
            case(aluop_i)
                `EXE_MADD_OP,
                `EXE_MADDU_OP:
                begin
                    if(cnt_i == 2'b00)
                    begin
                        hilo_temp_o <= mulres;
                        cnt_o <= 2'b01;
                        hilo_temp1 <= {`ZeroWord, `ZeroWord};
                        stallreq_for_madd_msub <= `Stop;
                    end
                    else if(cnt_i == 2'b01)
                    begin
                        hilo_temp_o <= {`ZeroWord, `ZeroWord};
                        cnt_o <= 2'b10;
                        hilo_temp1 <= hilo_temp_i + {HI, LO};
                        stallreq_for_madd_msub <= `NoStop;
                    end
                end
                `EXE_MSUB_OP,
                `EXE_MSUBU_OP:
                begin
                    if(cnt_i == 2'b00)
                    begin
                        hilo_temp_o <= ~mulres + 1;
                        cnt_o <= 2'b01;
                        hilo_temp1 <= {`ZeroWord, `ZeroWord};
                        stallreq_for_madd_msub <= `Stop;
                    end
                    else if(cnt_i == 2'b01)
                    begin
                        hilo_temp_o <= {`ZeroWord, `ZeroWord};
                        cnt_o <= 2'b10;
                        hilo_temp1 <= hilo_temp_i + {HI, LO};
                        stallreq_for_madd_msub <= `NoStop;
                    end
                end
                default:
                begin
                    hilo_temp_o <= {`ZeroWord, `ZeroWord};
                    cnt_o <= 2'b00;
                    stallreq_for_madd_msub <= `NoStop;
                end
            endcase
        end
    end

    // 暂停流水线
    always @(*)
    begin
        stallreq_from_ex = stallreq_for_madd_msub;
    end

    // MFHI、MFLO、MOVN、MOVZ指令
    always @(*)
    begin
        if(rst == `RstEnable)
        begin
            moveres <= `ZeroWord;
        end
        else
        begin
            moveres <= `ZeroWord;
            case(aluop_i)
                `EXE_MFHI_OP:               // 如果是mfhi指令，那么将HI的值作为移动操作的结果
                begin
                    moveres <= HI;
                end
                `EXE_MFLO_OP:               // 如果是mflo指令，那么将LO的值作为移动操作的结果
                begin
                    moveres <= LO;
                end
                `EXE_MOVZ_OP:               // 如果是movz指令，那么将reg1_i的值作为移动操作的结果
                begin
                    moveres <= reg1_i;
                end
                `EXE_MOVN_OP:               // 如果是movn指令，那么将reg1_i的值作为移动操作的结果
                begin
                    moveres <= reg1_i;
                end
                default:
                begin
                end
            endcase
        end
    end

    /* 依据alusel_i指示的运算类型，选择一个运算结果作为最终结果，此处只有逻辑运算 */
    always @(*)
    begin
        wd_o <= wd_i;                       // wd_o等于wd_i，要写的目的寄存器地址

        // 如果是add、addi、sub、subi指令，并且发生溢出，那么设置wreg_o为
        // WriteDisable，表示不写目的寄存器
        if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) ||
            (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1))
        begin
            wreg_o <= `WriteDisable;
        end
        else
        begin
            wreg_o <= wreg_i;
        end

        case(alusel_i)
            `EXE_RES_LOGIC:
            begin
                wdata_o <= logicout;        // 选择逻辑运算结果为最终运算结果
            end
            `EXE_RES_SHIFT:
            begin
                wdata_o <= shiftres;        // 选择移位运算结果为最终运算结果
            end
            `EXE_RES_MOVE:
            begin
                wdata_o <= moveres;         // 选择移动运算结果为最终运算结果
            end
            `EXE_RES_ARITHMETIC:
            begin
                wdata_o <= arithmeticres;
            end
            `EXE_RES_MUL:
            begin
                wdata_o <= mulres[31:0];
            end
            `EXE_RES_JUMP_BRANCH:
            begin
                wdata_o <= link_address_i;
            end
            default:
            begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end

    // 确定对HI、LO寄存器的操作信息
    always @(*)
    begin
        if(rst == `RstEnable)
        begin
            whilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end
        else if((aluop_i == `EXE_MSUB_OP) ||
                (aluop_i == `EXE_MSUBU_OP))
        begin
            whilo_o <= `WriteEnable;
            hi_o <= hilo_temp1[63:32];
            lo_o <= hilo_temp1[31:0];
        end
        else if((aluop_i == `EXE_MADD_OP) ||
                (aluop_i == `EXE_MADDU_OP))
        begin
            whilo_o <= `WriteEnable;
            hi_o <= hilo_temp1[63:32];
            lo_o <= hilo_temp1[31:0];
        end
        else if((aluop_i == `EXE_MULT_OP) ||
                (aluop_i == `EXE_MULTU_OP))
        begin
            whilo_o <= `WriteEnable;
            hi_o <= mulres[63:32];
            lo_o <= mulres[31:0];
        end
        else if(aluop_i == `EXE_MTHI_OP)
        begin
            whilo_o <= `WriteEnable;
            hi_o <= reg1_i;
            lo_o <= LO;
        end
        else if(aluop_i == `EXE_MTLO_OP)
        begin
            whilo_o <= `WriteEnable;
            hi_o <= HI;
            lo_o <= reg1_i;
        end
        else
        begin
            whilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end
    end
endmodule