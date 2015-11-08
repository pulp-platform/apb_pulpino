// Address offset: bit [4:2]
`define REG_PAD_MUX      3'b000
`define REG_PAD_CONF     3'b001
`define REG_INFO         3'b010

`define REG_PADCFG0     5'b00000 //BASEADDR
`define REG_PADCFG1     5'b00101 //BASEADDR+0x05
`define REG_PADCFG2     5'b01010 //BASEADDR+0x0A
`define REG_PADCFG3     5'b01111 //BASEADDR+0x0F
`define REG_PADCFG4     5'b10100 //BASEADDR+0x14
`define REG_PADCFG5     5'b11001 //BASEADDR+0x30

`define VERSION          5'b00001 // Version number 1.0
`define DATA_RAM         8'b00000100 //size of data ram in multiples of 8 kBye
`define INSTR_RAM        8'b00000100 //size of instr ram in multiples of 8 kBye
`define ROM              5'b00000 // size of ROM in kByte - floor to nearest
`define ICACHE           1'b0 // has instruction cache
`define DCACHE           1'b0 // has data cache
//`define PERIPHERALS      4'b1
module apb_pulpino 
#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    input  logic                      HCLK,
    input  logic                      HRESETn,
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,
    
    output logic         [31:0] [5:0] pad_cfg_o,
    output logic               [31:0] pad_mux_o
);
    logic [31:0]  pad_mux_q, pad_mux_n;
    logic [31:0] [5:0] pad_cfg_q, pad_cfg_n;

    logic [APB_ADDR_WIDTH - 1:0]       register_adr;

    assign register_adr = PADDR[4:2];

    // directly output registers to pad frame
    assign pad_mux_o = pad_mux_q;
    assign pad_cfg_o = pad_cfg_q;

    // register write logic
    always_comb
    begin
        pad_mux_n = pad_mux_q;
        pad_cfg_n = pad_cfg_q;

        if (PSEL && PENABLE && PWRITE)
        begin

            case (register_adr)
                `REG_PAD_MUX:
                begin
                    pad_mux_n[0] = PWDATA[`REG_PADCFG0];
                    pad_mux_n[1] = PWDATA[`REG_PADCFG1];
                    pad_mux_n[2] = PWDATA[`REG_PADCFG2];
                    pad_mux_n[3] = PWDATA[`REG_PADCFG3];
                    pad_mux_n[4] = PWDATA[`REG_PADCFG4];
                    pad_mux_n[5] = PWDATA[`REG_PADCFG5];
                end

                `REG_PAD_CONF:
                    pad_cfg_n[PADDR[9:5]] = PWDATA;

                // version reg can't be written to
            endcase
        end

    end

    // register read logic
    always_comb
    begin
        PRDATA = 'b0;

        if (PSEL && PENABLE && !PWRITE)
        begin

            unique case (register_adr)
                `REG_PAD_MUX:
                    PRDATA = pad_mux_q;

                `REG_PAD_CONF:
                    // leave some spaces for future pad technology changes...
                    PRDATA = {6'b0, pad_cfg_q[PADDR[9:5]][5], 4'b0, pad_cfg_q[PADDR[9:5]][4], 4'b0, pad_cfg_q[PADDR[9:5]][3], 4'b0, pad_cfg_q[PADDR[9:5]][2], 4'b0, pad_cfg_q[PADDR[9:5]][1], 4'b0, pad_cfg_q[PADDR[9:5]][0]};

                `REG_INFO:
                    PRDATA = {4'b0000, `DCACHE, `ICACHE, `ROM, `INSTR_RAM, `DATA_RAM,`VERSION};
                default:
                    PRDATA = 'b0;
            endcase

        end
    end

    // synchronouse part
    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if(~HRESETn)
        begin
            pad_mux_q          <= '{default: 32'b0};
            
            // cfg_pad_int[i][0]: PD, Pull Down
            // cfg_pad_int[i][1]: PU, Pull Up
            // cfg_pad_int[i][2]: SMT, Schmitt Trigger
            // cfg_pad_int[i][3]: SR, Slew Rate
            // cfg_pad_int[i][4]: PIN1, Drive Strength Select 1
            // cfg_pad_int[i][5]: PIN2, Drive Strength Select 2
            
            pad_cfg_q[0]       <= 6'b000000; // always GPIO - seperate config
            pad_cfg_q[1]       <= 6'b000000; // always GPIO - seperate config
            pad_cfg_q[2]       <= 6'b000000; // always GPIO - seperate config
            pad_cfg_q[3]       <= 6'b000000; // always GPIO - seperate config
            pad_cfg_q[4]       <= 6'b000000; // always GPIO - seperate config
            pad_cfg_q[5]       <= 6'b000000; // SPI Slave CS
            pad_cfg_q[6]       <= 6'b000000; // SPI Slave IO0
            pad_cfg_q[7]       <= 6'b000000; // SPI Slave IO1
            pad_cfg_q[8]       <= 6'b000000; // SPI Slave IO2 
            pad_cfg_q[9]       <= 6'b000000; // SPI Slave IO3
            pad_cfg_q[10]      <= 6'b000000; // UART CTS
            pad_cfg_q[11]      <= 6'b000000; // UART RTS
            pad_cfg_q[12]      <= 6'b000000; // UART TX 
            pad_cfg_q[13]      <= 6'b000000; // UART RX
            pad_cfg_q[14]      <= 6'b000000; // SPI Master IO3
            pad_cfg_q[15]      <= 6'b000000; // SPI Master IO2
            pad_cfg_q[16]      <= 6'b000000; // SPI Master IO1
            pad_cfg_q[17]      <= 6'b000000; // SPI Master IO0 
            pad_cfg_q[18]      <= 6'b000000; // SPI Master CS
            pad_cfg_q[19]      <= 6'b000000; // I2C SDA
            pad_cfg_q[20]      <= 6'b000000; // I2C SCLK

        end
        else
        begin            
            pad_mux_q          <=  pad_mux_n;
            pad_cfg_q          <=  pad_cfg_n;
        end
    end

    // APB logic: we are always ready to capture the data into our regs
    // not supporting transfare failure
    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

endmodule