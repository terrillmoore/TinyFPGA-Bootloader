
    
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ////
    //// SPI Slave Modeling
    ////
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    reg [1024 * 8:0] mosi_data = 8097'h0;
    reg [1024 * 8:0] miso_data = 8097'h0;
    reg [31:0] spi_mosi_length = 32'h0;
    reg [31:0] spi_miso_length = 32'h0;

    task prepare_spi_xfer;
      input [1024 * 8:0] new_mosi_data;
      input [1024 * 8:0] new_miso_data;
      input [31:0] new_length;
    begin
      mosi_data = new_mosi_data;
      miso_data = new_miso_data;
      spi_mosi_length <= new_length - 1; 
      spi_miso_length <= new_length; 
    end
    endtask
    
    assign spi_miso = (spi_miso_length == 32'hffffffff) ? 1'b1 : miso_data[spi_miso_length];

    always @(negedge spi_sck) begin
      if (spi_cs == 1'b0 && spi_miso_length > 0) begin
        spi_miso_length <= spi_miso_length - 1;
      end
    end

    always @(posedge spi_sck) begin
      if (spi_cs == 1'b0 && spi_mosi_length > 0) begin
        `assert("SPI MOSI data", spi_mosi, mosi_data[spi_mosi_length]);
        spi_mosi_length <= spi_mosi_length - 1;
      end
    end
    

