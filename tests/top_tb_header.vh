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
      $dumpvars(0, dut);
    end


    reg clk_48mhz;
    reg reset = 0;

    initial begin
      #1 clk_48mhz <= 0;
      forever begin
        #10416 clk_48mhz <= !clk_48mhz;
      end
    end

    // usb interface
    wire usb_p_tx_raw;
    wire usb_n_tx_raw;
    reg usb_p_rx = 1'b1;
    reg usb_n_rx = 1'b0;
    wire usb_tx_en;

    
    wire usb_p_tx = usb_tx_en ? usb_p_tx_raw : 1'b1;
    wire usb_n_tx = usb_tx_en ? usb_n_tx_raw : 1'b0;

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
