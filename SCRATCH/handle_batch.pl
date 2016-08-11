#!/usr/bin/perl -w 
use Getopt::Long ;
use XML::Simple ;

# run app has the following flow

# 4. cp the app_inputs.xml , {app}_output.xml, app_script.xml 
# 5. prepare the app run script using user_files.xml with other app related file
# 6. execute the app with its script
# 7. change the owner of the file to be apache, after the batch execution finshes

my (@args) =  @ARGV;
my $args = join(' ',@args);
if (!defined($args)) {
      $args = "";
}
my ($help, $apps_config);

my $parseResult = Getopt::Long::GetOptionsFromString($args ,
                                                       # read args here
                                                       "help"    => \$help,
                                                       "config=s"    => \$apps_config,
                                                      );

# 5. prepare the app run script using user_files.xml with apps_config and user_config file
my $xmlinputs = new XML::Simple;
my $appinputs = $xmlinputs->XMLin($apps_config);

# ---- find out if app uses a run script or a command line only to process the batch job------#
# uses a script to run the app
if (exists $appinputs->{script} ) {
$scr = $appinputs->{script} ;
print "$scr\n";
}

if(exists $appinputs->{tclfile} ) {
   $tcl_file = $appinputs->{tclfile} ;
   print "$tcl_file\n";
}

#-----    takes only the command line
if(exists $appinputs->{cmdline} ) {
   $cmd = $appinputs->{cmdline};
   print "cmd : $cmd \n";
}
my $tmpdir = $appinputs->{tmpdir};

#---- find all the required inputs ------#
foreach my $key ( keys %{$appinputs->{input}->{required}} ) {
  #----- check if the required input is supplie------# 
       if ( $key eq "userconfig" ) {
     $varname = $appinputs->{input}->{required}->{$key};
     $varvalue = ${tmpdir}."/app_config.xml";
     $tcl_file =~ s/$varname/$varvalue/;
     $scr =~ s/$varname/$varvalue/;
     $cmd =~ s/$varname/$varvalue/;
                                   } else {
  if(exists $appinputs->{userfiles}->{input}->{$key} ) {
     print "\t$appinputs->{userfiles}->{input}->{$key}\n";
     $varname = $appinputs->{input}->{required}->{$key};
     $varvalue = $appinputs->{userfiles}->{input}->{$key};
     $cmd =~ s/$varname/$varvalue/;
     $scr =~ s/$varname/$varvalue/;
     $tcl_file =~ s/$varname/$varvalue/;
                                   }
  }
}#foreach required input

################# Added by Aditya ####################
#---- find all the standard inputs ------#
if(exists $appinputs->{input}{stdprm}){
   foreach my $key ( keys %{$appinputs->{input}->{stdprm}} ) {
     if(exists $appinputs->{stdinput}->{$key}) {
        print "\t$appinputs->{stdinput}->{$key}\n";
        $varname = $appinputs->{input}->{stdprm}->{$key};
        $varvalue = $appinputs->{stdinput}->{$key};
        $cmd =~ s/$varname/$varvalue/;
        $scr =~ s/$varname/$varvalue/;
     }
   }#foreach required input
}
#######################################################

#---- find all the optional inputs ------#

#---- try to find the output file -----#
# if outfile is not specified then try to guess it from input file names and prefix
foreach my $key ( keys %{$appinputs->{output}->{handoff}} ) {
    print "OUTKEYS : $key\n";
if(exists $appinputs->{userfiles}->{output}->{$key} ){
   $varvalue = $appinputs->{userfiles}->{output}{$key};
   $varname = $appinputs->{output}->{handoff}->{$key}->{outfilename};
    print "OUTKEYS : $key : $varvalue : $varname \n";
   $cmd =~ s/$varname/$varvalue/;
   $scr =~ s/$varname/$varvalue/;
   
}
                                                             }# foreach apps output

print "tcl \"$tcl_file\"\n";
#------- create the configuration file for app's execution ---#
#------- configuration is created using vendor defined default configuration and overwriting it with user configuration ----#
#------- if user configuration is empty, default configuration is the one to use as app configuration ----#
use XML::Writer;
use IO::File;
my $xml_output = new IO::File(">$tmpdir/app_config.xml");
my $xml = new XML::Writer(OUTPUT => $xml_output);
$xml->xmlDecl();
$xml->startTag("root");
foreach my $key ( keys %{$appinputs->{defaultconfig}} ) {
        my $defaultvalue = $appinputs->{defaultconfig}->{$key};
if(exists $appinputs->{userconfig}->{$key} ){
        my $value = $appinputs->{userconfig}->{$key};
        $xml->dataElement("$key"=>$value);
                                            }
else {
$xml->dataElement("$key"=>$defaultvalue);
     }
}
$xml->endTag();
$xml->end();
$xml_output->close();
    
####### added by aditya to pass tcl command in script file #######
if (exists $appinputs->{tclfile} ) {
open(WRITE,">$tmpdir/script");
   open(READ, $tcl_file);
   while(<READ>){
     print WRITE "$_\n";
   }
   close(READ);
close(WRITE);
}

####################################################################

if (exists $appinputs->{script} ) {
open(WRITE,">>$tmpdir/script");
print WRITE "$scr\n";
close(WRITE);
}

$cmd =~ s/^\s+//g;
my $script = (split(/\s+/,$cmd))[0];
my $appdir = $appinputs->{appdir};
my $path = "$appdir/$script";
print "$cmd\n";

if(-e "$path"){
   system("cd $tmpdir ; $appdir/$cmd") == 0 && &write_status(0)
   or die &write_status(1);
   system("cd $tmpdir ; touch dirCanBeDeleted;  chown -R apache.apache *");

}else{
  print "WARN: $path does not exist\n";
  &write_status(1);
}




sub write_status{
my $arg = $_[0];
use XML::Writer;
use IO::File;

my $status = "success";
if($arg == 1){$status = "failure";}

my $xml_output = new IO::File(">$tmpdir/status.xml");
my $xml = new XML::Writer(OUTPUT => $xml_output);
$xml->startTag("root");
#$xml->startTag("status");
#$xml->characters("success") if($arg == 0);
#$xml->characters("failure") if($arg == 1);
#$xml->endTag();
$xml->dataElement("status"=>$status);
$xml->endTag();
$xml->end();
$xml_output->close();
}#sub write_status

sub write_config {
use XML::Writer;
use IO::File;
my $xml_output = new IO::File(">app_config.xml");
my $xml = new XML::Writer(OUTPUT => $xml_output);
$xml->startTag("root");

$xml->endTag();
$xml->end();
$xml_output->close();
}#sub write_config




#------ then find the file in the dir and check its time stamp----#
#------ commit the new files into repo and add the following tag to the svn repo ---#
#------ user : $userId has ccomitted design $designId on $date ------#

#---- GMT time ---#
#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time); @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
#$date = sprintf("%02d-%s-%04d",$mday,$months[$mon],$year+1900);
#$time = sprintf("%02d:%02d:%02d",$hour,$min,$sec);
#$gmttime = "$date, $time";
#
##---- local time ----#
#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
#$date = sprintf("%02d-%s-%04d",$mday,$months[$mon],$year+1900);
#$time = sprintf("%02d:%02d:%02d",$hour,$min,$sec);
#$localtime = "$date, $time";


#my $svn_comit_tag = "checked in by $userId for $designId on GMT : $gmttime or local time $localtime";
