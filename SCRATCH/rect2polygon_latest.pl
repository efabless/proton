#!/usr/bin/perl
use Math::Clipper ':all';
use Math::Polygon;
use Math::Polygon::Transform;

my @rect_array = ();
my $file_name = $ARGV[0];
open(READ,"$file_name");
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
  push(@rect_array,[@rect]);
}
close(READ);
my $upper_loop_limit = $#rect_array;
for(my $j=0; $j<=$upper_loop_limit; $j++){
  my @p = @{$rect_array[$j]};
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
my $lower_loop_limit = $#rect_array;
my $clipper = Math::Clipper->new;
for(my $j=0; $j<=$upper_loop_limit; $j++){
  my @p = @{$rect_array[$j]};
  if($#p >= 0){
    my @list_of_overlapping_rect = ();
    for(my $i=$j+1; $i<=$lower_loop_limit; $i++){
      my @p1 = @{$rect_array[$i]};
      if($#p1 >= 0){
        my $result_arr_len = &check_overlap_polygon_rect(\@p,\@p1);
        if($result_arr_len > 0){
          push(@list_of_overlapping_rect,$rect_array[$i]);
          my @empty_arr = ();
          $rect_array[$i] = \@empty_arr;
        }
      }
    }
    if($#list_of_overlapping_rect >=0){
      $clipper->clear();
      $clipper->add_subject_polygon($rect_array[$j]);
      foreach my $overlapping_rect (@list_of_overlapping_rect){
        $clipper->add_clip_polygon($overlapping_rect);
      }
      my $result = $clipper->execute(CT_UNION,PFT_NONZERO,PFT_NONZERO);
      my @array_of_polygons = @$result;
      foreach my $polygon (@array_of_polygons){
        $rect_array[$j] = $polygon;
      }
      $j--;
    }
  }
}
for(my $j=0; $j<=$upper_loop_limit; $j++){
  my @p = @{$rect_array[$j]};
  if($#p >= 0){
    foreach my $point_arr_ref (@p){
      my @point_arr = @$point_arr_ref;
      print ("{ ");
      foreach my $point (@point_arr){
        print ("$point ");
      }
      print ("}");
    }
    print ("\n");
  }
}

sub check_overlap_polygon_rect
{
  my @p = @{$_[0]};
  my @p1 = @{$_[1]};
  my @new_poly = polygon_move(dx=>0001, @p1);
  my $clip = Math::Clipper->new;
  $clip->add_subject_polygon([@new_poly]);
  $clip->add_clip_polygon([@p]);
  my $res = $clip->execute(CT_INTERSECTION);
  my @res_arr = @$res;
  my $res_arr_len = @res_arr;
  if($res_arr_len > 0){
    return $res_arr_len;
  }else{
     my @new_poly = polygon_move(dx=>-0001, @p1);
     my $clip = Math::Clipper->new;
     $clip->add_subject_polygon([@new_poly]);
     $clip->add_clip_polygon([@p]);
     my $res = $clip->execute(CT_INTERSECTION);
     my @res_arr = @$res;
     my $res_arr_len = @res_arr;
     if($res_arr_len > 0){
       return $res_arr_len;
     }else{
        my @new_poly = polygon_move(dy=>0001, @p1);
        my $clip = Math::Clipper->new;
        $clip->add_subject_polygon([@new_poly]);
        $clip->add_clip_polygon([@p]);
        my $res = $clip->execute(CT_INTERSECTION);
        my @res_arr = @$res;
        my $res_arr_len = @res_arr;
        if($res_arr_len > 0){
          return $res_arr_len;
        }else{
           my @new_poly = polygon_move(dy=>-0001, @p1);
           my $clip = Math::Clipper->new;
           $clip->add_subject_polygon([@new_poly]);
           $clip->add_clip_polygon([@p]);
           my $res = $clip->execute(CT_INTERSECTION);
           my @res_arr = @$res;
           my $res_arr_len = @res_arr;
           if($res_arr_len > 0){
             return $res_arr_len;
           }else{
             return 0;
           }
        }
      }
   }
}#sub check_overlap_polygon_rect

sub check_overlap_polygon_rect_new
{
  my @p = @{$_[0]};
  my @p1 = @{$_[1]};
  my $clip = Math::Clipper->new;
  $clip->add_subject_polygon([@p]);
  $clip->add_clip_polygon([@p1]);
  my $result = $clip->execute(CT_UNION,PFT_NONZERO,PFT_NONZERO);
  my @array_of_polygons = @$result;
  foreach my $polygon (@array_of_polygons){
    my @polygon_point_array = @$polygon;
    foreach my $polygon_point (@polygon_point_array){
      my @polygon_axis_array = @$polygon_point;
      print("[ ");
      foreach my $polygon_axis (@polygon_axis_array){
        print("$polygon_axis ");
      }
      print("]");
    }
    print("\n");
  }
}#sub check_overlap_polygon_rect_new
