#!/usr/bin/perl -w
use strict;
use Graph::Directed;
use Graph::Layouter qw(layout);
use Graph::Renderer;
use GraphViz;
use List::Util qw[min max];

my ($help, $debug, $verbose) = (0,0,0);
my $mGL  = Graph::Directed->new;
my $mGR  = Graph::Directed->new;
my $mGLV = GraphViz->new(rankdir=> 1);
my $mGRV = GraphViz->new();
my @MACRO;
my %MACRO;

## create a new graph
$mGL->add_vertex("M_L");
$mGL->add_vertex("M_R");
$mGR->add_vertex("M_L");
$mGR->add_vertex("M_R");
$MACRO{M_L}{min} = 0;
$MACRO{M_R}{max} = 0;

$MACRO{M_L}{curr} = 0;
$MACRO{M_1}{curr} = 1;
$MACRO{M_2}{curr} = 4;
$MACRO{M_3}{curr} = 17;
$MACRO{M_4}{curr} = 18;
$MACRO{M_5}{curr} = 2;
$MACRO{M_6}{curr} = 15;
$MACRO{M_7}{curr} = 3;
$MACRO{M_8}{curr} = 12;
$MACRO{M_R}{curr} = 20;

for (my $i=1; $i<=8; $i++) {
  my $macro = "M_".$i;
  push (@MACRO, $macro);
  $mGL->add_vertex($macro);
  $mGR->add_vertex($macro);
}
$mGL->add_weighted_edge("M_L","M_1",0);  $mGR->add_weighted_edge("M_1","M_L",0);
$mGL->add_weighted_edge("M_L","M_5",0);  $mGR->add_weighted_edge("M_5","M_L",0);
$mGL->add_weighted_edge("M_L","M_6",0);  $mGR->add_weighted_edge("M_6","M_L",0);
$mGL->add_weighted_edge("M_1","M_3",1);  $mGR->add_weighted_edge("M_3","M_1",1);
$mGL->add_weighted_edge("M_1","M_7",1);  $mGR->add_weighted_edge("M_7","M_1",1);
$mGL->add_weighted_edge("M_2","M_3",2);  $mGR->add_weighted_edge("M_3","M_2",2);
$mGL->add_weighted_edge("M_2","M_8",2);  $mGR->add_weighted_edge("M_8","M_2",2);
$mGL->add_weighted_edge("M_3","M_4",3);  $mGR->add_weighted_edge("M_4","M_3",3);
$mGL->add_weighted_edge("M_4","M_R",4);  $mGR->add_weighted_edge("M_R","M_4",4);
$mGL->add_weighted_edge("M_5","M_2",5);  $mGR->add_weighted_edge("M_2","M_5",5);
$mGL->add_weighted_edge("M_6","M_R",6);  $mGR->add_weighted_edge("M_R","M_6",6);
$mGL->add_weighted_edge("M_7","M_2",7);  $mGR->add_weighted_edge("M_2","M_7",7);
$mGL->add_weighted_edge("M_8","M_R",8);  $mGR->add_weighted_edge("M_R","M_8",8);
&display_graph;

&findMinX("M_R");
&findMaxX("M_L");
&place;




print "Done\n";
#&findMaxRightLen;

########################################################################
sub place {
  my @order = sort sortHashValue (keys(%MACRO));
  foreach my $m (@order) {
    if ($MACRO{$m}{min} > $MACRO{$m}{max}) {
      die "No solution exists because min of macro:$m > max=Min:$MACRO{$m}{min} max=$MACRO{$m}{max}";
    } elsif ( ($MACRO{$m}{curr} >= $MACRO{$m}{min}) && ($MACRO{$m}{curr} <= $MACRO{$m}{max})) {
      $MACRO{$m}{locX} = $MACRO{$m}{curr};
    } elsif ($MACRO{$m}{curr} < $MACRO{$m}{min}) {
      $MACRO{$m}{locX} = $MACRO{$m}{min};
    } elsif ($MACRO{$m}{curr} > $MACRO{$m}{max}) {
      $MACRO{$m}{locX} = $MACRO{$m}{max};
    }

    my @succ = $mGL->successors($m);
    foreach my $succ (@succ) {
      my $wt = $mGL->get_edge_weight($m, $succ);
      $wt += $MACRO{$m}{locX} - $MACRO{$m}{min};
      $mGL->set_edge_weight($m, $succ, $wt)
    }

    my @pred = $mGR->predecessors($m);
    foreach my $pred (@pred) {
      my $wt = $mGR->get_edge_weight($pred, $m);
      $wt += $MACRO{$m}{locX} - $MACRO{$m}{min};
      $mGR->set_edge_weight($pred, $m, $wt)
    }

    print"Placed Macro:$m at $MACRO{$m}{locX}\n";
    &findMinX("M_R");
    &findMaxX("M_L");
  }
}

########################################################################
sub display_graph {
  my @vertices = $mGL->vertices();
  foreach my $vtx (@vertices) {
    $mGLV->add_node($vtx);
  }
  my @edges = $mGL->edges();
  foreach my $edge (@edges) {
    my $wt = $mGL->get_edge_weight($edge->[0], $edge->[1]);
    $mGLV->add_edge($edge->[0] => $edge->[1], label => $wt);
  }
  $mGLV->as_png("seed_place_graph.png")
}

########################################################################
sub findMinX {
  my ($m) = @_;
  my $minX = -1;
  print"Finding Min X for $m...\n" if ($debug);
  if ($m eq "M_L") { 
    $minX = 0;
  } else {
    my @pred = $mGL->predecessors($m);
    my @predMinX;
    foreach my $pred (@pred) {
      my $predMinX = findMinX($pred);
      my $edgeWt = $mGL->get_edge_weight($pred,$m);
      print"\t\tm:$m pred:$pred predMinX:$predMinX edgeWt:$edgeWt\n" if ($debug);
      push(@predMinX, $predMinX +$edgeWt);
    }
    $minX = max(@predMinX);
    print"\t @pred : @predMinX\n" if ($debug);
  }
  print"MinX of Macro:$m = $minX\n"  if ($verbose);
  $MACRO{$m}{min} = $minX;
  return($minX);
}

########################################################################
sub findMaxX {
  my ($m) = @_;
  my $maxX = -1;
  print"Finding Max X for $m...\n" if ($debug);
  if ($m eq "M_R") { 
    $maxX = 0;
  } else {
    my @pred = $mGR->predecessors($m);
    my @predMaxX;
    foreach my $pred (@pred) {
      my $predMaxX = findMaxX($pred);
      my $edgeWt = $mGR->get_edge_weight($pred,$m);
      print"\t\tm:$m pred:$pred predMaxX:$predMaxX edgeWt:$edgeWt\n" if ($debug);
      push(@predMaxX, $predMaxX +$edgeWt);
    }
    $maxX = max(@predMaxX);
    print"\t @pred : @predMaxX\n" if ($debug);
  }
  print"MaxX of Macro:$m = $maxX\n" if ($verbose);
  $MACRO{$m}{max} = $MACRO{M_R}{curr} - $maxX;
  return($maxX);
}

########################################################################
sub sortHashValue {
   $MACRO{$a}{curr} <=> $MACRO{$b}{curr};
}
