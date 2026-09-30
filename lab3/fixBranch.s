#
# CMPUT 229 Student Submission License
# Version 1.0
#
# Copyright 2024 <student name>
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

# This MUST be the first line
.include "common.s"

.data
    # Your variables here
    	.align 2
	insPoints:  .space 204     # 最多 50 个插入点 + 哨兵 = 51 × 4
	insCounts:  .space 204
	branchArr:  .space 104     # 最多 25 个分支 + 哨兵 = 26 × 4
	targetArr:  .space 104	

.text

# ------------------------------------------------------------------------------
# fixBranch:
#   Fixes branch instructions in the modified program such that they
#   branch to the same target as they did in the original program. Writes the
#   binary representation of the new program with fixed branch instructions to a
#   separate array.
#
# Arguments:
#   a0: Pointer to the instructions array of the original program.
#   a1: Pointer to the instructions array of the modified program.
#   a2: Pointer to an empty array that is the same size as the instructions array
#       of the modified program. This function must write the instructions of the
#       fixed program to this array and terminate it with the sentinel value
#       0xFFFFFFFF.
#
# Register Usage:
#   s0: pointer to the instructions array of the original program
#   s1: pointer to the instructions array of the modified program
#   s2: pointer to the instructions array of the fixed program
#   s3: pointer to the insertion points array
#   s4: pointer to the insertions array
#   s5: read pointer into the branches array
#   s6: read pointer into the targets array
#   s7: pointer to the current instruction in the fixed program
#   s8: shift of the current branch instruction (B)
#   s9: shift of the current branch target (T)
#   s10: address of the current branch instruction in the original program (B)
#   s11: address of the current branch target in the original program (T)
#   t0: copy write pointer; new branch offset
#   t1: copy read pointer; sentinel; new address of B; immediate mask 0x01FFF07F
#   t2: current instruction
#   t3: sentinel during copy; branch opcode 0x63; temporary for immediate fields
#   t4: opcode of the current instruction
# ------------------------------------------------------------------------------
fixBranch:
#      ---- store -----
	addi sp, sp, -52
	sw ra, 0(sp)
	sw s0, 4(sp)  
	sw s1, 8(sp)
	sw s2, 12(sp)
	sw s3, 16(sp) #
	sw s4, 20(sp)
	sw s5, 24(sp)
	sw s6, 28(sp)
	sw s7, 32(sp)
	sw s8, 36(sp)
	sw s9, 40(sp)
	sw s10, 44(sp)
	sw s11, 48(sp)
	
	# ------------------
    	mv    s0, a0   # s0 <- orig
    	mv    s1, a1  # s1 <- modify
    	mv    s2, a2 # s2 <- fixed
    	jal   findInsertions
    	mv    s3, a0               # s3 = insPoints 的起始地址
    	mv    s4, a1               # s4 = insCounts 的起始地址

    	mv    a0, s0
    	jal   findBranches
    	mv    s5, a0               # s5 = branchArr 的起始地址
    	mv    s6, a1               # s6 = targetArr 的起始地址
    	
    	mv t0, s2
    	mv t1, s1
    	li t3, -1
insCpy:
	lw t2, 0(t1)
	sw t2, 0(t0)
	addi t1, t1, 4
	addi t0, t0, 4
	beq t2, t3, afterCpy
	j insCpy
	
afterCpy:
	mv s7, s2


fixedIte:
	lw t2, 0(s7)
	li t1, -1
	beq t2, t1, done
	andi t4, t2, 0x7F
	li t3, 0x63
	bne t4, t3, nextIte
	lw s10, 0(s5)  # get a B to s10
	
	addi s5, s5, 4

	mv a0, s10
	mv a1, s3
	mv a2, s4
	jal getShift
	mv s8, a0   # store Shift B to s8
	lw s11, 0(s6)  # get a T to s11
	mv a0, s11
	mv a1, s3
	mv a2, s4
	addi s6, s6, 4
	jal getShift
	mv s9, a0   # store Shift T to s9
	
	# newOff = (T + 4*shift(T)) - (B + 4*shift(B))
	slli t0, s9, 2        # t0 = 4 * shift(T)
	add  t0, t0, s11      # t0 = T 在新程序中的位置 = T + 4*shift(T)
	slli t1, s8, 2        # t1 = 4 * shift(B)
	add  t1, t1, s10      # t1 = B 在新程序中的位置 = B + 4*shift(B)
	sub  t0, t0, t1       # t0 = newOff

	lw   t2, 0(s7)        # 重新读出分支指令（getShift 改掉了 t2）
	# ---- 1. 清掉旧的立即数位，只保留 rs2 / rs1 / funct3 / opcode ----
	li   t1, 0x01FFF07F       # bit 24..12 和 bit 6..0 是 1，其余是 0
	and  t2, t2, t1

	# ---- 2. newOff bit 12 → 指令 bit 31 ----
	srli t3, t0, 12
	andi t3, t3, 1
	slli t3, t3, 31
	or   t2, t2, t3

	# ---- 3. newOff bit 10..5 → 指令 bit 30..25 ----
	srli t3, t0, 5
	andi t3, t3, 0x3F
	slli t3, t3, 25
	or   t2, t2, t3

	# ---- 4. newOff bit 4..1 → 指令 bit 11..8 ----
	srli t3, t0, 1
	andi t3, t3, 0xF
	slli t3, t3, 8
	or   t2, t2, t3

	# ---- 5. newOff bit 11 → 指令 bit 7 ----
	srli t3, t0, 11
	andi t3, t3, 1
	slli t3, t3, 7
	or   t2, t2, t3

	# ---- 6. 写回 fixed 数组里的同一个位置 ----
	sw   t2, 0(s7)
