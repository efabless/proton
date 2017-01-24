# Before `Build install' is performed this script should be runnable with
# `Build test'. After `Build install' it should work as `perl t/01load.t'
######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use GDS2;
$loaded = 1;
print "ok 1\n";

