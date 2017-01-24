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
        print "# @info\n" if @info;
    }
}

my $gds2File = new GDS2(-fileName=>'>test.gds');
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
$gds2File -> printAref(
                -name=>'contact',
                -columns=>2,
                -rows=>3,
                -xy=>[0,0],
             );
$gds2File -> printEndstr;
$gds2File -> printBgnstr(-name => 'contact');
$gds2File -> printBoundary(
                -layer=>10,
                -xy=>[0,0, 1,0, 1,1, 0,1],
             );
$gds2File -> printEndstr;
$gds2File -> printEndlib();
$gds2File -> close(-pad=>2048);
ok 2,(stat("test.gds"))[7] == 2048, 'Size of test.gds looks wrong.';

