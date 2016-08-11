#!/usr/bin/perl
my $numArg = @ARGV;
my $gdsFile = "";

if($ARGV[0] eq '-help' || $ARGV[0] eq '-HELP' || $ARGV[0] eq '-h' || $ARGV[0] eq 'H'){
   print "Usage:  ./gdsViewer -f <gds file>\n";
   exit;
}

for(my $i=0; $i<$numArg; $i++){
    if($ARGV[$i] eq '-f'){$gdsFile = $ARGV[$i+1];}
}

###############  These two packages are most important #############
##perl2exe_include Tk::Bitmap ;
###perl2exe_exclude utf8_heavy.pl;
## for rpc need switch
#use XML::SAX::PurePerl ; 
####################################################################
#use Cwd;
#use Benchmark;
#use List::Util qw[min max];
#use Tk;
#use Tk::Widget;
#use Tk::Pane;
#use Tk::Entry;
#use Tk::Frame;
#use Tk::Scrollbar;
#use Tk::Checkbutton;
#use Tk::Radiobutton;
#use Tk::DummyEncode;
#use Tk::BrowseEntry;
#use Tk::ROText;
#use Tk::Photo;
#use Tk::WorldCanvas;
#use Tk::Optionmenu;
#use Tk::Balloon;
#use Tk::Adjuster;

###################################################################
#use GDS2;
#use Math::Clipper ':all';
#use Math::Polygon;
#use Math::Polygon::Calc;
#use Math::Polygon::Transform;
#use XML::Simple;

###################################################################

my $BEEHOME = $ENV{SLVR_HOME};
if($BEEHOME eq ""){
   print "WARN: Please set your 'SLVR_HOME'....\n";
   exit;
}

require "${BEEHOME}/DB/make_GDS_GlobalVariable_package";
require "${BEEHOME}/DB/make_GDS_package";
require "${BEEHOME}/read_gds_file";

################# setting global values ############
$GLOBAL = Global::new();
$GDS_INFO_ALREADY = GDS::new();

#&read_lef(-lef, 'test/tsmc18_4lm.lef', -tech, also);
#&read_def(-def, 'test/s5378.def', '--all');
&read_gds(-gds, 'top.gds');



