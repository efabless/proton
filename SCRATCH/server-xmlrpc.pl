#!/usr/local/bin/perl
# sum() server
  	
use strict;
use warnings;
use Frontier::Daemon;

my $d = Frontier::Daemon->new(
		      methods => {
                	  sum => \&sum,
				 },
		      LocalAddr => 'titan.benarasdesign.com',
		      LocalPort => 1080,
	      );
	
sub sum {
  my ($arg1, $arg2) = @_;

  return $arg1 + $arg2;
}

