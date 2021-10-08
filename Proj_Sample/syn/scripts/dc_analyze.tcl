set search_path "../rtl/ $search_path"

analyze -format sverilog {
 
 generic_sync_fifo.sv
 cmap_kernel.sv
 cmap_decoder.sv
}