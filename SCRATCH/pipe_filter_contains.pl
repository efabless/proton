#!/usr/bin/perl -w

while (<>) 
{
chomp();
if ( $_ =~ /place/ ) { print "$_\n"; }
}

