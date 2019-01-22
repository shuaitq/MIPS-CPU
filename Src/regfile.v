`include "defines.v"

module regfile(
    input   wire                clk,
    input   wire                rst,

    // 写端口
    input   wire                we,
    input   wire[`RegAddrBus]   waddr,
    input   wire[`RegBus]       wdata,

    // 读端口1
    input   wire                re1,
    input   wire[`RegAddrBus]   raddr1,
    output  reg[`RegBus]        rdata1,

    // 读端口2
    input   wire                re2,
    input   wire[`RegAddrBus]   raddr2,
    output  reg[`RegBus]        rdata2
);

    /* 定义32个32位寄存器 */
    reg[`RegBus] regs[0:`RegNum - 1];

    /* 写操作 */
    always @(posedge clk)
    begin
        if(rst == `RstEnable)
        begin
            regs[0] <= `ZeroWord;
            regs[1] <= `ZeroWord;
            regs[2] <= `ZeroWord;
            regs[3] <= `ZeroWord;
            regs[4] <= `ZeroWord;
            regs[5] <= `ZeroWord;
            regs[6] <= `ZeroWord;
            regs[7] <= `ZeroWord;
            regs[8] <= `ZeroWord;
            regs[9] <= `ZeroWord;
            regs[10] <= `ZeroWord;
            regs[11] <= `ZeroWord;
            regs[12] <= `ZeroWord;
            regs[13] <= `ZeroWord;
            regs[14] <= `ZeroWord;
            regs[15] <= `ZeroWord;
            regs[16] <= `ZeroWord;
            regs[17] <= `ZeroWord;
            regs[18] <= `ZeroWord;
            regs[19] <= `ZeroWord;
            regs[20] <= `ZeroWord;
            regs[21] <= `ZeroWord;
            regs[22] <= `ZeroWord;
            regs[23] <= `ZeroWord;
            regs[24] <= `ZeroWord;
            regs[25] <= `ZeroWord;
            regs[26] <= `ZeroWord;
            regs[27] <= `ZeroWord;
            regs[28] <= `ZeroWord;
            regs[29] <= `ZeroWord;
            regs[30] <= `ZeroWord;
            regs[31] <= `ZeroWord;
        end
        else
        begin
            if((we == `WriteEnable) && (waddr != `RegNumLog2'h0))
            begin
                regs[waddr] <= wdata;
            end
        end
    end

    /* 读端口1的读操作 */
    always @(*)
    begin
        if(rst == `RstEnable)
        begin
            rdata1 <= `ZeroWord;
        end
        else if(raddr1 == `RegNumLog2'h0)
        begin
            rdata1 <= `ZeroWord;
        end
        else if((raddr1 == waddr) && (we == `WriteEnable) && re1 == `ReadEnable)
        begin
            rdata1 <= wdata;
        end
        else if(re1 == `ReadEnable)
        begin
            rdata1 <= regs[raddr1];
        end
        else
        begin
            rdata1 <= `ZeroWord;
        end
    end

    /* 读端口2的读操作 */
    always @(*)
    begin
        if(rst == `RstEnable)
        begin
            rdata2 <= `ZeroWord;
        end
        else if(raddr2 == `RegNumLog2'h0)
        begin
            rdata2 <= `ZeroWord;
        end
        else if((raddr2 == waddr) && (we == `WriteEnable) && re2 == `ReadEnable)
        begin
            rdata2 <= wdata;
        end
        else if(re2 == `ReadEnable)
        begin
            rdata2 <= regs[raddr2];
        end
        else
        begin
            rdata2 <= `ZeroWord;
        end
    end
endmodule