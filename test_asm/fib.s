	.globl main
	.text

;THIS IS A REALLY BAD IMPLEMENTATION OF FIBONACCI
;ON THE BRIGHT SIDE, IT STRESSES OUT OUR CPU SO IT'S A GOOD TEST

main:
		add $r8, $r0, $r0 ;r8 will be our stack pointer
		addi $r1, $r0, #5 ;r1 will be the argument to fibonacci
		jal fib

fib:
		addi $r8, $r8, #12	; make stack space to preserve old necessities
		sw $r1, 0($r8)		; store previous fib num
		sw $ra, 4($r8)		; store return address on stack
		add $r3, $r0, $r0	; initialize scratch register to 0
		beq $r1, $r0, ret	; if fib(0), don't recurse
		addi $r3, $r0, #1	; fib(1) = 1
		bne $r1, $r3, cont	; if not fib(1), go to cont, which recurses
ret:	add $r2, $r3, $r0	; set return value to scratch value
		lw $r1, 0($r8)		; restore to the previous context
		lw $ra, 4($r8)		
		addi $r8, $r8, #-12
		jr $ra				; return to calling function
cont:	addi $r1, $r1, #-1	; set argument to calling argument - 1
		jal fib				; call fib(n-1)
		add $r4, $r0, $r2	; store return value in scratch register
		sw $r4, 8($r8)		; push r4 onto stack
		addi $r1, $r1, #-2	; set argument to calling argument - 2 (n-1 was never saved on stack)
		jal fib				; call fib(n-2)
		lw $r1, 0($r8)		; restore to the previous context
		lw $ra, 4($r8)
		lw $r4, 8($r8)		; retrieve r4 from before
		addi $r8, $r8, #-12
		add $r2, $r2, $r4	; fib(n-2) + fib(n-1)
		jr $ra				; return to calling function
