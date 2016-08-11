#!/usr/bin/perl -w
# Testing sum()
  	
#  	use strict;
  	use warnings;
  	use Frontier::Client;
  	
  	#my $url  = "http://anshuman.benarasdesign.com:1201/RPC2";
  	my $url  = "http://titan.benarasdesign.com:1208/RPC2";
 
	my $client = Frontier::Client->new( url   => $url,
					    debug => 0,
				  );

  	my @args = (move,100,100);
	$client->call('rpcMouse', @args), "\n";
  	my @args = (str,"hello");
	$client->call('rpcKeyboard', @args), "\n";
  	my @args = (key,"Return");
	$client->call('rpcKeyboard', @args), "\n";
	$client->call('rpcQuit'), "\n";
