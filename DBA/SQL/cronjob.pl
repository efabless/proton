#!/usr/bin/perl 

use DBI;
sub reset_testcase_daily {
#my $KB_DATABASE = "DB;aditya.lnx4.com";
my $DBvalue = $GLOBAL->dbfGlobalGetInitializeDB;
if ( $DBvalue == 0 ) {
  print "first call IntKB to create database table\n";
  return;
}
my $dbh = DBI->connect( "dbi:mysql:$KB_DATABASE","qaadmin","qaadmin" ) || die "Cannot connect: $DBI::errstr";
$dbh->do( "UPDATE designStat SET Status = 0 WHERE RID = 0" );
}# reset_testcase_daily

1;
