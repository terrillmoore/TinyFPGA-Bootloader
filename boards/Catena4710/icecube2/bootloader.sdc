# ##############################################################################

# iCEcube SDC

# Version:            2017.01.27914

# File Generated:     Dec 9 2018 16:23:49

# ##############################################################################

####---- CreateClock list ----1
create_clock  -period 83.33 -name {pin_clk12} [get_ports {pin_clk12}] 

####---- CreateGenClock list ----1
create_generated_clock  [get_ports {usb_pll_inst/PLLOUTGLOBAL}]  -source [get_ports {pin_clk12}]  -multiply_by 4.00 -name {clk48

