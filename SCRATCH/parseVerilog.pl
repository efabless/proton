#!/usr/bin/perl -w

use Hardware::Verilog::Parser;
$parser = new Hardware::Verilog::Parser;

$parser->Filename(@ARGV);
