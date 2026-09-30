# s0 is the index of the array
# a0 is the address of array x
# a1 is the address of array y
# we want to copy all element from array y to array x

strcpy:
	addi sp, sp, -4
	sw s0, 0(sp)
	add s0, zero, zero
	
L1:
	add t0, s0, a1
	lbu t1, 0(t0)   #use lbu instead of lb to load byte
	add t0, s0, a0
	sb t1, 0(t0)
	beqz t1, L2    # put beqz after sb to make sure the \0 is copy
	addi s0, s0, 1
	j L1
L2:
	lw s0, 0(sp)
	addi sp, sp, 4
	jalr x0, 0(ra)