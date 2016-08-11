#!/usr/bin/perl
use Math::Clipper ':all';
use Math::Polygon;
use Math::Polygon::Calc;
use Math::Polygon::Transform;
use List::Part;
use List::Flatten;
use XML::Simple;
use Data::Dumper;

use Benchmark;
my $t0 = new Benchmark;

my $fileName = $ARGV[0];
my $tolerance = 0.0001;

my $current_routing_layer = $fileName;
$current_routing_layer =~ s/layer_with_via_//;
my $clipper = Math::Clipper->new;

#########################################################################################
#################### creating array of routing & via layer polys ########################
#########################################################################################
my @routing_layer_polys = ();
my @via_layer_polys = ();

open(READ, $fileName);
  while(<READ>){
     chomp();
     if($_ =~ /^\s*#/ ){next ;}
     my ($layer_type, $layer, @poly_coords) = split(/\s+/, $_);
   
     ######## removing last point which is same as fist point ########
     #pop @poly_coords;
     #pop @poly_coords;
     #print "INFO-GDS2LEF : 8001 : after popup last point:@poly_coords\n";

     ## converting the polygon coords array as array of poins needed for Math::Polygon ##
     my $j=0;
     my @parted_poly_coords = part { $j++/2 } @poly_coords[0 .. $#poly_coords];

     ###### check the polygon coords are counter clockwise, If not, inverting them ######
     my $direction = is_counter_clockwise([@parted_poly_coords]);
     if($direction == 0){
        #print "INFO-GDS2LEF : 8002 : direction $direction\n";    
        @parted_poly_coords = reverse @parted_poly_coords;
     }

     if($layer_type eq "P"){
        push (@routing_layer_polys, [$layer_type, $layer, @parted_poly_coords]);
     }else{
        push (@via_layer_polys, [$layer_type, $layer, @parted_poly_coords]);
     }

  }
close(READ);

#print "INFO-GDS2LEF : 001 : creating array of routing & via layer polys completed...\n";    
my $t1 = new Benchmark;
my $td0 = timediff($t1, $t0);
print "INFO TIME: 001 : creating array of routing & via layer polys completed in :",timestr($td0),"\n";
  
#########################################################################################
############# making hashes of minx,miny,maxx & maxy for routing layer polys ############
#########################################################################################
my %poly_minX_hash = ();
my %poly_minY_hash = ();
my %poly_maxX_hash = ();
my %poly_maxY_hash = ();
my $poly_maxY_length = 0;

foreach my $poly (@routing_layer_polys){
   my ($poly_layer_type, $poly_layer, @coords) = @$poly;

   my ($minx, $miny, $maxx, $maxy) = polygon_bbox @coords;
   my $len = keys %poly_minX_hash;

   $poly_minX_hash{$len} = $minx;
   $poly_minY_hash{$len} = $miny;
   $poly_maxX_hash{$len} = $maxx;
   $poly_maxY_hash{$len} = $maxy;

   my $y_length = $maxy - $miny;
   if($y_length > $poly_maxY_length){
      $poly_maxY_length = $y_length;
   }
}

#print "INFO-GDS2LEF : 002 : making minx,miny,maxx & maxy hashes for routing layer completed ...\n";    
my $t2 = new Benchmark;
my $td1 = timediff($t2, $t1);
print "INFO TIME: 002 : making minx,miny,maxx & maxy hashes for routing layer completed in :",timestr($td1),"\n";

#########################################################################################
########################## making groups of routing layer polys ########################
#########################################################################################
my @minY_keys = sort{$poly_minY_hash{$a}<=>$poly_minY_hash{$b}} (keys %poly_minY_hash);
my @maxY_keys = sort{$poly_maxY_hash{$a}<=>$poly_maxY_hash{$b}} (keys %poly_maxY_hash);

my @routing_layer_groups = ();
my @total_ovl_poly = ();
foreach my $maxY_poly_num (@maxY_keys){
   if(ref $routing_layer_polys[$maxY_poly_num] eq "" || @{$routing_layer_polys[$maxY_poly_num]} < 1){next;}
   my $minx = $poly_minX_hash{$maxY_poly_num};
   my $miny = $poly_minY_hash{$maxY_poly_num};
   my $maxx = $poly_maxX_hash{$maxY_poly_num};
   my $maxy = $poly_maxY_hash{$maxY_poly_num};

   my @sub_poly = @{$routing_layer_polys[$maxY_poly_num]};
   my ($sub_poly_layer_type, $sub_poly_layer, @p) = @sub_poly;

   my @overlapped_poly = ();
   my @overlapped_poly_num = ();
   @total_ovl_poly = ();

   my $num = $miny - $poly_maxY_length;
   my $low_limit = &get_routing_poly_lower_limit_using_partition(0, $#minY_keys, $num);

   for(my $i=$low_limit; $i<=$#minY_keys; $i++){
       my $minY_poly_num = $minY_keys[$i];
       if(ref $routing_layer_polys[$minY_poly_num] eq ""){next;}

       my $minx1 = $poly_minX_hash{$minY_poly_num};
       my $miny1 = $poly_minY_hash{$minY_poly_num};
       my $maxx1 = $poly_maxX_hash{$minY_poly_num};

       if(($minx1 - $maxx) > $tolerance || ($minx - $maxx1) > $tolerance || $maxY_poly_num == $minY_poly_num){next;}
       if(($miny1 - $maxy) > $tolerance){last;}

       my @clip_poly = @{$routing_layer_polys[$minY_poly_num]};
       my ($clip_poly_layer_type, $clip_poly_layer, @p1) = @clip_poly;     

       $clipper->clear();
       $clipper->add_subject_polygon([@p]);
       $clipper->add_clip_polygon([@p1]);
       my $result = $clipper->execute(CT_INTERSECTION);
       my $result_arr_len = @$result;
       if($result_arr_len > 0){
          push(@overlapped_poly,[@clip_poly]);
          push(@overlapped_poly_num,$minY_poly_num);
          delete $routing_layer_polys[$minY_poly_num];
       }else{
          my @new_poly = polygon_move(dx=>1, @p);
          $clipper->clear();
          $clipper->add_subject_polygon([@new_poly]);
          $clipper->add_clip_polygon([@p1]);
          my $res = $clipper->execute(CT_INTERSECTION);
          my $res_arr_len = @$res;
          if($res_arr_len > 0){
             push(@overlapped_poly,[@clip_poly]);
             push(@overlapped_poly_num,$minY_poly_num);
             delete $routing_layer_polys[$minY_poly_num];
          }else{
             my @new_poly1 = polygon_move(dx=>-1, @p);
             $clipper->clear();
             $clipper->add_subject_polygon([@new_poly1]);
             $clipper->add_clip_polygon([@p1]);
             my $res1 = $clipper->execute(CT_INTERSECTION);
             my $res_arr_len1 = @$res1;
             if($res_arr_len1 > 0){
                push(@overlapped_poly,[@clip_poly]);
                push(@overlapped_poly_num,$minY_poly_num);
                delete $routing_layer_polys[$minY_poly_num];
             }else{
                my @new_poly2 = polygon_move(dy=>1, @p);
                $clipper->clear();
                $clipper->add_subject_polygon([@new_poly2]);
                $clipper->add_clip_polygon([@p1]);
                my $res2 = $clipper->execute(CT_INTERSECTION);
                my $res_arr_len2 = @$res2;
                if($res_arr_len2 > 0){
                   push(@overlapped_poly,[@clip_poly]);
                   push(@overlapped_poly_num,$minY_poly_num);
                   delete $routing_layer_polys[$minY_poly_num];
                }else{
                   my @new_poly3 = polygon_move(dy=>-1, @p);
                   $clipper->clear();
                   $clipper->add_subject_polygon([@new_poly3]);
                   $clipper->add_clip_polygon([@p1]);
                   my $res3 = $clipper->execute(CT_INTERSECTION);
                   my $res_arr_len3 = @$res3;
                   if($res_arr_len3 > 0){
                      push(@overlapped_poly,[@clip_poly]);
                      push(@overlapped_poly_num,$minY_poly_num);
                      delete $routing_layer_polys[$minY_poly_num];
                   }
                }
             }
          }
       }#if touch
   }
   
   if($#overlapped_poly >= 0){
      delete $routing_layer_polys[$maxY_poly_num];
      &get_overlap_poly(\@overlapped_poly_num, \@overlapped_poly);

      push(@overlapped_poly, @total_ovl_poly);
      unshift(@overlapped_poly,[@sub_poly]);
      #-------- making group array ------#
      push(@routing_layer_groups,[@overlapped_poly]);
   }else{
      delete $routing_layer_polys[$maxY_poly_num];
      push(@routing_layer_groups,[[@sub_poly]]);
   }
}
   
#print "INFO-GDS2LEF : 003 : making groups of routing layer polys completed ...\n";    
my $t3 = new Benchmark;
my $td2 = timediff($t3, $t2);
print "INFO TIME: 003 : making groups of routing layer polys completed in :",timestr($td2),"\n";

#########################################################################################
############### making hashes of minx,miny,maxx & maxy for via layer polys ##############
#########################################################################################
my %via_poly_minX_hash = ();
my %via_poly_minY_hash = ();
my %via_poly_maxX_hash = ();
my %via_poly_maxY_hash = ();
my $via_poly_maxY_length = 0;

foreach my $poly (@via_layer_polys){
   my ($via_layer_type, $via_layer, @coords) = @$poly;

   my ($minx, $miny, $maxx, $maxy) = polygon_bbox @coords;
   my $len = keys %via_poly_minX_hash;

   $via_poly_minX_hash{$len} = $minx;
   $via_poly_minY_hash{$len} = $miny;
   $via_poly_maxX_hash{$len} = $maxx;
   $via_poly_maxY_hash{$len} = $maxy;

   my $y_length = $maxy - $miny;
   if($y_length > $via_poly_maxY_length){
      $via_poly_maxY_length = $y_length;
   }
}

#print "INFO-GDS2LEF : 004 : making hashes of minx,miny,maxx & maxy for via layer polys completed ...\n";    
my $t4 = new Benchmark;
my $td3 = timediff($t4, $t3);
print "INFO TIME: 004 : making hashes of minx,miny,maxx & maxy for via layer polys completed in :",timestr($td3),"\n";

#########################################################################################
######################## making groups of routing layer vs via ##########################
#########################################################################################
my @via_minY_keys = sort{$via_poly_minY_hash{$a}<=>$via_poly_minY_hash{$b}} (keys %via_poly_minY_hash);

my $group_cnt = 0;
open(WRITE, ">gds_layer_groups_$current_routing_layer");
foreach my $group (@routing_layer_groups){
   my @via_overlapped = ();
   #my $poly_layer =  @$group[0]->[1];
   #open(WRITE, ">gds_layer_$poly_layer"."_$group_cnt");
   print WRITE "GROUP: $group_cnt\n";
   foreach my $poly (@$group){
      my @flat_poly = flat @$poly;
      print WRITE "@flat_poly\n";

      my ($poly_layer_type, $poly_layer, @p) = @$poly;
      my ($minx, $miny, $maxx, $maxy) = polygon_bbox @p;

      my $num = $miny - $via_poly_maxY_length;
      my $lower_limit = &get_via_poly_lower_limit_using_partition(0, $#via_minY_keys, $num);

      for(my $j=$lower_limit; $j<=$#via_minY_keys; $j++){
          my $minY_poly_num = $via_minY_keys[$j];
          if(ref $via_layer_polys[$minY_poly_num] eq ""){next;}

          my $minx1 = $via_poly_minX_hash{$minY_poly_num};
          my $miny1 = $via_poly_minY_hash{$minY_poly_num};
          my $maxx1 = $via_poly_maxX_hash{$minY_poly_num};
          #my $maxy1 = $via_poly_maxY_hash{$minY_poly_num};

          if(($minx1 - $maxx) > $tolerance || ($minx - $maxx1) > $tolerance){next;}
          if(($miny1 - $maxy) > $tolerance){last;}

          my ($via_layer_type, $via_layer, @p1) = @{$via_layer_polys[$minY_poly_num]};

          $clipper->clear();
          $clipper->add_subject_polygon([@p]);
          $clipper->add_clip_polygon([@p1]);
          my $result = $clipper->execute(CT_INTERSECTION,PFT_NONZERO,PFT_NONZERO);
          my $result_arr_len = @$result;
          if($result_arr_len > 0){
             push(@via_overlapped,[@{$via_layer_polys[$minY_poly_num]}]);
             delete $via_poly_minX_hash{$minY_poly_num};
             #delete $via_poly_minY_hash{$minY_poly_num}; #we are using it inside get_via_poly_lower_limit_using_partition from 0 to max element
             delete $via_poly_maxX_hash{$minY_poly_num};
             delete $via_poly_maxY_hash{$minY_poly_num};
             delete $via_layer_polys[$minY_poly_num];
             #my @flat_via_poly = flat @{$via_layer_polys[$minY_poly_num]};
             #print WRITE "@flat_via_poly\n";
          }
      }#for each poly
   }#foreach polygon
   foreach my $via_poly (@via_overlapped){
      my @flat_via_poly = flat @$via_poly;
      print WRITE "@flat_via_poly\n";
   }
   $group_cnt++;
   #close(WRITE);
}#foreach group
close(WRITE);

#print "INFO-GDS2LEF : 005 : making groups of routing layer vs via completed ...\n";    
my $t5 = new Benchmark;
my $td4 = timediff($t5, $t4);
print "INFO TIME: 005 : making groups of routing layer vs via completed in :",timestr($td4),"\n";

#########################################################################################
#########################################################################################
#########################################################################################

my $t6 = new Benchmark;
my $td = timediff($t6, $t0);
print "INFO TIME: script create_group_of_polygons took :",timestr($td),"\n";

#########################################################################################
########## Recursive function to create groups of polygons for individual layer #########
#########################################################################################
sub get_overlap_poly{
  my @sub_poly_num_arr = @{$_[0]};
  my @ovl_poly_coords_arr = @{$_[1]};

  foreach my $maxY_poly_num(@sub_poly_num_arr){
      my $minx = $poly_minX_hash{$maxY_poly_num};
      my $miny = $poly_minY_hash{$maxY_poly_num};
      my $maxx = $poly_maxX_hash{$maxY_poly_num};
      my $maxy = $poly_maxY_hash{$maxY_poly_num};

      my @sub_poly = @{shift @ovl_poly_coords_arr};
      my ($sub_poly_layer_type, $sub_poly_layer, @p) = @sub_poly;

      my @ovl_poly = ();
      my @ovl_poly_num = ();

      my $num = $miny - $poly_maxY_length;
      my $low_limit = &get_routing_poly_lower_limit_using_partition(0, $#minY_keys, $num); 

      for(my $i=$low_limit; $i<=$#minY_keys; $i++){
          my $minY_poly_num = $minY_keys[$i];
          if(ref $routing_layer_polys[$minY_poly_num] eq ""){next;}

          my $minx1 = $poly_minX_hash{$minY_poly_num};
          my $miny1 = $poly_minY_hash{$minY_poly_num};
          my $maxx1 = $poly_maxX_hash{$minY_poly_num};

          if(($minx1 - $maxx) > $tolerance || ($minx - $maxx1) > $tolerance || $maxY_poly_num == $minY_poly_num){next;}
          if(($miny1 - $maxy) > $tolerance){last;}

          my @clip_poly = @{$routing_layer_polys[$minY_poly_num]};
          my ($clip_poly_layer_type, $clip_poly_layer, @p1) = @clip_poly;     

          $clipper->clear();
          $clipper->add_subject_polygon([@p]);
          $clipper->add_clip_polygon([@p1]);
          my $result = $clipper->execute(CT_INTERSECTION);
          my $result_arr_len = @$result;
          if($result_arr_len > 0){
             push(@ovl_poly,[@clip_poly]);
             push(@ovl_poly_num,$minY_poly_num);
             delete $routing_layer_polys[$minY_poly_num];
          }else{
             my @new_poly = polygon_move(dx=>1, @p);
             $clipper->clear();
             $clipper->add_subject_polygon([@new_poly]);
             $clipper->add_clip_polygon([@p1]);
             my $res = $clipper->execute(CT_INTERSECTION);
             my $res_arr_len = @$res;
             if($res_arr_len > 0){
                push(@ovl_poly,[@clip_poly]);
                push(@ovl_poly_num,$minY_poly_num);
                delete $routing_layer_polys[$minY_poly_num];
             }else{
                my @new_poly1 = polygon_move(dx=>-1, @p);
                $clipper->clear();
                $clipper->add_subject_polygon([@new_poly1]);
                $clipper->add_clip_polygon([@p1]);
                my $res1 = $clipper->execute(CT_INTERSECTION);
                my $res_arr_len1 = @$res1;
                if($res_arr_len1 > 0){
                   push(@ovl_poly,[@clip_poly]);
                   push(@ovl_poly_num,$minY_poly_num);
                   delete $routing_layer_polys[$minY_poly_num];
                }else{
                   my @new_poly2 = polygon_move(dy=>1, @p);
                   $clipper->clear();
                   $clipper->add_subject_polygon([@new_poly2]);
                   $clipper->add_clip_polygon([@p1]);
                   my $res2 = $clipper->execute(CT_INTERSECTION);
                   my $res_arr_len2 = @$res2;
                   if($res_arr_len2 > 0){
                      push(@ovl_poly,[@clip_poly]);
                      push(@ovl_poly_num,$minY_poly_num);
                      delete $routing_layer_polys[$minY_poly_num];
                   }else{
                      my @new_poly3 = polygon_move(dy=>-1, @p);
                      $clipper->clear();
                      $clipper->add_subject_polygon([@new_poly3]);
                      $clipper->add_clip_polygon([@p1]);
                      my $res3 = $clipper->execute(CT_INTERSECTION);
                      my $res_arr_len3 = @$res3;
                      if($res_arr_len3 > 0){
                         push(@ovl_poly,[@clip_poly]);
                         push(@ovl_poly_num,$minY_poly_num);
                         delete $routing_layer_polys[$minY_poly_num];
                      }
                   }
                }
             }
          }
      }
      if($#ovl_poly >= 0){
         push(@total_ovl_poly, @ovl_poly);
         &get_overlap_poly(\@ovl_poly_num, \@ovl_poly);
      }
  }
}#sub get_overlap_poly

#########################################################################################
############### function to get limit by partition for routing layer poly ###############
#########################################################################################
sub get_routing_poly_lower_limit_using_partition{
  my $min_ele = $_[0];
  my $max_ele = $_[1];
  my $num = $_[2];

  my $length = $max_ele - $min_ele + 1;
  if($length <= 2){return $min_ele;}
  
  my $mid_num = $length/2;
  my $int_mid_num = int($mid_num);
  if($num <= $poly_minY_hash{$minY_keys[$min_ele]}){
     return $min_ele;
  }elsif($num >= $poly_minY_hash{$minY_keys[$max_ele]}){
     return $max_ele;
  }elsif($num > $poly_minY_hash{$minY_keys[$min_ele]} && $num < $poly_minY_hash{$minY_keys[$min_ele + $int_mid_num]}){
     &get_routing_poly_lower_limit_using_partition($min_ele, $min_ele + $int_mid_num , $num);
  }else{
     &get_routing_poly_lower_limit_using_partition($min_ele+$int_mid_num+1, $max_ele, $num);
  }   
}#sub get_routing_poly_lower_limit_using_partition

#########################################################################################
############### function to get limit by partition for routing layer poly ###############
#########################################################################################
sub get_via_poly_lower_limit_using_partition{
  my $min_ele = $_[0];
  my $max_ele = $_[1];
  my $num = $_[2];

  my $length = $max_ele - $min_ele + 1;
  if($length <= 2){return $min_ele;}
  
  my $mid_num = $length/2;
  my $int_mid_num = int($mid_num);
  if($num <= $via_poly_minY_hash{$via_minY_keys[$min_ele]}){
     return $min_ele;
  }elsif($num >= $via_poly_minY_hash{$via_minY_keys[$max_ele]}){
     return $max_ele;
  }elsif($num > $via_poly_minY_hash{$via_minY_keys[$min_ele]} && $num < $via_poly_minY_hash{$via_minY_keys[$min_ele + $int_mid_num]}){
     &get_via_poly_lower_limit_using_partition($min_ele, $min_ele + $int_mid_num , $num);
  }else{
     &get_via_poly_lower_limit_using_partition($min_ele+$int_mid_num+1, $max_ele, $num);
  }   
}#sub get_via_poly_lower_limit_using_partition

#########################################################################################
#########################################################################################
#########################################################################################
sub canvas_zoomIn_zoomOut{
my @arg = @_;
my $canvas = $arg[0];
my @view_bbox = @{$arg[1]};
   #$canvas->CanvasFocus;
   #$canvas->configure(-bandColor => 'red');
   $canvas->CanvasBind('<3>'               => sub {$canvas->configure(-bandColor => "");
                                                   $canvas->configure(-bandColor => 'red');
                                                   $canvas->rubberBand(0)});
   $canvas->CanvasBind('<B3-Motion>'       => sub {$canvas->rubberBand(1)});
   $canvas->CanvasBind('<ButtonRelease-3>' => sub {my @box = $canvas->rubberBand(2);
                                                   $canvas->viewArea(@box, -border => 0);
                                                   });
   $canvas->CanvasBind('<2>'               => sub {$canvas->viewArea(@view_bbox, -border => 0);});               

   $canvas->CanvasBind('<i>' => sub {$canvas->zoom(1.25);});
   $canvas->CanvasBind('<o>' => sub {$canvas->zoom(0.80);});
   $canvas->CanvasBind('<f>' => sub {$canvas->viewArea(@view_bbox, -border => 0);});

   $mw->bind('WorldCanvas',    '<Up>' => "");
   $mw->bind('WorldCanvas',  '<Down>' => "");
   $mw->bind('WorldCanvas',  '<Left>' => "");
   $mw->bind('WorldCanvas', '<Right>' => "");

   $canvas->CanvasBind('<KeyPress-Up>'   => sub {$canvas->panWorld(0,  200);});
   $canvas->CanvasBind('<KeyPress-Down>' => sub {$canvas->panWorld(0, -200);});
   $canvas->CanvasBind('<KeyPress-Left>' => sub {$canvas->panWorld(-200, 0);});
   $canvas->CanvasBind('<KeyPress-Right>'=> sub {$canvas->panWorld( 200, 0);});

}#sub canvas_zoomIn_zoomOut

