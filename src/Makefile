GHDL_ARGS = '--workdir=../bin'
RUN_ARGS = '--stop-time=1000ms'
RUN_ARGS += '--vcd=wave.vcd'

tb_dcf77lcd: dcf77LCD.vhd tb_dcf77LCD.vhd
	ghdl -a $(GHDL_ARGS) $^
	ghdl -e $(GHDL_ARGS) tb_dcf77LCD

clean:
	rm ../bin/*.o ../bin/*.cf


wave.vcd: tb_dcf77lcd
	./tb_dcf77lcd $(RUN_ARGS)

visualize: wave.vcd
	gtkwave wave.vcd
