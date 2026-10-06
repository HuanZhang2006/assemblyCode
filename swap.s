# a0 is the address of a given array of integers
# a1 is the index we need to swap
swap:
	slli t0, a1, 2
	addi t0, t0, a0
	lw t1, 0(t0)
	lw t2, 4(t0)
	sw t2, 0(t0)
	sw t1, 4(t0)
	jalr zero, ra, 0