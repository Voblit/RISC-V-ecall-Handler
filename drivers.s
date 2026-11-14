# hardware driver for RISC-V 32 bit
#//uart lives at 0x10000000 and the line status is 5 bytes after that
#//qemu poweroff thingy is at 0x100000, write 0x5555 and it shuts down
.section .text.init
.globl _start
_start:
  la sp, stacktop
  la t0, handler
  csrw mtvec, t0
  jal main
halt:
  wfi
  j halt
.align 4
handler:
  addi sp, sp, -128
  #// saving everything (not sp or zero) because i dont trust myself
  sw x1, 4(sp)
  sw x3, 12(sp)
  sw x4, 16(sp)
  sw x5, 20(sp)
  sw x6, 24(sp)
  sw x7, 28(sp)
  sw x8, 32(sp)
  sw x9, 36(sp)
  sw x10, 40(sp)
  sw x11, 44(sp)
  sw x12, 48(sp)
  sw x13, 52(sp)
  sw x14, 56(sp)
  sw x15, 60(sp)
  sw x16, 64(sp)
  sw x17, 68(sp)
  sw x18, 72(sp)
  sw x19, 76(sp)
  sw x20, 80(sp)
  sw x21, 84(sp)
  sw x22, 88(sp)
  sw x23, 92(sp)
  sw x24, 96(sp)
  sw x25, 100(sp)
  sw x26, 104(sp)
  sw x27, 108(sp)
  sw x28, 112(sp)
  sw x29, 116(sp)
  sw x30, 120(sp)
  sw x31, 124(sp)
  csrr t0, mcause
  li t1, 11
  beq t0, t1, dispatch
  li t1, 8
  beq t0, t1, dispatch
  j fatal
dispatch:
  li t0, 1
  beq a7, t0, printint
  li t0, 4
  beq a7, t0, printstr
  li t0, 5
  beq a7, t0, readint
  li t0, 8
  beq a7, t0, readstr
  li t0, 10
  beq a7, t0, shutdown
  li t0, 11
  beq a7, t0, printchar
  j ecalldone
printchar:
  jal putc
  j ecalldone
printint:
  mv t0, a0
  bgez t0, pi_abs
  li a0, 45
  jal putc
  neg t0, t0
pi_abs:
  addi sp, sp, -16
  mv t1, sp
  li t2, 10
  bnez t0, pi_div
  li t3, 48
  sb t3, 0(t1)
  addi t1, t1, 1
  j pi_out
pi_div:
  beqz t0, pi_out
  remu t3, t0, t2
  divu t0, t0, t2
  addi t3, t3, 48
  sb t3, 0(t1)
  addi t1, t1, 1
  j pi_div
pi_out:
  beq t1, sp, pi_done
  addi t1, t1, -1
  lbu a0, 0(t1)
  jal putc
  j pi_out
pi_done:
  addi sp, sp, 16
  j ecalldone
printstr:
  mv t0, a0
psloop:
  lbu a0, 0(t0)
  beqz a0, ecalldone
  jal putc
  addi t0, t0, 1
  j psloop
readint:
  li t0, 0
  li t1, 1
skipws:
  jal getc
  li t2, 32
  beq a0, t2, skipws
  li t2, 9
  beq a0, t2, skipws
  li t2, 10
  beq a0, t2, skipws
  li t2, 13
  beq a0, t2, skipws
  li t2, 45
  bne a0, t2, plus
  li t1, -1
  jal getc
  j digits
plus:
  li t2, 43
  bne a0, t2, digits
  jal getc
digits:
  li t2, 48
  blt a0, t2, intdone
  li t2, 57
  bgt a0, t2, intdone
  addi a0, a0, -48
  li t2, 10
  mul t0, t0, t2
  add t0, t0, a0
  jal getc
  j digits
#// a0 gets restored from the stack later so the answer has to go in its slot
intdone:
  mul t0, t0, t1
  sw t0, 40(sp)
  j ecalldone
readstr:
  mv t0, a0
  mv t1, a1
  li t2, 1
  ble t1, t2, strend
  addi t1, t1, -1
  li t3, 0
strloop:
  beq t3, t1, strend
  jal getc
  li t4, 13
  beq a0, t4, strnl
  li t4, 10
  beq a0, t4, strnl
  li t4, 127
  beq a0, t4, backspace
  sb a0, 0(t0)
  addi t0, t0, 1
  addi t3, t3, 1
  j strloop
backspace:
  beqz t3, strloop
  addi t0, t0, -1
  addi t3, t3, -1
  li a0, 8
  jal putc
  li a0, 32
  jal putc
  li a0, 8
  jal putc
  j strloop
strnl:
  li t4, 10
  sb t4, 0(t0)
  addi t0, t0, 1
strend:
  sb zero, 0(t0)
  j ecalldone
shutdown:
  li t0, 0x100000
  li t1, 0x5555
  sw t1, 0(t0)
hang:
  wfi
  j hang
#// anything that isnt an ecall ends up here
fatal:
  la t0, trapmsg
fatalloop:
  lbu a0, 0(t0)
  beqz a0, shutdown
  jal putc
  addi t0, t0, 1
  j fatalloop
ecalldone:
  csrr t0, mepc
  addi t0, t0, 4
  csrw mepc, t0
restore:
  lw x1, 4(sp)
  lw x3, 12(sp)
  lw x4, 16(sp)
  lw x5, 20(sp)
  lw x6, 24(sp)
  lw x7, 28(sp)
  lw x8, 32(sp)
  lw x9, 36(sp)
  lw x10, 40(sp)
  lw x11, 44(sp)
  lw x12, 48(sp)
  lw x13, 52(sp)
  lw x14, 56(sp)
  lw x15, 60(sp)
  lw x16, 64(sp)
  lw x17, 68(sp)
  lw x18, 72(sp)
  lw x19, 76(sp)
  lw x20, 80(sp)
  lw x21, 84(sp)
  lw x22, 88(sp)
  lw x23, 92(sp)
  lw x24, 96(sp)
  lw x25, 100(sp)
  lw x26, 104(sp)
  lw x27, 108(sp)
  lw x28, 112(sp)
  lw x29, 116(sp)
  lw x30, 120(sp)
  lw x31, 124(sp)
  addi sp, sp, 128
  mret
putc:
  li t5, 0x10000000
putwait:
  lbu t6, 5(t5)
  andi t6, t6, 32
  beqz t6, putwait
  sb a0, 0(t5)
  ret
#// qemu doesnt echo so getc does it too
getc:
  li t5, 0x10000000
getwait:
  lbu t6, 5(t5)
  andi t6, t6, 1
  beqz t6, getwait
  lbu a0, 0(t5)
  li t5, 0x10000000
echowait:
  lbu t6, 5(t5)
  andi t6, t6, 32
  beqz t6, echowait
  sb a0, 0(t5)
  ret
.section .rodata
trapmsg:
  .string "\ntrap\n"
.section .bss
.align 4
stack:
  .space 4096
stacktop:
