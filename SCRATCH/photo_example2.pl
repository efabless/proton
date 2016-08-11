#!/usr/bin/perl
use warnings;
use strict;
use Tk;
use Tk::WinPhoto;
use Tk::JPEG;

my $mw = tkinit;

my $canv = $mw->Canvas(width => 300, height => 200)->pack();
# Create line inside the canvas  
$canv->create ('line',1, 1, 100, 100, -fill=>'red');

$canv->createRectangle(10,20,30,40, -fill=>'blue' );

my $fullbutton = $mw->Button(-text=>'Full Screen Capture',
                             -command => \&full_capture,
                            )->pack;

my $mainbutton = $mw->Button(-text=>'MainWindow Capture',
                             -command => \&mw_capture,
                            )->pack;

my $canvbutton = $mw->Button(-text=>'Canvas Capture',
                             -command => \&canv_capture,
                            )->pack;


MainLoop;

sub full_capture{

my @id = grep{$_ =~ 'Window id'} split("\n",`xwininfo -root`);
my @ids = split(' ',$id[0]);
(my $id) = grep{$_ =~ /0x/} @ids;

my $image = $mw->Photo(-format => 'Window',
#                    #    -data => oct($mw->id) 
#                    #    -data =>  oct('0xa00022') 
                          -data =>  oct($id)
                       );

my $pathname = './rootwindow.'.time.'.jpg';
$image->write($pathname, -format => 'JPEG');

}

######################################################### 
sub mw_capture{

my $image = $mw->Photo(-format => 'Window',
                        -data => oct($mw->id)
#                    #  -data =>  oct('0xa00022') 
                     #  -data =>  oct($id) 
                       );

my $pathname = './mainwindow.'.time.'.jpg';
$image->write($pathname, -format => 'JPEG');

}
########################################################## 

sub canv_capture{

my $image = $mw->Photo(-format => 'Window',
                        -data => oct($canv->id)
                       );

my $pathname = './canvas.'.time.'.jpg';
$image->write($pathname, -format => 'JPEG');

}
############################################################## 
