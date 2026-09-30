#
# CMPUT 229 Public Materials License
# Version 1.0
#
# Copyright 2024 University of Alberta
# Copyright 2017 Austin Crapo/Kristen Newbury
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
"""
Author: Austin Crapo
Date: May 4, 2017

Minor modifications: Kristen Newbury
Date: May 10, 2017

Conversion to RISC-V: Mehrab Mehdi Islam
Date: May 17, 2019

Minor modifications: Zhaoyu Li
Date July 31, 2024

A decompiler for binary RISC-V files, as produced through rars. It takes a .bin
file as a command line argument. Additionally, because rars can technically run
in big endian mode on certain machines, you can force big endian mode by passing
"big" as the third CLA, or leave it blank for "little" endian mode as default

mode flags include:
    b: binary file input
    h: hexadecimal instruction representation file input (each instruction as 0x________ on a newline)

sample usage:

    python3 binDecompiler.py modeFlag filename (optional)endianness

example:

    python3 binDecompiler.py h test.out

THIS PROGRAM DOES NOT IMPLEMENT ALL OPCODES/FUNCTION CODES
Feel free to add those that cause the compiler to crash or throw 'Unparsable' errors
to the dictionaries at the program start
"""

import sys
import argparse

parser = argparse.ArgumentParser(description='Decompiles binary RISC-V files')
parser.add_argument("modeFlag",
                    choices=['b', 'h'],
                    help="b for binary input file, h for textual hexadecimal input file")
parser.add_argument("filename", help="name of file to decompile")
parser.add_argument('-e', '--endianness',
                    required=False,
                    choices=['little', 'big'],
                    default='little',
                    help="endianness mode")
parser.add_argument('-o', '--output',
                    required=False,
                    help="Name of output file")

args = parser.parse_args()

mode = args.modeFlag
endian = args.endianness
bin_file = args.filename
tsv_out_file = open(f"{args.output}.tsv", 'w') if args.output is not None else sys.stdout
txt_out_file = open(f"{args.output}.txt", 'w') if args.output is not None else sys.stdout

# define the opcodes, function codes, and groups for translation later
all_ops = {
    0x03: 'ITYPE1',
    0x0F: 'ITYPE2',
    0x13: 'ITYPE3',
    0x17: 'auipc',
    0x1B: 'ITYPE4',
    0x23: 'STYPE',
    0x33: 'RTYPE1',
    0x37: 'lui',
    0x3B: 'RTYPE2',
    0x63: 'SBTYPE',
    0x67: 'jalr',
    0x6F: 'jal',
    0x73: 'ecall'
}

signed_ops = {
    0x01,
    0x04,
    0x05,
    0x06,
    0x07,
    0x08,
    0x0A,
    0x0c,
    0x0D,
    0x0F,
    0x20,
    0x21,
    0x23,
    0x28,
    0x29,
    0x2B
}

i1_funcs = {
    0x00: 'lb',
    0x01: 'lh',
    0x02: 'lw',
    0x03: 'ld',
    0x04: 'lbu',
    0x05: 'lhu',
    0x06: 'lwu'
}

i2_funcs = {
    0x00: 'fence',
    0x01: 'fence.i'
}

i3_funcs = {
    0x00: 'addi',
    0x01: 'slli',
    0x02: 'slti',
    0x03: 'sltiu',
    0x04: 'xori',
    0x05: 'si-right',
    0x06: 'ori',
    0x07: 'andi'
}

i4_funcs = {
    0x00: 'addiw',
    0x01: 'slliw',
    0x05: 'siw-right'
}

s_funcs = {
    0x00: 'sb',
    0x01: 'sh',
    0x02: 'sw',
    0x03: 'sd'
}

r1_funcs = {
    0x00: 'arth_opp',
    0x01: 'sll',
    0x02: 'slt',
    0x03: 'sltu',
    0x04: 'xor',
    0x05: 's-right',
    0x06: 'or',
    0x07: 'and',
}

