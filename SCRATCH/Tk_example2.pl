#!/usr/bin/perl
use warnings;
use strict;
use Tk;

my $dx;
my $dy;

my $mw = MainWindow->new;
$mw->geometry("700x600");

my $canvas = $mw->Canvas(-width => 700, -height => 565,
                -bg => 'black',
        -borderwidth => 3, 
        -relief => 'sunken',
           )->pack;

my $closebutton = $mw->Button(-text => 'Exit', -command => sub{Tk::exit(0)})
               ->pack; 

my $dragster = $canvas->createRectangle(0, 20, 50, 75, 
                             -fill => 'red',
                 -tags => ['move'],
                 
                 );

$canvas->bind('move', '<1>', sub {&mobileStart();});
$canvas->bind('move', '<B1-Motion>', sub {&mobileMove();});
$canvas->bind('move', '<ButtonRelease>', sub {&mobileStop();});

MainLoop;

sub mobileStart {
      my $ev = $canvas->XEvent;
      ($dx, $dy) = (0 - $ev->x, 0 - $ev->y);
      $canvas->raise('current');
      print "START MOVE->  $dx  $dy\n";
}


sub mobileMove {
      my $ev = $canvas->XEvent;
      $canvas->move('current', $ev->x + $dx, $ev->y +$dy);
      ($dx, $dy) = (0 - $ev->x, 0 - $ev->y);
      print "MOVING->  $dx  $dy\n";
      my $color = $canvas->itemcget($dragster,'-fill');
      print "color -> $color\n";
      
      #or use bbox here for odd shapes.. bounding box
      my @coords = $canvas->coords($dragster);
      print "coords-> @coords\n";
     
}


sub mobileStop{&mobileMove;}
