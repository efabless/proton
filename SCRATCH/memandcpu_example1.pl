#!/usr/bin/perl -w

use strict;

print join("\n", &memusage), "\n";
exit 0;


#   memusage subroutine
#
#   usage: memusage [processid]
#
#   this subroutine takes only one parameter, the process id for 
#   which memory usage information is to be returned.  If 
#   undefined, the current process id is assumed.
#
#   Returns array of two values, raw process memory size and 
#   percentage memory utilisation, in this order.  Returns 
#   undefined if these values cannot be determined.

sub memusage {
    use Proc::ProcessTable;
    my @results;
    my $pid = (defined($_[0])) ? $_[0] : $$;
    my $proc = Proc::ProcessTable->new;
    my %fields = map { $_ => 1 } $proc->fields;
    return undef unless exists $fields{'pid'};
    foreach (@{$proc->table}) {
        if ($_->pid eq $pid) {
            push (@results, $_->size) if exists $fields{'size'};
            push (@results, $_->pctmem) if exists $fields{'pctmem'};
        };
    };
    return @results;
}
