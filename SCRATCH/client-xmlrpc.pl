#!/usr/bin/perl -w
# Testing sum()
  	
#  	use strict;
  	use warnings;
  	use Frontier::Client;
  	
  	#my $url  = "http://anshuman.benarasdesign.com:1201/RPC2";
  	my $url  = "http://titan.benarasdesign.com:1080/RPC2";
  	my @args = (2,5);
 
	my $client = Frontier::Client->new( url   => $url,
					    debug => 0,
				  );

	print "$args[0] + $args[1] = ", $client->call('sum', @args), "\n";
