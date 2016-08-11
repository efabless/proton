#!/usr/bin/perl -w
use strict;
use Graph::Directed;
#use Graph::Layouter qw(layout);
#use Graph::Renderer;
#use GraphViz;
use List::Util qw[min max];
use Getopt::Long;
use Benchmark;

my ($fpdef, $fpdefout, $dir, $genGx);
my ($help, $debug, $verbose) = (0,0,0);
my $mGL  = Graph::Directed->new;
my $mGR  = Graph::Directed->new;
my $mGx  = Graph::Directed->new;
my @MACRO;
my %MACRO;
my @DIEAREA;
my $eps = 1;

#my $mGLV = GraphViz->new(rankdir=> 1);
#my $mGRV = GraphViz->new();


&make_blockplacer(@ARGV);

########################################################################
sub make_blockplacer {
  my $t0 = new Benchmark;

  # initialize vars
  my (@args) = @_;
  ($fpdef, $fpdefout, $dir, $genGx) = ();
  ($help, $debug, $verbose) = (0,0,0);
  $mGL  = Graph::Directed->new;
  $mGR  = Graph::Directed->new;
  $mGx  = Graph::Directed->new;
  @MACRO = ();
  %MACRO = ();
  @DIEAREA = ();


  $help = 0;
  &make_blockplacer_readArgs(@args);
  if ($help) {
    &make_blockplacer_usage();
  } else {
    &make_blockplacer_readFpdef;
    &make_blockplacer_genGx;
#    &display_graph;
    &make_blockplacer_place;
    &make_blockplacer_writeFpdef;
  } #if...else

  &finish();
  my $t1 = new Benchmark;
  my $td = timediff($t1, $t0);
  print "make_blockplacer took:",timestr($td),"\n";
} #sub make_blockplacer

########################################################################
sub make_blockplacer_readArgs {
  my (@args) =  @_;
  my $args = join(' ',@args);
  if (!defined($args)) {
	$args = "";
  }
  my $parseResult = Getopt::Long::GetOptionsFromString($args , 
						       # read args here
						       "fpdef=s"    => \$fpdef,
						       "output=s"   => \$fpdefout,
						       "dir"        => \$dir,
						       "genGx"      => \$genGx,
						       "help"       => \$help,
						       "debug"      => \$debug,
						       "verbose"    => \$verbose,
						      );
} #sub make_blockplacer_readArgs

########################################################################
sub finish() {
  #anything special to be done when this script exits
} #sub finish

########################################################################
sub make_blockplacer_place {


  my @order = sort make_blockplacer_sortHashValueCurr (keys(%MACRO));
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
    &make_blockplacer_findMinX("M_R");
    &make_blockplacer_findMaxX("M_L");

    $MACRO{$m}{p_llx} = $MACRO{$m}{locX};
    $MACRO{$m}{p_lly} = $MACRO{$m}{lly};
    $MACRO{$m}{p_urx} = $MACRO{$m}{p_llx} + $MACRO{$m}{urx} - $MACRO{$m}{llx};
    $MACRO{$m}{p_ury} = $MACRO{$m}{ury};
  }
} # sub make_blockplacer_place

