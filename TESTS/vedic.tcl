read_lef -lef /home/ubuntu/ef-xfab-xh035/EFXH035A/libs.ref/techLEF/v6_0_1/xh035_xx2x_METAL4.lef -tech only 
read_lef -lef /home/ubuntu/ef-xfab-xh035/EFXH035A/libs.ref/lef/D_CELLS/xh035_D_CELLS_qrouter.lef

read_verilog -v /home/ubuntu/workarea/efsynthesis.vg
set TOP_MODULE vedic_16x16
elaborate

set_floorplan 

write_graywolf_cel_file
exit
