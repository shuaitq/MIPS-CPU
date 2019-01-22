`include "defines.v"

module openmips_min_sopc(
    input   wire            clk,
    input   wire            rst,
    
    input   wire            A,
    input   wire            B,
    input   wire            calc,
    input   wire[15:0]      switch,
    output  wire[3:0]       an,
    output  wire[7:0]       led,
    output  wire[15:0]      switch_led
);

    assign switch_led = switch;

    // 连接指令存储器
    wire[`InstAddrBus]  inst_addr;
    wire[`InstBus]      inst;
    wire                rom_ce;
    wire                mem_we_i;
    wire[`DataAddrBus]  mem_addr_i;
    wire[`DataBus]      mem_data_i;
    wire[`DataBus]      mem_data_o;
    wire[3:0]           mem_sel_i;
    wire                mem_ce_i;
    
    reg                 real_clk;
    
    integer             i;

    initial
    begin
        i = 0;
        real_clk = 0;
    end

    always @(posedge clk)
    begin
        i = i + 1;
        if(i == 1)
        begin
            i = 0;
            real_clk = ~real_clk;
        end
    end

    // 例化处理器OpenMIPS
    openmips openmips0(
        .clk(real_clk),
        .rst(rst),
        .rom_addr_o(inst_addr),
        .rom_data_i(inst),
        .rom_ce_o(rom_ce),
        
        .ram_we_o(mem_we_i),
        .ram_addr_o(mem_addr_i),
        .ram_sel_o(mem_sel_i),
        .ram_data_o(mem_data_i),
        .ram_data_i(mem_data_o),
        .ram_ce_o(mem_ce_i)
    );

    // 例化指令存储器ROM
    inst_rom inst_rom0(
        .ce(rom_ce),
        .addr(inst_addr),
        .inst(inst)
    );
    
    data_ram data_ram0(
        .clk(real_clk),
        .ce(mem_ce_i),
        .we(mem_we_i),
        .addr(mem_addr_i),
        .sel(mem_sel_i),
        .data_i(mem_data_i),
        .A(A),
        .B(B),
        .calc(calc),
        .switch(switch),
        .an(an),
        .led(led),
        .data_o(mem_data_o)
    );
endmodule