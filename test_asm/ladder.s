addi $1, $1, 8
jr $1
addi $2, $2, 1
addi $1, $1, 16
add $1, $1, $0
jr $1
addi $2, $2, 2
addi $3, $3, 3
beq $2, $3, done
done:	add $5, $2, $3
