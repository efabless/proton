#!/usr/bin/perl -w

$key=$ARGV[3];
$t=$ARGV[2];
if ( $t eq "str" ) {
@keys=split(//, $key);
foreach $k ( @keys ) { system("xte -x $ARGV[0]:$ARGV[1] 'key $k'"); }
                   }
if ( $t eq "key" ) {
system("xte -x $ARGV[0]:$ARGV[1] 'key $key'");
                   }
system("xwd -display $ARGV[0]:$ARGV[1] -out test.xwd -root");
system("xwud -in test.xwd");
