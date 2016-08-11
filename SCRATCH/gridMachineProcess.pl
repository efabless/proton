
     use GRID::Machine;
     
     my $host = $ENV{GRID_REMOTE_MACHINE};
     my $machine = GRID::Machine->new( host => $host );
     
     my ($N, $np, $pi)  = (10000, 4, 0);
     for (0..$np-1) {
        $machine->fork( q{
            my ($id, $N, $np) = @_;
              
            my $sum = 0;
            for (my $i = $id; $i < $N; $i += $np) {
                my $x = ($i + 0.5) / $N;
                $sum += 4 / (1 + $x * $x);
            }
            $sum /= $N; 
         },
         args => [ $_, $N, $np ],
       );
     }
     
     $pi += $machine->waitall()->result for 1..$np;
     
     print "pi = $pi\n";
