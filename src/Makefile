GHDL_ARGS = '--workdir=../bin'


testbench: dcf77LCD.vhd tb_dcf77LCD.vhd
	ghdl -a $(GHDL_ARGS) $^
	ghdl -e $(GHDL_ARGS) tb_dcf77LCD

clean:
	rm ../bin/*.o ../bin/*.cf
