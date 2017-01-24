# Change 1..1 below to 1..last_test_to_print .
BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 2\n" unless $loaded;}
use GDS2;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict;
sub ok
{
    my ($n, $result, @info) = @_;
    if ($result) {
        print "ok $n\n";
        unlink "test.gds";
    }
    else {
        print "not ok $n\n";
        print STDERR " ERROR: @info\n" if @info;
    }
}

my $gds2File = new GDS2(-fileName=>'>test.gds');
my $G_epsilon = $gds2File -> getG_epsilon;
my $G_fltLen = $gds2File -> getG_fltLen;
print STDERR "\n Note: your perl appears to be able to use an epsilon of $G_epsilon and fltLen of $G_fltLen\n";
my $isLittleEndian = $gds2File -> endianness;
print STDERR " Note: your perl appears to run ".($isLittleEndian ? "littleEndian" : "bigEndian")."\n";
$gds2File -> printInitLib(-name=>'testlib');
$gds2File -> printBgnstr(-name=>'test');
$gds2File -> printPath(
                -layer=>6,
                -pathType=>0,
                -width=>2.4,
                -xy=>[0,0, 10.5,0, 10.5,3.3],
             );

$gds2File -> printSref(
                -name=>'contact',
                -xy=>[4,5.5],
             );

# Aref xyList: 1st coord: origin, 2nd coord: X of col * xSpacing + origin, 3rd coord: Y of row * ySpacing + origin
# see GDS2 pod for more information
$gds2File -> printAref(
                -name=>'contact',
                -columns=>2,
                -rows=>3,
                -xy=>[0,0, 10,0, 0,15],
             );
$gds2File -> printEndstr;
$gds2File -> printBgnstr(-name => 'contact');
$gds2File -> printBoundary(
                -layer=>10,
                -xy=>[0,0, 1,0, 1,1, 0,1],
             );
$gds2File -> printEndstr;
$gds2File -> printEndlib();
$gds2File -> close();

ok 2,(stat("test.gds"))[7] == 362, 'Size of created test.gds looks wrong.';

