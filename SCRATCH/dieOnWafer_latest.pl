#!/usr/bin/perl

my $die_width = 0;
my $die_height = 0;
my $horizontal_spacing = 0;
my $vertical_spacing = 0;
my $wafer_diameter = 0;
my $edge_clearance = 0;
my $flat_or_notch_clearance = 0;
my $out_coord_file = "out_coord_file";
my $wafer_map = "no_map";
my $drupal_temp_path = "";
for(my $i = 0; $i <=$#ARGV; $i++){
  if($ARGV[$i] eq "-die_width"){
    $die_width = $ARGV[$i+1];
  }elsif($ARGV[$i] eq "-die_height"){
    $die_height = $ARGV[$i+1];
  }elsif($ARGV[$i] eq "-horizontal_spacing"){
    $horizontal_spacing = $ARGV[$i+1];
  }elsif($ARGV[$i] eq "-vertical_spacing"){
    $vertical_spacing = $ARGV[$i+1];
  }elsif($ARGV[$i] eq "-wafer_diameter"){
    $wafer_diameter = $ARGV[$i+1];
  }elsif($ARGV[$i] eq "-edge_clearance"){
    $edge_clearance = $ARGV[$i+1];
  }elsif($ARGV[$i] eq "-flat_or_notch_clearance"){
    $flat_or_notch_clearance = $ARGV[$i+1];
  }elsif($ARGV[$i] eq "-wafer_map"){
    $wafer_map = $ARGV[$i+1];
  }elsif($ARGV[$i] eq "-out_coord_file"){
    $out_coord_file = $ARGV[$i+1];
  }elsif($ARGV[$i] eq "-drupal_temp_storage_path"){
    $drupal_temp_path = $ARGV[$i+1];
  }
}
if(($wafer_map ne "side_biased") &&($wafer_map ne "top_biased") &&($wafer_map ne "die_centered") &&($wafer_map ne "point_centered")){
  print("wafer_map can be one of these\n");
  print("\"side_biased\" \"top_biased\" \"die_centered\" \"point_centered\"\n");
}
print("Argument read\n");
#lets assume that circle centre is origin, so that
#x*x + y*y = (wafer_diameter/2)*(wafer_diameter/2)

#now starting from (-wafer_diameter/2,0) to (wafer_diameter/2,0)
#we need to find how many vertical rows can be on the circle
my $initial_x = -$wafer_diameter/2;
my $number_of_vertical_rows = -1;
for(my $curr_x=$initial_x;$curr_x<=$wafer_diameter/2;$curr_x+=$die_width+$horizontal_spacing){
  $number_of_vertical_rows++;
}
print("number of vertical rows = $number_of_vertical_rows\n");
my $total_vertical_spacing_on_both_side = $wafer_diameter - ($number_of_vertical_rows*$die_width + ($number_of_vertical_rows -1)*$horizontal_spacing);
my $average_vertical_spacing_on_both_side = $total_vertical_spacing_on_both_side/2;
if($wafer_map eq "die_centred"){
  #this means  circle centre lies on the centre of a die 
  my $nmbr_of_fll_rws_lft_cntr = int(($wafer_diameter/2 - $die_width/2)/($die_width + $horizontal_spacing));
  $initial_x = 0 - $die_width/2 -$nmbr_of_fll_rws_lft_cntr*($die_width + $horizontal_spacing);
}elsif($wafer_map eq "point_centered"){
  #this means  circle centre lies on one side of a die 
  my $nmbr_of_fll_rws_lft_cntr = int(($wafer_diameter/2 + $horizontal_spacing/2)/($die_width + $horizontal_spacing));
  $initial_x = 0 + $horizontal_spacing/2 -$nmbr_of_fll_rws_lft_cntr*($die_width + $horizontal_spacing);
}else{
  $initial_x = -$wafer_diameter/2 + $average_vertical_spacing_on_both_side;
}
my @vertical_row = ();
my %vertical_row_hash = ();
my $min_row_dst_cntr_left = "";
my $min_row_dst_cntr_right = "";
my $vertical_row_on_centre = "";
my $row_just_right_centre = "";
my $row_just_left_centre = "";
my $curr_row_number = 0 ;
#Need to find 1 vertical_row which lies on the circle centre,if any such vertical_row is there
#need to find two rows such that circle center lies in between them
for(my $curr_x=$initial_x;$curr_row_number<$number_of_vertical_rows;$curr_x+=$die_width+$horizontal_spacing){
  my $row_x1 = $curr_x;
  my $row_y1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($row_x1)*($row_x1)));
  my $row_x2 = $row_x1 + $die_width;
  my $row_y2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($row_x2)*($row_x2)));
  my $row_x3 = $row_x1;
  my $row_y3 = -$row_y1;
  my $row_x4 = $row_x2;
  my $row_y4 = -$row_y2;
  $vertical_row_hash{$curr_row_number} = $row_x1;
  $vertical_row[$curr_row_number] = [$row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4];
  print("vertical_row coords are ($row_x1,$row_y1) ($row_x2,$row_y2) ($row_x3,$row_y3) ($row_x4,$row_y4)\n");
  if(($row_x1 < 0) && ($row_x2 > 0)){
    $vertical_row_on_centre = $curr_row_number;
  }
  if(($row_x1 < 0) && ($row_x2 <= 0)){
    if($min_row_dst_cntr_left eq ""){
      $min_row_dst_cntr_left = abs($row_x2);
      $row_just_left_centre = $curr_row_number;
    }elsif(abs($row_x2) < $min_row_dst_cntr_left){
      $min_row_dst_cntr_left = abs($row_x2);
      $row_just_left_centre = $curr_row_number;
    }
  }elsif(($row_x1 >= 0) && ($row_x2 > 0)){
    if($min_row_dst_cntr_right eq ""){
      $min_row_dst_cntr_right = $row_x1;
      $row_just_right_centre = $curr_row_number;
    }elsif($row_x1 < $min_row_dst_cntr_right){
      $min_row_dst_cntr_right = $row_x1;
      $row_just_right_centre = $curr_row_number;
    }
  }
  $curr_row_number++;
}

