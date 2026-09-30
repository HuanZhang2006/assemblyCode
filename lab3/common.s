#
# CMPUT 229 Public Materials License
# Version 1.0
#
# Copyright 2024 University of Alberta
# Copyright 2017 Kristen Newbury
# Copyright 2024 Zhaoyu Li
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
# Lab- Fix Branch common.s
#
# Modified by: Zhaoyu Li
# Reason: to make consistent with the new lab specifications
# Date: July 29, 2024
#
# Author: Kristen Newbury
# Date: June 5 2017
#
# Adapted from:
# Control Flow Lab - Student Testbed
# Author: Taylor Lloyd
# Date: July 19, 2012
#
# reads two files and calls the function fixBranch
#
#-------------------------------
.data
.align 2
original:	  #These absolutely MUST be the first two data defined, for target address correction
.space 2052
.align 2
modified:
.space 3500
fixed:
.space 3500
noFileStr:
.asciz "Couldn't open specified file.\n"
format:
.asciz "\n"
oxStr:
.asciz "0x"

.text
main:

    mv   t2 a1

    # Read the instructions array of the original program into original
    lw      a0 0(t2)
    la      a2 original
    jal     readFile

    # Read the instructions array of the modified program into modified
    lw      a0 4(t2)
    la      a2 modified
    jal     readFile

    # Call student's solution with the three arrays: orginal, modified, and fixed
    la      a0 original
    la      a1 modified
    la      a2, fixed
    jal     fixBranch

    # Print the instructions array of the fixed progam
    la      a0 fixed
    jal     writeFile

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
    jr      ra, 0

#----------------------------------------------------------------------------
# writeFile writes a buffer to the standard output each instruction as an int on a newline, buffer is 0xFFFFFFFF terminated

#
# input:
# a0: the binary file to write out
#
# register usage:
#
# s0: the buffer to write out
# s1: sentinel
# s2: the instruction
#----------------------------------------------------------------------------
writeFile:

    addi    sp sp -16
    sw      ra 0(sp)
    sw      s0 4(sp)
    sw      s1 8(sp)
    sw      s2 12(sp)

    mv   s0 a0
    li      s1 0xFFFFFFFF  #sentinel         #load value to check to use for sentinel check

writeLoop:
    lw      s2 0(s0)
    beq     s2 s1 writeDone   # if word == sentinel: done
    addi	s0 s0 4             # increment buffer pointer

    # print to standard output
    mv    a0 s2
    jal     printHex    # print the instruction in hexadecimal format
    la      a0 format   # print newline
    li      a7 4
    ecall
    j       writeLoop

writeDone:
    lw      ra 0(sp)
    lw      s0 4(sp)
    lw      s1 8(sp)
    lw      s2 12(sp)
    addi    sp sp 16
    jr      ra 0

#--------------
# printHex
# ARGS: a0 = integer value
#
# Prints the integer provided to output in Hexadecimal
#--------------
printHex:
    li	t0 8      # There are 8 characters to print
    mv	t3 a0

    # Print the leading '0x'
    la	a0 oxStr
    li	a7 4
    ecall

printHex_loop:
        srli    t1 t3 28	# isolate uppermost 4 bits
        li	t2 9

        # Check if the current number we are printing is greater than 9
        bgt	t1 t2 charPrint

    # If it is not, then we are printing a digit (0-9)
    digitPrint:
        addi	a0 t1 48	# '0'
        j	print

    # If it is, then we are printing a char (a-f)
    charPrint:
        addi	a0 t1 87	# 'a' - 10

    # Print char ecall
    print:
        li	a7 11
        ecall

        # loop incrementation
        addi	t0 t0 -1    # One less character to print
        slli	t3 t3 4     # We have printed the character encoded in the upper most 4 bits

        # Keep looping until there are no more characters to print
        bgtz	t0 printHex_loop

    jr	ra 0
#-------------------end common-------------------------------------------------
