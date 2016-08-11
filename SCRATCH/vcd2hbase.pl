#!/usr/bin/perl -w 

use Verilog::VCD qw(:all);
my $vcd = parse_vcd($ARGV[0]);
my $ts  = get_timescale();
my $et  = get_endtime();

#print "$ts $et\n";
foreach $codeName ( keys %{$vcd} ) {
         $refTV = ${$vcd}{$codeName}{tv};
#----get the columns -------#
foreach $n (@{$refTV}) { #print "TV $n TV\n";
                         $cnt = ${$n}[0];
                  push(@TSAS,$cnt);
                                }
        @TSS = reverse sort { $b <=> $a } @TSAS;
        @TSSU = &uniq2(@TSS);
#        print "@TSSU\n";
#----get the columns -------#
                                  }

print "maccode,nodename,";
print join ",t", @TSSU ;
print "\n";

foreach $codeName ( keys %{$vcd} ) {
   
         $refNode = ${$vcd}{$codeName}{nets};
         $refTV = ${$vcd}{$codeName}{tv};
         #print "$refNode\n";
         #print "@{$refNode}\n";


         foreach $n (@{$refNode}) { #print "NV $n NV\n";
                         $netName = ${$n}{name};
                         #print "$codeName $netName ";
                         @TEMP = ();
                         push(@TEMP,$codeName);
                         push(@TEMP,$netName);
                                  }
         foreach $n (@{$refTV}) { #print "TV $n TV\n";
                              $cnt = 0;
                              $time = shift @{$n};
                        foreach $tag (@TSSU) {
                               if ( $tag < $time ) { $cnt++; }
                                            }
                              $val = shift @{$n};
                              $cnt = $cnt + 2;
                              $TEMP[$cnt] = $val;
                               
                                }
                          print join ",",@TEMP;
                          print "\n";
        
                                   }#foreach keys of vcd


sub uniq2 {
    my %seen = ();
    my @r = ();
    foreach my $a (@_) {
        unless ($seen{$a}) {
            push @r, $a;
            $seen{$a} = 1;
        }
    }
    return @r;
}