#now starting from (0,-wafer_diameter/2) to (0,wafer_diameter/2)
#we need to find how many rows can be on the circle
my $initial_y = -$wafer_diameter/2 + $flat_or_notch_clearance;
my $number_of_horizontal_rows = -1;
for(my $curr_y=$initial_y;$curr_y<=$wafer_diameter/2;$curr_y+=$die_height+$vertical_spacing){
  $number_of_horizontal_rows++;
}
print("number of horizontal rows = $number_of_horizontal_rows\n");
my $total_horizontal_spacing_on_both_side = $wafer_diameter - ($number_of_horizontal_rows*$die_height + ($number_of_horizontal_rows -1)*$vertical_spacing);
my $average_horizontal_spacing_on_both_side = $total_horizontal_spacing_on_both_side/2;
if($wafer_map eq "die_centred"){
  #this means  circle centre lies on the centre of a die 
  my $nmbr_of_fll_rws_blw_cntr = int(($wafer_diameter/2 - $die_height/2 - $flat_or_notch_clearance)/($die_height + $vertical_spacing));
  $initial_y = 0 - $die_width/2 -$nmbr_of_fll_rws_blw_cntr*($die_height + $vertical_spacing);
}elsif($wafer_map eq "point_centered"){
  #this means  circle centre lies on one side of a die 
  my $nmbr_of_fll_rws_blw_cntr = int(($wafer_diameter/2 + $vertical_spacing/2 - $flat_or_notch_clearance)/($die_height + $vertical_spacing));
  $initial_y = 0 + $vertical_spacing/2 -$nmbr_of_fll_rws_blw_cntr*($die_height + $vertical_spacing);
}else{
  if($flat_or_notch_clearance < $average_horizontal_spacing_on_both_side){
    $initial_y = -$wafer_diameter/2 + $average_horizontal_spacing_on_both_side;
  }
}
my @horizontal_row = ();
my %horizontal_row_hash = ();
my $min_row_dst_cntr_below = "";
my $min_row_dst_cntr_above = "";
my $horizontal_row_on_centre = "";
my $row_just_above_centre = "";
my $row_just_below_centre = "";
$curr_row_number = 0 ;
#Need to find 1 horizontal_row which lies on the circle centre,if any such horizontal_row is there
#need to find two horizontal rows such that circle center lies in between them
for(my $curr_y=$initial_y;$curr_row_number<$number_of_horizontal_rows;$curr_y+=$die_height+$vertical_spacing){
  my $row_y1 = $curr_y;
  my $row_x1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($row_y1)*($row_y1)));
  my $row_y2 = $row_y1 + $die_height;
  my $row_x2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($row_y2)*($row_y2)));
  my $row_y3 = $row_y1;
  my $row_x3 = -$row_x1;
  my $row_y4 = $row_y2;
  my $row_x4 = -$row_x2;
  $horizontal_row_hash{$curr_row_number} = $row_y1;
  $horizontal_row[$curr_row_number] = [$row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4];
  print("horizontal_row coords are ($row_x1,$row_y1) ($row_x2,$row_y2) ($row_x3,$row_y3) ($row_x4,$row_y4)\n");
  if(($row_y1 < 0) && ($row_y2 > 0)){
    $horizontal_row_on_centre = $curr_row_number;
  }
  if(($row_y1 < 0) && ($row_y2 <= 0)){
    if($min_row_dst_cntr_below eq ""){
      $min_row_dst_cntr_below = abs($row_y2);
      $row_just_below_centre = $curr_row_number;
    }elsif(abs($row_y2) < $min_row_dst_cntr_below){
      $min_row_dst_cntr_below = abs($row_y2);
      $row_just_below_centre = $curr_row_number;
    }
  }elsif(($row_y1 >= 0) && ($row_y2 > 0)){
    if($min_row_dst_cntr_above eq ""){
      $min_row_dst_cntr_above = $row_y1;
      $row_just_above_centre = $curr_row_number;
    }elsif($row_y1 < $min_row_dst_cntr_above){
      $min_row_dst_cntr_above = $row_y1;
      $row_just_above_centre = $curr_row_number;
    }
  }
  $curr_row_number++;
}
my $total_number_of_rect = 0;
for(my $i = 0;$i<$number_of_horizontal_rows;$i++){
  my @row_coords = @{$horizontal_row[$i]};
  ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
  my $no_of_rect_in_curr_row += &no_of_rect_in_horizontal_row($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4);
  print("Number of rectangle in horizontal row $i is $no_of_rect_in_curr_row\n");
  $total_number_of_rect += $no_of_rect_in_curr_row;
}
print("total number of rect = $total_number_of_rect\n");
print("rows populated\n");
if(($wafer_map ne "die_centred")&&($wafer_map ne "point_centered")){
  #space left on any horizontal_row will be less than width of rectangle
  my $max_pssbl_mvmnt_rws_blw_cntr = "";
  my $row_nearest_or_just_below_centre;
  if($horizontal_row_on_centre eq ""){
    $row_nearest_or_just_below_centre = $row_just_below_centre;
  }else{
    $row_nearest_or_just_below_centre = $horizontal_row_on_centre;
  }
  for(my $i = 0;$i<=$row_nearest_or_just_below_centre;$i++){
    my @row_coords = @{$horizontal_row[$i]};
    ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
    my $no_of_rect_in_curr_row = &no_of_rect_in_horizontal_row($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4);
    my $curr_row_width ;
    if(($row_x3 -$row_x1)<($row_x4 -$row_x2)){
      $curr_row_width  = $row_x3 - $row_x1;
    }else{
      $curr_row_width  = $row_x4 - $row_x2;
    }
    my $remaining_width = $curr_row_width -$no_of_rect_in_curr_row*$die_width -($no_of_rect_in_curr_row-1)*$horizontal_spacing; 
    print("remaining_width is $remaining_width curr_row_width is $curr_row_width\n");
    my $new_row_x1 = $row_x1 + $remaining_width/2;
    my $new_row_y1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_x1)*($new_row_x1)));
    if($no_of_rect_in_curr_row ==0){
    if($max_pssbl_mvmnt_rws_blw_cntr eq ""){
        $max_pssbl_mvmnt_rws_blw_cntr = $die_height + $vertical_spacing;
    }else{
         if(($die_height + $vertical_spacing) < $max_pssbl_mvmnt_rws_blw_cntr){
           $max_pssbl_mvmnt_rws_blw_cntr = $die_height + $vertical_spacing;
         }
    }
    }else{
    print("new_row_y1 is $new_row_y1 row_y1 is $row_y1\n");
    if($max_pssbl_mvmnt_rws_blw_cntr eq ""){
      if($new_row_y1 >= $initial_y){
        $max_pssbl_mvmnt_rws_blw_cntr = $row_y1 - $new_row_y1;
      }elsif($row_y1 > $initial_y){
        $new_row_y1 = $initial_y;
        $max_pssbl_mvmnt_rws_blw_cntr = $row_y1 - $new_row_y1;
      }else{
        $new_row_y1 = $row_y1;
        $max_pssbl_mvmnt_rws_blw_cntr = 0;
      }
    }elsif(($row_y1 - $new_row_y1 )< $max_pssbl_mvmnt_rws_blw_cntr){
      $max_pssbl_mvmnt_rws_blw_cntr = $row_y1 - $new_row_y1;
    }
    }
    print("row $i can move $max_pssbl_mvmnt_rws_blw_cntr\n");
    if($max_pssbl_mvmnt_rws_blw_cntr ==0){
      last;
    }
  }
  print("max_pssbl_mvmnt_rws_blw_cntr is $max_pssbl_mvmnt_rws_blw_cntr\n");
  my $max_pssbl_mvmnt_rws_abv_cntr = "";
  my $row_nearest_or_just_above_centre;
  if($horizontal_row_on_centre eq ""){
    $row_nearest_or_just_above_centre = $row_just_above_centre;
  }else{
    $row_nearest_or_just_above_centre = $horizontal_row_on_centre;
  }
  for(my $i = $number_of_horizontal_rows-1;$i>=$row_nearest_or_just_above_centre;$i--){
    my @row_coords = @{$horizontal_row[$i]};
    ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
    my $no_of_rect_in_curr_row = &no_of_rect_in_horizontal_row($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4);
    my $curr_row_width ;
    if(($row_x3 -$row_x1)<($row_x4 -$row_x2)){
      $curr_row_width  = $row_x3 - $row_x1;
    }else{
      $curr_row_width  = $row_x4 - $row_x2;
    }
    my $remaining_width = $curr_row_width -$no_of_rect_in_curr_row*$die_width -($no_of_rect_in_curr_row-1)*$horizontal_spacing; 
    if($no_of_rect_in_curr_row ==0){
      $remaining_width = $curr_row_width;
    }
    my $new_row_x2 = $row_x2 + $remaining_width/2;
    my $new_row_y2 = sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_x2)*($new_row_x2));
    if($max_pssbl_mvmnt_rws_abv_cntr eq ""){
      if($new_row_y2 <= $wafer_diameter/2){
        $max_pssbl_mvmnt_rws_abv_cntr = $new_row_y2 - $row_y2;
      }elsif($row_y2 < $wafer_diameter/2){
        $new_row_y2 = $wafer_diameter/2;
        $max_pssbl_mvmnt_rws_abv_cntr = $new_row_y2 - $row_y2;
      }else{
        $new_row_y2 = $row_y2;
        $max_pssbl_mvmnt_rws_abv_cntr = 0;
      }
    }elsif(($new_row_y2 - $row_y2)< $max_pssbl_mvmnt_rws_abv_cntr){
        $max_pssbl_mvmnt_rws_abv_cntr = $new_row_y2 - $row_y2;
    }
    print("row $i can move $max_pssbl_mvmnt_rws_abv_cntr\n");
    if($max_pssbl_mvmnt_rws_abv_cntr ==0){
      last;
    }
  }
  print("max_pssbl_mvmnt_rws_abv_cntr is $max_pssbl_mvmnt_rws_abv_cntr\n");
  #Now we need to check if by moving all the rows which are on or below centre,
  #upwards can increase number of rectangle in any of the rows.
  my $no_of_rect_increased_upward_movement = 0;
  for(my $i = 0;$i<=$row_just_below_centre;$i++){
    my @row_coords = @{$horizontal_row[$i]};
    ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
    my $no_of_rect_in_curr_row = &no_of_rect_in_horizontal_row($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4);
    my $new_row_y1 = $row_y1 + $max_pssbl_mvmnt_rws_abv_cntr;
    my $new_row_x1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y1)*($new_row_y1)));
    my $new_row_y2 = $row_y2 + $max_pssbl_mvmnt_rws_abv_cntr;
    my $new_row_x2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y2)*($new_row_y2)));
    my $new_row_x3 = -$new_row_x1;
    my $new_row_x4 = -$new_row_x2;
    my $new_row_y3 = $new_row_y1;
    my $new_row_y4 = $new_row_y2;
    my $new_no_of_rect_in_curr_row = &no_of_rect_in_horizontal_row($new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4);
    if($new_no_of_rect_in_curr_row > $no_of_rect_in_curr_row){
      $no_of_rect_increased_upward_movement++;
    }
  }
  my $no_of_rect_increased_downward_movement = 0;
  for(my $i = $number_of_horizontal_rows-1;$i>=$row_just_above_centre;$i--){
    my @row_coords = @{$horizontal_row[$i]};
    ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
    my $no_of_rect_in_curr_row = &no_of_rect_in_horizontal_row($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4);
    my $new_row_y1 = $row_y1 - $max_pssbl_mvmnt_rws_blw_cntr;
    my $new_row_x1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y1)*($new_row_y1)));
    my $new_row_y2 = $row_y2 - $max_pssbl_mvmnt_rws_blw_cntr;
    my $new_row_x2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y2)*($new_row_y2)));
    my $new_row_x3 = -$new_row_x1;
    my $new_row_x4 = -$new_row_x2;
    my $new_row_y3 = $new_row_y1;
    my $new_row_y4 = $new_row_y2;
    my $new_no_of_rect_in_curr_row = &no_of_rect_in_horizontal_row($new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4);
    if($new_no_of_rect_in_curr_row > $no_of_rect_in_curr_row){
      $no_of_rect_increased_downward_movement++;
    }
  }
  if($no_of_rect_increased_downward_movement > $no_of_rect_increased_upward_movement){
    for(my $i = 0;$i<$number_of_horizontal_rows;$i++){
      my @row_coords = @{$horizontal_row[$i]};
      ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
      my $new_row_y1 = $row_y1 - $max_pssbl_mvmnt_rws_blw_cntr;
      if($new_row_y1 >= -$wafer_diameter/2){
        my $new_row_x1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y1)*($new_row_y1)));
        my $new_row_y2 = $row_y2 - $max_pssbl_mvmnt_rws_blw_cntr;
        my $new_row_x2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y2)*($new_row_y2)));
        my $new_row_x3 = -$new_row_x1;
        my $new_row_x4 = -$new_row_x2;
        my $new_row_y3 = $new_row_y1;
        my $new_row_y4 = $new_row_y2;
        $horizontal_row[$i] = [$new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4];
      }else{
        my $new_row_x1 = $row_x1;
        my $new_row_y2 = $row_y2 - $max_pssbl_mvmnt_rws_blw_cntr;
        my $new_row_x2 = $row_x2;
        my $new_row_x3 = -$new_row_x1;
        my $new_row_x4 = -$new_row_x2;
        my $new_row_y3 = $new_row_y1;
        my $new_row_y4 = $new_row_y2;
        $horizontal_row[$i] = [$new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4];
      }
    }
  }elsif($no_of_rect_increased_upward_movement > $no_of_rect_increased_downward_movement){
    for(my $i = 0;$i<$number_of_horizontal_rows;$i++){
      my @row_coords = @{$horizontal_row[$i]};
      ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
      my $new_row_y1 = $row_y1 + $max_pssbl_mvmnt_rws_abv_cntr;
      if($new_row_y1 <= $wafer_diameter/2){
        my $new_row_x1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y1)*($new_row_y1)));
        my $new_row_y2 = $row_y2 + $max_pssbl_mvmnt_rws_abv_cntr;
        my $new_row_x2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y2)*($new_row_y2)));
        my $new_row_x3 = -$new_row_x1;
        my $new_row_x4 = -$new_row_x2;
        my $new_row_y3 = $new_row_y1;
        my $new_row_y4 = $new_row_y2;
        $horizontal_row[$i] = [$new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4];
      }else{
        my $new_row_x1 = $row_x1;
        my $new_row_y2 = $row_y2 + $max_pssbl_mvmnt_rws_abv_cntr;
        my $new_row_x2 = $row_x2;
        my $new_row_x3 = -$new_row_x1;
        my $new_row_x4 = -$new_row_x2;
        my $new_row_y3 = $new_row_y1;
        my $new_row_y4 = $new_row_y2;
        $horizontal_row[$i] = [$new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4];
      }
    }
  }
  #space left on any horizontal_row will be less than width of rectangle
  my $max_pssbl_mvmnt_rws_lft_cntr = "";
  my $row_nearest_or_just_left_centre;
  if($horizontal_row_on_centre eq ""){
    $row_nearest_or_just_left_centre = $row_just_left_centre;
  }else{
    $row_nearest_or_just_left_centre = $vertical_row_on_centre;
  }
  for(my $i = 0;$i<=$row_nearest_or_just_left_centre;$i++){
    my @row_coords = @{$vertical_row[$i]};
    ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
    my $no_of_rect_in_curr_row = &no_of_rect_in_vertical_row($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4);
    print("Number of rectangle in vertical row $i is $no_of_rect_in_curr_row\n");
    my $curr_row_height ;
    if(($row_y3 -$row_y1)<($row_y4 -$row_y2)){
      $curr_row_height  = $row_y3 - $row_y1;
    }else{
      $curr_row_height  = $row_y4 - $row_y2;
    }
    my $remaining_height = $curr_row_height -$no_of_rect_in_curr_row*$die_height -($no_of_rect_in_curr_row-1)*$vertical_spacing; 
    my $new_row_y1 = $row_y1 + $remaining_height/2;
    my $new_row_x1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y1)*($new_row_y1)));
    if($max_pssbl_mvmnt_rws_lft_cntr eq ""){
      if($new_row_x1 >= $initial_x){
        $max_pssbl_mvmnt_rws_lft_cntr = $row_x1 - $new_row_x1;
      }elsif($row_x1 > $initial_x){
        $new_row_x1 = $initial_x;
        $max_pssbl_mvmnt_rws_lft_cntr = $row_x1 - $new_row_x1;
      }else{
        $new_row_x1 = $row_x1;
        $max_pssbl_mvmnt_rws_lft_cntr = 0;
      }
    }elsif(($row_x1 - $new_row_x1 )< $max_pssbl_mvmnt_rws_lft_cntr){
      $max_pssbl_mvmnt_rws_lft_cntr = $row_x1 - $new_row_x1;
    }
    if($max_pssbl_mvmnt_rws_lft_cntr ==0){
      last;
    }
  }
  print("max_pssbl_mvmnt_rws_lft_cntr is $max_pssbl_mvmnt_rws_lft_cntr\n");
  my $max_pssbl_mvmnt_rws_rght_cntr = "";
  my $row_nearest_or_just_right_centre;
  if($vertical_row_on_centre eq ""){
    $row_nearest_or_just_right_centre = $row_just_right_centre;
  }else{
    $row_nearest_or_just_right_centre = $vertical_row_on_centre;
  }
  for(my $i = $number_of_vertical_rows-1;$i>=$row_nearest_or_just_right_centre;$i--){
    my @row_coords = @{$vertical_row[$i]};
    ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
    my $no_of_rect_in_curr_row = &no_of_rect_in_vertical_row($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4);
    print("Number of rectangle in vertical row $i is $no_of_rect_in_curr_row\n");
    my $curr_row_height ;
    if(($row_y3 -$row_y1)<($row_y4 -$row_y2)){
      $curr_row_height  = $row_y3 - $row_y1;
    }else{
      $curr_row_height  = $row_y4 - $row_y2;
    }
    my $remaining_height = $curr_row_height -$no_of_rect_in_curr_row*$die_height -($no_of_rect_in_curr_row-1)*$vertical_spacing; 
    my $new_row_y2 = $row_y2 + $remaining_height/2;
    my $new_row_x2 = sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y2)*($new_row_y2));
    if($max_pssbl_mvmnt_rws_rght_cntr eq ""){
      if($new_row_x2 <= $wafer_diameter/2){
        $max_pssbl_mvmnt_rws_rght_cntr = $new_row_x2 - $row_x2;
      }elsif($row_x2 < $wafer_diameter/2){
        $new_row_x2 = $wafer_diameter/2;
        $max_pssbl_mvmnt_rws_rght_cntr = $new_row_x2 - $row_x2;
      }else{
        $new_row_x2 = $row_x2;
        $max_pssbl_mvmnt_rws_rght_cntr = 0;
      }
    }elsif(($new_row_x2 - $row_x2)< $max_pssbl_mvmnt_rws_rght_cntr){
        $max_pssbl_mvmnt_rws_rght_cntr = $new_row_x2 - $row_x2;
    }
    if($max_pssbl_mvmnt_rws_rght_cntr ==0){
      last;
    }
  }
  print("max_pssbl_mvmnt_rws_rght_cntr is $max_pssbl_mvmnt_rws_rght_cntr\n");
  #Now we need to check if by moving all the rows which are on or left centre,
  #rightwards can increase number of rectangle in any of the rows.
  my $no_of_rect_increased_rightward_movement = 0;
  for(my $i = 0;$i<=$row_just_left_centre;$i++){
    my @row_coords = @{$vertical_row[$i]};
    ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
    my $no_of_rect_in_curr_row = &no_of_rect_in_vertical_row($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4);
    my $new_row_x1 = $row_x1 + $max_pssbl_mvmnt_rws_rght_cntr;
    my $new_row_y1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_x1)*($new_row_x1)));
    my $new_row_x2 = $row_x2 + $max_pssbl_mvmnt_rws_rght_cntr;
    my $new_row_y2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_x2)*($new_row_x2)));
    my $new_row_x3 = $new_row_x1;
    my $new_row_y3 = -$new_row_y1;
    my $new_row_x4 = $new_row_x2;
    my $new_row_y4 = -$new_row_y2;
    my $new_no_of_rect_in_curr_row = &no_of_rect_in_vertical_row($new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4);
    if($new_no_of_rect_in_curr_row > $no_of_rect_in_curr_row){
      $no_of_rect_increased_rightward_movement++;
    }
  }
  my $no_of_rect_increased_leftward_movement = 0;
  for(my $i = $number_of_vertical_rows-1;$i>=$row_just_right_centre;$i--){
    my @row_coords = @{$vertical_row[$i]};
    ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
    my $no_of_rect_in_curr_row = &no_of_rect_in_vertical_row($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4);
    my $new_row_x1 = $row_x1 - $max_pssbl_mvmnt_rws_lft_cntr;
    my $new_row_y1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_x1)*($new_row_x1)));
    my $new_row_x2 = $row_x2 - $max_pssbl_mvmnt_rws_lft_cntr;
    my $new_row_y2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_x2)*($new_row_x2)));
    my $new_row_x3 = $new_row_x1;
    my $new_row_y3 = -$new_row_y1;
    my $new_row_x4 = $new_row_x2;
    my $new_row_y4 = -$new_row_y2;
    my $new_no_of_rect_in_curr_row = &no_of_rect_in_vertical_row($new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4);
    if($new_no_of_rect_in_curr_row > $no_of_rect_in_curr_row){
      $no_of_rect_increased_leftward_movement++;
    }
  }
  if($no_of_rect_increased_leftward_movement > $no_of_rect_increased_rightward_movement){
    for(my $i = 0;$i<$number_of_vertical_rows;$i++){
      my @row_coords = @{$vertical_row[$i]};
      ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
      my $new_row_x1 = $row_x1 - $max_pssbl_mvmnt_rws_lft_cntr;
      if($new_row_x1 >= -$wafer_diameter/2){
        my $new_row_y1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_x1)*($new_row_x1)));
        my $new_row_x2 = $row_x2 - $max_pssbl_mvmnt_rws_lft_cntr;
        my $new_row_y2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_x2)*($new_row_x2)));
        my $new_row_x3 = $new_row_x1;
        my $new_row_y3 = -$new_row_y1;
        my $new_row_x4 = $new_row_x2;
        my $new_row_y4 = -$new_row_y2;
        $vertical_row[$i] = [$new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4];
      }else{
        my $new_row_y1 = $row_y1;
        my $new_row_x2 = $row_x2 - $max_pssbl_mvmnt_rws_lft_cntr;
        my $new_row_y2 = $row_y2;
        my $new_row_x3 = $new_row_x1;
        my $new_row_y3 = -$new_row_y1;
        my $new_row_x4 = $new_row_x2;
        my $new_row_y4 = -$new_row_y2;
        $vertical_row[$i] = [$new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4];
      }
    }
  }elsif($no_of_rect_increased_rightward_movement > $no_of_rect_increased_leftward_movement){
    for(my $i = 0;$i<$number_of_vertical_rows;$i++){
      my @row_coords = @{$vertical_row[$i]};
      ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
      my $new_row_x1 = $row_x1 + $max_pssbl_mvmnt_rws_rght_cntr;
      if($new_row_x1 <= $wafer_diameter/2){
        my $new_row_y1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_x1)*($new_row_x1)));
        my $new_row_x2 = $row_x2 + $max_pssbl_mvmnt_rws_rght_cntr;
        my $new_row_y2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_x2)*($new_row_x2)));
        my $new_row_x3 = $new_row_x1;
        my $new_row_y3 = -$new_row_y1;
        my $new_row_x4 = $new_row_x2;
        my $new_row_y4 = -$new_row_y2;
        $vertical_row[$i] = [$new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4];
      }else{
        my $new_row_y1 = $row_y1;
        my $new_row_x2 = $row_x2 + $max_pssbl_mvmnt_rws_rght_cntr;
        my $new_row_y2 = $row_y2;
        my $new_row_x3 = $new_row_x1;
        my $new_row_y3 = -$new_row_y1;
        my $new_row_x4 = $new_row_x2;
        my $new_row_y4 = -$new_row_y2;
        $vertical_row[$i] = [$new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4];
      }
    }
  }
}

