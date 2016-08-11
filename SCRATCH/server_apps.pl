#!/usr/bin/perl -w

use Switch;
use Getopt::Long ;
use Proc::ProcessTable ;

my (@args) =  @ARGV;
my $args = join(' ',@args);
if (!defined($args)) {
      $args = "";
}
my $hostname = "";
my $dirname = "/uploads/";
my $appname = "tool";
my $parseResult = Getopt::Long::GetOptionsFromString($args ,
                                                       # read args here
                                                       "host=s"    => \$hostname,
                                                       "port=s"   => \$port,
                                                       "tool=s"        => \$appname,
                                                       "dir=s"        => \$dirname,
                                                       "-verbose"    => \$verbose,
                                                       "-help"    => \$help,
                                                      );

$displaynum = $port;
print "$hostname : $port : $displaynum\n";

#------- subroutines -------#
sub communicate_keyboard { 
# ---- expecting str/key , keyboard inputs
print "got a call from client : keyboard :\n";
my @args = @_;
my $key=$args[1];
my $t=$args[0];
if ( $t eq "str" ) {
@keys=split(//, $key);
foreach $k ( @keys ) { system("xte -x $hostname:$displaynum 'key $k'"); }
                   }
if ( $t eq "key" ) {
system("xte -x $hostname:$displaynum 'key $key'");
                   }
system("xwd -display $hostname:$displaynum -root |  convert xwd:- ${dirname}/images/port$displaynum.png");

}# sub communicate_keyboard

sub communicate_mouse {
print "got a call from client : mouse :\n";
my @args = @_;
print "@args\n";
$x=$args[1];
$y=$args[2];
$t=$args[0];
print "$t\n";
if ($t eq "move") { system("xte -x $hostname:$displaynum 'mousemove $x $y'"); print "mouse-move\n";}
if ($t eq "click") { system("xte -x $hostname:$displaynum 'mouseclick 1'"); }
system("xwd -display $hostname:$displaynum -root | convert xwd:- ${dirname}/images/port$displaynum.png");

}#sub communicate_mouse




sub testFlexXML {
my $noOfArguments = @_;
#----------------- Defaults --------------------#

if ($noOfArguments < 1 || $_[0] eq '-h') { print "Usage : test_flex_xml\n";
  print "          <sub name, e.g., getLefPins>\n";
  print "          <args, e.g., macro_name>\n";
  return;
}

my $cmd = shift;
my $arg_str = join(':', @_);

print &rpcExec($cmd, $arg_str), "\n";

}# sub testFlexXML

############################################

sub rpcExec {
my $cmd = $_[0];
my $out;

switch ($cmd) {

  case ['keybd'] {
    my @argv = split(/:/, $_[1]);
    $out = &communicate_keyboard(@argv);
  }
  case ['mouse'] {
    my @argv = split(/:/, $_[1]);
    $out = &communicate_mouse(@argv);
  }
  case ['pingTool'] {
    my $rpcSub = 'rpcCmd' . "\u$cmd";
    $out = &$rpcSub();
  }
  else {
    $out = "<root><cmd>$cmd</cmd>" .
           "<errmsg>Unknown RPC command $cmd</errmsg></root>";
  }
} # switch ($cmd)

return $out;
#return '<![CDATA[' . "\n". $out . ']]>' . "\n";
}# sub rpcExec

############################################

sub rpcCmdPingTool {
  return "<root><cmd>pingTool</cmd><infomsg>" .
         "\u$appname is alive</infomsg></root>";
}#sub rpcCmdPingTool

############################################

sub rpcQuit {
  print "gotta quit\n";
  &interrupt;
}#sub rpcQuit


$SIG{'INT' } = \&interrupt;  $SIG{'QUIT'} = 'interrupt';
$SIG{'HUP' } = 'interrupt';  $SIG{'TRAP'} = 'interrupt';
$SIG{'ABRT'} = 'interrupt';  $SIG{'STOP'} = 'interrupt';

sub interrupt {
     my($signal)=@_;
     print "Caught Interrupt\: $signal \n";
     print "Now Exiting\n";
     $SIG{'INT' };
}

END {kill 15, -$$}


############################################

###################################################################################################
################################## Allow to remote login ##########################################
###################################################################################################
sub allow_remote_login{
use Frontier::Daemon;
my $noOfArg = @_;
my $host;
my $port = 1200;

 if($_[0] eq "-h" || $_[0] eq "-help" || $_[0] eq "-HELP"){
    print "Usage: allow_remote_login -host <host name (default:localhost)> \n";
    print "                          -port <port no (default:1200)>\n";
    return;
 }else{
    for(my $i=0; $i< $noOfArg; $i++){
        if($_[$i] eq "-host"){$host = $_[$i+1];}
        if($_[$i] eq "-port"){$port = $_[$i+1];}
    }
    
 
    print "running a daemon on $host at $port ... OK\n";
    my $server = Frontier::Daemon->new(
                           methods => {
                                      rpcExec => \&rpcExec,
                                      rpcQuit => \&rpcQuit,
                                      rpcMouse => \&communicate_mouse,
                                      rpcKeyboard => \&communicate_keyboard,
                                      },   
                           LocalPort => $port, 
                           LocalAddr => $host,
                           Broadcast => 1,
                           PeerAddr => "divakar",
                          );
 #$server->close;
 }#if correct no of arg
}#sub allow_remote_login 
################################################################################
system("Xvfb -ac :$displaynum -screen 0 800x600x24 &");
#system("DISPLAY=$host:$displaynum proton --win &");
system("DISPLAY=$hostname:$displaynum xterm &");
&allow_remote_login("-host", $hostname, "-port", $port);
