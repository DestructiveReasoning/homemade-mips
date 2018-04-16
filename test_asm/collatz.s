#Collatz Problem
#Start with some number x
#Collatz(x,n) = /- n                    x is 0
#               |- Collatz(3x+1, n+1)   x is odd
#Collatz(x,n) = \- Collatz(x/2, n+1)    x is even
#This program computes Collatz(17, 0)
#The return value is stored in $5
#For Collatz(x,n), $1 stores x, $2 stores n

addi $1, $1, 17
addi $2, $2, 0
addi $4, $0, 3
addi $7, $0, 2
addi $8, $0, 1
j collatz

collatz:	beq $1, $8, done
			addi $2, $2, 1
			andi $3, $1, 1
			beq $3, $0, even
odd:		mult $1, $4
			mflo $1
			addi $1, $1, 1
			j collatz
even:		div $1, $7
			mflo $1
			j collatz
done:		add $5, $0, $2
