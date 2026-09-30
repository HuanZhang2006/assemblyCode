#
# CMPUT 229 Public Materials License
# Version 1.0
#
# Copyright 2024 University of Alberta
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
Author: Zhaoyu Li
Date: July 31, 2024

This program converts hexadecimal numbers in textual format to binary format and writes the result to a file.

Input Modes:
    - If no input file name is given, the program will read the input from standard input.
    - If an input file name is given, the program will read the input file name from standard input.

Output Modes:
    - If no input file name is given, the program will write the output to a file named out.bin.
    - If an input file name is given, the program will write the output to the file with the given name.

Input: Hexadecimal numbers (prefixed with 0x) in a textual format. It is recommended that each hexadecimal number is
separated by a newline.

Output: Binary representation of the input written to a file.
"""

import argparse


def parse_args():
    args = argparse.ArgumentParser()
    args.add_argument("-i", "--input", required=False, help="Input file name, defaults to standard input")
    args.add_argument("-o", "--output", required=False, help="Output file name, defaults to out.bin")
    return args.parse_args()


def read_from_stdin():
    hex_array = []
    while True:
        hexadecimal = input()
        if hexadecimal == '':
            break
        hex_array.append(hexadecimal)
    return hex_array


def read_from_file(filename):
    with open(filename, 'r') as f:
        hex_array = [i.strip('\n') for i in f.readlines()]
        return hex_array


def write_output(hex_array, file_name):
    with open(file_name, 'wb') as f:
        for i in hex_array:
            hex_value = int(i, 16)
            bytes_rep = hex_value.to_bytes(4, byteorder='little')
            f.write(bytes_rep)

        f.flush()


def main():
    args = parse_args()
    out_file_name = args.output if args.output is not None else 'out.bin'
    hex_array = read_from_file(args.input) if args.input is not None else read_from_stdin()
    write_output(hex_array, out_file_name)


if __name__ == '__main__':
    main()
