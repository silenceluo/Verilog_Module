verilator -Wall --cc --trace fifo.sv --exe testbench.c
make -C obj_dir -f Vfifo.mk
obj_dir/Vfifo 
gtkwave fifo.vcd 
