read_lef -lef /home/ubuntu/proton/TESTS/library/NangateOpenCellLibrary_PDKv1_2_v2008_10.lef  -tech also

read_verilog -v /home/ubuntu/proton/TESTS/rtls/vedic/vedic.gv
set TOP_MODULE vedic_16x16
elaborate

set_floorplan 

write_graywolf_cel_file
exit
