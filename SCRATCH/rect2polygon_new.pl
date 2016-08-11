#!/usr/bin/perl
use Math::Clipper ':all';
use Math::Polygon;
use Math::Polygon::Transform;

my $upper_loop_limit = $#rect_array;
my $lower_loop_limit = $#rect_array;
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
          my @enhanced_poly_coords = @{&get_merged_poly_with_rect(\@p,\@p1)};
          $rect_array[$j] = \@enhanced_poly_coords;
          $j--;
        }
      }
    }
  }
}

#points of polygon and rects to be in anticlockwise direction, point 
#with minimum X and maximum Y should be the first point of the array

sub get_merged_poly_with_rect
{
  my @poly_coords = @{$_[0]};
  my @rect_coords = @{$_[1]};
  my @mrgd_rect_poly_coords = ();
  my %hash_poly_coords = ();
  my $poly_loop_limit = $#poly_coords;
  my $rect_loop_limit = $#rect_coords;
  my $rect_max_x = "";
  my $rect_min_x = "";
  my $rect_max_y = "";
  my $rect_min_y = "";
  for(my $j=0; $j<=$poly_loop_limit; $j++){
    my $curr_poly_coord = $poly_coords[$j];
    $hash_poly_coords{$curr_poly_coord} = 1;
  }
  my $rect_poly_points_to_sort = ();
  for(my $i=0; $i<=$rect_loop_limit; $i++){
    my $curr_rect_coord =~ s/(|)|\s//g;
    push(@rect_poly_points_to_sort,$curr_rect_coord);
    my $curr_rect_x = (split(/,/,$curr_rect_coord))[0]; 
    my $curr_rect_y = (split(/,/,$curr_rect_coord))[1]; 
    if($i ==0){
      $rect_min_x = $curr_rect_x;
      $rect_max_x = $curr_rect_x;
      $rect_min_y = $curr_rect_y;
      $rect_max_y = $curr_rect_y;
    }else{
      if($rect_min_x > $curr_rect_x){
        $rect_min_x = $curr_rect_x;
      }
      if($rect_max_x < $curr_rect_x){
        $rect_max_x = $curr_rect_x;
      }
      if($rect_min_y > $curr_rect_y){
        $rect_min_y = $curr_rect_y;
      }
      if($rect_max_y < $curr_rect_y){
        $rect_max_y = $curr_rect_y;
      }
    }
  }
  my $starting_index = -1;
  my $first_coord_in_sorted_list = "";
  my $last_coord_in_sorted_list = "";
  for(my $j=0; $j<=$poly_loop_limit; $j++){
    my $curr_poly_coord = $poly_coords[$j];
    my $next_poly_coord;
    my $next_index ;
    if($j== $poly_loop_limit){
      $next_index = 0;
      $next_poly_coord = $poly_coords[0];;
    }else{
      $next_index = $j+1;
      $next_poly_coord = $poly_coords[$j+1];;
    }
    my $curr_poly_coord_copy = $curr_poly_coord;
    $curr_poly_coord_copy =~ s/(|)|\s//g;
    my $curr_poly_x = (split(/,/,$curr_poly_coord_copy))[0]; 
    my $curr_poly_y = (split(/,/,$curr_poly_coord_copy))[1]; 
    my $next_poly_coord_copy = $next_poly_coord;
    $next_poly_coord_copy =~ s/(|)|\s//g;
    my $next_poly_x = (split(/,/,$next_poly_coord_copy))[0]; 
    my $next_poly_y = (split(/,/,$next_poly_coord_copy))[1]; 
    if((($curr_poly_x == $rect_min_x) && ($next_poly_x == $rect_min_x))
      ||(($curr_poly_x == $rect_max_x) && ($next_poly_x == $rect_max_x))){
      if((($curr_poly_y >= $rect_min_y) && ($curr_poly_y <= $rect_max_y))
        ||(($next_poly_y >= $rect_min_y) && ($next_poly_y <= $rect_max_y))){
        if(($curr_poly_y >= $rect_min_y) && ($curr_poly_y <= $rect_max_y)){
          push(@rect_poly_points_to_sort,$curr_poly_coord);
          $first_coord_in_sorted_list = $curr_poly_coord;
        }else{
          push(@mrgd_rect_poly_coords,$curr_poly_coord);
        }
        if(($next_poly_y >= $rect_min_y) && ($next_poly_y <= $rect_max_y)){
          push(@rect_poly_points_to_sort,$next_poly_coord);
          $last_coord_in_sorted_list = $next_poly_coord;
          my $temp_list = &sort_in_anti_clockwise_direction(@rect_poly_points_to_sort,$first_coord_in_sorted_list,$last_coord_in_sorted_list);
          push(@mrgd_rect_poly_coords,@{$temp_list});
        }else{
          my $temp_list = &sort_in_anti_clockwise_direction(@rect_poly_points_to_sort,$first_coord_in_sorted_list,$last_coord_in_sorted_list);
          push(@mrgd_rect_poly_coords,@{$temp_list});
        }
      }elsif((($curr_poly_y <= $rect_min_y) && ($next_poly_y >= $rect_max_y))
        ||(($curr_poly_y >= $rect_max_y) && ($next_poly_y <= $rect_min_y))){
        push(@mrgd_rect_poly_coords,$curr_poly_coord);
        push(@mrgd_rect_poly_coords,$rect_poly_points_to_sort);
      }else{
        push(@mrgd_rect_poly_coords,$curr_poly_coord);
      }
    }elsif((($curr_poly_y == $rect_min_y) && ($next_poly_y == $rect_min_y))
      ||(($curr_poly_y == $rect_max_y) && ($next_poly_y == $rect_max_y))){
      if((($curr_poly_x >= $rect_min_x) && ($curr_poly_x <= $rect_max_x))
        ||(($next_poly_x >= $rect_min_x) && ($next_poly_x <= $rect_max_x))){
        if(($curr_poly_x >= $rect_min_x) && ($curr_poly_x <= $rect_max_x)){
          push(@rect_poly_points_to_sort,$curr_poly_coord);
          $first_coord_in_sorted_list = $curr_poly_coord;
        }else{
          push(@mrgd_rect_poly_coords,$curr_poly_coord);
        }
        if(($next_poly_x >= $rect_min_x) && ($next_poly_x <= $rect_max_x)){
          push(@rect_poly_points_to_sort,$next_poly_coord);
          $last_coord_in_sorted_list = $next_poly_coord;
          my $temp_list = &sort_in_anti_clockwise_direction(@rect_poly_points_to_sort,$first_coord_in_sorted_list,$last_coord_in_sorted_list);
          push(@mrgd_rect_poly_coords,@{$temp_list});
        }else{
          my $temp_list = &sort_in_anti_clockwise_direction(@rect_poly_points_to_sort,$first_coord_in_sorted_list,$last_coord_in_sorted_list);
          push(@mrgd_rect_poly_coords,@{$temp_list});
        }
      }elsif((($curr_poly_x <= $rect_min_x) && ($next_poly_x >= $rect_max_x))
        ||(($curr_poly_x >= $rect_max_x) && ($next_poly_x <= $rect_min_x))){
        push(@mrgd_rect_poly_coords,$curr_poly_coord);
        push(@mrgd_rect_poly_coords,$rect_poly_points_to_sort);
      }else{
        push(@mrgd_rect_poly_coords,$curr_poly_coord);
      }
    }elsif(((($curr_poly_y == $rect_min_y)||($curr_poly_y == $rect_max_y)) && (($curr_poly_x >= $rect_min_x) && ($curr_poly_x <= $rect_max_x)))
      ||((($curr_poly_x == $rect_min_x)||($curr_poly_x == $rect_max_x)) && (($curr_poly_y >= $rect_min_y) && ($curr_poly_y <= $rect_max_y)))){
      print "\n";
    }else{
      push(@mrgd_rect_poly_coords,$curr_poly_coord);
    }
  }
  return \@mrgd_rect_poly_coords;
}#sub get_merged_poly_with_rect

