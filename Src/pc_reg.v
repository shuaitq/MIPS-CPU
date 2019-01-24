`include "defines.v"

module pc_reg(
    input   wire                clk,
    input   wire                rst,

    // 来自控制模块的信息
    input   wire[5:0]           stall,
    
    // 来自译码阶段ID模块的信息
    input   wire                branch_flag_i,
    input   wire[`RegBus]       branch_target_address_i,
    
    output  reg[`InstAddrBus]   pc,
    output  reg                 ce
);

    always @(posedge clk)
    begin
        if(rst == `RstEnable)
        begin
            ce <= `ChipDisable;         // 复位的时候指令存储器禁用
        end
        else
        begin
            ce <= `ChipEnable;          // 复位结束后，指令存储器使能
        end
    end

    always @(posedge clk)
    begin
        if(ce == `ChipDisable)
        begin
            pc <= `ZeroWord;            // 指令存储器禁用的时候，pc清0
        end
        else if(stall[0] == `NoStop)
        begin
            if(branch_flag_i == `Branch)
            begin
                pc <= branch_target_address_i;
            end
            else
            begin
                pc <= pc + 4'h4;
            end
        end
    end
endmodule