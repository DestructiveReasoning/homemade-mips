# Extrenous Looping
# r31: 0x16
# r30: 0xF
# r29: 0x0
# r28: 0xF
# r27: 0x0
# r26: 0x0
# r25: 0x0
# r24: 0x0
# r23: 0x0
# r22: 0x0
# r21: 0x0
# r19: 0x0
# r18: 0x0
# r17: 0x0
# r16: 0x0
# r15: 0x0
# r14: 0x0
# r13: 0x0
# r12: 0x0
# r11: 0x0
# r10: 0x0
# r9:  0x0
# r8:  0x25
# r7:  0x25
# r6:  0x0
# r5:  0x0
# r4:  0x20
# r3:  0x10
# r2:  0x100
# r1:  0x100
# r0:  0x0

# skip over these functions
j start
# just changes $1 128 -> 256
side_loop1: add $2, $1, $2 # change loop1 end condition
addi $5, $0, 1 # side_loop1 end condition
beq $5, $4, loop1
j side_loop1

j start # you shouldn't be here
loop2: add $7, $3, $31
addi $8, $0, 1
bne $8, $7, loop2
addi $31, $31, 1 # skip the line after the jal that called this subroutine
jr $31

start: addi $1, $0, 128 # first branch condition
addi $2, $0, 1 # exponential counter
addi $3, $0, 16 # first side branch condition
addi $4, $0, 8 # side_loop1 end condition
loop1: beq $2, $1, end_loop1
add $2, $2, $2 # grow in powers of 2
beq $2, $3, side_loop1
j loop1
end_loop1: addi $30, $0, 15 # End marker
jal loop2
addi $29, $0, 15 # should be skipped
addi $28, $0, 15