sub check_overlap_polygon_rect
{
  my @p = @{$_[0]};
  my @p1 = @{$_[1]};
  my @new_poly = polygon_move(dx=>.0001, @p1);
  my $clip = Math::Clipper->new;
  $clip->add_subject_polygon([@new_poly]);
  $clip->add_clip_polygon([@p]);
  my $res = $clip->execute(CT_INTERSECTION);
  my @res_arr = @$res;
  my $res_arr_len = @res_arr;
  if($res_arr_len > 0){
    return $res_arr_len;
  }else{
     my @new_poly = polygon_move(dx=>-.0001, @p1);
     my $clip = Math::Clipper->new;
     $clip->add_subject_polygon([@new_poly]);
     $clip->add_clip_polygon([@p]);
     my $res = $clip->execute(CT_INTERSECTION);
     my @res_arr = @$res;
     my $res_arr_len = @res_arr;
     if($res_arr_len > 0){
       return $res_arr_len;
     }else{
        my @new_poly = polygon_move(dy=>.0001, @p1);
        my $clip = Math::Clipper->new;
        $clip->add_subject_polygon([@new_poly]);
        $clip->add_clip_polygon([@p]);
        my $res = $clip->execute(CT_INTERSECTION);
        my @res_arr = @$res;
        my $res_arr_len = @res_arr;
        if($res_arr_len > 0){
          return $res_arr_len;
        }else{
           my @new_poly = polygon_move(dy=>-.0001, @p1);
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

sub sort_in_anti_clockwise_direction
{
  my @rect_poly_points_to_sort = @{$_[0]};
  my $first_coord_in_sorted_list = $_[1];
  my $last_coord_in_sorted_list = $_[2];
  my $rect_centroid_coord = $_[3];
  @rect_poly_points_to_sort = sort {sort_anticlockwise($a,$b,$rect_centroid_coord)} @rect_poly_points_to_sort;
  my $first_coord_index = -1;
  if($first_coord_in_sorted_list != ""){
    while($rect_poly_points_to_sort[$first_coord_index] != $first_coord_in_sorted_list){
      $first_coord_index++;
    }
    my @rearranged_sorted_list = ();
    my $temp_index;
    for (my $i = $first_coord_index ; $i <= $first_coord_index + $#rect_poly_points_to_sort ; $i++ ){
      if($i > $#rect_poly_points_to_sort){
        $temp_index = $i - ($#rect_poly_points_to_sort +1);
      }else{
        $temp_index = $i;
      }
      push(@rearranged_sorted_list,$rect_poly_points_to_sort[$temp_index]);
    }
    return \@rearranged_sorted_list;
  }
  my $last_coord_index = -1;
  if($last_coord_in_sorted_list != ""){
    while($rect_poly_points_to_sort[$last_coord_index] != $last_coord_in_sorted_list){
      $last_coord_index++;
    }
    my $temp_index;
    for (my $i = $last_coord_in_sorted_list ; $i >= $last_coord_in_sorted_list - $#rect_poly_points_to_sort ; $i-- ){
      if($i < 0){
        $temp_index = $i + ($#rect_poly_points_to_sort +1);
      }else{
        $temp_index = $i;
      }
      unshift(@rearranged_sorted_list,$rect_poly_points_to_sort[$temp_index]);
    }
    return \@rearranged_sorted_list;
  }
}#sub sort_in_anti_clockwise_direction

sub sort_anticlockwise
{
  my $a = $_[0];
  my $b = $_[1];
  my $rect_centroid_coord = $_[2];
  my $a_copy = $a;
  $a_copy =~ s/(|)|\s//g;
  my $a_x = (split(/,/,$a_copy))[0]; 
  my $a_y = (split(/,/,$a_copy))[1]; 
  my $b_copy = $b;
  $b_copy =~ s/(|)|\s//g;
  my $b_x = (split(/,/,$b_copy))[0]; 
  my $b_y = (split(/,/,$b_copy))[1]; 
  my $rect_centroid_coord_copy = $rect_centroid_coord;
  $rect_centroid_coord_copy =~ s/(|)|\s//g;
  my $rect_centroid_x = (split(/,/,$rect_centroid_coord_copy))[0]; 
  my $rect_centroid_y = (split(/,/,$rect_centroid_coord_copy))[1]; 
  my $a_atan2 = atan2($a_y - $rect_centroid_y,$a_x - $rect_centroid_x);
  my $b_atan2 = atan2($b_y - $rect_centroid_y,$b_x - $rect_centroid_x);
  return $a_atan2 <=> $b_atan2;
}#sub sort_anticlockwise
