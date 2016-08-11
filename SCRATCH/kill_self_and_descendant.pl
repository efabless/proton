#!/usr/bin/perl  
use Proc::ProcessTable;
my $process_id = $ARGV[0];
my $currentProcessStatus = new Proc::ProcessTable; 
&kill_self_and_descendant($process_id);
sub kill_self_and_descendant
{
  my $process_family_head_pid = $_[0];
  foreach my $currProcess (@{$currentProcessStatus->table}) {
    if($currProcess->ppid == $process_family_head_pid){
      &kill_self_and_descendant($currProcess->pid);
    }
  }
  kill(9,$process_family_head_pid);
}#sub kill_self_and_descendant
