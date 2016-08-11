
sub read_demo_lef {
&read_lef ("-lef", "/home/ubuntu/ef-xfab-xh035/EFXH035A/libs.ref/techLEF/v6_0_1/xh035_xx2x_METAL4.lef", "-tech","only");
&read_lef ("-lef","/home/ubuntu/ef-xfab-xh035/EFXH035A/libs.ref/lef/D_CELLS/xh035_xx2x_METAL4_D_CELLS_mprobe.lef");
&call_read_lef;
}

1;
