#!/usr/bin/perl -w
my $file = $ARGV[0];
my $temp_line = "";
open(READ,"$file");
open(WRITE,">output.txt");
$temp_line = <READ>;
$temp_line =~ s/^\s*\|\s*//;
my @node = (split(/\=\d\s+/,$temp_line));
$temp_line =~ s/(\w+)\=//g;
my @node_value = (split(/\s+/,$temp_line));
print WRITE "@node\n";
print WRITE "@node_value\n";
while(<READ>){
chomp();
if($_ =~ /\s*time\s*/){next;}
s/^\s*\|\s*//;
s/(\w+)\=//g;
my @node_value = (split(/\s+/,$_));
print WRITE "@node_value\n";
}