my $total_number_of_rect = 0;
open(WRITE,">$out_coord_file");
print WRITE "$wafer_diameter\n";
for(my $ii = 0;$ii<$number_of_horizontal_rows;$ii++){
  my @row_coords = @{$horizontal_row[$ii]};
  ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
  my $min_left_x ;
  my $min_right_x ;
  if(($row_x3 -$row_x1)<($row_x4 -$row_x2)){
    $min_left_x = $row_x1;
    $min_right_x = $row_x3;
  }else{
    $min_left_x = $row_x2;
    $min_right_x = $row_x4;
  }
  my $no_of_rect_in_given_horizontal_row = -1;
  for($i=0;$i<$number_of_vertical_rows;$i++){
    if($vertical_row_hash{$i} >= $min_left_x){
      if($no_of_rect_in_given_horizontal_row == -1){
        $no_of_rect_in_given_horizontal_row = 0;
      }
      if($no_of_rect_in_given_horizontal_row == 0){
        if(($vertical_row_hash{$i} + $die_width) <= $min_right_x){
          $total_number_of_rect++;
          my $rect_x1 = $vertical_row_hash{$i}; 
          my $rect_y1 = $row_y1;
          my $rect_x2 = $vertical_row_hash{$i} + $die_width;
          my $rect_y2 = $row_y1; 
          my $rect_x3 = $vertical_row_hash{$i} + $die_width;
          my $rect_y3 = $row_y2; 
          my $rect_x4 = $vertical_row_hash{$i};
          my $rect_y4 = $row_y2;
          print WRITE "$rect_x1 $rect_y1 $rect_x2 $rect_y2 $rect_x3 $rect_y3 $rect_x4 $rect_y4\n";
        }else{
          last;
        }
      }
    }
  }
}
close(WRITE);
print("total number of rect = $total_number_of_rect\n");
system("scp -i /apps/scp_key -o StrictHostKeyChecking=no $out_coord_file root\@192.168.20.20:/var/www/html/drupal/$drupal_temp_path/out_coord_file");

