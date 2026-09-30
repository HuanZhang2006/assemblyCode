# a0 = n, return a0 = n!
fact:
	blt zero, a0, L1
	li a0, 1
	jalr zero, 0(ra)
	
L1:
	addi sp, sp, -8
	sw ra, 4(sp)
	sw a0, 0(sp)
	addi a0, a0, -1
	jal ra, fact
	lw ra, 4(sp)
	lw t0, 0(sp)
	addi sp, sp, 8
	mul a0, a0, t0
	jalr zero, 0(ra)
	