nextIte:
	addi s7, s7, 4
	j fixedIte
    	
done:
    	# ---- restore ------
    	mv a2, s2
    	
    	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	lw s3, 16(sp)
	lw s4, 20(sp)
	lw s5, 24(sp)
	lw s6, 28(sp)
	lw s7, 32(sp)
	lw s8, 36(sp)
	lw s9, 40(sp)
	lw s10, 44(sp)
	lw s11, 48(sp)
	addi sp, sp, 52
	
    	ret

# -----------------------------------------------------------------------------
# findInsertions:
#   Finds all the insertion points and how many instructions were inserted
#   after each insertion point
#
# Arguments:
#   a0: Pointer to the instruction array of the original program.
#   a1: Pointer to the instruction array of the modified program.
#
# Returns:
#   a0: Pointer to the insertion points array
#   a1: Pointer to the insertions array
#
# Register usage:
#   --- insert your register usage here ---
#
# -----------------------------------------------------------------------------
findInsertions:
	la t0, insPoints
	la t1, insCounts
	mv t2, a0
	mv t3, a1
fIloop:
	li t6, -1
	lw t4, 0(t2)
	beq t4, t6, donefI 
	lw t5, 0(t3)
	beq t4, t5, next
	li  t6, 0

countLoop:
	addi t3, t3, 4
	addi t6, t6, 1
	lw t5, 0(t3)
	beq t4, t5, record
	j countLoop
	
next:
	addi t2, t2, 4
	addi t3, t3, 4
	j fIloop
	
record:
	sw t6, 0(t1)
	addi t6, t2, -4
	sw t6, 0(t0)
	addi t0, t0, 4
	addi t1, t1, 4
	j fIloop
	
donefI:
	li t6, -1
	sw t6, 0(t0)
	sw t6, 0(t1)
	la a0, insPoints
	la a1, insCounts
	ret
#----------------------------------------------------------------------------
# findBranches:
#   Finds all branches and their respective targets in the original program
#
# Arguments:
#   a0: Pointer to the instruction array of the original program.
#
# Returns:
#   a0: Pointer to the branches array.
#   a1: Pointer to the targets array.
#
   # Register usage:
   #   a0: pointer into the original instructions array
   #   t0: write pointer into branchArr
   #   t1: write pointer into targetArr
   #   t2: current instruction
   #   t3: temporary for opcode / immediate fields
   #   t4: decoded branch offset, then target address
   #   t5: branch opcode 0x63
   #   t6: sentinel 0xFFFFFFFF
#----------------------------------------------------------------------------
findBranches:
	la t0, branchArr
	la t1, targetArr
	li t6, -1
	li t5, 0x63
fBloop:
	lw t2, 0(a0)
	beq t2, t6, donefB
	andi t3, t2, 0x7F
	beq t3, t5, recordfB
	addi a0, a0, 4
	j fBloop
recordfB:
	sw a0, 0(t0)
	addi t0, t0, 4
    	# imm[12]：bit 31
    	srli  t4, t2, 31             # 取出 bit 31
    	slli  t4, t4, 12             # 放到第 12 位

    	# imm[11]：bit 7
    	srli  t3, t2, 7
    	andi  t3, t3, 1
    	slli  t3, t3, 11
    	or    t4, t4, t3

    	# imm[10:5]：bit 30..25
    	srli  t3, t2, 25
    	andi  t3, t3, 0x3F           # 6 位
    	slli  t3, t3, 5
    	or    t4, t4, t3

    	# imm[4:1]：bit 11..8
    	srli  t3, t2, 8
    	andi  t3, t3, 0xF            # 4 位
    	slli  t3, t3, 1
    	or    t4, t4, t3

    	# 符号扩展：13 位 → 32 位
    	slli  t4, t4, 19
    	srai  t4, t4, 19             # 必须是 srai（算术右移）
    	
    	add t4, t4, a0
    	sw t4, 0(t1)
    	addi t1, t1, 4
    	
    	addi a0, a0, 4
    	j fBloop
donefB:
	sw t6, 0(t0)
	sw t6, 0(t1)
	la a0, branchArr
	la a1, targetArr
	ret
	
# -----------------------------------------------------------------------------
# getShift:
#   Counts how many instructions were inserted before a given instruction
#   of the original program, i.e. the sum of insertions[i] over all
#   insertion points[i] < x.
#
# Arguments:
#   a0: Address x of an instruction in the original program.
#   a1: Pointer to the insertion points array.
#   a2: Pointer to the insertions array.
#
# Returns:
#   a0: Number of instructions inserted before x.
#
# Register usage:
#   a1: read pointer into the insertion points array
#   a2: read pointer into the insertions array
#   t0: running sum
#   t1: sentinel 0xFFFFFFFF
#   t2: current insertion point
#   t3: current insertion count
# -----------------------------------------------------------------------------
getShift:
    li    t0, 0                 # sum = 0
    li    t1, -1                # sentinel
gSloop:
    lw    t2, 0(a1)             # p = insPoints[i]
    beq   t2, t1, gSdone        # 先判断哨兵：到结尾就结束
    bgeu  t2, a0, gSnext        # p >= x → 插在 x 后面（或就在 x 后面），不算，为什么用无符号（u）： 因为比较的是地址。地址没有负数，0x80000000 比 0x7FFFFFFC 大。但如果用有符号的 bge，0x80000000 会被当成一个很大的负数，比较结果就反了
    lw    t3, 0(a2)             # count = insCounts[i]
    add   t0, t0, t3            # sum += count
gSnext:
    addi  a1, a1, 4             # 两个读指针一起往后挪
    addi  a2, a2, 4
    j     gSloop
gSdone:
    mv    a0, t0                # 返回 sum
    ret