sub no_of_rect_in_horizontal_row
{
  my $row_x1 = $_[0];
  my $row_y1 = $_[1];
  my $row_x2 = $_[2];
  my $row_y2 = $_[3];
  my $row_x3 = $_[4];
  my $row_y3 = $_[5];
  my $row_x4 = $_[6];
  my $row_y4 = $_[7];
  my $min_left_x ;
  my $min_right_x ;
  if(($row_x3 -$row_x1)<($row_x4 -$row_x2)){
    $min_left_x = $row_x1;
    $min_right_x = $row_x3;
  }else{
    $min_left_x = $row_x2;
    $min_right_x = $row_x4;
  }
  my $no_of_rect_in_given_horizontal_row = -1;
  for($i=0;$i<$number_of_vertical_rows;$i++){
    if($vertical_row_hash{$i} >= $min_left_x){
      if($no_of_rect_in_given_horizontal_row == -1){
        $no_of_rect_in_given_horizontal_row = 0;
      }
      if(($vertical_row_hash{$i} + $die_width) <= $min_right_x){
        $no_of_rect_in_given_horizontal_row++;
      }else{
        last;
      }
    }
  }
  return $no_of_rect_in_given_horizontal_row;
}

sub no_of_rect_in_vertical_row
{
  my $row_x1 = $_[0];
  my $row_y1 = $_[1];
  my $row_x2 = $_[2];
  my $row_y2 = $_[3];
  my $row_x3 = $_[4];
  my $row_y3 = $_[5];
  my $row_x4 = $_[6];
  my $row_y4 = $_[7];
  my $frst_hrzntl_rw_on_th_vrtcl_rw = -1;
  my $lst_hrzntl_rw_on_th_vrtcl_rw = -1;
  my $min_bttm_y ;
  my $min_top_y ;
  if(($row_y3 -$row_y1)<($row_y4 -$row_y2)){
    $min_bttm_y = $row_y1;
    $min_top_y = $row_y3;
  }else{
    $min_bttm_y = $row_y2;
    $min_top_y = $row_y4;
  }
  my $no_of_rect_in_given_vertical_row = -1;
  for($i=0;$i<$number_of_horizontal_rows;$i++){
    if($horizontal_row_hash{$i} >= $min_bttm_y){
      if($no_of_rect_in_given_vertical_row == -1){
        $no_of_rect_in_given_vertical_row = 0;
      }
      if(($horizontal_row_hash{$i} + $die_height) <= $min_top_y){
        $no_of_rect_in_given_vertical_row++;
      }else{
        last;
      }
    }
  }
  return $no_of_rect_in_given_vertical_row;
}
