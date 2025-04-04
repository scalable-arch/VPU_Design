# VPU_Design
## Instruction
[Instruction_set](./docs/instruction_set.md)
| Operation      | Assembly                    | Opcode[7:0] | Encoding                                                            | Status          | Description                                                | Cycle(200MHz) |
|----------------|-----------------------------|-------------|---------------------------------------------------------------------|-----------------|------------------------------------------------------------|------|
| ADD 2 operands | VADD2 DST, SRC1, SRC2       | 0000_0001   | {Opcode[7:0], DST[23:0], SRC1[23:0], SRC2[23:0], 48'd0}             | RTL (Xilinx)    | Vector Addition                                            |  4   |
| SUB            | VSUB DST, SRC1, SRC2        | 0000_0010   | {Opcode[7:0], DST[23:0], SRC1[23:0], SRC2[23:0], 48'd0}             | RTL (Xilinx)    | Vector Subtraction                                         |  4   |
| MUL            | VMUL DST, SRC1, SRC2        | 0000_0011   | {Opcode[7:0], DST[23:0], SRC1[23:0], SRC2[23:0], 48'd0}             | RTL (Xilinx)    | Vector Multiplication                                      |  4   |
| DIV            | VDIV DST, SRC1, SRC2        | 0000_0100   | {Opcode[7:0], DST[23:0], SRC1[23:0], SRC2[23:0], 48'd0}             | RTL (Xilinx)    | Vector division                                            |  7   |
| MAX 2 operands | VMAX2 DST, SRC1, SRC2       | 0000_1000   | {Opcode[7:0], DST[23:0], SRC1[23:0], SRC2[23:0], 48'd0}             | RTL (Xilinx)    | Compare two vectors and get only the larger elements       |  2   |
| AVG 2 operands | VAVG2 DST, SRC1, SRC2       | 0000_1010   | {Opcode[7:0], DST[23:0], SRC1[23:0], SRC2[23:0], 48'd0}             | RTL (Xilinx)    | Get theaverage of two vector's each elements               |  10  |
| SUM            | VREDSUMN DST, SRC1          | 0000_0110   | {Opcode[7:0], DST[23:0], SRC1[23:0], 72'd0}                         | RTL (Xilinx)    | Get sum of all elements of a vector                        |  16  |
| Reduction Max  | VREDMAX, DST, SRC1          | 0000_0111   | {Opcode[7:0], DST[23:0], SRC1[23:0], 72'd0}                         | RTL (Xilinx)    | Get max value in a vector                                  |  6   |
| EXP            | VEXP DST, SRC1              | 0000_1100   | {Opcode[7:0], DST[23:0], SRC1[23:0], 72'd0}                         | RTL (Xilinx)    | Get the exponential of each element in the vector          |  9   |
| SQRT           | VSQRT DST, SRC1             | 0000_1101   | {Opcode[7:0], DST[23:0], SRC1[23:0], 72'd0}                         | RTL (Xilinx)    | Get the sqrt of each element in the vector                 |  6   |
| Reciprocal SQRT| VSQRT DST, SRC1             | 0000_1110   | {Opcode[7:0], DST[23:0], SRC1[23:0], 72'd0}                         | RTL (Xilinx)    | Get the reciporcal sqrt of each element in the vector      |  12  |
| ADD 3 operands | VADD3 DST, SRC1, SRC2, SRC3 | 0000_0101   | {Opcode[7:0], DST[23:0], SRC1[23:0], SRC2[23:0], SRC3[23:0], 25'd0} | RTL (Xilinx)    | Vector Addition with three operand                         |  7   |
| MAX 3 operands | VMAX3 DST, SRC1, SRC3, SRC3 | 0000_1001   | {Opcode[7:0], DST[23:0], SRC1[23:0], SRC2[23:0], SRC3[23:0], 25'd0} | RTL (Xilinx)    | Compare three vectors and get only the larger elements     |  3   |
| AVG 3 operands | VAVG3 DST, SRC1, SRC3, SRC3 | 0000_1011   | {Opcode[7:0], DST[23:0], SRC1[23:0], SRC2[23:0], SRC3[23:0], 25'd0} | RTL (Xilinx)    | Get average of three vector's each elements                |  13  |
## RTL
### - Block Diagram
#### ![image](https://github.com/user-attachments/assets/6af3d0f9-e7ff-43a0-82e6-243b63773d01)

### - Interface
####  ![image](https://github.com/user-attachments/assets/13f7aba4-5bb2-4d49-b69b-9514884a22c6)
####  ![image](https://github.com/user-attachments/assets/1b1679f0-f7db-4e5f-98ca-d65d60d35b16)

## SIM
### UVM TestBench
### ![image](https://github.com/user-attachments/assets/5dfa5dc7-0b0e-472b-b2db-fb33275692fc)
