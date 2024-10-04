cl65 -t none -C my_sbc_ram_d000.cfg 12_sieve_term.asm uart_ti.asm std.asm

cl65 -t none -C my_sbc_rambottom.cfg 14_memtest.asm std.asm
cl65 -t none -C my_sbc_ram.cfg 17_dos_ti.asm uart_ti.asm
cl65 -t none -C my_sbc_rombl.cfg 18_bootload_ti.asm
cl65 -t none -C my_sbc_rambottom.cfg 19_memprobe.asm uart_ti.asm
cl65 -t none -C my_sbc_ram_d000.cfg basic.asm basic_bios.asm uart_ti.asm
