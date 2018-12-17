`include "top_tb_header.vh"
  initial begin
    // TODO(tmm@mcci.com) we shoud send a USB reset; and we ought to
    // probe the address some other way, rather than trying to look
    // in the registers -- that only works for functional, not timing,
    // verification.
    send_usb_address_device(8'h00, 8'h1e);
    //`assert("new device address", `DUT.dev_addr, 7'h1e);

    $finish(0);
  end
`include "top_tb_footer.vh"