r2_funcs = {
    0x00: 'arthW-opp',
    0x01: 'sllw',
    0x05: 'sw-right',
}

sb_funcs = {
    0x00: 'beq',
    0x01: 'bne',
    0x04: 'blt',
    0x05: 'bge',
    0x06: 'bltu',
    0x07: 'bgeu',
}

m_funcs = {
    0x00: 'mul',
    0x01: 'mulh',
    0x04: 'div'
}

regs = {
    0: 'zero',
    1: 'ra',
    2: 'sp',
    3: 'gp',
    4: 'tp',
    5: 't0',
    6: 't1',
    7: 't2',
    8: 's0',
    9: 's1',
    10: 'a0',
    11: 'a1',
    12: 'a2',
    13: 'a3',
    14: 'a4',
    15: 'a5',
    16: 'a6',
    17: 'a7',
    18: 's2',
    19: 's3',
    20: 's4',
    21: 's5',
    22: 's6',
    23: 's7',
    24: 's8',
    25: 's9',
    26: 's10',
    27: 's11',
    28: 't3',
    29: 't4',
    30: 't5',
    31: 't6'
}

# hardcoded binary address used for line calculation for addresses, ONLY works if binary representation is located first
# in the data segment
PC = 268503044

if mode == "b":
    f = open(bin_file, "rb")
    word = int.from_bytes(f.read(4), endian)
# read every word, word by word
else:
    f = open(bin_file)
    try:
        parsed = f.readline().rstrip()[2:]  # want to remove the 0x on each string
        word = int.from_bytes(bytes.fromhex(parsed), "big")
    except ValueError:  # if there is an invalid character or no lines in the file to read
        sys.exit()

instr_list = []

print(f"Address   \tCode      \tSource\n"
      f"----------\t----------\t----------", file=tsv_out_file)
