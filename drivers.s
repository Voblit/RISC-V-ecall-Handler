# hardware driver for RISC-V
# tested working in QEMU, for 32 bit.
.equ UART_BASE, 0x10000000
.equ UART_RBR,  0x00
.equ UART_THR,  0x00
.equ UART_LSR,  0x05
.equ LSR_DR,    0x01
.equ LSR_THRE,  0x20
.equ TEST_BASE, 0x100000
.equ TEST_PASS, 0x5555
.section .text.init
.globl _start
_start:
    la sp, _driver_stack_top
    la t0, _trap_handler
    csrw mtvec, t0
    call main
_halt:
    wfi
    j _halt
.align 4
_trap_handler:
    addi sp, sp, -128
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
    beq t0, t1, _handle_ecall
    li t1, 8
    beq t0, t1, _handle_ecall
    j _trap_fatal
    _handle_ecall:
    li t0, 1
    beq a7, t0, _sys_print_int
    li t0, 4
    beq a7, t0, _sys_print_str
    li t0, 5
    beq a7, t0, _sys_read_int
    li t0, 8
    beq a7, t0, _sys_read_str
    li t0, 10
    beq a7, t0, _sys_exit
    li t0, 11
    beq a7, t0, _sys_print_char
    j _ecall_done
_sys_print_char:
    call _uart_putc
    j _ecall_done
_sys_print_int:
    mv t0, a0
    bgez t0, _pi_abs_done
    li a0, 45
    call _uart_putc
    neg t0, t0
_pi_abs_done:
    addi sp, sp, -16
    mv t1, sp
    li t2, 10
    bnez t0, _pi_div_loop
    li t3, 48
    sb t3, 0(t1)
    addi t1, t1, 1
    j _pi_print_loop
_pi_div_loop:
    beqz t0, _pi_print_loop
    remu t3, t0, t2
    divu t0, t0, t2
    addi t3, t3, 48
    sb t3, 0(t1)
    addi t1, t1, 1
    j _pi_div_loop
_pi_print_loop:
    beq t1, sp, _pi_cleanup
    addi t1, t1, -1
    lbu a0, 0(t1)
    call _uart_putc
    j _pi_print_loop
_pi_cleanup:
    addi sp, sp, 16
    j _ecall_done
_sys_print_str:
    mv t0, a0
_ps_loop:
    lbu a0, 0(t0)
    beqz a0, _ecall_done
    call _uart_putc
    addi t0, t0, 1
    j _ps_loop
_sys_read_int:
    li t0, 0
    li t1, 1
_ri_skip_ws:
    call _uart_getc
    li t2, 32
    beq a0, t2, _ri_skip_ws
    li t2, 9
    beq a0, t2, _ri_skip_ws
    li t2, 10
    beq a0, t2, _ri_skip_ws
    li t2, 13
    beq a0, t2, _ri_skip_ws
    li t2, 45
    bne a0, t2, _ri_check_plus
    li t1, -1
    call _uart_getc
    j _ri_digit_loop
_ri_check_plus:
    li t2, 43
    bne a0, t2, _ri_digit_loop
    call _uart_getc
_ri_digit_loop:
    li t2, 48
    blt a0, t2, _ri_done
    li t2, 57
    bgt a0, t2, _ri_done
    addi a0, a0, -48
    li t2, 10
    mul t0, t0, t2
    add t0, t0, a0
    call _uart_getc
    j _ri_digit_loop
_ri_done:
    mul t0, t0, t1
    sw t0, 40(sp)
    j _ecall_done
_sys_read_str:
    mv t0, a0
    mv t1, a1
    li t2, 1
    ble t1, t2, _rs_terminate
    addi t1, t1, -1
    li t3, 0
_rs_loop:
    beq t3, t1, _rs_terminate
    call _uart_getc
    li t4, 13
    beq a0, t4, _rs_newline
    li t4, 10
    beq a0, t4, _rs_newline
    li t4, 127
    beq a0, t4, _rs_back
    sb a0, 0(t0)
    addi t0, t0, 1
    addi t3, t3, 1
    j _rs_loop
_rs_back:
    beqz t3, _rs_loop
    addi t0, t0, -1
    addi t3, t3, -1
    li a0, 8
    call _uart_putc
    li a0, 32
    call _uart_putc
    li a0, 8
    call _uart_putc
    j _rs_loop
_rs_newline:
    li t4, 10
    sb t4, 0(t0)
    addi t0, t0, 1
_rs_terminate:
    sb zero, 0(t0)
    j _ecall_done
_sys_exit:
    li t0, TEST_BASE
    li t1, TEST_PASS
    sw t1, 0(t0)
_exit_halt:
    wfi
    j _exit_halt
_trap_fatal:
    la t0, _trap_msg
_tf_loop:
    lbu a0, 0(t0)
    beqz a0, _sys_exit
    call _uart_putc
    addi t0, t0, 1
    j _tf_loop
_ecall_done:
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0
_trap_exit:
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
_uart_putc:
    li t5, UART_BASE
_putc_wait:
    lbu t6, UART_LSR(t5)
    andi t6, t6, LSR_THRE
    beqz t6, _putc_wait
    sb a0, UART_THR(t5)
    ret
_uart_getc:
    li t5, UART_BASE
_getc_wait:
    lbu t6, UART_LSR(t5)
    andi t6, t6, LSR_DR
    beqz t6, _getc_wait
    lbu a0, UART_RBR(t5)
    li t5, UART_BASE
_echo_wait:
    lbu t6, UART_LSR(t5)
    andi t6, t6, LSR_THRE
    beqz t6, _echo_wait
    sb a0, UART_THR(t5)
    ret
.section .rodata
_trap_msg:
    .string "\ntrap\n"
.section .bss
.align 4
_driver_stack:
    .space 4096
_driver_stack_top:
