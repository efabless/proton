#!/usr/bin/perl -w 



#--------------------------------------------------------#
# This script checksout the design repository
#
#
# It needs userId and designId to checkout the data 
#--------------------------------------------------------#


my $designId = "";
my $userId = "";
my $appsName = "";

use Getopt::Long ;
use XML::Simple ;


my (@args) =  @ARGV;
my $args = join(' ',@args);
if (!defined($args)) {
      $args = "";
}
my $parseResult = Getopt::Long::GetOptionsFromString($args ,
                                                       # read args here
                                                       "userid=s"    => \$userId,
                                                       "designid=s"   => \$designId,
                                                       "app=s"   => \$appsName,
                                                       "help"    => \$help,
                                                      );

#------ first read the <apps>_outputs.xml-------#
my $xml = new XML::Simple;
my $appFiles = $xml->XMLin("${appsName}_output.xml");
   my %appFilesHash = %$appFiles;
   foreach my $key (keys %appFilesHash){
           print "$key\n";
   }#foreach key

my $logfile = $appFiles{logfile} ;

#------ then find the file in the dir and check its time stamp----#
#------ commit the new files into repo and add the following tag to the svn repo ---#
#------ user : $userId has ccomitted design $designId on $date ------#

#---- GMT time ---#
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time); @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
$date = sprintf("%02d-%s-%04d",$mday,$months[$mon],$year+1900);
$time = sprintf("%02d:%02d:%02d",$hour,$min,$sec);
$gmttime = "$date, $time";

#---- local time ----#
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
$date = sprintf("%02d-%s-%04d",$mday,$months[$mon],$year+1900);
$time = sprintf("%02d:%02d:%02d",$hour,$min,$sec);
$localtime = "$date, $time";


my $svn_comit_tag = "checked in by $userId for $designId on GMT : $gmttime or local time $localtime";

#print "$svn_comit_tag\n";
system("svn commit $logfile -m \"$svn_comit_tag\"");
