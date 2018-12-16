`timescale 1ps / 1ps

`ifdef __ICARUS__
 `define finish_and_return(code) $finish_and_return(code)
`else
 `define finish_and_return(code) $finish
`endif

`define assert(msg, signal, value) \
        if ((signal) !== value) begin \
            $display("%d ERROR (%m): %s. signal != value", $time, msg); \
            $display("    actual:   %x", signal); \
            $display("    expected: %x", value); \
        end

`define assert_true(msg, signal) \
        if (!(signal)) begin \
            $display("%d ERROR (%m): %s. (signal) == FALSE", $time, msg); \
        end

module top_tb;
    initial begin
      $dumpfile("test.vcd");
      $dumpvars(0, top_tb);
    end


    reg clk_48mhz;
    reg reset = 0;

    initial begin
      #1 clk_48mhz <= 0;
      forever begin
        #10416 clk_48mhz <= !clk_48mhz;
      end
    end

    // usb interface to FPGA
    wire usb_p_tx_raw;
    wire usb_n_tx_raw;
    wire usb_tx_en;

    // the top-level USB
    wire usb_p_top;
    wire usb_n_top;

    // put bus into default state
    assign	(pull1, pull0)	usb_p_top = 1'b1;
    assign	(pull1, pull0)	usb_n_top = 1'b0;

    // the FPGA's output driver
    assign usb_p_top = usb_tx_en ? usb_p_tx_raw : 1'bz;
    assign usb_n_top = usb_tx_en ? usb_n_tx_raw : 1'bz;
    wire usb_p_rx;
    wire usb_n_rx;
    assign usb_p_rx = usb_tx_en ? 1'b1 : usb_p_top;
    assign usb_n_rx = usb_tx_en ? 1'b0 : usb_n_top;

    // usb interface to host
    reg usb_host_p_tx = 1'b1;
    reg usb_host_n_tx = 1'b0;
    reg usb_host_tx_en = 1'b0;
    wire usb_host_p_rx;
    wire usb_host_n_rx;

    assign usb_host_p_rx = usb_host_tx_en ? 1'b1 : usb_p_top;
    assign usb_host_n_rx = usb_host_tx_en ? 1'b0 : usb_n_top;

    assign usb_p_top = usb_host_tx_en ?  usb_host_p_tx : 1'bz;
    assign usb_n_top = usb_host_tx_en ?  usb_host_n_tx : 1'bz;

    // user interface
    wire led;

    // spi interface
    wire spi_cs;
    wire spi_sck;
    wire spi_mosi;
    wire spi_miso;

    // boot interface
    wire boot;

    tinyfpga_bootloader dut (
      .clk_48mhz(clk_48mhz),
      .reset(reset),

      .usb_p_tx(usb_p_tx_raw),
      .usb_n_tx(usb_n_tx_raw),

      .usb_p_rx(usb_p_rx),
      .usb_n_rx(usb_n_rx),

      .usb_tx_en(usb_tx_en),

      .led(led),

      .spi_cs(spi_cs),
      .spi_sck(spi_sck),
      .spi_mosi(spi_mosi),
      .spi_miso(spi_miso),

      .boot(boot)
    );

`include "top_tb_model_spi.vh"

`include "top_tb_model_usb_host.vh"

// end of top_tb_header.vh
