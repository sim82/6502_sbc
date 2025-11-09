#
# Makefile created by AI superpower...
#

# To add a new relocatable executable:
# 1. Add it to OS_CFG_TARGETS
# 2. (optionally) entry to Symlink Names section to automatically create symlink in disk dir
# 3. Add Dependency Definition listing the object files to link into the executable

# --- Basic Configuration ---
BUILD_DIR := ./build
AS_FLAGS  := --cpu 65c02
LINKER    := ld65
ASSEMBLER := ca65

# --- Source & Object Definitions ---
# Group targets by the config file they use for clarity.
RAM_D000_TARGETS   := 12_sieve_term 23_flow_control
OS_CFG_TARGETS     := 12_sieve_term_rel 12_sieve_dyn 12_sieve_bss 20_uart 20_uart_rel 21_reltest_rel \
                      22_irq 24_cmd_cat 25_cmd_bs02 26_resident 27_snake 28_sudoku 29_template \
                      29_pcm 30_iotest 31_fiostress 32_vector_dac 33_hdtest 33_hdbios \
					  33_diskdump
RAMBOTTOM_TARGETS  := 14_memtest 19_memprobe
DOS_CFG_TARGETS    := 17_dos
ROMBL_CFG_TARGETS  := 18_bootload_ti 18_bootload_hd
RAM_BASIC_TARGETS  := basic

TARGETS := $(RAM_D000_TARGETS) $(OS_CFG_TARGETS) $(RAMBOTTOM_TARGETS) $(DOS_CFG_TARGETS) $(ROMBL_CFG_TARGETS) $(RAM_BASIC_TARGETS)
TARGETS_OUT := $(patsubst %,$(BUILD_DIR)/%,$(TARGETS))

# Common dependencies
DEPS_NO_STD := $(BUILD_DIR)/uart_ti.o
DEPS_ALL    := $(BUILD_DIR)/std.o $(DEPS_NO_STD)
COMMON_INCS := std.inc os.inc 17_dos.inc

# Object file list for the 'dos' targets
DOS_OBJS := $(BUILD_DIR)/17_dos.o $(BUILD_DIR)/17_dos_token.o $(BUILD_DIR)/17_dos_pageio.o \
            $(BUILD_DIR)/17_dos_baseio.o $(BUILD_DIR)/17_dos_rel.o $(BUILD_DIR)/17_dos_pagetable.o \
            $(BUILD_DIR)/17_dos_builtin.o $(BUILD_DIR)/17_dos_event.o $(BUILD_DIR)/17_dos_zeropage.o \
            $(BUILD_DIR)/17_dos_os_func_table.o ${BUILD_DIR}/17_dos_dbg.o \
            $(BUILD_DIR)/17_dos_vfs.o $(BUILD_DIR)/17_dos_vfs_uart.o $(BUILD_DIR)/17_dos_vfs_ide.o 
# --- Target-Specific Variable Definitions (The "Data" Section) ---

# 1. Define Linker Configs

# Assign the linker config variable to each group
$(patsubst %,$(BUILD_DIR)/%,$(RAM_D000_TARGETS)):   LINKER_CFG := my_sbc_ram_d000.cfg
$(patsubst %,$(BUILD_DIR)/%,$(OS_CFG_TARGETS)):     LINKER_CFG := my_sbc_os.cfg
$(patsubst %,$(BUILD_DIR)/%,$(RAMBOTTOM_TARGETS)):  LINKER_CFG := my_sbc_rambottom.cfg
$(patsubst %,$(BUILD_DIR)/%,$(DOS_CFG_TARGETS)):    LINKER_CFG := my_sbc_dos.cfg
$(patsubst %,$(BUILD_DIR)/%,$(ROMBL_CFG_TARGETS)):  LINKER_CFG := my_sbc_rombl.cfg
$(patsubst %,$(BUILD_DIR)/%,$(RAM_BASIC_TARGETS)):  LINKER_CFG := my_sbc_ram_basic.cfg

# 2. Define Symlink Names (if any)
$(BUILD_DIR)/12_sieve_term:     SYMLINK := sieve
$(BUILD_DIR)/12_sieve_term_rel: SYMLINK := sieve_rel
$(BUILD_DIR)/12_sieve_dyn:      SYMLINK := sieved
$(BUILD_DIR)/12_sieve_bss:      SYMLINK := psb
$(BUILD_DIR)/14_memtest:        SYMLINK := memtest
$(BUILD_DIR)/17_dos:            SYMLINK := dos
# $(BUILD_DIR)/17_dos_rel:        SYMLINK := dosr
$(BUILD_DIR)/18_bootload_ti:    SYMLINK := bl
$(BUILD_DIR)/19_memprobe:       SYMLINK := memprobe
$(BUILD_DIR)/basic:             SYMLINK := basic
$(BUILD_DIR)/20_uart:           SYMLINK := ti
$(BUILD_DIR)/20_uart_rel:       SYMLINK := tir
$(BUILD_DIR)/22_irq:            SYMLINK := irq
$(BUILD_DIR)/24_cmd_cat:        SYMLINK := cat
$(BUILD_DIR)/25_cmd_bs02:       SYMLINK := bs02
$(BUILD_DIR)/26_resident:       SYMLINK := res
$(BUILD_DIR)/27_snake:          SYMLINK := sn
$(BUILD_DIR)/28_sudoku:         SYMLINK := su
$(BUILD_DIR)/29_template:       SYMLINK := temp
$(BUILD_DIR)/29_pcm:            SYMLINK := pcm
$(BUILD_DIR)/30_iotest:         SYMLINK := iot
$(BUILD_DIR)/31_fiostress:      SYMLINK := ios
$(BUILD_DIR)/32_vector_dac:     SYMLINK := vec
$(BUILD_DIR)/33_hdtest:         SYMLINK := hd
$(BUILD_DIR)/33_hdbios:         SYMLINK := hb
$(BUILD_DIR)/33_diskdump:       SYMLINK := dd


