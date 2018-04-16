# Euclid's algorithm
addi $1, $0, 30
addi $2, $0, 9

gcd:	add $3, $0, $2
		div $2, $1, $2
		add $1, $0, $3
		mfhi $2
		beq $2, $0, done
		j gcd
done:	add $5, $1, $0
