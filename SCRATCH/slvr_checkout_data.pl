#!/usr/bin/perl -w 

#-----------------------------------#
# This script checksout the design repository
#
#
# It needs userId and designId to checkout the data 
#-----------------------------------#


my $designId = "";
my $userId = "";

use Getopt::Long ;

my (@args) =  @ARGV;
my $args = join(' ',@args);
if (!defined($args)) {
      $args = "";
}
my $parseResult = Getopt::Long::GetOptionsFromString($args ,
                                                       # read args here
                                                       "userid=s"    => \$userId,
                                                       "designid=s"   => \$designId,
                                                       "-help"    => \$help,
                                                      );

system("svn co https://stagesvn.benarasdesign.com/repos/cubby/$userId/$designId");
