/*

Module:	bootloader.v

Function:
	USB bootloader top-level for MCCI Catena 4710

Copyright:
	See accompanying license file

Author:
	Adapted from TinyFPGA original by Terry Moore, MCCI

*/

module bootloader (
  input  pin_clk12,

  inout  pin_usbp,
  inout  pin_usbn,

  output pin_led,

  input  pin_SPI_SI,
  output pin_SPI_SS,
  output pin_SPI_SO,
  output pin_SPI_SCK,

  inout [6 : 0] pin_gpio,
  inout [32 : 0] wire_D
);
  //================================================================================
  // defaults for the various pins
  //================================================================================
  localparam IOB_PIN_INPUT                                      = 2'b01;
  localparam IOB_PIN_INPUT_LATCH                                = 2'b11;
  localparam IOB_PIN_INPUT_REGISTERED                           = 2'b00;
  localparam IOB_PIN_INPUT_DDR                                  = IOB_PIN_INPUT_REGISTERED;
  localparam IOB_PIN_INPUT_REGISTERED_LATCH                     = 2'b01;

  localparam IOB_PIN_OUTPUT_NONE                                = 4'b0000;
  localparam IOB_PIN_OUTPUT                                     = 4'b0110;
  localparam IOB_PIN_OUTPUT_TRISTATE                            = 4'b1010;
  localparam IOB_PIN_OUTPUT_ENABLE_REGISTERED                   = 4'b1110;
  localparam IOB_PIN_OUTPUT_REGISTERED                          = 4'b0101;
  localparam IOB_PIN_OUTPUT_REGISTERED_ENABLE                   = 4'b1001;
  localparam IOB_PIN_OUTPUT_REGISTERED_ENABLE_REGISTERED        = 4'b1101;
  localparam IOB_PIN_OUTPUT_DDR                                 = 4'b0100;
  localparam IOB_PIN_OUTPUT_DDR_ENABLE                          = 4'b1000;
  localparam IOB_PIN_OUTPUT_DDR_ENABLE_REGISTERED               = 4'b1100;
  localparam IOB_PIN_OUTPUT_REGISTERED_INVERTED                 = 4'b1011;
  localparam IOB_PIN_OUTPUT_REGISTERED_EABLE_REGISTERED_INVERTED = 4'b1111;

  localparam  OSC_48MHZ = 48000000,
              OSC_24MHZ = 24000000,
              OSC_12MHZ = 12000000,
              OSC_06MHZ =  6000000;
  localparam  OSC_SPEED = OSC_12MHZ; // OSC clock speed; SET HERE
  localparam  OSC_STR   = OSC_SPEED == OSC_48MHZ ? "0b00" :
                          OSC_SPEED == OSC_24MHZ ? "0b01" :
                          OSC_SPEED == OSC_12MHZ ? "0b10" : "0b11";


  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// generate 48 MHz clock from a 12 MHz clock.
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////

  wire clk_hfosc;
  SB_HFOSC #(.CLKHF_DIV(OSC_STR))
  OSCInst0(
      .CLKHFEN(1'b1 ),
      .CLKHFPU(1'b1 ),
      .CLKHF  (clk_hfosc)
  ) /* synthesis ROUTE_THROUGH_FABRIC= 1 */;

  wire clk_48mhz;
  wire clk_12MHz;

  SB_IO #(
    .PIN_TYPE( {IOB_PIN_OUTPUT_NONE, IOB_PIN_INPUT} )
  ) pad_clk12_inst (
    .PACKAGE_PIN(pin_clk12),
    .D_IN_0(clk_12MHz)
    //.GLOBAL_BUFFER_OUTPUT(clk_12MHz)
  );

  SB_PLL40_CORE #(
  //SB_PLL40_PAD #(
    .DIVR(4'b0000),
    //.DIVF(7'b0101111),
    .DIVF(7'b0111111),
    .DIVQ(3'b100),
    .FILTER_RANGE(3'b001),
    .FEEDBACK_PATH("SIMPLE"),
    .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
    .FDA_FEEDBACK(4'b0000),
    .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
    .FDA_RELATIVE(4'b0000),
    .SHIFTREG_DIV_MODE(2'b00),
    .PLLOUT_SELECT("GENCLK"),
    .ENABLE_ICEGATE(1'b0)
  ) usb_pll_inst (
    .REFERENCECLK(clk_12MHz),
    //.PACKAGEPIN(pin_clk12),
    .PLLOUTCORE(),
    .PLLOUTGLOBAL(clk_48mhz),
    .EXTFEEDBACK(),
    .DYNAMICDELAY(),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .LATCHINPUTVALUE(),
    .LOCK(),
    .SDI(),
    .SDO(),
    .SCLK()
  );

  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// interface with iCE40 warmboot/multiboot capability
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  wire boot;

`ifdef NOTYET
  SB_WARMBOOT warmboot_inst (
    .S1(1'b0),
    .S0(1'b1),
    .BOOT(boot)
  );
`endif

  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// instantiate tinyfpga bootloader
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  wire reset;
  wire usb_p_tx;
  wire usb_n_tx;
  wire usb_p_rx;
  wire usb_n_rx;
  wire usb_tx_en;

  tinyfpga_bootloader tinyfpga_bootloader_inst (
    .clk_48mhz(clk_48mhz),
    .reset(reset),
    .usb_p_tx(usb_p_tx),
    .usb_n_tx(usb_n_tx),
    .usb_p_rx(usb_p_rx),
    .usb_n_rx(usb_n_rx),
    .usb_tx_en(usb_tx_en),
    .led(pin_led),
    .spi_miso(pin_SPI_SI),
    .spi_cs(pin_SPI_SS),
    .spi_mosi(pin_SPI_SO),
    .spi_sck(pin_SPI_SCK),
    .boot(boot)
  );

  assign pin_pu = 1'b1;
/*
  assign pin_usbp = usb_tx_en ? usb_p_tx : 1'bz;
  assign pin_usbn = usb_tx_en ? usb_n_tx : 1'bz;
  assign usb_p_rx = usb_tx_en ? 1'b1 : pin_usbp;
  assign usb_n_rx = usb_tx_en ? 1'b0 : pin_usbn;
*/

  SB_IO #(
    .PIN_TYPE(6'b 1010_01), // PIN_OUTPUT_TRISTATE - PIN_INPUT
    .PULLUP(1'b 0)
  )
  iobuf_usbp
  (
    .PACKAGE_PIN(pin_usbp),
    .OUTPUT_ENABLE(usb_tx_en),
    .D_OUT_0(usb_p_tx),
    .D_IN_0(usb_p_rx)
  );

  SB_IO #(
    .PIN_TYPE(6'b 1010_01), // PIN_OUTPUT_TRISTATE - PIN_INPUT
    .PULLUP(1'b 0)
  )
  iobuf_usbn
  (
    .PACKAGE_PIN(pin_usbn),
    .OUTPUT_ENABLE(usb_tx_en),
    .D_OUT_0(usb_n_tx),
    .D_IN_0(usb_n_rx)
  );
  assign reset = 1'b0;

/* other things for us */
  assign pin_gpio[0] = 1'bZ;	//
  assign pin_gpio[1] = 1'bZ;	//
  assign pin_gpio[2] = 1'bZ;	//
  assign pin_gpio[3] = 1'bZ;	//
  assign pin_gpio[4] = 1'bZ;	//
  assign pin_gpio[5] = 1'b0;	// turn off external voltages
  assign pin_gpio[6] = 1'b0;	// turn off external voltages

/* the wires */
    assign wire_D[ 0] = 1'bZ;
    assign wire_D[ 1] = 1'bZ;
    assign wire_D[ 2] = 1'bZ;
    assign wire_D[ 3] = 1'bZ;
    assign wire_D[ 4] = 1'bZ;
    assign wire_D[ 5] = 1'bZ;
    assign wire_D[ 6] = 1'bZ;
    assign wire_D[ 7] = 1'bZ;
    assign wire_D[ 8] = 1'bZ;
    assign wire_D[ 9] = 1'bZ;
    assign wire_D[10] = 1'bZ;
    assign wire_D[11] = 1'bZ;
    assign wire_D[12] = 1'bZ;
    assign wire_D[13] = 1'bZ;           // not used; pin_led controls directly
    assign wire_D[14] = 1'bZ;
    assign wire_D[15] = 1'bZ;
    assign wire_D[16] = 1'bZ;
    assign wire_D[17] = 1'bZ;
    assign wire_D[18] = 1'bZ;
    assign wire_D[19] = 1'bZ;
    assign wire_D[20] = 1'bZ;
    assign wire_D[21] = 1'bZ;
    assign wire_D[22] = 1'bZ;
    assign wire_D[23] = 1'bZ;
    assign wire_D[24] = 1'bZ;
    assign wire_D[25] = 1'bZ;
//  assign wire_D[26] = 1'bZ;
    SB_IO_OD #(
        .PIN_TYPE ( {IOB_PIN_OUTPUT_NONE, IOB_PIN_INPUT} )
        )
    pad_rgb2(
        .PACKAGEPIN (wire_D[26]),
        .OUTPUTENABLE (),
        .LATCHINPUTVALUE (),
        .CLOCKENABLE (),
        .INPUTCLK (),
        .OUTPUTCLK (),
        .DOUT0 (),
        .DOUT1 (),
        .DIN0 (),
        .DIN1 ()
        );
    assign wire_D[27] = 1'bZ;
    assign wire_D[28] = 1'b0;           // D29_SCK_MIC
    assign wire_D[29] = 1'bZ;
//  assign wire_D[30] = 1'bZ;
    SB_IO_OD #(
        .PIN_TYPE ( {IOB_PIN_OUTPUT_NONE, IOB_PIN_INPUT} )
        )
    pad_rgb0(
        .PACKAGEPIN (wire_D[30]),
        .OUTPUTENABLE (),
        .LATCHINPUTVALUE (),
        .CLOCKENABLE (),
        .INPUTCLK (),
        .OUTPUTCLK (),
        .DOUT0 (),
        .DOUT1 (),
        .DIN0 (),
        .DIN1 ()
        );
//  assign wire_D[31] = 1'bZ;
    SB_IO_OD #(
        .PIN_TYPE ( {IOB_PIN_OUTPUT_NONE, IOB_PIN_INPUT} )
        )
    pad_rgb1(
        .PACKAGEPIN (wire_D[31]),
        .OUTPUTENABLE (),
        .LATCHINPUTVALUE (),
        .CLOCKENABLE (),
        .INPUTCLK (),
        .OUTPUTCLK (),
        .DOUT0 (),
        .DOUT1 (),
        .DIN0 (),
        .DIN1 ()
        );

//  assign wire_D[32] = 1'b1;           // 48 MHz enable: on
    SB_IO #(
      .PIN_TYPE( {IOB_PIN_OUTPUT, IOB_PIN_INPUT} ),
      .PULLUP(1'b1)
    )
    iobuf_wire_D32_inst
    (
      .PACKAGE_PIN(wire_D[32]),
      .OUTPUT_ENABLE(),
      .D_OUT_0(1'b1),
      .D_IN_0()
    );

endmodule
