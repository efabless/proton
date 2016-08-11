#!/usr/bin/perl
use GDS2;
use Math::Clipper ':all';
use Math::Polygon;
use Math::Polygon::Transform;
use XML::Simple;
use Benchmark;
my $t0 = new Benchmark;
my $upper_loop_limit = $#rect_array;
my $lower_loop_limit = $#rect_array;
for(my $j=0; $j<=$upper_loop_limit; $j++){
  my @p = @{$rect_array[$j]};
  if($#p >= 0){
    for(my $i=$j+1; $i<=$lower_loop_limit; $i++){
      my @p1 = @{$rect_array[$i]};
      if($#p1 >= 0){
        my $result_arr_len = &check_overlap_polygon_rect(\@p,\@p1);
        if($result_arr_len > 0){
          my @enhanced_poly_coords = @{&get_merged_poly_with_rect(\@p,\@p1)};
          $rect_array[$j] = \@enhanced_poly_coords;
          $j--;
          my @empty_arr = ();
          $rect_array[$i] = \@empty_arr;
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
  my $poly_loop_limit = $#poly_coords;
  my $rect_loop_limit = $#rect_coords;
  my @merged_poly_coords = ();
  my $is_touch_point_found = 0;
  my $last_rect_coord = "";
  for(my $j=0; $j<=$poly_loop_limit; $j++){
    my $curr_poly_coord = $poly_coords[$j];
    if($curr_poly_coord != $last_rect_coord){
      push(@merged_poly_coords,$curr_poly_coord);
    }
    my $next_poly_coord = "";
    if($j == $poly_loop_limit){
      $next_poly_coord = $poly_coords[0];
    }else{
      $next_poly_coord = $poly_coords[$j+1];
    }
    if($is_touch_point_found ==0){
      for(my $i=0; $i<=$rect_loop_limit; $i++){
        my $curr_rect_coord = $rect_coords[$i];
        if ($curr_rect_coord ne ""){
          $is_touch_point_found =1;
          my $if_rect_point_touch_poly_line = &check_if_point_touch_line($curr_poly_coord,$next_poly_coord,$curr_rect_coord);
          if($if_rect_point_touch_poly_line == 1){
            my $next_rect_coord ;
            if($i == 3){
              $next_rect_coord = $rect_coords[0];
            }else{
              $next_rect_coord = $rect_coords[$i+1];
            }
            my $coord_order = &check_if_adjcnt_anti_clockwise($next_rect_coord,$curr_rect_coord,$curr_poly_coord);
            if ($coord_order == 1){
              if($i ==0){
                $i = 3;
              }else{
                $i -= 1;
              }
            }
            for(my $ii=$i; $ii<=$i+3; $ii++){
              my $temp_rect_coord;
              if($ii>3){
                my $temp_index = $ii -3;
                $temp_rect_coord = $rect_coords[$temp_index];
              }else{
                $temp_rect_coord = $rect_coords[$ii];
              }
              $last_rect_coord = $temp_rect_coord;
              push(@merged_poly_coords,$temp_rect_coord);
            }
            last;
          }
        }
      }
    }
    if($is_touch_point_found ==0){
      for(my $i=0; $i<=$rect_loop_limit; $i++){
        my $curr_rect_coord = $rect_coords[$i];
        my $next_rect_coord = "";
        if($j == $rect_loop_limit){
          $next_rect_coord = $rect_coords[0];
        }else{
          $next_rect_coord = $rect_coords[$i+1];
        }
        my $if_poly_point_touch_rect_line = &check_if_point_touch_line($curr_rect_coord,$next_rect_coord,$curr_poly_coord);
        if($if_poly_point_touch_rect_line == 1){
          for(my $ii=$i; $ii<=$i+3; $ii++){
            my $temp_rect_coord;
            if($ii>3){
              my $temp_index = $ii -3;
              $temp_rect_coord = $rect_coords[$temp_index];
            }else{
              $temp_rect_coord = $rect_coords[$ii];
            }
            $last_rect_coord = $temp_rect_coord;
            push(@merged_poly_coords,$temp_rect_coord);
          }
          last;
        }
      }
    }
  }
}

sub check_if_point_touch_line
{
  my $curr_poly_coord = $_[0];
  my $next_poly_coord = $_[1];
  my $curr_rect_coord = $_[2];

  $curr_poly_coord =~ s/(|)|\s//g;
  my $curr_poly_x = (split(/,/,$curr_poly_coord))[0]; 
  my $curr_poly_y = (split(/,/,$curr_poly_coord))[1]; 
  $next_poly_coord =~ s/(|)|\s//g;
  my $next_poly_x = (split(/,/,$next_poly_coord))[0]; 
  my $next_poly_y = (split(/,/,$next_poly_coord))[1]; 
  $curr_rect_coord =~ s/(|)|\s//g;
  my $curr_rect_x = (split(/,/,$curr_rect_coord))[0]; 
  my $curr_rect_y = (split(/,/,$curr_rect_coord))[1]; 
  if((($curr_rect_x == $curr_poly_x) && ($curr_rect_y == $curr_poly_y))
   || (($curr_rect_x == $next_poly_x) && ($curr_rect_y == $next_poly_y))){
    return 1;
  }
  if($curr_poly_x == $next_poly_x){
    if($curr_rect_x == $curr_poly_x){
      if($curr_poly_y < $next_poly_y){ #upward going line,since it is anti clockwise
        if(($curr_rect_y < $curr_poly_y)&&($curr_rect_y > $next_poly_y)){
          return 1;
        }
      }
      if($curr_poly_y > $next_poly_y){ #downward going line,since it is anti clockwise
        if(($curr_rect_y > $curr_poly_y)&&($curr_rect_y < $next_poly_y)){
          return 1;
        }
      }
    }
  }
  if($curr_poly_y == $next_poly_y){
    if($curr_rect_y == $curr_poly_y){
      if($curr_poly_x < $next_poly_x){ #rightward going line,since it is anti clockwise
        if(($curr_rect_x > $curr_poly_x)&&($curr_rect_x < $next_poly_x)){
          return 1;
        }
      }
      if($curr_poly_x > $next_poly_x){ #leftward going line,since it is anti clockwise
        if(($curr_rect_x > $curr_poly_x)&&($curr_rect_x < $next_poly_x)){
          return 1;
        }
      }
    }
  }
}

sub check_if_adjcnt_anti_clockwise
{
  my $first_coord = $_[0];
  my $second_coord = $_[1];
  my $third_coord = $_[2];

  $first_coord =~ s/(|)|\s//g;
  my $first_x = (split(/,/,$first_coord))[0]; 
  my $first_y = (split(/,/,$first_coord))[1]; 
  $second_coord =~ s/(|)|\s//g;
  my $second_x = (split(/,/,$second_coord))[0]; 
  my $second_y = (split(/,/,$second_coord))[1]; 
  $third_coord =~ s/(|)|\s//g;
  my $third_x = (split(/,/,$third_coord))[0]; 
  my $third_y = (split(/,/,$third_coord))[1]; 
  if(($first_x == $second_x)&&($third_x == $second_x)){
    if(($third_y < $second_y)&&($third_y > $first_y)){
      return 1;
    }
    if(($third_y > $second_y)&&($third_y < $first_y)){
      return 1;
    }
  }
  if(($first_y == $second_y)&&($third_y == $second_y)){
    if(($third_x < $second_x)&&($third_x > $first_x)){
      return 1;
    }
    if(($third_x > $second_x)&&($third_x < $first_x)){
      return 1;
    }
  }
  return 0;
}#sub check_if_adjcnt_anti_clockwise

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
}
