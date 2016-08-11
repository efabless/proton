#!/bin/perl -w

my %HASHTABLE = ();
open(READ,"listfile");
while (<READ>) {
chomp();
my $fileName = $_;
open(READ2,"$fileName");
     while(<READ2>) {
     if($_ =~ /\#/ ) {next ; }
     elsif($_ =~ /sub\s/ ) { $subroutineName = (split(/\s+/, $_))[1]; 
                          #print "$subroutineName\n";
                          %{$HASHTABLE{$subroutineName}} = ();
                        }
     elsif($_ =~ /\&(\w*)/ ) {
                         $calledsub = $1; 
                         $HASHTABLE{$subroutineName}{$calledsub} = 1;
                          #print "\t$calledsub\n";
                         }
                         
                    }#while
close(READ2);

}#while
close(READ);

foreach $subName (keys %HASHTABLE ) {
       foreach $called ( keys %{$HASHTABLE{$subName}} ) {
       if ( $called eq "" ) { }
       else {
print "$subName \-\> $called \;\n";
                                                               }
            }
}
