#!/usr/bin/perl
use Math::Clipper ':all';
use Math::Polygon;
use Math::Polygon::Transform;

my $file_name1 = $ARGV[0];
my $file_name2 = $ARGV[1];
my $compare_type = $ARGV[2];
my $out_file_name = $ARGV[3];
my $debug = "no";
if($ARGC == 5){
  if($ARGV[4] eq "debug"){
    $debug = "yes";
  }
}
my @rect_array1 = ();
my @rect_array2 = ();
open(READ,"<$file_name1");
while(<READ>){
  s/\s+//g;
  s/^\(//;
  s/\)$//;
  my @points = split(/\)\,\(/);
  my @rect = ();
  foreach my $point (@points){
    my @point_array = split(/\,/,$point);
    push(@rect,[@point_array]);
  }
  push(@rect_array1,[@rect]);
}
close(READ);
open(READ,"<$file_name2");
while(<READ>){
  s/\s+//g;
  s/^\(//;
  s/\)$//;
  my @points = split(/\)\,\(/);
  my @rect = ();
  foreach my $point (@points){
    my @point_array = split(/\,/,$point);
    push(@rect,[@point_array]);
  }
  push(@rect_array2,[@rect]);
}
my $scale = integerize_coordinate_sets(@rect_array1,@rect_array2);
close(READ);
if($debug eq "yes"){
  for(my $j=0; $j<=$#rect_array1; $j++){
    my @p = @{$rect_array1[$j]};
    if($#p >= 0){
      foreach my $point_arr_ref (@p){
        my @point_arr = @$point_arr_ref;
        print ("( ");
        foreach my $point (@point_arr){
          print ("$point ");
        }
        print (")");
      }
      print ("\n");
    }
  }
  for(my $j=0; $j<=$#rect_array2; $j++){
    my @p = @{$rect_array2[$j]};
    if($#p >= 0){
      foreach my $point_arr_ref (@p){
        my @point_arr = @$point_arr_ref;
        print ("( ");
        foreach my $point (@point_arr){
          print ("$point ");
        }
        print (")");
      }
      print ("\n");
    }
  }
}
my $clipper = Math::Clipper->new;
$clipper->clear();
for(my $j=0; $j<=$#rect_array1; $j++){
  if($j ==0){
    $clipper->add_subject_polygon($rect_array1[$j]);
  }else{
    $clipper->add_clip_polygon($rect_array1[$j]);
  }
}
my $result = $clipper->execute(CT_UNION,PFT_NONZERO,PFT_NONZERO);
@rect_array1 = @$result;
$clipper->clear();
for(my $j=0; $j<=$#rect_array2; $j++){
  if($j ==0){
    $clipper->add_subject_polygon($rect_array2[$j]);
  }else{
    $clipper->add_clip_polygon($rect_array2[$j]);
  }
}
$result = $clipper->execute(CT_UNION,PFT_NONZERO,PFT_NONZERO);
@rect_array2 = @$result;
if($debug eq "yes"){
  for(my $j=0; $j<=$#rect_array1; $j++){
    my @p = @{$rect_array1[$j]};
    foreach my $point_arr_ref (@p){
      my @point_arr = @$point_arr_ref;
      print ("( ");
      foreach my $point (@point_arr){
        print ("$point ");
      }
      print (")");
    }
    print ("\n");
  }
  for(my $j=0; $j<=$#rect_array2; $j++){
    my @p = @{$rect_array2[$j]};
    foreach my $point_arr_ref (@p){
      my @point_arr = @$point_arr_ref;
      print ("( ");
      foreach my $point (@point_arr){
        print ("$point ");
      }
      print (")");
    }
    print ("\n");
  }
}
my @rect1_rect2_array = ();
$clipper->clear();
for(my $j=0; $j<=$#rect_array1; $j++){
  if($j ==0){
    $clipper->add_subject_polygon($rect_array1[$j]);
  }else{
    $clipper->add_clip_polygon($rect_array1[$j]);
  }
}
for(my $j=0; $j<=$#rect_array2; $j++){
  $clipper->add_clip_polygon($rect_array2[$j]);
}
$result = $clipper->execute(CT_UNION,PFT_NONZERO,PFT_NONZERO);
@rect1_rect2_array = @$result;
if($debug eq "yes"){
  for(my $j=0; $j<=$#rect1_rect2_array; $j++){
    my @p = @{$rect1_rect2_array[$j]};
    foreach my $point_arr_ref (@p){
      my @point_arr = @$point_arr_ref;
      print ("( ");
      foreach my $point (@point_arr){
        print ("$point ");
      }
      print (")");
    }
    print ("\n");
  }
}
my @rect1_minus_or_xor_rect2_array = ();
for(my $j=0; $j<=$#rect1_rect2_array; $j++){
  $clipper->clear();
  $clipper->add_subject_polygon($rect1_rect2_array[$j]);
  for(my $i=0; $i<=$#rect_array2; $i++){
    $clipper->add_clip_polygon($rect_array2[$i]);
  }
  $result = $clipper->execute(CT_DIFFERENCE);
  push(@rect1_minus_or_xor_rect2_array , @$result);
}
if($compare_type eq "xor"){
  for(my $j=0; $j<=$#rect1_rect2_array; $j++){
    $clipper->clear();
    $clipper->add_subject_polygon($rect1_rect2_array[$j]);
    for(my $i=0; $i<=$#rect_array1; $i++){
      $clipper->add_clip_polygon($rect_array1[$i]);
    }
    $result = $clipper->execute(CT_DIFFERENCE);
    push(@rect1_minus_or_xor_rect2_array , @$result);
  }
}
unscale_coordinate_sets( $scale, [@rect1_minus_or_xor_rect2_array]);
open(WRITE,">$out_file_name");
my $is_first_point;
my $is_first_axis;
for(my $j=0; $j<=$#rect1_minus_or_xor_rect2_array; $j++){
  my @p = @{$rect1_minus_or_xor_rect2_array[$j]};
  $is_first_point = 1;
  foreach my $point_arr_ref (@p){
    if($is_first_point != 1){
      print WRITE ",";
    }else{
      $is_first_point = 0;
    }
    my @point_arr = @$point_arr_ref;
    print WRITE "(";
    $is_first_axis = 1;
    foreach my $point (@point_arr){
      if($is_first_axis != 1){
        print WRITE ",";
      }else{
        $is_first_axis = 0;
      }
      print WRITE "$point";
    }
    print WRITE ")";
  }
  print WRITE "\n";
}
close(READ);
