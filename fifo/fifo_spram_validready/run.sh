verilator -Wall --cc --trace spram_fifo.sv --exe testbench.c
make -C obj_dir -f Vspram_fifo.mk
obj_dir/Vspram_fifo
gtkwave fifo.vcd 
