#!/usr/bin/perl -w

$x=$ARGV[3];
$y=$ARGV[4];
$t=$ARGV[2];
if ($t eq "move") { system("xte -x $ARGV[0]:$ARGV[1] 'mousemove $x $y'"); }
if ($t eq "click") { system("xte -x $ARGV[0]:$ARGV[1] 'mouseclick 1'"); }
system("xwd -display $ARGV[0]:$ARGV[1] -out test.xwd -root");
system("xwud -in test.xwd");
