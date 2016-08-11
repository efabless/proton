#!/usr/bin/perl -w
use strict;
use POSIX qw(ceil floor);
use Graph::Directed;
#use Graph::Layouter qw(layout);
#use Graph::Renderer;
#use GraphViz;
use List::Util qw[min max];
use Getopt::Long;
use Benchmark;

my ($fpdef, $fpdefout, $dir, $genGx);
my ($help, $debug, $verbose) = (0,0,0);
my ($hcellSx, $hcellSy) = (1,1);
my ($hcellMaxX, $hcellMaxY) = (0,0);
my ($maxMove, $maxIter) = (100,100);

my @MACRO;
my %MACRO;
my %HCELL;
my @DIEAREA;
my $eps = 0.1;


&make_blockplacer(@ARGV);

########################################################################
sub make_blockplacer {
  my $t0 = new Benchmark;

  # initialize vars
  my (@args) = @_;
  ($fpdef, $fpdefout, $dir, $genGx) = ();
  ($help, $debug, $verbose) = (0,0,0);
  @MACRO = ();
  %MACRO = ();
  %HCELL = ();
  @DIEAREA = ();


  $help = 0;
  &make_blockplacer_readArgs(@args);
  if ($help) {
    &make_blockplacer_usage();
  } else {
    &make_blockplacer_readFpdef;
    &make_blockplacer_hcellGrid;
    &make_blockplacer_place;
    &make_blockplacer_writeFpdef;
  } #if...else

  &finish();
  my $t1 = new Benchmark;
  my $td = timediff($t1, $t0);
  print "make_blockplacer took:",timestr($td),"\n";
} #sub make_blockplacer

########################################################################
sub make_blockplacer_hcellGrid {
  # initialize %HCELL
  $hcellMaxX = floor(($DIEAREA[2]-$eps)/$hcellSx);
  $hcellMaxY = floor(($DIEAREA[3]-$eps)/$hcellSy);
  for (my $hx = 0; $hx <= $hcellMaxX; $hx++) {
    for (my $hy = 0; $hy <= $hcellMaxY; $hy++) {
      $HCELL{$hx}{$hy}{occupancy} = 0;
    } #for
  } #for
  # populate macros
  foreach my $macro (keys %MACRO) {
    $MACRO{$macro}{h_llx} = floor($MACRO{$macro}{llx}/$hcellSx);
    $MACRO{$macro}{h_lly} = floor($MACRO{$macro}{lly}/$hcellSy);
    $MACRO{$macro}{h_urx} = floor($MACRO{$macro}{urx}/$hcellSx);
    $MACRO{$macro}{h_ury} = floor($MACRO{$macro}{ury}/$hcellSy);
    for (my $hx = $MACRO{$macro}{h_llx}; $hx <= $MACRO{$macro}{h_urx}; $hx++) {
      for (my $hy = $MACRO{$macro}{h_lly}; $hy <= $MACRO{$macro}{h_ury}; $hy++) {
        push(@{$HCELL{$hx}{$hy}{macros}},$macro); 
        $HCELL{$hx}{$hy}{occupancy}++;
      } #for
    } # for
  } #foreach
  #print "test";

} #sub make_blockplacer_hcellGrid
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
print "Finished\n";
} #sub finish

########################################################################
sub make_blockplacer_place {
  my $moveCnt = 0;
  my $solved = 0;
  my $iterCnt = 0;
  my $move = 0;
  my @dirOrder = ("W","E","N","S");
  while (!$solved && ($moveCnt < $maxMove) && ($iterCnt < $maxIter)) {
    $iterCnt++;
    #find max overlapping hcell
    my ($maxX, $maxY, $occupancy) = &make_blockplacer_maxOverlapHcell;
    if ($occupancy == 0) {$solved = 1; last;}
    foreach my $macro (@{$HCELL{$maxX}{$maxY}{macros}}) {
      foreach my $dir (@dirOrder) {
        $move = make_blockplacer_movePossible($macro,$dir);
        print "Iter:$iterCnt x:$maxX y:$maxY macro:$macro dir:$dir move:$move\n";
        if ($move) {
	  &make_blockplacer_move($macro,"$dir",1); last; 
	}; 
      } # foreach dir
      if ($move) {last;}
    } #foreach
  } #while
  print"test";
} # sub make_blockplacer_place
########################################################################
sub make_blockplacer_maxOverlapHcell {
  my ($maxX, $maxY, $occupancy) = (0,0,-1);
  for (my $hx = 0; $hx <= $hcellMaxX; $hx++) {
    for (my $hy = 0; $hy <= $hcellMaxY; $hy++) {
      if ($HCELL{$hx}{$hy}{occupancy} > $occupancy) {
        ($maxX, $maxY, $occupancy) = ($hx, $hy, $HCELL{$hx}{$hy}{occupancy});
      } #if
    } #for
  } #for
  return($maxX,$maxY,$occupancy);
} # sub make_blockplacer_maxOverlapHcell

