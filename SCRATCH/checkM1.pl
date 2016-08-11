#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;

my $noOfArguments = @ARGV; 
if($ARGV[0] eq "-h" || $ARGV[0] eq "-help" || $ARGV[0] eq "-HELP"){
  print "Usage : checkM1.pl\n";
  print "      : -def <input def file>\n";
  print "      : -layer <layerName>\n";
}else {
  my $def_file = "";
  my $layer = ""; 
  my $TWL = 0;
  for(my $i =0; $i<$noOfArguments;$i++){
    if($ARGV[$i] eq "-def"){$def_file = $ARGV[$i+1];}
    if($ARGV[$i] eq "-layer"){$layer = $ARGV[$i+1];}
  }#for
  open(READ,"$def_file");
  while(<READ>){
    chomp();
    if($_ =~ (/^\s*\+\s*ROUTED/) || (/^\s*\+\s*FIXED/) || (/^\s*\bNEW\b/)){
      $_ =~ s/^\s*\+\s*ROUTED\s*//;
      $_ =~ s/^\s*\+\s*FIXED\s*//; 
      $_ =~ s/^\s*NEW\s*//;
      my $routelayer = (split(/\s+/,$_))[0];
      if($routelayer =~ /$layer/i){
        my @routebbox = &xformNetSegToPathSeg($_);
        my $X_distance = $routebbox[2] - $routebbox[0];
        my $Y_distance = $routebbox[3] -$routebbox[1];
        my $total_distance = $X_distance + $Y_distance;
        $TWL = $TWL + $total_distance;
      }
    }
  }#while 
  print "Total wire length of given layer $layer is $TWL in dbu\n";
}#else
my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "script checkM1.pl took:",timestr($td),"\n";
#---------------------------------------------------------------------------------------------------------------#
sub xformNetSegToPathSeg {
  my $netSeg = $_[0];
  my $return_with_via = $_[1];
  my @routeBox = ();
  my $return_with_via_value = 0;
  if($return_with_via =~ /--via/){
    $return_with_via_value = 1;
  }else {
    $return_with_via_value = 0;
  }
  if ($netSeg =~ m/\( (\d+) (\d+) \) (\w+)/ ) {
    return($1,$2,$1,$2);
  }# if only via
  elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( (\d+) \* \) (\w+)/ ) {
    my $llx = $1;
    my $lly = $2;
    my $urx = $3;
    my $ury = $2;
    if($return_with_via_value == 1){
      my $via_llx = $urx; 
      my $via_lly = $lly; 
      return($llx,$lly,$urx,$ury,$via_llx,$via_lly);
    }else {
      return($llx,$lly,$urx,$ury);
    }
  }# if horizontal without extn with via
  elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( (\d+) \* (\d+) \) (\w)/ ) {
    my $llx = $1;
    my $lly = $2;
    my $urx = $3+$4;
    my $ury = $2;
    if($return_with_via_value == 1){
      my $via_llx = $urx; 
      my $via_lly = $lly; 
      return($llx,$lly,$urx,$ury,$via_llx,$via_lly);
    }else {
      return($llx,$lly,$urx,$ury);
    }
  }# if horizontal R-extn with via
  elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( (\d+) \* (\d+) \)/ ) {
    my $llx = $1;
    my $lly = $2;
    my $urx = $3+$4;
    my $ury = $2;
    return($llx,$lly,$urx,$ury);
  }# if horizontal R-extn without via
  elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( (\d+) \* \) (\w)/ ) {
    my $llx = $1-$3;
    my $lly = $2;
    my $urx = $4;
    my $ury = $2;
    if($return_with_via_value == 1){
      my $via_llx = $urx; 
      my $via_lly = $lly; 
      return($llx,$lly,$urx,$ury,$via_llx,$via_lly);
    }else {
      return($llx,$lly,$urx,$ury);
    }
  }# if horizontal L-extn with via
  elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( (\d+) \* \)/ ) {
    my $llx = $1-$3;
    my $lly = $2;
    my $urx = $4;
    my $ury = $2;
    return($llx,$lly,$urx,$ury);
  }# if horizontal L-extn without via
  elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( (\d+) \* (\d+) \)/ ) {
    my $llx = $1-$3;
    my $lly = $2;
    my $urx = $4+$5;
    my $ury = $2;
    return($llx,$lly,$urx,$ury);
  }# if horizontal L-extn and R-extn without via
  elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( (\d+) \* (\d+) \) (\w)/ ) {
    my $llx = $1-$3;
    my $lly = $2;
    my $urx = $4+$5;
    my $ury = $2;
    if($return_with_via_value == 1){
      my $via_llx = $urx; 
      my $via_lly = $lly; 
      return($llx,$lly,$urx,$ury,$via_llx,$via_lly);
    }else {
      return($llx,$lly,$urx,$ury);
    }
  }# if horizontal L-extn and R-extn with via
  elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( (\d+) \* \)/ ) {
    my $llx = $1;
    my $lly = $2;
    my $urx = $3;
    my $ury = $2;
    return($llx,$lly,$urx,$ury);
  }# if horizontal without extn without via
  elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( \* (\d+) \) (\w)/ ) {
    my $llx = $1;
    my $lly = $2;
    my $urx = $1;
    my $ury = $3;
    if($return_with_via_value == 1){
      my $via_llx = $llx; 
      my $via_lly = $ury; 
      return($llx,$lly,$urx,$ury,$via_llx,$via_lly);
    }else {
      return($llx,$lly,$urx,$ury);
    }
  }# if verical without extn with via
  elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( \* (\d+) (\d+) \) (\w)/ ) {
    my $llx = $1;
    my $lly = $2;
    my $urx = $1;
    my $ury = $3+$4;
    if($return_with_via_value == 1){
      my $via_llx = $llx; 
      my $via_lly = $ury; 
      return($llx,$lly,$urx,$ury,$via_llx,$via_lly);
    }else {
      return($llx,$lly,$urx,$ury);
    }
  }# if verical T-extn with via
  elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( \* (\d+) (\d+) \)/ ) {
    my $llx = $1;
    my $lly = $2;
    my $urx = $1;
    my $ury = $3+$4;
    return($llx,$lly,$urx,$ury);
  }# if verical T-extn without via
  elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( \* (\d+) \) (\w)/ ) {
    my $llx = $1;
    my $lly = $2-$3;
    my $urx = $1;
    my $ury = $4;
    if($return_with_via_value == 1){
      my $via_llx = $llx; 
      my $via_lly = $ury; 
      return($llx,$lly,$urx,$ury,$via_llx,$via_lly);
    }else {
      return($llx,$lly,$urx,$ury);
    }
  }# if verical B-extn with via
  elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( \* (\d+) \)/ ) {
    my $llx = $1;
    my $lly = $2-$3;
    my $urx = $1;
    my $ury = $4;
    return($llx,$lly,$urx,$ury);
  }# if verical B-extn without via
  elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( \* (\d+) (\d+) \)/ ) {
    my $llx = $1;
    my $lly = $2-$3;
    my $urx = $1;
    my $ury = $4+$5;
    return($llx,$lly,$urx,$ury);
  }# if verical B-extn and T-extn without via
  elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( \* (\d+) (\d+) \) (\w)/ ) {
    my $llx = $1;
    my $lly = $2-$3;
    my $urx = $1;
    my $ury = $4+$5;
    if($return_with_via_value == 1){
      my $via_llx = $llx; 
      my $via_lly = $ury; 
      return($llx,$lly,$urx,$ury,$via_llx,$via_lly);
    }else {
      return($llx,$lly,$urx,$ury);
    }
  }# if verical B-extn and T-extn with via
  elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( \* (\d+) \)/ ) {
    my $llx = $1;
    my $lly = $2;
    my $urx = $1;
    my $ury = $3;
    return($llx,$lly,$urx,$ury);
  }# if verical without extn without via
