#!/usr/local/bin/perl -w
# Change above line to point to your perl binary

use CGI ':standard';
use GD::Graph::bars;
use strict;

# Both the arrays should same number of entries.
my @data = (["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug",
             "Sep", "Oct", "Nov", "Dec"],
            [23, 5, 2, 20, 11, 33, 7, 31, 77, 18, 65, 52]);

my $mygraph = GD::Graph::bars->new(500, 300);
$mygraph->set(
    x_label     => 'Month',
    y_label     => 'Number of Hits',
    title       => 'Number of Hits in Each Month in 2002',
) or warn $mygraph->error;

my $myimage = $mygraph->plot(\@data) or die $mygraph->error;

print "Content-type: image/png\n\n";
open(PICTURE, ">picture.png") or die("Cannot open file for writing");

# Make sure we are writing to a binary stream
binmode PICTURE;

# Convert the image to PNG and print it to the file PICTURE
#print PICTURE $im->png;
print PICTURE $myimage->jpeg;
close PICTURE;

