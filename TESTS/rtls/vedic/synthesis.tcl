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
dfflibmap -liberty /home/ubuntu/proton/TESTS/library/NangateOpenCellLibrary_PDKv1_2_v2008_10_slow_conditional_ecsm.lib


# mapping logic to mycells.lib
abc -liberty /home/ubuntu/proton/TESTS/library/NangateOpenCellLibrary_PDKv1_2_v2008_10_slow_conditional_ecsm.lib


# cleanup
clean

# write synthesized design
write_verilog vedic.vg
