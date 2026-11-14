# RISC-V ecall Handler
A port of RARS-style system calls for RV32IM, using a trap handler and UART for I/O.

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

needs clang, LLD, and QEMU.

build it with clang:
``clang --target=riscv32 -march=rv32im -mabi=ilp32 -c drivers.s -o drivers.o``


then build the program with it:
``clang --target=riscv32 -march=rv32im -mabi=ilp32 -c [your target].s -o [your target].o``

``ld.lld -Ttext=0x80000000 drivers.o [your target].o -o prog.elf``

finally, test in qemu:
``qemu-system-riscv32 -machine virt -bios none -nographic -kernel prog.elf``

The driver initializes the stack, installs the trap handler, and calls `main`.

Arguments for these system calls use `a0` and `a1`. The service number should be loaded into `a7`, then use`ecall`.

`ReadString` uses `a0` as the buffer address and `a1` as its maximum capacity.
