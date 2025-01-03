BUILD_DIR=./build
SRCS := uart_ti.asm std.asm 12_sieve_term.asm 12_sieve_dyn.asm 12_sieve_bss.asm 14_memtest.asm 17_dos.asm 17_dos_token.asm 17_dos_pageio.asm 17_dos_baseio.asm 17_dos_pagetable.asm 18_bootload_ti.asm 19_memprobe.asm basic.asm basic_bios.asm 20_uart.asm 21_reltest.asm 22_irq.asm 23_flow_control.asm
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)

DEPS_NO_STD := $(BUILD_DIR)/uart_ti.o
DEPS_ALL := $(BUILD_DIR)/std.o $(DEPS_NO_STD)

$(BUILD_DIR)/%.o: %.asm
	mkdir -p $(dir $@)
	ca65 -o $@ $<

all: $(BUILD_DIR)/12_sieve_term $(BUILD_DIR)/12_sieve_term_rel $(BUILD_DIR)/12_sieve_dyn $(BUILD_DIR)/12_sieve_bss $(BUILD_DIR)/14_memtest $(BUILD_DIR)/17_dos $(BUILD_DIR)/17_dos_rel $(BUILD_DIR)/18_bootload_ti $(BUILD_DIR)/19_memprobe $(BUILD_DIR)/basic $(BUILD_DIR)/20_uart $(BUILD_DIR)/20_uart_rel $(BUILD_DIR)/21_reltest_ram $(BUILD_DIR)/21_reltest_rel $(BUILD_DIR)/22_irq $(BUILD_DIR)/23_flow_control

$(BUILD_DIR)/12_sieve_term: $(BUILD_DIR)/12_sieve_term.o $(DEPS_ALL)	
	ld65 -o $@ -C my_sbc_ram_d000.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/sieve

$(BUILD_DIR)/12_sieve_term_rel: $(BUILD_DIR)/12_sieve_term.o $(DEPS_ALL)	
	ld65 -o $@ -C my_sbc_rel.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/sieve_rel

$(BUILD_DIR)/12_sieve_dyn: $(BUILD_DIR)/12_sieve_dyn.o $(DEPS_ALL)	
	ld65 -o $@ -C my_sbc_rel.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/sieved

$(BUILD_DIR)/12_sieve_bss: $(BUILD_DIR)/12_sieve_bss.o $(DEPS_ALL)	
	ld65 -o $@ -C my_sbc_rel.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/psb

$(BUILD_DIR)/14_memtest: $(BUILD_DIR)/14_memtest.o $(BUILD_DIR)/std.o
	ld65 -o $@ -C my_sbc_rambottom.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/memtest

DOS_OBJS = $(BUILD_DIR)/17_dos.o $(BUILD_DIR)/17_dos_token.o $(BUILD_DIR)/17_dos_pageio.o $(BUILD_DIR)/17_dos_baseio.o $(BUILD_DIR)/17_dos_rel.o $(BUILD_DIR)/17_dos_pagetable.o 

$(BUILD_DIR)/17_dos: $(DOS_OBJS) $(DEPS_NO_STD)	
	ld65 -o $@ -C my_sbc_dos.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/dos

$(BUILD_DIR)/17_dos_rel: $(DOS_OBJS) $(DEPS_NO_STD)	
	ld65 -o $@ -C my_sbc_rel.cfg $^ 
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
	ld65 -o $@ -C my_sbc_rel.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/tir

# $(BUILD_DIR)/21_reltest_ram: $(BUILD_DIR)/21_reltest.o 	
# 	ld65 -o $@ -C my_sbc_ram_d000.cfg $^ 
$(BUILD_DIR)/21_reltest_rel: $(BUILD_DIR)/21_reltest.o 	
	ld65 -o $@ -C my_sbc_rel.cfg $^ 

$(BUILD_DIR)/22_irq: $(BUILD_DIR)/22_irq.o $(DEPS_ALL)
	ld65 -o $@ -C my_sbc_ram_d000.cfg $^ 

$(BUILD_DIR)/23_flow_control: $(BUILD_DIR)/23_flow_control.o $(DEPS_ALL)
	ld65 -o $@ -C my_sbc_ram_d000.cfg $^ 

clean:
	rm -r $(BUILD_DIR)
# build/uart_ti.o: uart_ti.asm
# 	ca65 -o build/uart_ti.o uart_ti.asm
	
	
# build/17_dos_ti.o: 17_dos_ti.asm
# 	ca65 -o build/17_dos_ti.o 17_dos_ti.asm


# build/17_dos_ti: build/uart_ti.o build/17_dos_ti.o
# 	ld65 -o build/17_dos_ti -C my_sbc_ram.cfg build/17_dos_ti.o build/uart_ti.o 


# all: build/17_dos_ti
	

