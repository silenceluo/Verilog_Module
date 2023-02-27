set search_path "../../src $search_path"

analyze -format sverilog {
 
 
 fifo_slice.sv
 bridge_split.sv
 bridge_combine.sv
 zeroskip.sv
 
 zeroskip_pipe_wrapper_MAC64.sv
 
}