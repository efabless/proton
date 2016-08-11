#!/usr/bin/perl
 use Math::Clipper ':all';
  my $clipper = Math::Clipper->new;
  
  # Add the polygon to-be-clipped
  $clipper->add_subject_polygon(
    [ [1, 1],
      [3, 1],
      [3, 3],
      [1, 3],
      [1, 1],
    ],
  );

  # Add the polygon that defines the clipping
  $clipper->add_clip_polygon(
    [ [3.5, 1],
      [5, 1],
      [5, 2.5],
      [3.5, 2.5],
      [3.5, 1],
    ],
  );
  
  # Run the clipping operation
  my $result = $clipper->execute(CT_INTERSECTION);
  #my $result = $clipper->execute(CT_UNION);
  my @t = @{$result};
  my $t1 = @t;
  print "$result : @t : $t1\n";
  # $result is array ref containing 0 or more
  # polygons (themselves array refs as above) that represent
  # the intersection between the subject and the clipping
  # polygon(s)
