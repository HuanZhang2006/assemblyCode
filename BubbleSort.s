#void sort(int v[], int n) {
#    int i, j;
#    for (i = 0; i < n; i += 1) {
#        for (j = i - 1; j >= 0 && v[j] > v[j + 1]; j -= 1) {
#            swap(v, j);
#        }
#    }
#}
.data
.align 2
array: .word 12, 1, 4, -3, 6, -99

.text
.globl main
main:
    andi sp, sp, -16        # 补充：独立演示入口将栈顶向下对齐到16字节
    la   a0, array         # a0 = 数组首地址
    li   a1, 6             # a1 = 元素个数
    jal  ra, sort
    # 在这里检查 array，应该是 -99, -3, 1, 4, 6, 12
    li   a7, 10            # 课件演示环境的退出服务
    ecall


BubbleSort:
    addi sp, sp, -32       # 修订：保留16字节对齐
    sw   ra, 16(sp)
    sw   s3, 12(sp)
    sw   s2, 8(sp)
    sw   s1, 4(sp)
    sw   s0, 0(sp)

    mv   s2, a0            # 保存 v
    mv   s3, a1            # 保存 n
    mv   s0, zero          # i = 0
    
for1:
    bge s0, s3, exit1
    addi s1, s0, -1        # j = i-1
for2:
    blt s1, zero, exit2
    slli t0, s1, 2
    add t0, t0, a0
    lw t1, 0(t0)
    lw t2, 4(t0)
    bge t2, t1, exit2
    mv a0, s2
    mv a1, s1
    jal ra, swap
    addi s1, s1, -1
    j for2

exit2:
    addi s0, s0, 1
    j for1
    
exit1:
    lw   s0, 0(sp)
    lw   s1, 4(sp)
    lw   s2, 8(sp)
    lw   s3, 12(sp)
    lw   ra, 16(sp)
    addi sp, sp, 32
    jalr zero, ra, 0

swap:
    slli t1, a1, 2
    add  t1, a0, t1
    lw   t0, 0(t1)
    lw   t2, 4(t1)
    sw   t2, 0(t1)
    sw   t0, 4(t1)
    jalr zero, ra, 0