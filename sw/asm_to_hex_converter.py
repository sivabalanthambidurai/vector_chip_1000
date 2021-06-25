#____________________________________________________________________________________________________________________
#file name : asm_to_hex_converter.py
#author : sivabalan
#description : This file contains logic to convert assembly level code to
#machine code. 
#____________________________________________________________________________________________________________________


def opcode_to_hex(opcode_input):
    opcode_dict = {   "NO_OP"         : 0,
                      "ADDVVD"        : 1,
                      "ADDVSD"        : 2,
                      "SUBVVD"        : 3,
                      "SUBVSD"        : 4,
                      "SUBSVD"        : 5,
                      "MULVVD"        : 6,
                      "MULVSD"        : 7,
                      "DIVVVD"        : 8,
                      "DIVVSD"        : 9,
                      "DIVSVD"        : 10,
                      "LV"            : 11,
                      "LVI"           : 12,
                      "LVWS"          : 13,
                      "SV"            : 14,
                      "SVI"           : 15,
                      "SVWS"          : 16,
                      "SEQVVD"        : 17,
                      "SNEVVD"        : 18,
                      "SGTVVD"        : 19,
                      "SLTVVD"        : 20,
                      "SGEVVD"        : 21,
                      "SLEVVD"        : 22,
                      "SEQVSD"        : 23,
                      "SNEVSD"        : 24,
                      "SGTVSD"        : 25,
                      "SLTVSD"        : 26,
                      "SGEVSD"        : 27,
                      "SLEVSD"        : 28,
                      "POP"           : 29,
                      "CVM"           : 30,
                      "MTC1"          : 31,
                      "MFC1"          : 32,
                      "MVTM"          : 33,
                      "MVFM"          : 34,
                      "PIPE_ACTIVATE" : 35,
                      "PIPE_HALT"     : 36,
                      "MOV_IMM"       : 37,
                      "MOV_IMM_DATA"  : 38}
    hex_output = hex(opcode_dict.get(opcode_input,0))
    return hex_output;

def reg_to_hex(reg_input):
    reg_dict = {"V0"  : 0,
                "V1"  : 1,
                "V2"  : 2,
                "V3"  : 3,
                "V4"  : 4,
                "V5"  : 5,
                "V6"  : 6,
                "V7"  : 7,
                "R0"  : 0,
                "R1"  : 1,
                "R2"  : 2,
                "R3"  : 3,
                "R4"  : 4,
                "R5"  : 5,
                "R6"  : 6,
                "R7"  : 7,
                "R8"  : 8,
                "R9"  : 9,
                "R10" : 10,
                "R11" : 11,
                "R12" : 12,
                "R13" : 13,
                "R14" : 14,
                "R15" : 15,
                "R16" : 16,
                "R17" : 17,
                "R18" : 18,
                "R19" : 19,
                "R20" : 20,
                "R21" : 21,
                "R22" : 22,
                "R23" : 23,
                "R24" : 24,
                "R25" : 25,
                "R26" : 26,
                "R27" : 27,
                "R28" : 28,
                "R29" : 29,
                "R30" : 30,
                "R31" : 31
                }
    reg_hex = hex(reg_dict.get(reg_input,0))
    return reg_hex;

asm = open("assembly.txt",'r')
array_of_codes = asm.readlines()
machine_code = ""
for i in range(0,len(array_of_codes)):
    code = array_of_codes[i].rstrip("\n")
    code_array = code.split(" ")
    opcode = code_array[0]
    reg_array = code_array[1].split(",")
    opcode_hex = opcode_to_hex(opcode);
    reg1 = reg_to_hex(reg_array[0])
    reg2 = reg_to_hex(reg_array[1])
    reg3 = reg_to_hex(reg_array[2])
    code_merged = str(opcode_hex[2:] + reg1[2:] + reg2[2:] + reg3[2:])
    machine_code += "0x"
    machine_code += code_merged
    machine_code += "\n"

machine = open("machine_code.txt",'w')
machine.write(machine_code)