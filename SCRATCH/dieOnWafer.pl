#!/usr/bin/perl

my $die_width = 0;
my $die_height = 0;
my $horizontal_spacing = 0;
my $vertical_spacing = 0;
my $wafer_diameter = 0;
my $edge_clearance = 0;
my $flat_or_notch_clearance = 0;
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
  }
}
print("Argument read\n");
#lets assume that circle centre is origin, so that
#x*x + y*y = (wafer_diameter/2)*(wafer_diameter/2)
#now starting from (wafer_diameter/2,0) to (wafer_diameter/2,wafer_diameter)
#we need to find how many rows can be on the circle
my $initial_y = -$wafer_diameter/2 + $flat_or_notch_clearance;
my $number_of_rows = -1;
for(my $curr_y=$initial_y;$curr_y<=$wafer_diameter/2;$curr_y+=$die_height+$vertical_spacing){
  $number_of_rows++;
}
print("number of rows = $number_of_rows\n");
my $total_spacing_on_both_side = $wafer_diameter - ($number_of_rows*$die_height + ($number_of_rows -1)*$vertical_spacing);
my $average_spacing_on_both_side = $total_spacing_on_both_side/2;
if($flat_or_notch_clearance < $average_spacing_on_both_side){
  $initial_y = -$wafer_diameter/2 + $average_spacing_on_both_side;
}
my @row = ();
my $min_row_dst_cntr_below = "";
my $min_row_dst_cntr_above = "";
my $row_on_centre = "";
my $row_just_above_centre = "";
my $row_just_below_centre = "";
my $row_on_centre_width = "";
my $row_just_above_centre_width = "";
my $row_just_below_centre_width = "";
my $no_of_rect_in_row_on_centre = "";
my $no_of_rect_in_row_just_above_centre = "";
my $no_of_rect_in_row_just_below_centre = "";
my $curr_row_number = 0 ;
#Need to find 1 row which lies on the circle centre,if any such row is there
#need to find two rows such that circle center lies in between them
for(my $curr_y=$initial_y;$curr_row_number<$number_of_rows;$curr_y+=$die_height+$vertical_spacing){
  my $row_y1 = $curr_y;
  my $row_x1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($row_y1)*($row_y1)));
  my $row_y2 = $row_y1 + $die_height;
  my $row_x2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($row_y2)*($row_y2)));
  my $row_y3 = $row_y1;
  my $row_x3 = -$row_x1;
  my $row_y4 = $row_y2;
  my $row_x4 = -$row_x2;
  $row[$curr_row_number] = [$row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4];
  print("row coords are $row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4\n");
  my $curr_row_width ;
  if(($row_x3 -$row_x1)<($row_x4 -$row_x2)){
    $curr_row_width  = $row_x3 - $row_x1;
  }else{
    $curr_row_width  = $row_x4 - $row_x2;
  }
  my $no_of_rect_in_curr_row = int(($curr_row_width+$horizontal_spacing)/($die_width+$horizontal_spacing));
  if(($row_y1 < 0) && ($row_y2 > 0)){
    $row_on_centre = $curr_row_number;
    $no_of_rect_in_row_on_centre = $no_of_rect_in_curr_row;
    $row_on_centre_width = $curr_row_width;
  }
  if(($row_y1 < 0) && ($row_y2 <= 0)){
    if($min_row_dst_cntr_below eq ""){
      $min_row_dst_cntr_below = abs($row_y2);
      $row_just_below_centre = $curr_row_number;
      $no_of_rect_in_row_just_below_centre = $no_of_rect_in_curr_row;
      $row_just_below_centre_width = $curr_row_width;
    }elsif(abs($row_y2) < $min_row_dst_cntr_below){
      $min_row_dst_cntr_below = abs($row_y2);
      $row_just_below_centre = $curr_row_number;
      $no_of_rect_in_row_just_below_centre = $no_of_rect_in_curr_row;
      $row_just_below_centre_width = $curr_row_width;
    }
  }elsif(($row_y1 >= 0) && ($row_y2 > 0)){
    if($min_row_dst_cntr_above eq ""){
      $min_row_dst_cntr_above = $row_y1;
      $row_just_above_centre = $curr_row_number;
      $no_of_rect_in_row_just_above_centre = $no_of_rect_in_curr_row;
      $row_just_above_centre_width = $curr_row_width;
    }elsif($row_y1 < $min_row_dst_cntr_above){
      $min_row_dst_cntr_above = $row_y1;
      $row_just_above_centre = $curr_row_number;
      $no_of_rect_in_row_just_above_centre = $no_of_rect_in_curr_row;
      $row_just_above_centre_width = $curr_row_width;
    }
  }
  $curr_row_number++;
}
print("rows populated\n");
#space left on any row will be less than width of rectangle
my $max_pssbl_mvmnt_rws_blw_cntr = "";
my $row_nearest_or_just_below_centre;
if($row_on_centre eq ""){
  $row_nearest_or_just_below_centre = $row_just_below_centre;
}else{
  $row_nearest_or_just_below_centre = $row_on_centre;
}
for(my $i = 0;$i<=$row_nearest_or_just_below_centre;$i++){
  my @row_coords = @{$row[$i]};
  ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
  print("row coords are $row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4\n");
  my $curr_row_width ;
  if(($row_x3 -$row_x1)<($row_x4 -$row_x2)){
    $curr_row_width  = $row_x3 - $row_x1;
  }else{
    $curr_row_width  = $row_x4 - $row_x2;
  }
  my $no_of_rect_in_curr_row = int(($curr_row_width+$horizontal_spacing)/($die_width+$horizontal_spacing));
  my $remaining_width = $curr_row_width -$no_of_rect_in_curr_row*$die_width -($no_of_rect_in_curr_row-1)*$horizontal_spacing; 
  my $new_row_x1 = $row_x1 + $remaining_width/2;
  my $new_row_y1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_x1)*($new_row_x1)));
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
  if($max_pssbl_mvmnt_rws_blw_cntr ==0){
    last;
  }
}
print("max_pssbl_mvmnt_rws_blw_cntr is $max_pssbl_mvmnt_rws_blw_cntr\n");
my $max_pssbl_mvmnt_rws_abv_cntr = "";
my $row_nearest_or_just_above_centre;
if($row_on_centre eq ""){
  $row_nearest_or_just_above_centre = $row_just_above_centre;
}else{
  $row_nearest_or_just_above_centre = $row_on_centre;
}
for(my $i = $number_of_rows-1;$i>=$row_nearest_or_just_above_centre;$i--){
  my @row_coords = @{$row[$i]};
  ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
  print("row coords are $row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4\n");
  my $curr_row_width ;
  if(($row_x3 -$row_x1)<($row_x4 -$row_x2)){
    $curr_row_width  = $row_x3 - $row_x1;
  }else{
    $curr_row_width  = $row_x4 - $row_x2;
  }
  my $no_of_rect_in_curr_row = int(($curr_row_width+$horizontal_spacing)/($die_width+$horizontal_spacing));
  my $remaining_width = $curr_row_width -$no_of_rect_in_curr_row*$die_width -($no_of_rect_in_curr_row-1)*$horizontal_spacing; 
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
  if($max_pssbl_mvmnt_rws_abv_cntr ==0){
    last;
  }
}
print("max_pssbl_mvmnt_rws_abv_cntr is $max_pssbl_mvmnt_rws_abv_cntr\n");
#Now we need to check if by moving all the rows which are on or below centre,
#upwards can increase number of rectangle in any of the rows.
my $no_of_rect_increased_upward_movement = 0;
for(my $i = 0;$i<=$row_just_below_centre;$i++){
  my @row_coords = @{$row[$i]};
  ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = $row_coords[0,1,2,3,4,5,6,7];
  my $curr_row_width ;
  if(($row_x3 -$row_x1)<($row_x4 -$row_x2)){
    $curr_row_width  = $row_x3 - $row_x1;
  }else{
    $curr_row_width  = $row_x4 - $row_x2;
  }
  my $no_of_rect_in_curr_row = int(($curr_row_width+$horizontal_spacing)/($die_width+$horizontal_spacing));
  my $new_row_y1 = $row_y1 + $max_pssbl_mvmnt_rws_abv_cntr;
  my $new_row_x1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y1)*($new_row_y1)));
  my $new_row_y2 = $row_y2 + $max_pssbl_mvmnt_rws_abv_cntr;
  my $new_row_x2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y2)*($new_row_y2)));
  my $new_row_x3 = -$new_row_x1;
  my $new_row_x4 = -$new_row_x2;
  my $new_curr_row_width ;
  if(($new_row_x3 -$new_row_x1)<($new_row_x4 -$new_row_x2)){
    $new_curr_row_width  = $new_row_x3 - $new_row_x1;
  }else{
    $new_curr_row_width  = $new_row_x4 - $new_row_x2;
  }
  my $new_no_of_rect_in_curr_row = int(($new_curr_row_width+$horizontal_spacing)/($die_width+$horizontal_spacing));
  if($new_no_of_rect_in_curr_row > $no_of_rect_in_curr_row){
    $no_of_rect_increased_upward_movement++;
  }
}
my $no_of_rect_increased_downward_movement = 0;
for(my $i = $number_of_rows-1;$i>=$row_just_above_centre;$i--){
  my @row_coords = @{$row[$i]};
  ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = $row_coords[0,1,2,3,4,5,6,7];
  my $curr_row_width ;
  if(($row_x3 -$row_x1)<($row_x4 -$row_x2)){
    $curr_row_width  = $row_x3 - $row_x1;
  }else{
    $curr_row_width  = $row_x4 - $row_x2;
  }
  my $no_of_rect_in_curr_row = int(($curr_row_width+$horizontal_spacing)/($die_width+$horizontal_spacing));
  my $new_row_y1 = $row_y1 - $max_pssbl_mvmnt_rws_blw_cntr;
  my $new_row_x1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y1)*($new_row_y1)));
  my $new_row_y2 = $row_y2 - $max_pssbl_mvmnt_rws_blw_cntr;
  my $new_row_x2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y2)*($new_row_y2)));
  my $new_row_x3 = -$new_row_x1;
  my $new_row_x4 = -$new_row_x2;
  my $new_curr_row_width ;
  if(($new_row_x3 -$new_row_x1)<($new_row_x4 -$new_row_x2)){
    $new_curr_row_width  = $new_row_x3 - $new_row_x1;
  }else{
    $new_curr_row_width  = $new_row_x4 - $new_row_x2;
  }
  my $new_no_of_rect_in_curr_row = int(($new_curr_row_width+$horizontal_spacing)/($die_width+$horizontal_spacing));
  if($new_no_of_rect_in_curr_row > $no_of_rect_in_curr_row){
    $no_of_rect_increased_downward_movement++;
  }
}
if($no_of_rect_increased_downward_movement > $no_of_rect_increased_upward_movement){
  for(my $i = 0;$i<$number_of_rows;$i++){
    my @row_coords = @{$row[$i]};
    ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = $row_coords[0,1,2,3,4,5,6,7];
    my $new_row_y1 = $row_y1 - $max_pssbl_mvmnt_rws_blw_cntr;
    my $new_row_x1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y1)*($new_row_y1)));
    my $new_row_y2 = $row_y2 - $max_pssbl_mvmnt_rws_blw_cntr;
    my $new_row_x2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y2)*($new_row_y2)));
    my $new_row_x3 = -$new_row_x1;
    my $new_row_x4 = -$new_row_x2;
    $row[$i] = [$new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4];
  }
}elsif($no_of_rect_increased_upward_movement > $no_of_rect_increased_downward_movement){
  for(my $i = 0;$i<$number_of_rows;$i++){
    my @row_coords = @{$row[$i]};
    ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = $row_coords[0,1,2,3,4,5,6,7];
    my $new_row_y1 = $row_y1 + $max_pssbl_mvmnt_rws_abv_cntr;
    my $new_row_x1 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y1)*($new_row_y1)));
    my $new_row_y2 = $row_y2 + $max_pssbl_mvmnt_rws_abv_cntr;
    my $new_row_x2 = -(sqrt(($wafer_diameter/2)*($wafer_diameter/2) - ($new_row_y2)*($new_row_y2)));
    my $new_row_x3 = -$new_row_x1;
    my $new_row_x4 = -$new_row_x2;
    $row[$i] = [$new_row_x1 ,$new_row_y1 ,$new_row_x2 ,$new_row_y2 ,$new_row_x3 ,$new_row_y3 ,$new_row_x4 ,$new_row_y4];
  }
}
my $total_number_of_rect = 0;
for(my $i = 0;$i<$number_of_rows;$i++){
  my @row_coords = @{$row[$i]};
  ($row_x1 ,$row_y1 ,$row_x2 ,$row_y2 ,$row_x3 ,$row_y3 ,$row_x4 ,$row_y4) = @row_coords[0,1,2,3,4,5,6,7];
  my $curr_row_width ;
  if(($row_x3 -$row_x1)<($row_x4 -$row_x2)){
    $curr_row_width  = $row_x3 - $row_x1;
  }else{
    $curr_row_width  = $row_x4 - $row_x2;
  }
  $total_number_of_rect += int(($curr_row_width+$horizontal_spacing)/($die_width+$horizontal_spacing));
}
print("total number of rect = $total_number_of_rect\n");
