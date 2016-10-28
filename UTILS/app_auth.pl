#!/usr/bin/perl
use Frontier::Client;
use Term::ReadKey;
use Digest::MD5 'md5_hex';
use XML::Simple;
use XML::SAX::PurePerl;
use Data::Dumper;
#use LWP::UserAgent;
#'#perl2exe_exclude'; #added to hide perl2exe warning message but not working

$appName = 'test_app';
my $secretFile = $ENV{"HOME"}."/silverline_secret";

#$server_url = "http://$host:$port/RPC2";
############# if server is proton.silverline-da.com ##############
#my $host = "proton.silverline-da.com";
#my $port = 80;
#my $server_url = "http://$host:$port/drupal/xmlrpc.php";
############# if server is apps.silverline-da.com ##############
my $host = "apps.silverline-da.com";
my $port = 443;
my $server_url = "https://$host:$port/xmlrpc.php";
##################################################################

$server = Frontier::Client->new(url => $server_url);

my $userKey = 0;
my $passKey = 0;
my $password = "";
$userName = "";

if(-e $secretFile){
   open(READ, $secretFile); 
   while(<READ>){
     chomp($_);
     if($_ =~ /^user:/){
        $userName = (split(/\:/, $_))[1];
     }
     if($_ =~ /^passwd:/){
        $password = (split(/\:/, $_))[1];
     }
   }
   close(READ);
   
   my $auth_result = $server->call('authenticate', $userName,$password);
   my $xml = new XML::Simple;
   my $data = $xml->XMLin("$auth_result");
   if($data->{status} ne 'ok'){
      print $data->{message}."\n";
      exit;
   }
}else{
   my $charCnt = 0;
   print "\nPlease input your username: ";
   # Start reading the keys 
   ReadMode(4); #Disable the control keys
   while(ord($userKey = ReadKey(0)) != 10){
     # This will continue until the Enter key is pressed (decimal value of 10) 
     # For all value of ord($userKey) see http://www.asciitable.com/
     if(ord($userKey) == 127 || ord($userKey) == 8) {
        # DEL/Backspace was pressed
        #1. Remove the last char from the userName
        chop($userName);
        #2 move the cursor back by one, print a blank character, move the cursor back by one
        if($charCnt > 0){ 
           print "\b \b";
           $charCnt--;
        }
     }elsif(ord($userKey) < 32) {
        # Do nothing with these control characters
     }else {
        $userName = $userName.$userKey;
        #print "*(".ord($userKey).")";
        print "$userKey";
        $charCnt++;
     }
   }
   ReadMode(0); #Reset the terminal once we are done
   
   $charCnt = 0;
   print "\nPlease input your password: ";
   # Start reading the keys 
   ReadMode(4); #Disable the control keys
   while(ord($passKey = ReadKey(0)) != 10){
     # This will continue until the Enter key is pressed (decimal value of 10) 
     # For all value of ord($passKey) see http://www.asciitable.com/
     if(ord($passKey) == 127 || ord($passKey) == 8) {
        # DEL/Backspace was pressed
        #1. Remove the last char from the password
        chop($password);
        #2 move the cursor back by one, print a blank character, move the cursor back by one
        if($charCnt > 0){ 
           print "\b \b";
           $charCnt--;
        }
     }elsif(ord($passKey) < 32) {
        # Do nothing with these control characters
     }else {
        $password = $password.$passKey;
        #print "*(".ord($passKey).")";
        print "*";
        $charCnt++;
     }
   }
   ReadMode(0); #Reset the terminal once we are done
   $password = md5_hex($password);
   print "\n";
   my $auth_result = $server->call('authenticate', $userName,$password);
   my $xml = new XML::Simple;
   my $data = $xml->XMLin("$auth_result");
   if($data->{status} ne 'ok'){
      print $data->{message}."\n";
      exit;
   }
   open (WRITE, ">$secretFile")|| die("Cannot open file for writing");
   if(-w $secretFile ){
      print WRITE "user:$userName\n"; 
      print WRITE "passwd:$password\n"; 
   }
   close(WRITE);
}

my $nodeAddress = md5_hex(`/sbin/ifconfig eth0 | grep 'HWaddr' | awk '{ print \$5}' | tr -d '\n'`);
#my $ipAddress = md5_hex(`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print \$1}'`);
#my $ipAddress = md5_hex(`curl -s http://ifconfig.me | tr -d '\n'`);
my $ipAddress = md5_hex(`wget -qO- ifconfig.me/ip | tr -d '\n'`);
my $token_result = $server->call('request_token', $userName,$appName,$nodeAddress,$ipAddress);
my $xml = new XML::Simple;
my $data = $xml->XMLin("$token_result");
if($data->{app_found} eq 'No'){
   print "WRAN: This is not a silverline app ..\n";
   exit;
}
if($data->{access_time}->{status} ne 'ok'){
   print "WRAN: Your access time has been finished ... ".$data->{access_time}->{remaining_time}."\n";
   exit;
}else{
   print "You have access time : ".$data->{access_time}->{remaining_time}."\n";
}

if($data->{app_status} ne 'enable'){
   print "WRAN: This App is not enabled for you...\n";
   exit;
}

if($data->{mac_lock}->{status} ne 'ok'){
   print "WRAN: App can not run on this machine ....\n";
   #print "This App is  ".$data->{mac_lock}->{type}."\n";
   #print "Mac address is ".$data->{mac_lock}->{address}."\n";
   exit;
}

$start_time = time;
my $start_time_result = $server->call('start_time', $userName,$appName,$start_time);
$xml = new XML::Simple;
$data = $xml->XMLin("$start_time_result");
$run_count = $data->{app_run_count};
#print Dumper($data);

######################## put script here ###########################

####################################################################
#sleep(3);
my $end_time = time;
my $time_diff = $end_time - $start_time;
my $end_time_result = $server->call('end_time', $userName,$appName,int($run_count),$end_time,$time_diff);
print "App run time is: $time_diff\n";
