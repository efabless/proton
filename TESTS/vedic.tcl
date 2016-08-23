read_lef -lef /ef/tech/XFAB/EFXH035A/libs.ref/techLEF/v6_0_1/xh035_xx2x_METAL4.lef -tech only 
read_lef -lef /ef/tech/XFAB/EFXH035A/libs.ref/lef/D_CELLS/xh035_D_CELLS_qrouter.lef

read_verilog -v rtls/vedic/vedic.gv
set TOP_MODULE vedic_16x16
elaborate

set_floorplan_parameters -HEIGHT 1000 -WIDTH 1500
#set_floorplan_parameters -ASPECT_RATIO 1
set_floorplan 

#write_graywolf_cel_file
#read_graywolf_placement_result

place_graywolf

win

#write_lef -tech also -output all.lef
#write_def -output vedic.def --overwrite

qroute

#defIn -def vedic.def