#--------------------- temporary code to support jspeed routing text -------------------------#
  elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( (\d+) (\d+) \)/ ) {
    if ( $1 == $3 ) {
      my $llx = $1;
      my $lly = $2;
      my $urx = $3;
      my $ury = $4;
      return($llx,$lly,$urx,$ury);
    }
    elsif ( $2 == $4 ) {
      my $llx = $1;
      my $lly = $2;
      my $urx = $3;
      my $ury = $4;
      return($llx,$lly,$urx,$ury);
    }
  }# if verical without extn without via
  elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( (\d+) (\d+) (\d+) \)/ ) {
    if($1 == $4){
      my $llx = $1;
      my $lly = $2-$3;
      my $urx = $4;
      my $ury = $5+$6;
      return($llx,$lly,$urx,$ury);
    }elsif($3 == $6){
      my $llx = $1-$3;
      my $lly = $2;
      my $urx = $4+$6;
      my $ury = $5;
      return($llx,$lly,$urx,$ury);
    }
  }# if verical B-extn and T-extn with via
  elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( (\d+) (\d+) (\d+) \) (\w)/ ) {
    if($1 == $4){
      my $llx = $1;
      my $lly = $2-$3;
      my $urx = $4;
      my $ury = $5+$6;
      if($return_with_via_value == 1){
        my $via_llx = $urx; 
        my $via_lly = $ury; 
        return($llx,$lly,$urx,$ury,$via_llx,$via_lly);
      }else {
        return($llx,$lly,$urx,$ury);
      }
    }elsif($3 == $6){
      my $llx = $1-$3;
      my $lly = $2;
      my $urx = $4+$6;
      my $ury = $5;
      if($return_with_via_value == 1){
        my $via_llx = $urx; 
        my $via_lly = $ury; 
        return($llx,$lly,$urx,$ury,$via_llx,$via_lly);
      }else {
        return($llx,$lly,$urx,$ury);
      }
    }
  }# if verical B-extn and T-extn with via
}#sub xformNetSegToPathSeg

