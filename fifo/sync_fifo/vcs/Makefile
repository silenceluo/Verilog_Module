vcs:
	vlogan 	-full64 +systemverilogext+sv -sverilog  -full64 +systemverilogext+sv -sverilog -debug_access+all -kdb -lca  += -timescale=1ns/1ns \
			-f src.f \
			-f tb.f \
			+incdir+../ \
			+incdir+../src/ 

	vcs -P	/apps/synopsys/verdi/Q-2020.03-1/share/PLI/VCS/LINUX64/novas.tab \
			/apps/synopsys/verdi/Q-2020.03-1/share/PLI/VCS/LINUX64/pli.a  \
			-full64 -debug_all testbench #-lca -kdb

clean:
	rm -rf AN.DB  novas.*  simv.daidir  ucli.key  verdiLog  vericomLog  work.lib++ *log simv 

