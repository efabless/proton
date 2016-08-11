#!/usr/bin/perl
 use Math::Clipper ':all';
  my $clipper = Math::Clipper->new;
  
  # Add the polygon to-be-clipped
  $clipper->add_subject_polygon( [ [0, 0], [2947.42,0],[2947.42, 359.100], [0,359.100] ],);
  $clipper->add_subject_polygon( [ [0.000, 359.200], [3167.360,359.200], [ 3167.360, 1547.280], [0, 1547.280 ]],);

  # Add the polygon that defines the clipping
#  $clipper->add_clip_polygon( [ [1578.920, 1547.280], [ 3167.360, 1653.120] ]);
#  $clipper->add_clip_polygon( [ [0.000, 359.100], [ 3167.360, 1547.280] ]);
#  $clipper->add_clip_polygon( [ [1752.240, 3115.980], [ 3650.220, 4372.200] ]);
#  $clipper->add_clip_polygon( [ [1578.920, 1653.120], [ 3650.220, 3115.980] ]);
  
  # Run the clipping operation
  my $result = $clipper->execute(CT_INTERSECTION);
  #my $result = $clipper->execute(CT_UNION);
  my @t = @{$result};
  my $t1 = @t;
  print "$result : @t : $t1:\n";
  # $result is array ref containing 0 or more
  # polygons (themselves array refs as above) that represent
  # the intersection between the subject and the clipping
  # polygon(s)
