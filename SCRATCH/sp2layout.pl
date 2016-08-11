#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;

my $noOfArg = @ARGV; 
my ($spFile_str,$drupal_temp_path,$outfile) = ("","","silverline");
my $output = "";
my $module;
my $chip_width;
my $chip_height;
my $trans_width;
my $trans_height;
my $tech_size;
my $layer_1;
my $layer_1_width;
my $layer_1_spacing;
my $layer_1_direction;
my $layer_2;
my $layer_2_width;
my $layer_2_spacing;
my $layer_2_direction;
my $layer_3;
my $layer_3_width;
my $layer_3_spacing;
my $layer_3_direction;
my $layer_4;
my $layer_4_width;
my $layer_4_spacing;
my $layer_4_direction;
my $layer_1_direction_new;
my $layer_2_direction_new;
my $layer_3_direction_new;
my $layer_4_direction_new;
if($ARGV[0] eq "-h" || $ARGV[0] eq "-help" || $ARGV[0] eq "-HELP"){
   print"Usage: sp2layout -spice_file <sp file name>\n";
}else{
  for(my $xx=0; $xx<$noOfArg; $xx++){
    if($ARGV[$xx] eq "-chip_width"){$chip_width = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-chip_height"){$chip_height = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-trans_width"){$trans_width = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-trans_height"){$trans_height = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-tech_size"){$tech_size = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_1"){$layer_1 = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_1_width"){$layer_1_width = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_1_spacing"){$layer_1_spacing = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_1_direction"){$layer_1_direction = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_2"){$layer_2 = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_2_width"){$layer_2_width = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_2_spacing"){$layer_2_spacing = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_2_direction"){$layer_2_direction = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_3"){$layer_3 = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_3_width"){$layer_3_width = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_3_spacing"){$layer_3_spacing = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_3_direction"){$layer_3_direction = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_4"){$layer_4 = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_4_width"){$layer_4_width = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_4_spacing"){$layer_4_spacing = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-layer_4_direction"){$layer_4_direction = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-spice_file"){$spFile_str = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-output"){
      $outfile = $ARGV[$xx+1];
      if($outfile =~ /\.layout/){
        $output = $outfile;
      }else {
        $output = "$outfile.layout";
      }
    }
    if($ARGV[$xx] eq "-drupal_temp_storage_path"){
      $drupal_temp_path = $ARGV[$xx+1];
    }
  }
if($layer_1_direction =~ /hori/){
  $layer_1_direction_new = "HORIZONTAL";
}elsif($layer_1_direction =~ /ver/){
  $layer_1_direction_new = "VERTICAL";
}
if($layer_2_direction =~ /hori/){
  $layer_2_direction_new = "HORIZONTAL";
}elsif($layer_2_direction =~ /ver/){
  $layer_2_direction_new = "VERTICAL";
}
if($layer_3_direction =~ /hori/){
  $layer_3_direction_new = "HORIZONTAL";
}elsif($layer_3_direction =~ /ver/){
  $layer_3_direction_new = "VERTICAL";
}
if($layer_4_direction =~ /hori/){
  $layer_4_direction_new = "HORIZONTAL";
}elsif($layer_4_direction =~ /ver/){
  $layer_4_direction_new = "VERTICAL";
}
open(WRITE,">script_0");
#print WRITE "set_layer_width_and_spacing_in_db -layer{M1,0.70,0.70,HORIZONTAL,M2,0.70,0.70,VERTICAL,M3,0.70,0.70,HORIZONTAL,M4,0.70,0.70,VERTICAL}\n";
print WRITE "set_layer_width_and_spacing_in_db -layer{$layer_1,$layer_1_width,$layer_1_spacing,$layer_1_direction_new,$layer_2,$layer_2_width,$layer_2_spacing,$layer_2_direction_new,$layer_3,$layer_3_width,$layer_3_spacing,$layer_3_direction_new,$layer_4,$layer_4_width,$layer_4_spacing,$layer_4_direction_new}\n";
print WRITE "create_lef_trans_from_given_data -trans pd -trans_width $trans_width -trans_height $trans_height -tech_size $tech_size -chip_width $chip_width -chip_height $chip_height\n"; 
print WRITE "create_lef_trans_from_given_data -trans nd -trans_width $trans_width -trans_height $trans_height -tech_size $tech_size -chip_width $chip_width -chip_height $chip_height\n";
print WRITE "read_spice_new -sp $spFile_str\n";
print WRITE "calc_bbox_of_pType_and_nType_inst -chip_width $chip_width -chip_height $chip_height -trans_width $trans_width -trans_height $trans_height -tech_size $tech_size\n";
print WRITE "set_layout_loc_in_flplan -chip_width $chip_width -chip_height $chip_height -trans_width $trans_width -trans_height $trans_height -tech_size $tech_size\n";
print WRITE "elaborate\n";
print WRITE "hier2flat\n";
print WRITE "write_flat_router_graph_for_spice\n";
print WRITE "exit\n";
close(WRITE);
#system ("/apps/content/drupal_app/proton -f script_0 --nolog");
system ("/home/mansis/Projects/proton/proton -f script_0 --nolog");
if( -e "router_new.txt"){ 
  system("cp /home/mansis/Projects/proton/3RDBIN/._po* .");
  system("/home/mansis/Projects/proton/3RDBIN/eeRouter");
  system("rm -rf ._po*");
}
open(WRITE,">script_1");
#print WRITE "set_layer_width_and_spacing_in_db -layer{M1,0.70,0.70,HORIZONTAL,M2,0.70,0.70,VERTICAL,M3,0.70,0.70,HORIZONTAL,M4,0.70,0.70,VERTICAL}\n";
print WRITE "set_layer_width_and_spacing_in_db -layer{$layer_1,$layer_1_width,$layer_1_spacing,$layer_1_direction_new,$layer_2,$layer_2_width,$layer_2_spacing,$layer_2_direction_new,$layer_3,$layer_3_width,$layer_3_spacing,$layer_3_direction_new,$layer_4,$layer_4_width,$layer_4_spacing,$layer_4_direction_new}\n";
print WRITE "create_lef_trans_from_given_data -trans pd -trans_width $trans_width -trans_height $trans_height -tech_size $tech_size -chip_width $chip_width -chip_height $chip_height\n"; 
print WRITE "create_lef_trans_from_given_data -trans nd -trans_width $trans_width -trans_height $trans_height -tech_size $tech_size -chip_width $chip_width -chip_height $chip_height\n";
print WRITE "read_spice_new -sp $spFile_str\n";
print WRITE "calc_bbox_of_pType_and_nType_inst -chip_width $chip_width -chip_height $chip_height -trans_width $trans_width -trans_height $trans_height -tech_size $tech_size\n";
print WRITE "set_layout_loc_in_flplan -chip_width $chip_width -chip_height $chip_height -trans_width $trans_width -trans_height $trans_height -tech_size $tech_size\n";
print WRITE "elaborate\n";
print WRITE "hier2flat\n";
print WRITE "read_flat_router -file router_new.txt.output\n";
print WRITE "write_edp_layout -output silverline.layout -chip_width $chip_width -chip_height $chip_height -trans_width $trans_width -trans_height $trans_height -tech_size $tech_size\n"; 
print WRITE "exit\n";
close (WRITE);
system ("/home/mansis/Projects/proton/proton -f script_1 --nolog");
#system ("/apps/content/drupal_app/proton -f script_0 --nolog");
#system("scp -i /apps/scp_key -o StrictHostKeyChecking=no silverline.layout root\@192.168.20.20:/var/www/html/drupal/$drupal_temp_path/");
#system("ssh -i /apps/scp_key -o StrictHostKeyChecking=no root\@192.168.20.20 'chown apache:apache /var/www/html/drupal/$drupal_temp_path/*'");
}
my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "script sp2layout took:",timestr($td),"\n";
