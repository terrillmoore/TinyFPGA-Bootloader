module bootloader (
  input  pin_clk,

  inout  pin_usbp,
  inout  pin_usbn,
  output pin_pu,

  output pin_led,

  input  pin_29_miso,
  output pin_30_cs,
  output pin_31_mosi,
  output pin_32_sck
);
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// generate 48 MHz clock from a 12 MHz clock.
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  wire clk_48mhz;

  //SB_PLL40_CORE #(
  SB_PLL40_PAD #(
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
    //.REFERENCECLK(pin_clk),
    .PACKAGEPIN(pin_clk),
    .PLLOUTCORE(clk_48mhz),
    .PLLOUTGLOBAL(),
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

  wire led_pwm;

  SB_RGBA_DRV RGB_DRIVER (
    .RGBLEDEN(1'b1),
    .RGB0PWM(1'b0),
    .RGB1PWM(led_pwm),
    .RGB2PWM(1'b0),
    .CURREN(1'b1),
    .RGB0(),
    .RGB1(pin_led),
    .RGB2()
    );
    defparam RGB_DRIVER.CURRENT_MODE = "0b0";
    defparam RGB_DRIVER.RGB0_CURRENT = "0b111111";
    defparam RGB_DRIVER.RGB1_CURRENT = "0b000011";
    defparam RGB_DRIVER.RGB2_CURRENT = "0b111111";

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
    .led(led_pwm),
    .spi_miso(pin_29_miso),
    .spi_cs(pin_30_cs),
    .spi_mosi(pin_31_mosi),
    .spi_sck(pin_32_sck),
    .boot(boot)
  );

  assign pin_pu = 1'b1;
  assign pin_usbp = usb_tx_en ? usb_p_tx : 1'bz;
  assign pin_usbn = usb_tx_en ? usb_n_tx : 1'bz;
  assign usb_p_rx = usb_tx_en ? 1'b1 : pin_usbp;
  assign usb_n_rx = usb_tx_en ? 1'b0 : pin_usbn;

  
  assign reset = 1'b0;
endmodule
