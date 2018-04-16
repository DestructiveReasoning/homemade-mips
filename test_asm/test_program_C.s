# Simple subroutine stuff
# r31: 0x0
# r30: 0xF
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
# r8:  0x0
# r7:  0x0
# r6:  0x0
# r5:  0x0
# r4:  0x0
# r3:  0x0
# r2:  0x0
# r1:  0x0
# r0:  0x0

# Goto init and main
j init

sub1: sub $10, $5, $1
beq $10, $0, end_sub_1
addi $1, $1, 1 # modify end condition
end_sub_1: jr $31

# if ($3 == 60) {
#   $4 = 0;
# }
sub2: bne $3, $5, end_if_sub2
addi $4, $0, 0 # actual terminate condition
end_if_sub2: jr $31

# Count in multiples of 2 and 3
init:  addi $1, $0, 15 # end condition
addi $5, $0, 60
addi $4, $0, 1
main: addi $2, $2, 2 # count x2
addi $3, $3, 3 # count x3
jal sub1
jal sub2
beq $2, $1, end
beq $3, $1, end
beq $4, $0, end
j main

end: addi $30, $0, 15 # End marker
