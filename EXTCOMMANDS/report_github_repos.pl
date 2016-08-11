#!/usr/bin/perl -w

   use Net::GitHub::V3;

    my $gh = Net::GitHub::V3->new; # read L<Net::GitHub::V3> to set right authentication info
    my $repos = $gh->repos;

    # set :user/:repo for simple calls

    # starting at id 500
    my @rp = $repos->list_all(500);

print "@rp\n";

    my $search = $gh->search;
    my %data = $search->repositories({ q => 'spice-parser'});
    print "%data\n";
