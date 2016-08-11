#!/usr/bin/perl -w

$fileType = "UND" ;

my $fileName = $ARGV[0];
if ( $fileName =~ /\.lef/ ) { $fileType = "LEF"; }
if ( $fileName =~ /\.def/ ) { $fileType = "DEF"; }
if ( $fileName =~ /\.vg/ ) { $fileType = "Verilog"; }
if ( $fileName =~ /\.gv/ ) { $fileType = "Verilog"; }
if ( $fileName =~ /\.v/ ) { $fileType = "Rtl"; }
if ( $fileName =~ /\.rtl/ ) { $fileType = "Rtl"; }

return($fileType);
