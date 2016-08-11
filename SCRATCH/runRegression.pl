#!/usr/bin/perl

use  VMS::Filespec;
use  Net::SSH::Perl::Cipher::DES3;
use  Net::SSH::Perl::Key::DSA;
use  Net::SSH::Perl::Auth::PublicKey;
use  Net::SSH::Perl::Auth::Password;
use  Math::BigInt;
use  Math::BigInt::FastCalc;
use  File::Spec;
use  File::Spec::VMS;
use  Net::SSH::Perl::Util;
use  Net::SSH::Perl::Util::Hosts;
use  Net::SSH::Perl::Util::Term;
use  Net::SSH::Perl::SSH1;
use  Net::SSH::Perl::SSH2;
use  Net::SSH::Perl::Util::SSH1MP;
use  Net::SSH::Perl::Util::SSH2MP;
use  Net::SSH::Perl::Util::Authfile;
use  Net::SSH::Perl::Util::RSA;
use  Net::SSH::Perl::Util::SSH1Misc;
use  Net::SSH::Perl;
 
my $SQLDB ="";
my $SQLU = "";
my $SQLP = "";
my $noOfArguments = @ARGV;
print "$noOfArguments\n";
if($_[0] eq "-h" || $noOfArguments < 6)  {
        print "Usage :  tesLauncher\n";
        print "                       -host <hostname>\n";
        print "                       -luser <username which will launch qa jobs>\n";
        print "                       -lpasswd <password>\n";
        print "                       -path <path>\n";
        print "                       <-debug>\n";

  }
  else {
  for(my $i = 0; $i < $noOfArguments; $i++){
  if($ARGV[$i] eq "-host"){ $host = $ARGV[$i+1]; }
  if($ARGV[$i] eq "-luser"){ $user = $ARGV[$i+1]; }
  if($ARGV[$i] eq "-lpasswd"){ $pass = $ARGV[$i+1]; }
  if($ARGV[$i] eq "-path"){ $path = $ARGV[$i+1]; }
                                           }#for all arguments

print "INFO-launcher : HOST->$host USER->$user Dir->$path ...\n"; 
#-- set up a new connection
print "INFO-launcher : Logging in to $host as $user\n";
my $ssh = Net::SSH::Perl->new($host,1);
#-- authenticate
$ssh->login($user, $pass);
#-- execute the command
print "INFO-launcher : changing directory to $path\n";
print "INFO-launcher : Executing job on $host\n";
my($stdout, $stderr, $exit) = $ssh->cmd("cd $path ; make");
exit;
       }#if correct arguments