########################################################################
sub make_blockplacer_findMinX {
  my ($m) = @_;
  my $minX = -1;
  print"Finding Min X for $m...\n" if ($debug);
  if ($m eq "M_L") { 
    $minX = 0;
  } else {
    my @pred = $mGL->predecessors($m);
    my @predMinX;
    foreach my $pred (@pred) {
      my $predMinX = make_blockplacer_findMinX($pred);
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
} #sub make_blockplacer_findMinX

########################################################################
sub make_blockplacer_findMaxX {
  my ($m) = @_;
  my $maxX = -1;
  print"Finding Max X for $m...\n" if ($debug);
  if ($m eq "M_R") { 
    $maxX = 0;
  } else {
    my @pred = $mGR->predecessors($m);
    my @predMaxX;
    foreach my $pred (@pred) {
      my $predMaxX = make_blockplacer_findMaxX($pred);
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
} #sub make_blockplacer_findMaxX

########################################################################
sub make_blockplacer_sortHashValueCurr {
   $MACRO{$a}{curr} <=> $MACRO{$b}{curr};
} #sub make_blockplacer_sortHashValueCurr

########################################################################
#sub display_graph {
#  my @vertices = $mGL->vertices();
#  foreach my $vtx (@vertices) {
#    $mGLV->add_node($vtx);
#  }
#  my @edges = $mGL->edges();
#  foreach my $edge (@edges) {
#    my $wt = $mGL->get_edge_weight($edge->[0], $edge->[1]);
#    $mGLV->add_edge($edge->[0] => $edge->[1], label => $wt);
#  }
#  $mGLV->as_png("seed_place_graph.png")
#}

## ########################################################################
sub make_blockplacer_readFpdef {

  open(FPDEF, $fpdef)    or &finish( "$! : $fpdef",__LINE__);

  my $readComps = 0;
  my $line = <FPDEF>;
  my $lineCount = 0;
  while ($line) {
    chomp $line;
    if ($line =~ /^\s*DIEAREA\s*\(\s*(.*)\s*\)\s*;/ ) {
      print "Found $1\n";
      @DIEAREA = split(/\s+/,$1);
    } elsif ($line =~ /^\s*COMPONENTS/ ) {
      $readComps = 1;
      while ($readComps) {
	$line = <FPDEF>; $lineCount++; 
	#read components
	if ($line =~ /^\s*([A-Za-z]\w*)\s+\(\s*(.*)\s*\)\s*\(\s*(.*)\s*\)\s*;/ ) {
	  ($MACRO{$1}{llx},$MACRO{$1}{lly}) = split(/\s+/,$2);
	  ($MACRO{$1}{urx},$MACRO{$1}{ury}) = split(/\s+/,$3);
	} elsif ($line =~ /^\s*END COMPONENTS/ ) {
	  $readComps = 0;
	}
      } #while
    } #elsif
      $line = <FPDEF>; $lineCount++; 
  } #while
  close(FPDEF);

  ## read fpdef and create graph
  foreach my $macro (keys %MACRO) {
    $mGL->add_vertex($macro);
    $mGR->add_vertex($macro);
    $MACRO{$macro}{curr} = $MACRO{$macro}{llx};
  }

  # create pesudo macros for Left and Right edge
  $mGL->add_vertex("M_L");
  $mGL->add_vertex("M_R");
  $mGR->add_vertex("M_L");
  $mGR->add_vertex("M_R");
  $MACRO{M_L}{min} = 0;
  $MACRO{M_R}{max} = 0;
  $MACRO{M_L}{curr} = 0;
  $MACRO{M_R}{curr} = $DIEAREA[2];
  $MACRO{M_L}{llx} = 0;
  $MACRO{M_L}{lly} = 0;
  $MACRO{M_L}{urx} = 0;
  $MACRO{M_L}{ury} = $DIEAREA[3];
  $MACRO{M_R}{llx} = $DIEAREA[2];
  $MACRO{M_R}{lly} = 0;
  $MACRO{M_R}{urx} = $DIEAREA[2];
  $MACRO{M_R}{ury} = $DIEAREA[3];

  #create Gx
  my @checky;
  foreach my $m (keys %MACRO) {
#    if (($m ne "M_L") && ($m ne "M_R")) {
      my $ylo = $MACRO{$m}{lly} + $eps;
      my $yhi = $MACRO{$m}{ury} - $eps;
      if ($ylo > $DIEAREA[1]) { push(@checky, $ylo);}
      if ($yhi < $DIEAREA[3]) { push(@checky, $yhi);}
#    } #if
  } #foreach

  my $yLast = -100;
  foreach my $y (sort {$a <=> $b} @checky) {
    if ($y != $yLast) {
      my %macroVld = ();
      my @macroSeq = ();
      foreach my $m (keys %MACRO) {
	if (($MACRO{$m}{lly}<$y) && ($MACRO{$m}{ury}>$y)) { push(@{$macroVld{$MACRO{$m}{llx}}},$m); }
      } #foreach
      foreach my $x (sort {$a <=> $b} keys %macroVld) { push(@macroSeq,@{$macroVld{$x}}); }
      for (my $i=0; $i<$#macroSeq; $i++) {
	my $sizeX = $MACRO{$macroSeq[$i]}{urx} - $MACRO{$macroSeq[$i]}{llx};
	if (!$mGL->has_edge($macroSeq[$i]  ,$macroSeq[$i+1])) {
	  $mGL->add_weighted_edge($macroSeq[$i]  ,$macroSeq[$i+1],$sizeX);
	}
	if (!$mGR->has_edge($macroSeq[$i+1],$macroSeq[$i])) {
	  $mGR->add_weighted_edge($macroSeq[$i+1],$macroSeq[$i]  ,$sizeX);
	}
      }
      $yLast = $y;
    }#if
  }#foreach


  &make_blockplacer_findMinX("M_R");
  &make_blockplacer_findMaxX("M_L");
  print "Done\n";


} # sub make_blockplacer_readFpdef

## ########################################################################
sub make_blockplacer_writeFpdef {

  open(FPDEFRD, $fpdef)           or &finish( "$! : $fpdef"   ,__LINE__);
  open(FPDEFWR, "> $fpdefout")    or &finish( "$! : $fpdefout",__LINE__);
  
  my $readComps = 0;
  my $line = <FPDEFRD>;
  my $lineCount = 0;
  while ($line) {
    chomp $line;
    if ($line =~ /^\s*COMPONENTS/ ) {
      $readComps = 1;
      print FPDEFWR "$line\n";
      while ($readComps) {
	$line = <FPDEFRD>; $lineCount++; 
	#read components
	if ($line =~ /^\s*([A-Za-z]\w*)\s+\(\s*(.*)\s*\)\s*\(\s*(.*)\s*\)\s*;/ ) {
	  print FPDEFWR "$1 ( $MACRO{$1}{p_llx} $MACRO{$1}{p_lly} ) ( $MACRO{$1}{p_urx} $MACRO{$1}{p_ury} ) ;\n";
	} else {
	  if ($line =~ /^\s*END COMPONENTS/ ) {
	    $readComps = 0;
	  } #if
	  print FPDEFWR "$line\n";
	} #else
      } #while
    } else {
      print FPDEFWR "$line\n";
    } #else
    $line = <FPDEFRD>; $lineCount++; 
  } #while
  close(FPDEFRD);
  close(FPDEFWR);
} #sub make_blockplacer_writeFpdef

########################################################################
sub make_blockplacer_genGx {

} # sub make_blockplacer_genGx
########################################################################
sub make_blockplacer_usage {
    print"\nmake_blockplacer Usage: make_blockplacer -fpdef <fpdef file> -output <output fpdef file> -dir <x/y> [-verbose -debug -norun -help]\n";
	# add details of each switch here
    return;
}
















