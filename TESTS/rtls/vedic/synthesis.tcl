read_verilog vedicMultiplier/adder12.v
read_verilog vedicMultiplier/adder16.v
read_verilog vedicMultiplier/adder24.v
read_verilog vedicMultiplier/adder4.v
read_verilog vedicMultiplier/adder6.v
read_verilog vedicMultiplier/adder8.v
read_verilog vedicMultiplier/halfAdder.v
read_verilog vedicMultiplier/vedic_16x16.v
read_verilog vedicMultiplier/vedic_2x2.v
read_verilog vedicMultiplier/vedic_4x4.v
read_verilog vedicMultiplier/vedic_8x8.v


hierarchy -check -top vedic_16x16

proc; opt; fsm; opt; memory; opt

# mapping to internal cell library
techmap; opt

# mapping flip-flops to mycells.lib
dfflibmap -liberty /ef/tech/ef-xfab-xh035/EFXH035A/libs.ref/liberty-yosys-abc/D_CELLS/PVT_3_30V_range/D_CELLS_MOS_fast_3_60V_25C_abc.lib


# mapping logic to mycells.lib
abc -liberty /ef/tech/ef-xfab-xh035/EFXH035A/libs.ref/liberty-yosys-abc/D_CELLS/PVT_3_30V_range/D_CELLS_MOS_fast_3_60V_25C_abc.lib


# cleanup
clean

# write synthesized design
write_verilog vedic.v
