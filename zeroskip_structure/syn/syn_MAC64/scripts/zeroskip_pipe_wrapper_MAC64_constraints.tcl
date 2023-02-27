#create_clock -period 1000 -name design_clk [get_ports *clk*]
create_clock -period 1000 -name design_clk [get_ports *clk*]

#create_clock -period 200 -name design_clk [get_ports *clk*]
#set_case_analysis 1 [get_ports as_rst_n]
#set_input_delay 200 [all_inputs] -clock design_clk
#set_output_delay 200 [all_outputs] -clock design_clk
#
set_input_delay 50 [all_inputs] -clock design_clk
set_output_delay 50 [all_outputs] -clock design_clk
#set_input_delay 240 [all_inputs] -clock design_clk
#set_output_delay 240 [all_outputs] -clock design_clk

#set_clock_uncertainty  100 [get_clocks]
set_clock_uncertainty  120 [get_clocks]
#set_clock_uncertainty  50 [get_clocks]

#Pile on margin due to lack of wireload models
#set_clock_uncertainty -setup 50 design_clk
set_clock_uncertainty -setup 200 design_clk

#set_min_delay 300 -to [all_outputs]
set_min_delay 300 -to [all_outputs]

#set_min_delay 60 -to [all_outputs]


#set_dont_touch [find design -hier *ram]
#set_dont_touch [find design -hier *lut]
