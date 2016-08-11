#!/usr/bin/perl

use Term::ProgressBar 2.00;

use constant MAX => 100_000;
my $max = 10;
my $progress = Term::ProgressBar->new({name => 'Powers', count => $max, remove => 1});
$progress->minor(0);
my $next_update = 0;

for (0..$max) {
  my $is_power = 0;
  for(my $i = 0; 2**$i <= $_; $i++) {
    $is_power = 1
      if 2**$i == $_;
 $i= $i+ 5;
  }

  $next_update = $progress->update($_)
    if $_ >= $next_update;
 sleep 1;
}
$progress->update($max)
  if $max >= $next_update;
