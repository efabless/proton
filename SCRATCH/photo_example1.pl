#!/usr/local/bin/perl -w
use Tk;
#use Tk::widgets qw/JPEG PNG TIFF/;
use Tk::widgets qw/PNG/;
use strict;

my $mw = MainWindow->new;
my $column = 0;

foreach (
        [qw/Photo  png /],
        ) {

    my $image_type = shift @$_;
    my $f = $mw->Frame->grid(-row => 0, -column => $column++, -sticky => 'n');
    my $l = $f->Label(-text => $image_type, -foreground => 'blue')->grid;

    while (my $image_format = shift @$_) {
        my $image = $mw->$image_type(-file => "picture.${image_format}");
        $f->Label(-image => $image)->grid;
        $f->Label(-text  => $image_format)->grid;
    }

} # forend all image types

MainLoop;
