## Generated SDC file "top.out.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition"

## DATE    "Fri May 22 11:48:04 2020"

##
## DEVICE  "EP2C70F672C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {iCLK_100} -period 10.000 -waveform { 0.000 5.000 } [get_ports {iCLK_100}]
create_clock -name {iCLK_11MHz} -period 90.909 -waveform { 0.000 0.500 } [get_ports { iCLK_11MHz }]
create_clock -name {AN831:AN831|mw8731_controller:MW8731_CONTROLLER1|dsp_slave_reader:DSP_SLAVE_READER_INSTANCE|sample_available_from_adc} -period 1.000 -waveform { 0.000 0.500 } [get_registers {AN831:AN831|mw8731_controller:MW8731_CONTROLLER1|dsp_slave_reader:DSP_SLAVE_READER_INSTANCE|sample_available_from_adc}]
create_clock -name {AUD_BCLK} -period 1.000 -waveform { 0.000 0.500 } [get_ports {AUD_BCLK}]
create_clock -name {mTransmitter:mTransmitter|current_state.finish} -period 1.000 -waveform { 0.000 0.500 } [get_registers {mTransmitter:mTransmitter|current_state.finish}]
create_clock -name {mTransmitter:mTransmitter|mTXD:txd|TX_current_stat.start} -period 1.000 -waveform { 0.000 0.500 } [get_registers {mTransmitter:mTransmitter|mTXD:txd|TX_current_stat.start}]
create_clock -name {AN831:AN831|out_page_sample_available} -period 1.000 -waveform { 0.000 0.500 } [get_registers {AN831:AN831|out_page_sample_available}]
create_clock -name {AN831:AN831|mw8731_controller:MW8731_CONTROLLER1|i2c_clk_prescaler:I2C_CLK_PRESCALER_INSTANCE|clk_100kHz_int} -period 1.000 -waveform { 0.000 0.500 } [get_registers {AN831:AN831|mw8731_controller:MW8731_CONTROLLER1|i2c_clk_prescaler:I2C_CLK_PRESCALER_INSTANCE|clk_100kHz_int}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {AN831|c0|altpll_component|pll|clk[0]} -source [get_pins {AN831|c0|altpll_component|pll|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -divide_by 2 -master_clock {iCLK_100} [get_pins {AN831|c0|altpll_component|pll|clk[0]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

