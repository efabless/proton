#!/usr/bin/perl
use Math::Clipper ':all';
use Math::Polygon;
use Math::Polygon::Transform;

  my $clipper = Math::Clipper->new;
  $clipper->add_subject_polygon( [ [200,  300], [  200, 200], [300, 200], [ 300, 100], [ 200, 100], [ 200, 0], [ 400, 0], [ 400, 400], [ 300, 400], [ 300, 300] ] );
  #$clipper->add_clip_polygon( [ [200,  200], [ 200, 100], [300, 100], [ 300, 200] ] );
  #$clipper->add_clip_polygon( [ [100,  300], [  100, 0], [200, 0], [ 200, 300] ] );
  $clipper->add_clip_polygon( [ [-100,  300], [  -100, 0], [-200, 0], [ -200, 300] ] );
  #$clipper->add_clip_polygon(    [ [100, 0], [200, 0], [  200, 100], [ 100, 100] ] );
  #$clipper->add_clip_polygon(    [ [200, 0], [300, 0], [  300, 100], [ 200, 100] ] );
  my $result = $clipper->execute(CT_UNION,PFT_NONZERO,PFT_NONZERO);
  #my $result = $clipper->execute(CT_INTERSECTION);
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
