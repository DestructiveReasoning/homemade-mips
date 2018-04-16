addi $1, $0, 4
addi $2, $0, 5
addi $4, $0, 3

fn:	mult $3, $2, $4
	sub $3, $3, $1
	beq $3, $0, eq
	addi $1, $1, -1
	beq $1, $4, end
	beq $1, $0, end

eq:	srl $1, $1, 1
	beq $1, $4, end
	j fn

end: add $5, $0, $1
