#
# CMPUT 229 Public Materials License
# Version 1.0
#
# Copyright 2025 University of Alberta
# Copyright 2025 Austin Lu
#
# This software is distributed to students in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the disclaimer below in the documentation
#    and/or other materials provided with the distribution.
#
# 2. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#-------------------------------
# Lab- BranchCounting common.s
#
# Author: Austin Lu
# Date: May 5, 2025
#
# Adapted from:
# Control Flow Lab - Student Testbed
# Author: Taylor Lloyd
# Date: July 19, 2012
#
# reads a file and calls the function branchCounting
#
#-------------------------------
.data
.align 2
input:	  
.space 2052
.align 2
fixed:
.space 3500
noFileStr:
.asciz "Couldn't open specified file.\n"
format:
.asciz "\n"
forStr:
.asciz "Forward: "
backStr:
.asciz "Backward: "

.text
main:
    mv   t2 a1

    # Read the instructions array of the input program into input
    lw      a0 0(t2)
    la      a2 input
    jal     readFile

    # Call student's solution with the array input
    la      a0 input
    jal     branchCounting

  	# Print the results
    jal     printInt

    li	a7 10      # exit program
    ecall
    
#----------------------------------------------------------------------------
# readFile reads the file, places it in provided buffer and -1 terminates
#
# input:
#   a0: file name pointer of specific file
#   a2: address of space to place the file in mem
#
# register usage:
#   s0: copy over address of space to place the file in mem
#----------------------------------------------------------------------------
readFile:

    addi    sp sp -8
    sw      s0 0(sp)
    sw      a1 4(sp)

    mv    s0 a2

    # Open file in read-only mode
    li      a1 0
    li      a7 1024
    ecall

    # Check whether an error occurred
    bltz	a0 main_err

    # Read the content of the file into a buffer
    mv	    a1 s0
    li      a2 2048
    li      a7 63
    ecall


    mv	t0 s0
    add     t0 t0 a0	# t0 <- pointer to the end of the buffer
    li      t1 0xFFFFFFFF

    # Place sentinel value at the end of the buffer
    sw      t1 0(t0)
    j       readFileDone

main_err:
    la      a0 noFileStr
    li      a7 4
    ecall
    li      a7 10
    ecall

readFileDone:
    lw      a1 4(sp)
    lw      s0 0(sp)
    addi    sp sp 8
    jr      ra 0

#--------------
# printNum
# ARGS: a0 = integer value 1
# 		a1 = integer value 2
#
# Prints the integer provided to output in decimal
#--------------
printInt:
    li	t0 8      # There are 8 characters to print
    mv	t3 a0
    mv  t4 a1

    # Print the prefix
    la	a0 forStr
    li	a7 4
    ecall
    
    # Print the number passed
    mv a0 t3
    li a7 1
    ecall
    
    la a0 format
    li a7 4
    ecall
    
    # Print the suffix
    la	a0 backStr
    li	a7 4
    ecall
    
    # Print the number passed
    mv a0 t4
    li a7 1
    ecall
    
    la a0 format
    li a7 4
    ecall

    jr	ra 0
