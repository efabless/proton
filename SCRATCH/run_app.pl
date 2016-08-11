#!/usr/bin/perl -w 
use Getopt::Long ;
use XML::Simple ;

# run app has the following flow

# 1. checkout the repo data for the design
# 2. check if app directory is there ... if not create one and add to svn
# 3. cd to app dir
# 4. cp the app_inputs.xml , {app}_output.xml, app_script.xml 
# 5. prepare the app run script using user_files.xml with other app related file
# 6. execute the app with its script
# 7. commit the files based on the app_output.xml 

my $designId = "";
my $userId = "";


my (@args) =  @ARGV;
my $args = join(' ',@args);
if (!defined($args)) {
      $args = "";
}
my $parseResult = Getopt::Long::GetOptionsFromString($args ,
                                                       # read args here
                                                       "userid=s"    => \$userId,
                                                       "designid=s"   => \$designId,
                                                       "appid=s"   => \$appId,
                                                       "help"    => \$help,
                                                      );
$appsName = "proton";
# 1. checkout the repo data for the design
system("svn co https://stagesvn.benarasdesign.com/repos/cubby/$userId/$designId");

# 2. check if app directory is there ... if not create one and add to svn
system("mkdir $designId/$appsName");
system("svn add $designId/$appsName");
system("svn commit $designId/$appsName -m \"\"");
# 3. cd to app dir
chdir "${designId}/${appsName}" ;
system("rm -rf *");
# 4. cp the app_inputs.xml , {app}_output.xml, app_script.xml 
system("cp ../../${appsName}_inputs.xml .");
system("cp ../../${appsName}_outputs.xml .");
system("cp ../../${appsName}_script.xml .");
system("cp ../../${appsName}_files.xml .");
system("wait 10");
# 5. prepare the app run script using user_files.xml with other app related file
my $xml = new XML::Simple;
my $userfiles = $xml->XMLin("${appsName}_files.xml");
   my %userfilesHash = %$userfiles;
   foreach my $key (keys %userfilesHash){
           print "$key\n";
   }#foreach key
my $techlef = $userfiles->{techlef}->{name} ;
print "\t techlef $techlef\n";

my $xmlinputs = new XML::Simple;
my $appinputs = $xmlinputs->XMLin("${appsName}_inputs.xml");
   my %appinputsHash = %$appinputs;
   open(WRITE,">run_script.tcl");
   foreach my $key (keys %appinputsHash){
           print WRITE "set $key $userfiles->{$key}->{name}\n";
   }#foreach key
my $xmlscript = new XML::Simple;
my $appscript = $xmlscript->XMLin("${appsName}_script.xml");
   foreach my $key (sort( keys %{$appscript})){
           print WRITE "$appscript->{$key}->{name}\n";
           print "script:$key\n";
   }#foreach key
   close(WRITE);

system("$appsName -init run_script.tcl -log proton.log");





# 6. delete the previous outputs got from svn based on the apps_output.xml file execute the app with its script
my $xml = new XML::Simple;
my $appFiles = $xml->XMLin("${appsName}_outputs.xml");
   my %appFilesHash = %$appFiles;
   foreach my $key (keys %appFilesHash){
           print "$key\n";
   }#foreach key

my $logfile = $appFiles{logfile} ;

# 7. commit the files based on the app_output.xml 
#------ first read the <apps>_outputs.xml-------#
my $xml = new XML::Simple;
my $appFiles = $xml->XMLin("${appsName}_outputs.xml");
   my %appFilesHash = %$appFiles;
   foreach my $key (keys %appFilesHash){
           print "$key\n";
   }#foreach key
my $logfile = $appFiles->{logfile}->{name} ;

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

print " $logfile : $svn_comit_tag\n";

system("svn add $logfile");
print " $logfile : $svn_comit_tag\n";
system("svn commit $logfile -m \"$svn_comit_tag\"");



