BUILD_DIR=./build
SRCS_CMD := 24_cmd_cat.asm 25_cmd_bs02.asm 27_snake.asm 28_sudoku.asm
SRCS := uart_ti.asm std.asm 12_sieve_term.asm 12_sieve_dyn.asm 12_sieve_bss.asm 14_memtest.asm 17_dos.asm 17_dos_token.asm 17_dos_pageio.asm 17_dos_baseio.asm 17_dos_pagetable.asm 17_dos_event.asm 17_dos_func_table.asm 18_bootload_ti.asm 19_memprobe.asm basic.asm basic_bios.asm 20_uart.asm 21_reltest.asm 22_irq.asm 23_flow_control.asm 26_resident.asm $(SRCS_CMD)
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)

DEPS_NO_STD := $(BUILD_DIR)/uart_ti.o
DEPS_ALL := $(BUILD_DIR)/std.o $(DEPS_NO_STD)
AS_FLAGS := --cpu 65c02
$(BUILD_DIR)/%.o: %.asm
	mkdir -p $(dir $@)
	ca65 ${AS_FLAGS} -o $@ $<

BINS_CMD := $(BUILD_DIR)/24_cmd_cat $(BUILD_DIR)/25_cmd_bs02 $(BUILD_DIR)/27_snake $(BUILD_DIR)/28_sudoku

all: $(BUILD_DIR)/12_sieve_term $(BUILD_DIR)/12_sieve_term_rel $(BUILD_DIR)/12_sieve_dyn $(BUILD_DIR)/12_sieve_bss $(BUILD_DIR)/14_memtest $(BUILD_DIR)/17_dos $(BUILD_DIR)/17_dos_rel $(BUILD_DIR)/18_bootload_ti $(BUILD_DIR)/19_memprobe $(BUILD_DIR)/basic $(BUILD_DIR)/20_uart $(BUILD_DIR)/20_uart_rel $(BUILD_DIR)/21_reltest_rel $(BUILD_DIR)/22_irq $(BUILD_DIR)/23_flow_control $(BUILD_DIR)/26_resident $(BINS_CMD)

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

DOS_OBJS = $(BUILD_DIR)/17_dos.o $(BUILD_DIR)/17_dos_token.o $(BUILD_DIR)/17_dos_pageio.o $(BUILD_DIR)/17_dos_baseio.o $(BUILD_DIR)/17_dos_rel.o $(BUILD_DIR)/17_dos_pagetable.o $(BUILD_DIR)/17_dos_builtin.o $(BUILD_DIR)/17_dos_event.o $(BUILD_DIR)/17_dos_os_func_table.o

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
	ld65 -o $@ -C my_sbc_ram_d000.cfg $^ 
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

$(BUILD_DIR)/28_sudoku: $(BUILD_DIR)/28_sudoku.o 	
	ld65 -o $@ -C my_sbc_os.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/su

clean:
	rm -r $(BUILD_DIR)
# build/uart_ti.o: uart_ti.asm
# 	ca65 -o build/uart_ti.o uart_ti.asm
	
	
# build/17_dos_ti.o: 17_dos_ti.asm
# 	ca65 -o build/17_dos_ti.o 17_dos_ti.asm


# build/17_dos_ti: build/uart_ti.o build/17_dos_ti.o
# 	ld65 -o build/17_dos_ti -C my_sbc_ram.cfg build/17_dos_ti.o build/uart_ti.o 


# all: build/17_dos_ti
	

