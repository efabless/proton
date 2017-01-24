package List::Compare::Base::_Engine;
$VERSION = 0.52;
# Holds subroutines used within
# List::Compare::Base::Accelerated and List::Compare::Functional
use Carp;
use List::Compare::Base::_Auxiliary qw(
    _equiv_engine
    _calculate_union_seen_only
    _calculate_seen_only
);
@ISA = qw(Exporter);
@EXPORT_OK = qw|
    _unique_all_engine
    _complement_all_engine
|;
use strict;
local $^W = 1;

sub _unique_all_engine {
    my $aref = shift;
    my $seenref = _calculate_seen_only($aref);

    my @all_uniques = ();
    for my $i (sort {$a <=> $b} keys %{$seenref}) {
        my %seen_in_all_others = ();
        for my $j (keys %{$seenref}) {
            unless ($i == $j) {
                for my $k (keys %{$seenref->{$j}}) {
                    $seen_in_all_others{$k}++;
                }
            }

        }
        my @these_uniques = ();
        for my $l (keys %{$seenref->{$i}}) {
            push @these_uniques, $l
                unless $seen_in_all_others{$l};
        }
        $all_uniques[$i]  = \@these_uniques;
    }
    return \@all_uniques;
}

sub _complement_all_engine {
    my ($aref, $unsortflag) = @_;
    my ($unionref, $seenref) = _calculate_union_seen_only($aref);
    my @union = $unsortflag ? keys %{$unionref} : sort(keys %{$unionref});

    # Calculate @xcomplement
    # Inputs:  $aref @union %seen
    my (@xcomplement);
    for (my $i = 0; $i <= $#{$aref}; $i++) {
        my @complementthis = ();
        foreach my $el (@union) {
            push(@complementthis, $el) unless (exists $seenref->{$i}->{$el});
        }
        $xcomplement[$i] = \@complementthis;
    }
    return \@xcomplement;
}

1;


__END__

=head1 NAME

List::Compare::Base::_Engine - Internal use only

=head1 VERSION

This document refers to version 0.52 of List::Compare::Base::_Engine.
This version was released May 21 2015.

=head1 SYNOPSIS

This module contains subroutines used within List::Compare and
List::Compare::Functional.  They are not intended to be publicly callable.

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).  When sending correspondence, please
include 'List::Compare' or 'List-Compare' in your subject line.

Creation date:  May 20, 2002.  Last modification date:  May 21 2015.
Copyright (c) 2002-15 James E. Keenan.  United States.  All rights reserved.
This is free software and may be distributed under the same terms as Perl
itself.

=cut

