    .globl main
    .text

main:
        addi $5, $0, 16
        jal addone
        addi $5, $5, -1
        jal bs
        addi $6, $0, 1
        jal inter
ret:    add $5, $5, $6

addone:
        addi $5, $5, 1
        jr $31

bs:
        jr $31

inter:
        jal end
        j ret

end:
        jr $31
