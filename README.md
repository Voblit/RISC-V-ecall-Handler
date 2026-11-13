# RISC-V ecall Handler
RARS-style system calls ported via a UART on bare metal.

supports these instructions currently: 

| load into `a7` | Service provided |
| :---: | :--- |
| 1 | `PrintInt` |
| 4 | `PrintString` |
| 5 | `ReadInt` |
| 8 | `ReadString` |
| 10 | `Exit` |
| 11 | `PrintChar` |

## useage 

build it with clang:
``clang --target=riscv32 -march=rv32im -mabi=ilp32 -c drivers.s -o drivers.o``


then build the program with it:
``clang --target=riscv32 -march=rv32im -mabi=ilp32 -c [your target].s -o [your target].o
ld.lld -Ttext=0x80000000 drivers.o [your target].o -o prog.elf``

finally, test in qemu:
``qemu-system-riscv32 -machine virt -bios none -nographic -kernel prog.elf``
