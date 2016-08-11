#!/usr/bin/perl -w
use strict;
use Tk;

my $mw = MainWindow->new();

my $canv = $mw->Canvas(-bg => 'lightsteelblue',
-relief => 'sunken',
-width => 550,
-height => 350)->pack(-expand => 1, -fill => 'both');

my $xtermWidth = 400;
my $xtermHeight = 300;

## this Frame is needed for including the xterm in Tk::Canvas
my $xtermContainer = $canv->Frame(-container => 1);
my $xtid = $xtermContainer->id();
# converting the id from HEX to decimal as xterm requires a decimal Id
my ($xtId) = sprintf hex $xtid;

my $dcontitem = $canv->createWindow(275,175,
-window => $xtermContainer,
-width => $xtermWidth+100,
-height => $xtermHeight,
-state => 'normal');

my $label = $canv->createText( 275,10,
-text => "Hide xterm",
);

$canv->Tk::bind("<Button-1>", \&hideShow);

my $width = $xtermWidth;
my $height = $xtermHeight;

$mw->Button(-text => "Exit", -command => [sub{Tk::exit}] )->pack( );

my $tl; #used to mask xterm
system("xterm -into $xtId &");


MainLoop();

sub hideShow {
if ($canv->itemcget($label, -text) =~ /Hide/) {
$canv->itemconfigure($label,
-fill => 'white',
-text => "Show xterm");

$tl = $mw->Toplevel(-use=>$xtId );
} else {
$canv->itemconfigure($label,
-fill => 'black',
-text => "Hide xterm");
$tl->withdraw;
}
}
