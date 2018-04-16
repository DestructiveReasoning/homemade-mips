# Testing every single jump
# Expected Output
# r31: 0xC
# r30: 0xA
# r29: 0x0
# r28: 0x0
# r27: 0x0
# r26: 0x0
# r25: 0x0
# r24: 0x0
# r23: 0x0
# r22: 0x0
# r21: 0x0
# r19: 0x0
# r18: 0x28
# r17: 0x0
# r16: 0x0
# r15: 0xF
# r14: 0x0
# r13: 0x0
# r12: 0x0
# r11: 0x0
# r10: 0x0
# r9:  0x0
# r8:  0x0
# r7:  0x3
# r6:  0x0
# r5:  0x0
# r4:  0x20
# r3:  0x14
# r2:  0x14
# r1:  0x20
# r0:  0x0
addi $1, $0, 1
addi $3, $0, 20
jal jal_test
loop: add $1, $1, $1
addi $2, $2, 4
sw $1, 0($2)
beq $2, $3, terminate
j loop
terminate: lw $4, 20($0)
j skippoint
jr_testpoint: addi $7, $0, 3
j die
skippoint: addi $18, $0, 40
jr $18
die: j exit
jal_test: addi $30, $0, 10
jr $31
exit: addi $15, $0, 15
