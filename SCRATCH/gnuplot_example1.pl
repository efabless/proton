#!/usr/bin/perl
#use warnings;
#use strict;
use Tk;
use Tk::ROText;
use IPC::Open3;

# see http://en.wikipedia.org/wiki/Superformula
# for the formula

$|++;

my %var =(
  'a1'=> 1, 
  'b1'=> 1,        
  'm1'=> 8,
  'n1'=> 1,
  'n2'=> 1,
  'n3'=> 1,
);

my $stop = 0;
my $repeater;
my $running = 0;

my $mw = MainWindow->new;

my $tframe = $mw->Frame()->pack();
my $canvas = $tframe->Canvas(
                  -bg => 'white',
          -height =>500,
          -width =>500,
          )->pack(-side=>'left',-expand=>1,-fill=>'both');
my $tframe1 = $tframe->Frame()->pack(-side=>'right',-padx=>0);

my %scale;

for ('a1','b1','m1','n1','n2','n3'){
 
    my $tframea = $tframe1->Frame()->pack(-side=>'left',-padx=>0);

   $tframea->Label(-text => " $_   ")->pack(-side=>'top');
    
     $scale{$_} = $tframea->Scale(
      -from    => -100,
      -to    => 100,
      -length => 500,
      -orient    => 'vertical',
      -variable    => \$var{$_},
      -resolution => .01,
      -borderwidth =>0,
      -foreground => 'white',
      -background => 'lightslategrey',
      -troughcolor => 'powderblue',
     )->pack(-side => 'left', -padx=>0);
 }

my $text = $mw->Scrolled('ROText',
            -bg=>'white',
        -height =>5,
        -width => 45)
     ->pack( -fill => 'both', -expand => 1 );

tie(*STDOUT, 'Tk::Text', $text);

$text->tagConfigure( 'red', -foreground => 'red' );

my $pid = open3( \*gIN, \*gOUT, \*gERR, "/usr/bin/gnuplot" ) || die;
$mw->fileevent( \*gOUT, readable => \&read_out );
$mw->fileevent( \*gERR, readable => \&read_err );

#comment out the below line to get gnuplot's X11 display
#which is more efficient than the canvas plot
print gIN "set term tkcanvas perltk interactive\n";

my $bframe = $mw->Frame->pack();
my $startbut = $bframe->Button(
                    -text=>'Start',
                    -command=> \&start)->pack(-side=>'left');

my $stopbut = $bframe->Button(
                    -text=>'Stop',
                    -command=> sub{ $auto = 0;
              $repeater->cancel;
                  $running = 0;        
             })->pack(-side=>'left');

#must be last or get broken pipe error
tie(*STDERR, 'Tk::Text', $text);

$mw->update; 

MainLoop;

sub start{

my $string =<<"EOF";
reset
unset border
set clip
set polar
set xtics axis nomirror
set ytics axis nomirror
set zeroaxis
set trange [0:2*pi]
a=$var{'a1'}
b=$var{'b1'}
m=$var{'m1'}
n1=$var{'n1'}
n2=$var{'n2'}
n3=$var{'n3'}
butterfly(x) =  ( ( abs(( (cos(m*x)/4))/a)  )**n2 + ( abs(( (sin(m*x)/
+4))/b)  )**n3  )**(-1/n1)
set samples 800
set title "SuperFormula"
unset key
plot butterfly(t)
EOF
print gIN  "$string\n";


if( $running == 0){
 $repeater=$mw->repeat(1000,sub{ 
                     $running = 1;
                     &start;
        });
   }
}

sub read_out {
  my $buffer = <gOUT>;
  #  print $buffer,"\n";
  my $can = $canvas;
  eval($buffer);

}

sub read_err {
#    print "read_err()\n";
    my $num = sysread(gERR, my $buffer, 1024 );
#    print "sysread() got $num bytes:\n[$buffer]\n";
    $text->insert( 'end', $buffer, 'red' );
    $text->see('end');
}