########################################################################
sub make_blockplacer_findMacroCost {
  my ($hx, $hy) = @_;
  foreach my $macro (@{$HCELL{$hx}{$hy}{macros}}) {
    
  } #foreach
} # sub make_blockplacer_maxOverlapHcell

########################################################################
sub make_blockplacer_movePossible {
  # is move possible for a macro in dir direction 
  my ($macro, $dir) = @_;
  my $possible = 1;
  my $h_llx = $MACRO{$macro}{h_llx};
  my $h_urx = $MACRO{$macro}{h_urx};
  my $h_lly = $MACRO{$macro}{h_lly};
  my $h_ury = $MACRO{$macro}{h_ury};
  if ($dir eq "W") {
    if ($h_llx <= 0) {$possible = 0;} else {
      for (my $y = $h_lly; $y <= $h_ury; $y++) {
        if ($HCELL{$h_llx-1}{$y}{occupancy} > 0) {$possible = 0; last;}
      } #for
    } #if
  } elsif ($dir eq "E") {
    if ($h_urx >= $hcellMaxX) {$possible = 0;} else {
      for (my $y = $h_lly; $y <= $h_ury; $y++) {
        if ($HCELL{$h_urx+1}{$y}{occupancy} > 0) {$possible = 0; last;}
      } #for
    } #if
  } elsif ($dir eq "N") {
    if ($h_ury >= $hcellMaxY) {$possible = 0;} else {
      for (my $x = $h_llx; $x <= $h_urx; $x++) {
        if ($HCELL{$x}{$h_ury+1}{occupancy} > 0) {$possible = 0; last;}
      } #for
    } #if
  } elsif ($dir eq "S") {
    if ($h_lly <= 0) {$possible = 0;} else {
      for (my $x = $h_llx; $x <= $h_urx; $x++) {
        if ($HCELL{$x}{$h_lly-1}{occupancy} > 0) {$possible = 0; last;}
      } #for
    } #if
  }
  return($possible);
} #sub 

########################################################################
sub make_blockplacer_move {
  # move macro in dir direction by distance dist
  my ($macro, $dir, $dist) = @_;
  if ($dir eq "W") {
    my $new_llx = $MACRO{$macro}{llx}-($dist*$hcellSx);
    my $new_urx = $MACRO{$macro}{urx}-($dist*$hcellSx);
    $MACRO{$macro}{llx} = $new_llx;
    $MACRO{$macro}{urx} = $new_urx;
  } elsif ($dir eq "E") {
    my $new_llx = $MACRO{$macro}{llx}+($dist*$hcellSx);
    my $new_urx = $MACRO{$macro}{urx}+($dist*$hcellSx);
    $MACRO{$macro}{llx} = $new_llx;
    $MACRO{$macro}{urx} = $new_urx;
  } elsif ($dir eq "N") {
    my $new_lly = $MACRO{$macro}{lly}+($dist*$hcellSy);
    my $new_ury = $MACRO{$macro}{ury}+($dist*$hcellSy);
    $MACRO{$macro}{lly} = $new_lly;
    $MACRO{$macro}{ury} = $new_ury;
  } elsif ($dir eq "S") {
    my $new_lly = $MACRO{$macro}{lly}-($dist*$hcellSy);
    my $new_ury = $MACRO{$macro}{ury}-($dist*$hcellSy);
    $MACRO{$macro}{lly} = $new_lly;
    $MACRO{$macro}{ury} = $new_ury;
  }
  &make_blockplacer_hcellGrid;
} #sub 

########################################################################
sub make_blockplacer_findMaxX {

} #sub 

########################################################################
sub make_blockplacer_sortHashValueCurr {
   $MACRO{$a}{curr} <=> $MACRO{$b}{curr};
} #sub make_blockplacer_sortHashValueCurr

########################################################################
sub make_blockplacer_readFpdef {

  open(FPDEF, $fpdef)    or &finish( "$! : $fpdef",__LINE__);

  my $readComps = 0;
  my $line = <FPDEF>;
  my $lineCount = 0;
  while ($line) {
    chomp $line;
    if ($line =~ /^\s*DIEAREA\s*\(\s*(.*)\s*\)\s*;/ ) {
      #print "Found $1\n";
      my @DIEAREA1 = split(/\s+/,$1);
      @DIEAREA = ($DIEAREA1[0], $DIEAREA1[1], $DIEAREA1[4], $DIEAREA1[5]);
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
	  print FPDEFWR "$1 ( $MACRO{$1}{llx} $MACRO{$1}{lly} ) ( $MACRO{$1}{urx} $MACRO{$1}{ury} ) ;\n";
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
sub XXX {

} # sub XXX
########################################################################
sub make_blockplacer_usage {
    print"\nmake_blockplacer Usage: make_blockplacer -fpdef <fpdef file> -output <output fpdef file> -dir <x/y> [-verbose -debug -norun -help]\n";
	# add details of each switch here
    return;
}
















