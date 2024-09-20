
| Operation | Assembly                 | Opcode[7:0] | Encoding                                                  | Status          | Description     |
|-----------|--------------------------|-------------|-----------------------------------------------------------|-----------------|-----------------|
| ADD       | VADD DST, SRC1, SRC2     | 0000_0001   | {0000_0001, DST[23:0], SRC1[23:0], SRC2[23:0], 48'd0}     | RTL (Xilinx)    | Vector Addition |