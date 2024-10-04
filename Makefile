BUILD_DIR=./build
SRCS := uart_ti.asm std.asm 12_sieve_term.asm 14_memtest.asm 17_dos_ti.asm 18_bootload_ti.asm 19_memprobe.asm basic.asm basic_bios.asm
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)

DEPS_NO_STD := $(BUILD_DIR)/uart_ti.o
DEPS_ALL := $(BUILD_DIR)/std.o $(DEPS_NO_STD)

$(BUILD_DIR)/%.o: %.asm
	mkdir -p $(dir $@)
	ca65 -o $@ $<

all: $(BUILD_DIR)/12_sieve_term $(BUILD_DIR)/14_memtest $(BUILD_DIR)/17_dos_ti $(BUILD_DIR)/18_bootload_ti $(BUILD_DIR)/19_memprobe $(BUILD_DIR)/basic

$(BUILD_DIR)/12_sieve_term: $(BUILD_DIR)/12_sieve_term.o $(DEPS_ALL)	
	ld65 -o $@ -C my_sbc_ram_d000.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/sieve

$(BUILD_DIR)/14_memtest: $(BUILD_DIR)/14_memtest.o $(BUILD_DIR)/std.o
	ld65 -o $@ -C my_sbc_rambottom.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/memtest

$(BUILD_DIR)/17_dos_ti: $(BUILD_DIR)/17_dos_ti.o $(DEPS_NO_STD)	
	ld65 -o $@ -C my_sbc_ram.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/dos

$(BUILD_DIR)/18_bootload_ti: $(BUILD_DIR)/18_bootload_ti.o 
	ld65 -o $@ -C my_sbc_rombl.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/bl

$(BUILD_DIR)/19_memprobe: $(BUILD_DIR)/19_memprobe.o $(DEPS_ALL)	
	ld65 -o $@ -C my_sbc_rambottom.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/memprobe

$(BUILD_DIR)/basic: $(BUILD_DIR)/basic.o $(BUILD_DIR)/basic_bios.o $(DEPS_NO_STD)	
	ld65 -o $@ -C my_sbc_ram_d000.cfg $^ 
	ln -sf $(shell pwd)/$@ mimonify/disk/basic

clean:
	rm -r $(BUILD_DIR)
# build/uart_ti.o: uart_ti.asm
# 	ca65 -o build/uart_ti.o uart_ti.asm
	
	
# build/17_dos_ti.o: 17_dos_ti.asm
# 	ca65 -o build/17_dos_ti.o 17_dos_ti.asm


# build/17_dos_ti: build/uart_ti.o build/17_dos_ti.o
# 	ld65 -o build/17_dos_ti -C my_sbc_ram.cfg build/17_dos_ti.o build/uart_ti.o 


# all: build/17_dos_ti
	

