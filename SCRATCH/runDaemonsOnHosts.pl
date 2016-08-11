#!/usr/bin/perl
if ( @ARGV < 2 || $ARGV[0] eq '-h' ) {
     print "This execuatable launches daemons on master and slave machines\n";
     print "it can only be used from within proton platform! un-authorized access is strictly prohibited\n";
     print "please contact your support AE or email at support\@benarasdesign.com for help\n";
                                      }
else {
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

my $host = $ARGV[0];
my $user = $ARGV[1];
my $pass = $ARGV[2];
my $path2reportDaemon  = $ARGV[3];
my $masterMac = $ARGV[4];

print "Starting daemon $path2reportDaemon on $host reporting status to $masterMac\n";
#-- set up a new connection
my $ssh = Net::SSH::Perl->new($host,1);
#-- authenticate
$ssh->login($user, $pass);
#-- execute the command
my($stdout, $stderr, $exit) = $ssh->cmd("$path2reportDaemon $masterMac &");
$ssh->sock;
exit;
     }
