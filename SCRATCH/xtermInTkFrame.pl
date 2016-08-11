#!/usr/bin/perl
use strict;
use Tk;

my $mw = MainWindow->new( -bg => 'white' );

my $frame1 = $mw->Frame(
-height => 30,
-bg => 'lightblue',
)->pack( -fill => 'x', -side => 'top' );

my $frame;

my $button = $frame1->Button(
-text => 'Open window',
-command => sub { open_w($frame) },
)->pack;

$frame = $mw->Frame(
-container => 1,
-bg => 'white',
)->pack( -fill => 'y', -side => 'left' );

MainLoop();

sub open_w {
my ($f) = @_;
my $id = sprintf hex $f->id;
my $t = $mw->Toplevel( -use => $id );
system("xterm -into $id &");
}

