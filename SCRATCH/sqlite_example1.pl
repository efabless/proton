#!/usr/bin/perl

   use DBI;

   $dbh = DBI->connect( "dbi:SQLite:data.dbl" ) || die "Cannot connect: $DBI::errstr";

   $dbh->do( "CREATE TABLE authors ( lastname, firstname )" );
   $dbh->do( "INSERT INTO authors VALUES ( 'Conway', 'Damian' ) " );
   $dbh->do( "INSERT INTO authors VALUES ( 'Booch', 'Grady' ) " );
   $dbh->do( "CREATE TABLE books ( title, author )" );
   $dbh->do( "INSERT INTO books VALUES ( 'Object Oriented Perl',
                                             'Conway' ) " );
   $dbh->do( "INSERT INTO books VALUES ( 'Object-Oriented Analysis and Design',
                                             'Booch' ) ");
   $dbh->do( "INSERT INTO books VALUES ( 'Object Solutions', 'Booch' ) " );


   $res = $dbh->selectall_arrayref( q( SELECT a.lastname, a.firstname, b.title
                                           FROM books b, authors a
                                           WHERE b.title like '%Orient%'
                                       AND a.lastname = b.author ) );

   foreach( @$res ) {
    foreach $i (0..$#$_) {
       print "$_->[$i] "
       }
    print "\n";

   }

   $dbh->disconnect;
