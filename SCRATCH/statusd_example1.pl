  use Schedule::Load::Hosts;
  my $hosts = Schedule::Load::Hosts->fetch();
  foreach my $host ($hosts->hosts_sorted) {
      printf $host->hostname," is on our network\n";
  }

  # Choose hosts
  use Schedule::Load::Schedule;
  my $scheduler = Schedule::Load::Schedule->fetch();
  print "Best host for a new job: ", $scheduler->best(), "\n";
   my $bestMac = $scheduler->best();
   print "$bestMac\n";