# --- Build Rules (The "Logic" Section) ---

.PHONY: all clean

all: $(TARGETS_OUT)

# Generic rule to assemble a single .asm file into a .o file
$(BUILD_DIR)/%.o: %.asm $(COMMON_INCS)
	@mkdir -p $(dir $@)
	@echo "AS $<"
	@$(ASSEMBLER) $(AS_FLAGS) -o $@ $<

#.SECONDEXPANSION:
# Generic rule for all targets.
# It uses the target-specific variables defined above.
# The `if` function conditionally creates the symlink only if the SYMLINK variable is set.
$(TARGETS_OUT): #$$(LINKER_CFG)
	@echo "LD $@ ($(LINKER_CFG))"
	@$(LINKER) -o $@ -C $(LINKER_CFG) $^
	@$(if $(SYMLINK), ln -sf $(CURDIR)/$@ mimonify/disk/$(SYMLINK))

# --- Dependency Definitions (linking object files to final targets) ---
# For most targets, the dependency is just its own .o file plus common libs.
$(BUILD_DIR)/12_sieve_term: $(BUILD_DIR)/12_sieve_term.o $(DEPS_ALL)
$(BUILD_DIR)/12_sieve_term_rel: $(BUILD_DIR)/12_sieve_term.o $(DEPS_ALL)
$(BUILD_DIR)/12_sieve_dyn: $(BUILD_DIR)/12_sieve_dyn.o $(DEPS_ALL)
$(BUILD_DIR)/12_sieve_bss: $(BUILD_DIR)/12_sieve_bss.o
$(BUILD_DIR)/14_memtest: $(BUILD_DIR)/14_memtest.o $(BUILD_DIR)/std.o
$(BUILD_DIR)/18_bootload_ti: $(BUILD_DIR)/18_bootload_ti.o
$(BUILD_DIR)/18_bootload_hd: $(BUILD_DIR)/18_bootload_hd.o
$(BUILD_DIR)/19_memprobe: $(BUILD_DIR)/19_memprobe.o $(DEPS_ALL)
$(BUILD_DIR)/20_uart: $(BUILD_DIR)/20_uart.o $(DEPS_NO_STD)
$(BUILD_DIR)/20_uart_rel: $(BUILD_DIR)/20_uart.o $(DEPS_NO_STD)
$(BUILD_DIR)/21_reltest_rel: $(BUILD_DIR)/21_reltest.o
$(BUILD_DIR)/22_irq: $(BUILD_DIR)/22_irq.o $(DEPS_ALL)
$(BUILD_DIR)/23_flow_control: $(BUILD_DIR)/23_flow_control.o $(DEPS_ALL)
$(BUILD_DIR)/24_cmd_cat: $(BUILD_DIR)/24_cmd_cat.o
$(BUILD_DIR)/25_cmd_bs02: $(BUILD_DIR)/25_cmd_bs02.o
$(BUILD_DIR)/26_resident: $(BUILD_DIR)/26_resident.o
$(BUILD_DIR)/27_snake: $(BUILD_DIR)/27_snake.o
$(BUILD_DIR)/29_template: $(BUILD_DIR)/29_template.o
$(BUILD_DIR)/29_pcm: $(BUILD_DIR)/29_pcm.o
$(BUILD_DIR)/30_iotest: $(BUILD_DIR)/30_iotest.o
$(BUILD_DIR)/31_fiostress: $(BUILD_DIR)/31_fiostress.o
$(BUILD_DIR)/32_vector_dac: $(BUILD_DIR)/32_vector_dac.o
$(BUILD_DIR)/33_hdtest: $(BUILD_DIR)/33_hdtest.o
$(BUILD_DIR)/33_hdbios: $(BUILD_DIR)/33_hdbios.o
$(BUILD_DIR)/33_diskdump: $(BUILD_DIR)/33_diskdump.o

# Special targets with multiple object files
$(BUILD_DIR)/17_dos: $(DOS_OBJS) $(DEPS_NO_STD)
# $(BUILD_DIR)/17_dos_rel: $(DOS_OBJS) $(DEPS_NO_STD)
$(BUILD_DIR)/28_sudoku: $(BUILD_DIR)/28_sudoku.o $(BUILD_DIR)/28_sudoku_ui.o
$(BUILD_DIR)/basic: $(BUILD_DIR)/basic.o $(BUILD_DIR)/basic_bios.o $(DEPS_NO_STD)

# --- Cleanup ---
clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)

