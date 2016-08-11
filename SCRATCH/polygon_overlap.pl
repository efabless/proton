#!/usr/bin/perl
use Math::Clipper ':all';
my %boundary_layer_hash = (1=>[[1,1,3,1,3,3,1,3,1,1], [2,2,4,2,4,4,2,4,2,2],[3,3,4,3,4,4,3,4,3,3],[4,5,5,5,5,6,4,6,4,5],[3.5,1,5,1,5,2.5,3.5,2.5,3.5,1],[4.5,2,5.5,2,5.5,3,4.5,3,4.5,2.5],[4,4,5,4,5,5.5,4,5.5,4,4]],
                           2=>[[1,5,2,5,2,7,1,7,1,5],[1,6,3,6,3,7,1,7,1,6],[2.5,5,3.5,5,3.5,7,2.5,7,2.5,5],[4.5,7,5,7,5,8,4.5,8,4.5,7]]);
my %layer_group_hash = ();
  foreach my $l(keys %boundary_layer_hash){
     @poly_arr = @{$boundary_layer_hash{$l}};
     my @group_arr = ();
     for(my $i=0; $i<$#poly_arr; $i++){
         if($poly_arr[$i] eq ""){next;}
         my @sub_poly = @{$poly_arr[$i]};
         my @overlapped_poly = ();
         my @p = ();
         for(my $k=0; $k<=$#sub_poly; $k=$k+2){
             push(@p,[$sub_poly[$k],$sub_poly[$k+1]]);
         }
         for(my $j=$i+1; $j<=$#poly_arr; $j++){
             if($poly_arr[$j] eq ""){next;}
             my @clip_poly = @{$poly_arr[$j]};     
             my @p1 = ();
             for(my $l=0; $l<=$#clip_poly; $l=$l+2){
                 push(@p1,[$clip_poly[$l],$clip_poly[$l+1]]);
             }
             my $clipper = Math::Clipper->new;
             $clipper->add_subject_polygon([@p]);
             $clipper->add_clip_polygon([@p1]);
             my $result = $clipper->execute(CT_INTERSECTION);
             my @result_arr = @$result;
             my $result_arr_len = @result_arr;
             #print "@sub_poly | @clip_poly | $result_arr_len\n";
             if($result_arr_len > 0){
                push(@overlapped_poly,[@clip_poly]);
                delete $poly_arr[$j];
             }#if overlapped
         }
         if($#overlapped_poly >= 0){
            unshift(@overlapped_poly,[@sub_poly]);
            delete $poly_arr[$i];
            my @add_overlap = &get_overlap_poly(\@overlapped_poly);
            push(@overlapped_poly,@add_overlap);
            #-------- making group array ------#
            push(@group_arr,[@overlapped_poly]);
         }else{
            push(@group_arr,[@sub_poly]);
         }
         @{$layer_group_hash{$l} = @group_arr;
         #foreach (@overlapped_poly){
         #   print "ad $l |$i | @$_\n";
         #}
     }
  }
 
sub get_overlap_poly{
  my @sub_poly_arr = @{$_[0]};
  my @ovl_poly = ();
  for(my $i=0; $i<=$#sub_poly_arr; $i++){
      my @sub_poly = @{$sub_poly_arr[$i]};
      my @p = ();
      for(my $k=0; $k<=$#sub_poly; $k=$k+2){
          push(@p,[$sub_poly[$k],$sub_poly[$k+1]]);
      }
      for(my $j=0; $j<=$#poly_arr; $j++){
          if($poly_arr[$j] eq ""){next;}
          my @clip_poly = @{$poly_arr[$j]};     
          my @p1 = ();
          for(my $l=0; $l<=$#clip_poly; $l=$l+2){
              push(@p1,[$clip_poly[$l],$clip_poly[$l+1]]);
          }
          my $clipper = Math::Clipper->new;
          $clipper->add_subject_polygon([@p]);
          $clipper->add_clip_polygon([@p1]);
          my $result = $clipper->execute(CT_INTERSECTION);
          my @result_arr = @$result;
          my $result_arr_len = @result_arr;
          #print "@sub_poly | @clip_poly | $result_arr_len\n";
          if($result_arr_len > 0){
             push(@ovl_poly,[@clip_poly]);
             delete $poly_arr[$j];
          }#if overlapped
      }
      if($#ovl_poly >= 0){
        push(@ovl_poly, &get_overlap_poly(\@ovl_poly));
      }
  }
  return @ovl_poly;
}#sub get_overlap_poly

