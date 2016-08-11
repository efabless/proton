#!/usr/local/bin/perl -w
# Change above line to point to your perl binary

use CGI ':standard';
use GD::Graph::lines;
use strict;

# Both the arrays should same number of entries.
my @data = (['Fall 01', 'Spr 01', 'Fall 02', 'Spr 02' ],
            [80, 90, 85, 75], 
            [76, 55, 75, 95],
            [66, 58, 92, 83]);

my $mygraph = GD::Graph::lines->new(600, 300);
$mygraph->set(
    x_label     => 'Semester',
    y_label     => 'Marks',
    title       => 'Grade report for a student',
    # Draw datasets in 'solid', 'dashed' and 'dotted-dashed' lines
    line_types  => [1, 2, 4],
    # Set the thickness of line
    line_width  => 2,
    # Set colors for datasets
    dclrs       => ['blue', 'green', 'cyan'],
) or warn $mygraph->error;

$mygraph->set_legend_font(GD::gdMediumBoldFont);
$mygraph->set_legend('Exam 1', 'Exam 2', 'Exam 3');
my $myimage = $mygraph->plot(\@data) or die $mygraph->error;

print "Content-type: image/png\n\n";
open(PICTURE, ">picture.png") or die("Cannot open file for writing");

# Make sure we are writing to a binary stream
binmode PICTURE;

# Convert the image to PNG and print it to the file PICTURE
print PICTURE $myimage->png;
#print PICTURE $myimage->jpeg;
close PICTURE;

#print $myimage->png;
