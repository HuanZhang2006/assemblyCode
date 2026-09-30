#
# CMPUT 229 Student Submission License
# Version 1.0
#
# Copyright 2025 <student name>
#
# Redistribution is forbidden in all circumstances. Use of this
# software without explicit authorization from the author or CMPUT 229
# Teaching Staff is prohibited.
#
# This software was produced as a solution for an assignment in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada. This solution is confidential and remains confidential
# after it is submitted for grading.
#
# Copying any part of this solution without including this copyright notice
# is illegal.
#
# If any portion of this software is included in a solution submitted for
# grading at an educational institution, the submitter will be subject to
# the sanctions for plagiarism at that institution.
#
# If this software is found in any public website or public repository, the
# person finding it is kindly requested to immediately report, including
# the URL or other repository locating information, to the following email
# address:
#
#          cmput229@ualberta.ca
#
#------------------------------------------------------------------------------
# CCID:
# Lecture Section:
# Instructor:
# Lab Section:
# Teaching Assistant:
#-----------------------------------------------------------------------------
#

.include "common.s"

.text

# ------------------------------------------------------------------------------
# branchCounting:
#   Counts forward and backward branch instructions in the program pointed to by a0
#	On exit, the number of forward branches should be in a0, and the number of backward branches
#	should be in a1
#
# Arguments:
#   a0: Pointer to the instructions array of the program.
#
# Return Values:
#   a0: Number of forward branches.
#   a1: Number of backward branches.
#
# Register Usage:
#
# ------------------------------------------------------------------------------
branchCounting:
	  # write your solution here
	  li t0, 0x63        # store the opcode of branch type
	  li t1, -1  # store -1 to t0
	  li t5, 0  #count forward
	  li t6, 0  #count backward
	 
loop:
	lw t2, 0(a0)
	beq t2, t1, exit_loop
	andi t3, t2, 0x7f
	beq t3, t0, isBranch
	addi a0, a0, 4
	j loop

isBranch:
	srli t4, t2, 31
	beqz t4, isForward
	addi t6, t6, 1
	addi a0, a0, 4
	j loop
	
	  
isForward:
	addi t5, t5, 1
	addi a0, a0, 4
	j loop
	  
exit_loop:
	mv a0, t5
	mv a1, t6
    	ret

