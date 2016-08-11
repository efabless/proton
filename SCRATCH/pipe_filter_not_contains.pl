#!/usr/bin/perl -w

while (<>) 
{
chomp();
if ( !($_ =~ /Re/) ) { print "$_\n"; }
}

