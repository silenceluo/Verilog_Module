verilator -Wall --cc --trace ../src/fifo_fwft.sv ../src/fifo_bank.sv ../src/spram.sv --exe testbench.c
make -C obj_dir -f Vfifo_fwft.mk
obj_dir/Vfifo_fwft
gtkwave fifo.vcd 
