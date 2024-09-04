#include "Vfifo_fwft.h"
#include "verilated.h"
#include "verilated_vcd_c.h" 


#define DATA_WIDTH      8    
#define ADDR_WIDTH      3
#define FIFO_DEPTH      1<<ADDR_WIDTH

vluint64_t main_time = 0;

double sc_time_stamp () {
    return main_time;
}

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    
    Vfifo_fwft* top = new Vfifo_fwft;
    
    // init trace dump
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;

    top->trace(tfp, 100);
    tfp->open("fifo.vcd");



    //  while (!Verilated::gotFinish()) {
    while(main_time < 200) {
        top->clk    = main_time % 2;
        top->rst_n  = (main_time < 5) ? 0 : 1;
        top->wen_i  = (main_time < 10) ? 0 : 1;
        top->ren_i  = (main_time < 40) ? 0 : 1;
        if(main_time%2==0)
            top->wdata_i  = (main_time/2)%256;
        
        top->eval();
        tfp->dump(main_time);

        main_time++;
    }
    tfp->close();
    top->final();
    delete top;
    exit(0);
}

