    .globl main
    .text

main:
        addi $r5, $r0, #16
        jal addone
        addi $r5, $r5, #-1
        jal bs
        addi $r6, $r0, #1
        jal inter
ret:    add $r5, $r5, $r6

addone:
        addi $r5, $r5, #1
        jr $ra

bs:
        jr $ra

inter:
        jal end
        j ret

end:
        jr $ra
