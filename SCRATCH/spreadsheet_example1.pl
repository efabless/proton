#!/bin/perl -w 

use Spreadsheet::Read;

my $ref = ReadData('test.csv');
my @colB = @{$ref->[1]{cell}[4] };
print join ", " , @colB;
print "\n";