while (word != -1) and (word != 0):
    if word < 0:
        # correct for negative ints
        signedBin = bin(word & 0xffffffff)
        word = int(signedBin, 2)

    instr = f"0x{hex(word)[2:].zfill(8)}"
    instr_list.append(instr)

    print(f"{hex(PC)}\t{instr}", end='\t', file=tsv_out_file)

    opcode = word & 0x0000007F
    funct7 = word >> 25

    try:
        # try to interpret the opcode
        inst = all_ops[opcode]
    except Exception as e:
        inst = 'Unknown'
    if funct7 == 0x01:
        func = word & 28672
        func = func >> 12

        inst = m_funcs[func]
        rs = regs[(word & 0x000F8000) >> 15]
        rt = regs[(word & 0x01F00000) >> 20]
        rd = regs[(word & 0x00000F80) >> 7]
        print(inst + "\t" + rd + ", " + rs + ", " + rt, file=tsv_out_file)
    # do mul j_ops
    else:
        if inst == 'RTYPE1':
            # Rtype functions come in 5 forms, shifts, 1/2/3 register arithmetic forms, and syscall
            func = word & 28672
            func = func >> 12

            inst = r1_funcs[func]
            rs = regs[(word & 0x000F8000) >> 15]
            rt = regs[(word & 0x01F00000) >> 20]
            rd = regs[(word & 0x00000F80) >> 7]

            if func == 0x00:
                func7 = word >> 25
                if func7 == 0x00:
                    # This is a shift R type
                    print('add' + "\t" + rd + ", " + rs + ",", rt, file=tsv_out_file)
                elif func7 == 0x20:
                    print('sub' + "\t" + rd + ", " + rs + ",", rt, file=tsv_out_file)
            elif func == 0x05:

                if func7 == 0x00:
                    # This is a shift R type
                    print('srl' + "\t" + rd + ", " + rs + ",", rt, file=tsv_out_file)
                elif func7 == 0x20:
                    print('sra' + "\t" + rd + ", " + rs + ",", rt, file=tsv_out_file)

            else:
                # 3 register arithmetic
                print(inst + "\t" + rd + ", " + rs + ", " + rt, file=tsv_out_file)

        if inst == 'RTYPE2':
            # Rtype functions come in 5 forms, shifts, 1/2/3 register arithmetic forms, and syscall
            func = word & 28672
            func = func >> 12

            inst = r2_funcs[func]
            rs = regs[(word & 0x000F8000) >> 15]
            rt = regs[(word & 0x01F00000) >> 20]
            rd = regs[(word & 0x00000F80) >> 7]

            if func == 0x00:
                func7 = word >> 25
                if func7 == 0x00:
                    # This is a shift R type
                    print('addw' + "\t" + rd + ", " + rs + ",", rt, file=tsv_out_file)
                elif func7 == 0x20:
                    print('subw' + "\t" + rd + ", " + rs + ",", rt, file=tsv_out_file)
            elif func == 0x05:

                if func7 == 0x00:
                    # This is a shift R type
                    print('srlw' + "\t" + rd + ", " + rs + ",", rt, file=tsv_out_file)
                elif func7 == 0x20:
                    print('sraw' + "\t" + rd + ", " + rs + ",", rt, file=tsv_out_file)

            else:
                # 3 register arithmetic
                print(inst + "\t" + rd + ", " + rs + ", " + rt, file=tsv_out_file)
        elif inst == 'ITYPE1':
            # Rtype functions come in 5 forms, shifts, 1/2/3 register arithmetic forms, and syscall
            func = word & 28672
            func = func >> 12

            # if shamt >= 2**15 and funct3 in signed_funcs:
            # 	shamt -= 2**16
            try:
                inst = i1_funcs[func]
                rs = regs[(word & 0x000F8000) >> 15]
                rd = regs[(word & 0x00000F80) >> 7]
                imm = word >> 20

            except:
                print("Unparsable instruction")

            print(inst + "\t" + rt + ", " + str(imm) + "(" + rs + ")", file=tsv_out_file)

        elif inst == 'ITYPE2':
            #Rtype functions come in 5 forms, shifts, 1/2/3 register arithmetic forms, and syscall
            func = word & 28672
            func = func >> 12

            try:

                inst = i2_funcs[func]
                rs = regs[(word & 0x000F8000) >> 15]
                rd = regs[(word & 0x00000F80) >> 7]
                imm = word >> 20


            except:
                print("Unparsable instruction")

            print(inst + "\t" + rd + ", " + rs + ", " + str(imm), file=tsv_out_file)

        elif inst == 'ITYPE3':
            #Rtype functions come in 5 forms, shifts, 1/2/3 register arithmetic forms, and syscall
            func = word & 28672
            func = func >> 12

            try:

                inst = i3_funcs[func]
                rs = regs[(word & 0x000F8000) >> 15]
                rd = regs[(word & 0x00000F80) >> 7]
                imm = word >> 20


            except:
                print("Unparsable instruction")

            if imm >= 2 ** 11 and inst == 'addi':
                imm -= 2 ** 12
            if func == 0x05:
                func7 = word >> 25
                if func7 == 0x00:
                    #This is a shift R type
                    print('srli' + "\t" + rd + ", " + rs + ",", str(imm), file=tsv_out_file)
                elif func7 == 0x20:
                    print('srai' + "\t" + rd + ", " + rs + ",", str(imm), file=tsv_out_file)
            else:
                print(inst + "\t" + rd + ", " + rs + ", " + str(imm), file=tsv_out_file)

        elif inst == 'ITYPE4':
            #Rtype functions come in 5 forms, shifts, 1/2/3 register arithmetic forms, and syscall
            func = word & 28672
            func = func >> 12

            try:
                inst = i4_funcs[func]
                rs = regs[(word & 0x000F8000) >> 15]
                rd = regs[(word & 0x000007C0) >> 7]
                imm = word >> 20


            except:
                print("Unparsable instruction")

            if func == 0x05:
                func7 = word >> 25
                if func7 == 0x00:
                    #This is a shift R type
                    print('srliw' + "\t" + rd + ", " + rs + ",", str(imm), file=tsv_out_file)
                elif func7 == 0x20:
                    print('sraiw' + "\t" + rd + ", " + rs + ",", str(imm), file=tsv_out_file)
            else:
                print(inst + "\t" + rd + ", " + rs + ", " + str(imm), file=tsv_out_file)
        elif inst == 'ecall':
            print(inst, file=tsv_out_file)


        elif inst == 'SBTYPE':
            #Rtype functions come in 5 forms, shifts, 1/2/3 register arithmetic forms, and syscall
            func = word & 28672
            func = func >> 12

            try:
                inst = sb_funcs[func]
                rs = regs[(word & 0x000F8000) >> 15]
                rt = regs[(word & 0x01F00000) >> 20]
                imm1 = (word & 0xFE000000) >> 20
                imm2 = (word & 0x00000F80) >> 7
                imm20 = (imm1 & 0x00000800)
                imm10 = (imm1 & 0x000007E0) >> 1
                imm = imm20 | imm10
                imm11 = (imm2 & 0x00000001) << 10
                imm = imm | imm11
                imm4 = (imm2 & 0x0000001E) >> 1
                imm = imm | imm4



            except:
                print("Unparsable instruction")
            if imm >= 2 ** 11:
                imm -= 2 ** 12
            imm = imm << 1
            branchTarget = (imm) + PC
            print(inst + "\t" + rs + ", " + rt + ", " + hex(branchTarget), file=tsv_out_file)
        elif inst == 'STYPE':
            #Rtype functions come in 5 forms, shifts, 1/2/3 register arithmetic forms, and syscall
            func = word & 28672
            func = func >> 12

            try:
                inst = s_funcs[func]
                rs = regs[(word & 0x000F8000) >> 15]
                rt = regs[(word & 0x01F00000) >> 20]
                imm1 = (word & 0xFE000000) >> 20
                imm2 = (word & 0x00000F80) >> 7
                imm = imm1 | imm2


            except:
                print("Unparsable instruction")

            print(inst + "\t" + rt + ", " + str(imm) + "(" + rs + ")", file=tsv_out_file)
        elif inst == 'jal':

            address = word >> 12
            #print(hex(address))
            rd = regs[(word & 0x00000F80) >> 7]
            #Jumps store addresses that will then be shifted, the shift is displayed for readability
            twenty_bit = address & 0x00080000

            #print(hex(twenty_bit))
            ten_one_bit = (address & 0x0007FE00) >> 9
            #print(hex(ten_one_bit))
            cor_address = twenty_bit | ten_one_bit
            elev_bit = (address & 0x00000100) << 2
            #print(hex(elev_bit))
            cor_address = cor_address | elev_bit
            nTwelve = (address & 0x000000FF) << 11
            #print(hex(nTwelve))
            cor_address = cor_address | nTwelve

            # print(hex(cor_address))

            if cor_address >= 2 ** 19:
                cor_address -= 2 ** 20
            cor_address = cor_address * 2
            targetAddress = PC + cor_address
            print(inst + '\t' + rd + ", " + hex(targetAddress), file=tsv_out_file)

        elif inst == 'jalr':

            print("jr" + "\t" + "ra", file=tsv_out_file)

        elif inst == 'lui':

            rd = regs[(word & 0x00000F80) >> 7]
            imm = word >> 12

            print(inst + '\t' + rd + ", " + str(imm), file=tsv_out_file)

    PC += 4
    if mode == "b":
        word = int.from_bytes(f.read(4), endian)
    else:
        parsed = f.readline().rstrip()[2:]  # want to remove the 0x on each string
        if parsed != "":
            word = int.from_bytes(bytes.fromhex(parsed), "big")
        else:
            break

if args.output is None:
    print()

for i in instr_list:
    print(i, file=txt_out_file)
