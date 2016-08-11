#!/usr/bin/perl
 
use Net::SSH::Perl;
 
my $host = "ravi.lnx2.com";
my $user = "rajeevs";
my $pass = "hanuman";
 
#-- set up a new connection
my $ssh = Net::SSH::Perl->new($host,2);
#-- authenticate
$ssh->login($user, $pass);
#-- execute the command
my($stdout, $stderr, $exit) = $ssh->cmd("/home/rajeevs/Projects/proton/eqator -f t.tcl");
