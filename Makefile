TARGETS := 24_cmd_cat 25_cmd_bs02 27_snake 28_sudoku 29_template 29_pcm 30_iotest 31_fiostress \
	    32_vector_dac 12_sieve_term 12_sieve_term_rel 12_sieve_dyn 12_sieve_bss 14_memtest \
	    17_dos 17_dos_rel 18_bootload_ti 19_memprobe basic 20_uart 20_uart_rel 21_reltest_rel \
	    22_irq 23_flow_control 26_resident 

DEPS_NO_STD := $(BUILD_DIR)/uart_ti.o
DEPS_ALL := $(BUILD_DIR)/std.o $(DEPS_NO_STD)
AS_FLAGS := --cpu 65c02
BUILD_DIR=./build
$(BUILD_DIR)/%.o: %.asm
	mkdir -p $(dir $@)
	ca65 ${AS_FLAGS} -o $@ $<

TARGETS_OUT := $(TARGETS:%=$(BUILD_DIR)/%)
all: $(TARGETS_OUT)

$(BUILD_DIR)/12_sieve_term: $(BUILD_DIR)/12_sieve_term.o $(DEPS_ALL)	
	ld65 -o $@ -C my_sbc_ram_d000.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/sieve

$(BUILD_DIR)/12_sieve_term_rel: $(BUILD_DIR)/12_sieve_term.o $(DEPS_ALL)	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/sieve_rel

$(BUILD_DIR)/12_sieve_dyn: $(BUILD_DIR)/12_sieve_dyn.o $(DEPS_ALL)	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/sieved

$(BUILD_DIR)/12_sieve_bss: $(BUILD_DIR)/12_sieve_bss.o
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/psb

$(BUILD_DIR)/14_memtest: $(BUILD_DIR)/14_memtest.o $(BUILD_DIR)/std.o
	ld65 -o $@ -C my_sbc_rambottom.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/memtest

DOS_OBJS = $(BUILD_DIR)/17_dos.o $(BUILD_DIR)/17_dos_token.o $(BUILD_DIR)/17_dos_pageio.o $(BUILD_DIR)/17_dos_baseio.o $(BUILD_DIR)/17_dos_rel.o $(BUILD_DIR)/17_dos_pagetable.o $(BUILD_DIR)/17_dos_builtin.o $(BUILD_DIR)/17_dos_event.o $(BUILD_DIR)/17_dos_os_func_table.o ${BUILD_DIR}/17_dos_dbg.o

$(BUILD_DIR)/17_dos: $(DOS_OBJS) $(DEPS_NO_STD)
	ld65 -o $@ -C my_sbc_dos.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/dos

$(BUILD_DIR)/17_dos_rel: $(DOS_OBJS) $(DEPS_NO_STD)	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/dosr

$(BUILD_DIR)/18_bootload_ti: $(BUILD_DIR)/18_bootload_ti.o 
	ld65 -o $@ -C my_sbc_rombl.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/bl

$(BUILD_DIR)/19_memprobe: $(BUILD_DIR)/19_memprobe.o $(DEPS_ALL)	
	ld65 -o $@ -C my_sbc_rambottom.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/memprobe

$(BUILD_DIR)/basic: $(BUILD_DIR)/basic.o $(BUILD_DIR)/basic_bios.o $(DEPS_NO_STD)	
	ld65 -o $@ -C my_sbc_ram_basic.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/basic

$(BUILD_DIR)/20_uart: $(BUILD_DIR)/20_uart.o $(DEPS_NO_STD)	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/ti

$(BUILD_DIR)/20_uart_rel: $(BUILD_DIR)/20_uart.o $(DEPS_NO_STD)	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/tir

# $(BUILD_DIR)/21_reltest_ram: $(BUILD_DIR)/21_reltest.o 	
# 	ld65 -o $@ -C my_sbc_ram_d000.cfg $^ 
$(BUILD_DIR)/21_reltest_rel: $(BUILD_DIR)/21_reltest.o 	
	ld65 -o $@ -C my_sbc_os.cfg $^ 

$(BUILD_DIR)/22_irq: $(BUILD_DIR)/22_irq.o $(DEPS_ALL)
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/irq

$(BUILD_DIR)/23_flow_control: $(BUILD_DIR)/23_flow_control.o $(DEPS_ALL)
	ld65 -o $@ -C my_sbc_ram_d000.cfg $^ 

$(BUILD_DIR)/24_cmd_cat : $(BUILD_DIR)/24_cmd_cat.o 	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/cat

$(BUILD_DIR)/25_cmd_bs02: $(BUILD_DIR)/25_cmd_bs02.o 	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/bs02

$(BUILD_DIR)/26_resident: $(BUILD_DIR)/26_resident.o 	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/res

$(BUILD_DIR)/27_snake: $(BUILD_DIR)/27_snake.o 	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/sn

$(BUILD_DIR)/28_sudoku: $(BUILD_DIR)/28_sudoku.o $(BUILD_DIR)/28_sudoku_ui.o 
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/su

$(BUILD_DIR)/29_template: $(BUILD_DIR)/29_template.o 	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/temp

$(BUILD_DIR)/29_pcm: $(BUILD_DIR)/29_pcm.o 	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/pcm

$(BUILD_DIR)/30_iotest: $(BUILD_DIR)/30_iotest.o 	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/iot

$(BUILD_DIR)/31_fiostress: $(BUILD_DIR)/31_fiostress.o 	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/ios

$(BUILD_DIR)/32_vector_dac: $(BUILD_DIR)/32_vector_dac.o 	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/vec

clean:
	rm -r $(BUILD_DIR)
# build/uart_ti.o: uart_ti.asm
# 	ca65 -o build/uart_ti.o uart_ti.asm
	
	
# build/17_dos_ti.o: 17_dos_ti.asm
# 	ca65 -o build/17_dos_ti.o 17_dos_ti.asm


# build/17_dos_ti: build/uart_ti.o build/17_dos_ti.o
# 	ld65 -o build/17_dos_ti -C my_sbc_ram.cfg build/17_dos_ti.o build/uart_ti.o 


# all: build/17_dos_ti

