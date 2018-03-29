    .globl main
    .text

#THIS IS A REALLY BAD IMPLEMENTATION OF FIBONACCI
#ON THE BRIGHT SIDE, IT STRESSES OUT OUR CPU SO IT'S A GOOD TEST

main:
        add $8, $0, $0 #r8 will be our stack pointer
        addi $1, $0, 5 #r1 will be the argument to fibonacci
        jal fib

fib:
        addi $8, $8, 12     # make stack space to preserve old necessities
        sw $1, 0($8)        # store previous fib num
        sw $31, 4($8)       # store return address on stack
        add $3, $0, $0      # initialize scratch register to 0
        beq $1, $0, ret     # if fib(0), don't recurse
        addi $3, $0, 1      # fib(1) = 1
        bne $1, $3, cont    # if not fib(1), go to cont, which recurses
ret:    add $2, $3, $0      # set return value to scratch value
        lw $1, 0($8)        # restore to the previous context
        lw $31, 4($8)      
        addi $8, $8, -12
        jr $31              # return to calling function
cont:   addi $1, $1, -1     # set argument to calling argument - 1
        jal fib             # call fib(n-1)
        add $4, $0, $2      # store return value in scratch register
        sw $4, 8($8)        # push r4 onto stack
        addi $1, $1, -2     # set argument to calling argument - 2 (n-1 was never saved on stack)
        jal fib             # call fib(n-2)
        lw $1, 0($8)        # restore to the previous context
        lw $a, 4($8)
        lw $4, 8($8)        # retrieve r4 from before
        addi $8, $8, -12
        add $2, $2, $4      # fib(n-2) + fib(n-1)
        jr $a               # return to calling function
