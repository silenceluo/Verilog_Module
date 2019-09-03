#include "Vspram_fifo.h"
#include "verilated.h"
#include "verilated_vcd_c.h" 


#define DATA_WIDTH      8    
#define ADDR_WIDTH      5
#define FIFO_DEPTH      1<<ADDR_WIDTH

vluint64_t main_time = 0;

double sc_time_stamp () {
    return main_time;
}




int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    
    Vspram_fifo* top = new Vspram_fifo;
    
    // init trace dump
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;

    top->trace(tfp, 100);
    tfp->open("fifo.vcd");



//    while (!Verilated::gotFinish()) {
    while(main_time < 200) {
        top->clk        = (main_time/5) % 2;
        top->rst_n      = (main_time < 8) ? 0 : 1;
/*        
        if(main_time < 10) {
            top->in_valid = 0;
        } else if(main_time < 30) {
            top->in_valid = 1;
        } else {
            top->in_valid = 0;
        }
*/        
        
        top->in_valid   = (main_time < 45) ? 0 : 1;
        
        if(main_time%2==1)
            top->in_data  = ((main_time+5)/10)%256;
            
                    
        top->out_ready  = (main_time < 95) ? 0 : 1;

        
        top->eval();
        tfp->dump(main_time);

        main_time++;
    }
    tfp->close();
    top->final();
    delete top;
    exit(0);
}

