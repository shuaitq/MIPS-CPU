`include "defines.v"

module data_ram(
    input   wire                clk,
    input   wire                ce,
    input   wire                we,
    input   wire[`DataAddrBus]  addr,
    input   wire[3:0]           sel,
    input   wire[`DataBus]      data_i,
    
    input   wire                A,
    input   wire                B,
    input   wire                calc,
    input   wire[15:0]          switch,
    output  reg[3:0]            an,
    output  reg[7:0]            led,
    
    output  reg[`DataBus]       data_o
);

    wire[7:0] zero8;
    assign zero8 = `ZeroByte;

    reg[`ByteWidth] data_mem0[0:`DataMemNum - 1];
    reg[`ByteWidth] data_mem1[0:`DataMemNum - 1];
    reg[`ByteWidth] data_mem2[0:`DataMemNum - 1];
    reg[`ByteWidth] data_mem3[0:`DataMemNum - 1];
    integer i, j;
    reg real_clk;
    
    reg[3:0] temp_data;
    
    initial
    begin
        real_clk = 0;
        j = 0;
    end
    
    always @(posedge clk)
    begin
        j = j + 1;
        if(j == 1000)
        begin
            j = 0;
            real_clk = ~real_clk;
        end
    end
    
    always @(posedge real_clk)
    begin
            case(an)
                4'b1110:
                begin
                    an = 4'b1101;
                    temp_data = data_mem0[6'h30][7:4];
                end
                4'b1101:
                begin
                    an = 4'b1011;
                    temp_data = data_mem1[6'h30][3:0];
                end
                4'b1011:
                begin
                    an = 4'b0111;
                    temp_data = data_mem1[6'h30][7:4];
                end
                4'b0111:
                begin
                    an = 4'b1110;
                    temp_data = data_mem0[6'h30][3:0];
                end
                default:
                begin
                    an = 4'b1110;
                    temp_data = data_mem0[6'h30][3:0];
                end
            endcase
            
            case(temp_data)
                4'h0:
                begin
                    led = 8'b11000000;
                end
                4'h1:
                begin
                    led = 8'b11111001;
                end
                4'h2:
                begin
                    led = 8'b10100100;
                end
                4'h3:
                begin
                    led = 8'b10110000;
                end
                4'h4:
                begin
                    led = 8'b10011001;
                end
                4'h5:
                begin
                    led = 8'b10010010;
                end
                4'h6:
                begin
                    led = 8'b10000010;
                end
                4'h7:
                begin
                    led = 8'b11111000;
                end
                4'h8:
                begin
                    led = 8'b10000000;
                end
                4'h9:
                begin
                    led = 8'b10010000;
                end
                4'hA:
                begin
                    led = 8'b00001000;
                end
                4'hB:
                begin
                    led = 8'b00000000;
                end
                4'hC:
                begin
                    led = 8'b01000110;
                end
                4'hD:
                begin
                    led = 8'b01000000;
                end
                4'hE:
                begin
                    led = 8'b00000110;
                end
                4'hF:
                begin
                    led = 8'b00001110;
                end
            endcase
    end
    
    initial
    begin
        for(i = 0; i < `DataMemNum; i = i + 1)
        begin
            data_mem0[i] = 8'b00000000;
            data_mem1[i] = 8'b00000000;
            data_mem2[i] = 8'b00000000;
            data_mem3[i] = 8'b00000000;
        end
    end
    
    always @(posedge clk)
    begin
        data_mem0[6'h20] <= {zero8[7:1], A};
        data_mem1[6'h20] <= zero8;
        data_mem2[6'h20] <= zero8;
        data_mem3[6'h20] <= zero8;
        
        data_mem0[6'h24] <= {zero8[7:1], B};
        data_mem1[6'h24] <= zero8;
        data_mem2[6'h24] <= zero8;
        data_mem3[6'h24] <= zero8;
        
        data_mem0[6'h28] <= {zero8[7:1], calc};
        data_mem1[6'h28] <= zero8;
        data_mem2[6'h28] <= zero8;
        data_mem3[6'h28] <= zero8;
        
        data_mem0[6'h2c] <= switch[7:0];
        data_mem1[6'h2c] <= switch[15:8];
        data_mem2[6'h2c] <= zero8;
        data_mem3[6'h2c] <= zero8;
        if(ce == `ChipDisable)
        begin
            // data_o <= `ZeroWord;
        end
        else if(we == `WriteEnable)
        begin
            if(sel[3] == 1'b1)
            begin
                data_mem3[addr[`DataMemNumLog2 + 1:2]] <= data_i[31:24];
            end
            if(sel[2] == 1'b1)
            begin
                data_mem2[addr[`DataMemNumLog2 + 1:2]] <= data_i[23:16];
            end
            if(sel[1] == 1'b1)
            begin
                data_mem1[addr[`DataMemNumLog2 + 1:2]] <= data_i[15:8];
            end
            if(sel[0] == 1'b1)
            begin
                data_mem0[addr[`DataMemNumLog2 + 1:2]] <= data_i[7:0];
            end
        end
    end
    
    always @(*)
    begin
        if(ce == `ChipDisable)
        begin
            data_o <= `ZeroWord;
        end
        else if(we == `WriteDisable)
        begin
            data_o <= {data_mem3[addr[`DataMemNumLog2 + 1:2]],
                       data_mem2[addr[`DataMemNumLog2 + 1:2]],
                       data_mem1[addr[`DataMemNumLog2 + 1:2]],
                       data_mem0[addr[`DataMemNumLog2 + 1:2]]};
        end
        else
        begin
            data_o <= `ZeroWord;
        end
    end
endmodule
