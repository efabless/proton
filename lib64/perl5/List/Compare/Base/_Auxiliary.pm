package List::Compare::Base::_Auxiliary;
$VERSION = 0.52;
use Carp;
@ISA = qw(Exporter);
@EXPORT_OK = qw|
    _validate_2_seenhashes
    _validate_seen_hash
    _validate_multiple_seenhashes
    _calculate_array_seen_only
    _calculate_seen_only
    _calculate_intermediate
    _calculate_union_only
    _calculate_union_seen_only
    _calculate_sharedref
    _subset_subengine
    _chart_engine_regular
    _chart_engine_multiple
    _equivalent_subengine
    _index_message1
    _index_message2
    _index_message3
    _index_message4
    _prepare_listrefs
    _subset_engine_multaccel
    _calc_seen
    _calc_seen1
    _equiv_engine
    _argument_checker_0
    _argument_checker
    _argument_checker_1
    _argument_checker_2
    _argument_checker_3
    _argument_checker_3a
    _argument_checker_4
    _alt_construct_tester
    _alt_construct_tester_1
    _alt_construct_tester_2
    _alt_construct_tester_3
    _alt_construct_tester_4
    _alt_construct_tester_5
|;
%EXPORT_TAGS = (
    calculate => [ qw(
        _calculate_array_seen_only
        _calculate_seen_only
        _calculate_intermediate
        _calculate_union_only
        _calculate_union_seen_only
        _calculate_sharedref
    ) ],
    checker => [ qw(
        _argument_checker_0
        _argument_checker
        _argument_checker_1
        _argument_checker_2
        _argument_checker_3
        _argument_checker_3a
        _argument_checker_4
    ) ],
    tester => [ qw(
        _alt_construct_tester
        _alt_construct_tester_1
        _alt_construct_tester_2
        _alt_construct_tester_3
        _alt_construct_tester_4
        _alt_construct_tester_5
    ) ],
);
use strict;
local $^W =1;

my $bad_lists_msg = q{If argument is single hash ref, you must have a 'lists' key whose value is an array ref};

sub _validate_2_seenhashes {
    my ($refL, $refR) = @_;
    my (%seenL, %seenR);
    my (%badentriesL, %badentriesR);
    foreach (keys %$refL) {
        if (${$refL}{$_} =~ /^\d+$/ and ${$refL}{$_} > 0) {
            $seenL{$_} = ${$refL}{$_};
        } else {
            $badentriesL{$_} = ${$refL}{$_};
        }
    }
    foreach (keys %$refR) {
        if (${$refR}{$_} =~ /^\d+$/ and ${$refR}{$_} > 0) {
            $seenR{$_} = ${$refR}{$_};
        } else {
            $badentriesR{$_} = ${$refR}{$_};
        }
    }
    my $msg = q{};
    if ( (keys %badentriesL) or (keys %badentriesR) ) {
        $msg .= "\nValues in a 'seen-hash' may only be positive integers.\n";
        $msg .= "  These elements have invalid values:\n";
        if (keys %badentriesL) {
            $msg .= "  First hash in arguments:\n";
            $msg .= "     Key:  $_\tValue:  $badentriesL{$_}\n"
                foreach (sort keys %badentriesL);
        }
        if (keys %badentriesR) {
            $msg .= "  Second hash in arguments:\n";
            $msg .= "     Key:  $_\tValue:  $badentriesR{$_}\n"
                foreach (sort keys %badentriesR);
        }
        $msg .= "Correct invalid values before proceeding";
        croak "$msg:  $!";
    }
    return (\%seenL, \%seenR);
}

sub _validate_seen_hash {
    if (@_ > 2) {
        _validate_multiple_seenhashes( [@_] );
    } else {
        my ($l, $r) = @_;
        my (%badentriesL, %badentriesR);
        foreach (keys %$l) {
            $badentriesL{$_} = ${$l}{$_}
                unless (${$l}{$_} =~ /^\d+$/ and ${$l}{$_} > 0);
        }
        foreach (keys %$r) {
            $badentriesR{$_} = ${$r}{$_}
                unless (${$r}{$_} =~ /^\d+$/ and ${$r}{$_} > 0);
        }
        my $msg = q{};
        if ( (keys %badentriesL) or (keys %badentriesR) ) {
            $msg .= "\nValues in a 'seen-hash' must be numeric.\n";
            $msg .= "  These elements have invalid values:\n";
            if (keys %badentriesL) {
                $msg .= "  First hash in arguments:\n";
                $msg .= "     Key:  $_\tValue:  $badentriesL{$_}\n"
                    foreach (sort keys %badentriesL);
            }
            if (keys %badentriesR) {
                $msg .= "  Second hash in arguments:\n";
                $msg .= "     Key:  $_\tValue:  $badentriesR{$_}\n"
                    foreach (sort keys %badentriesR);
            }
            $msg .= "Correct invalid values before proceeding";
            croak "$msg:  $!";
        }
    }
}

sub _validate_multiple_seenhashes {
    my $hashrefsref = shift;
    my (%badentries);
    for (my $i = 0; $i <= $#{$hashrefsref}; $i++) {
        foreach my $k (keys %{$hashrefsref->[$i]}) {
            unless ($hashrefsref->[$i]->{$k} =~ /^\d+$/ and $hashrefsref->[$i]->{$k} > 0) {
                $badentries{$i}{$k} = $hashrefsref->[$i]->{$k};
            }
        }
    }
    my $msg = q{};
    if (scalar(keys %badentries)) {
        $msg .= "\nValues in a 'seen-hash' must be positive integers.\n";
        $msg .= "  These elements have invalid values:\n\n";
        foreach my $b (sort keys %badentries) {
            $msg .= "    Hash $b:\n";
            foreach my $val (sort keys %{$badentries{$b}}) {
                $msg .= "        Bad key-value pair:  $val\t$badentries{$b}->{$val}\n";
            }
        }
        $msg .= "Correct invalid values before proceeding";
        croak "$msg:  $!";
    }
}

sub _list_builder {
    my ($aref, $x) = @_;
    if (ref(${$aref}[$x]) eq 'HASH') {
        return keys %{${$aref}[$x]};
    } else {
        return      @{${$aref}[$x]};
    }
}

sub _calculate_array_seen_only {
    my $aref = shift;
    my (@seen);
    for (my $i = 0; $i <= $#{$aref}; $i++) {
        my %seenthis = ();
        foreach my $el ( _list_builder($aref, $i) ) {
            $seenthis{$el}++;
        }
        push @seen, \%seenthis;
    }
    return \@seen;
}

sub _calculate_seen_only {
    my $aref = shift;
    my (%seen);
    for (my $i = 0; $i <= $#{$aref}; $i++) {
        my %seenthis = ();
        foreach my $h ( _list_builder($aref, $i) ) {
            $seenthis{$h}++;
        }
        $seen{$i} = \%seenthis;
    }
    return \%seen;
}

sub _calculate_intermediate {
    my $aref = shift;
    my $aseenref = _calculate_array_seen_only($aref);
    my @vals = sort { scalar(keys(%{$a})) <=> scalar(keys(%{$b})) } @{$aseenref};
    my %intermediate = map { $_ => 1 } keys %{$vals[0]};
    for my $l ( 1..$#vals ) {
        %intermediate = map { $_ => 1 }
            grep { exists $intermediate{$_} }
            keys %{$vals[$l]};
    }
    return \%intermediate;
}

sub _calculate_union_only {
    my $aref = shift;
    my (%union);
    for (my $i = 0; $i <= $#{$aref}; $i++) {
        foreach my $h ( _list_builder($aref, $i) ) {
            $union{$h}++;
        }
    }
    return \%union;
}

sub _calculate_union_seen_only {
    my $aref = shift;
    my (%union, %seen);
    for (my $i = 0; $i <= $#{$aref}; $i++) {
        my %seenthis = ();
        foreach my $h ( _list_builder($aref, $i) ) {
            $seenthis{$h}++;
            $union{$h}++;
        }
        $seen{$i} = \%seenthis;
    }
    return (\%union, \%seen);
}

sub _calculate_sharedref {
    my $seenrefsref = shift;

    my %intermediate = ();
    for my $href (@{$seenrefsref}) {
       my %this = map { $_ => 1 } keys(%{$href});
        for my $k (keys %this) {;
            $intermediate{$k}++;
        };
    }

    my $sharedref;
    for my $k (keys %intermediate) {
        $sharedref->{$k}++ if $intermediate{$k} > 1;
    }
    return $sharedref;
}

sub _subset_subengine {
    my $aref = shift;
    my (@xsubset);
    my %seen = %{_calculate_seen_only($aref)};
    foreach my $i (keys %seen) {
        foreach my $j (keys %seen) {
            $xsubset[$i][$j] = 1;
            foreach my $k (keys %{$seen{$i}}) {
                $xsubset[$i][$j] = 0 if (! $seen{$j}{$k});
            }
        }
    }
    return \@xsubset;
}

sub _chart_engine_regular {
    my $aref = shift;
    my @sub_or_eqv = @$aref;
    my $title = shift;
    my ($v, $w, $t);
    print "\n";
    print $title, ' Relationships', "\n\n";
    print '   Right:    0    1', "\n\n";
    print 'Left:  0:    1    ', $sub_or_eqv[0], "\n\n";
    print '       1:    ', $sub_or_eqv[1], '    1', "\n\n";
}

sub _chart_engine_multiple {
    my $aref = shift;
    my @sub_or_eqv = @$aref;
    my $title = shift;
    my ($v, $w, $t);
    print "\n";
    print $title, ' Relationships', "\n\n";
    print '   Right:';
    for ($v = 0; $v <= $#sub_or_eqv; $v++) {
        print '    ', $v;
    }
    print "\n\n";
    print 'Left:  0:';
    my @firstrow = @{$sub_or_eqv[0]};
    for ($t = 0; $t <= $#firstrow; $t++) {
        print '    ', $firstrow[$t];
    }
    print "\n\n";
    for ($w = 1; $w <= $#sub_or_eqv; $w++) {
        my $length_left = length($w);
        my $x = '';
        print ' ' x (8 - $length_left), $w, ':';
        my @row = @{$sub_or_eqv[$w]};
        for ($x = 0; $x <= $#row; $x++) {
            print '    ', $row[$x];
        }
        print "\n\n";
    }
    1; # force return true value
}

sub _equivalent_subengine {
    my $aref = shift;
    my @xsubset = @{_subset_subengine($aref)};
    my (@xequivalent);
    for (my $f = 0; $f <= $#xsubset; $f++) {
        for (my $g = 0; $g <= $#xsubset; $g++) {
            $xequivalent[$f][$g] = 0;
            $xequivalent[$f][$g] = 1
                if ($xsubset[$f][$g] and $xsubset[$g][$f]);
        }
    }
    return \@xequivalent;
}

sub _index_message1 {
    my ($index, $dataref) = @_;
    my $method = (caller(1))[3];
    croak "Argument to method $method must be the array index of the target list \n  in list of arrays passed as arguments to the constructor: $!"
        unless (
                $index =~ /^\d+$/
           and  $index <= ${$dataref}{'maxindex'}
        );
}

sub _index_message2 {
    my $dataref = shift;
    my ($index_left, $index_right);
    my $method = (caller(1))[3];
    croak "Method $method requires 2 arguments: $!"
        unless (@_ == 0 || @_ == 2);
    if (@_ == 0) {
        $index_left = 0;
        $index_right = 1;
    } else {
        ($index_left, $index_right) = @_;
        foreach ($index_left, $index_right) {
            croak "Each argument to method $method must be a valid array index for the target list \n  in list of arrays passed as arguments to the constructor: $!"
                unless (
                        $_ =~ /^\d+$/
                   and  $_ <= ${$dataref}{'maxindex'}
                );
        }
    }
    return ($index_left, $index_right);
}

sub _index_message3 {
    my ($index, $maxindex) = @_;
    my $method = (caller(1))[3];
    croak "Argument to method $method must be the array index of the target list \n  in list of arrays passed as arguments to the constructor: $!"
        unless (
                $index =~ /^\d+$/
           and  $index <= $maxindex
        );
}

sub _index_message4 {
    my $maxindex = shift;
    my ($index_left, $index_right);
    my $method = (caller(1))[3];
    croak "Method $method requires 2 arguments: $!"
        unless (@_ == 0 || @_ == 2);
    if (@_ == 0) {
        $index_left = 0;
        $index_right = 1;
    } else {
        ($index_left, $index_right) = @_;
        foreach ($index_left, $index_right) {
            croak "Each argument to method $method must be a valid array index for the target list \n  in list of arrays passed as arguments to the constructor: $!"
                unless (
                        $_ =~ /^\d+$/
                   and  $_ <= $maxindex
                );
        }
    }
    return ($index_left, $index_right);
}

sub _prepare_listrefs {
    my $dataref = shift;
    delete ${$dataref}{'unsort'};
    my (@listrefs);
    foreach my $lref (sort {$a <=> $b} keys %{$dataref}) {
        push(@listrefs, ${$dataref}{$lref});
    };
    return \@listrefs;
}

sub _subset_engine_multaccel {
    my $dataref = shift;
    my $aref = _prepare_listrefs($dataref);
    my ($index_left, $index_right) = _index_message4($#{$aref}, @_);

    my $xsubsetref = _subset_subengine($aref);
    return ${$xsubsetref}[$index_left][$index_right];
}

sub _calc_seen {
    my ($refL, $refR) = @_;
    # We've already guaranteed that args are both array refs or both hash
    # refs.  So checking the left-hand one is sufficient.
    if (ref($refL) eq 'ARRAY') {
        my (%seenL, %seenR);
        foreach (@$refL) { $seenL{$_}++ }
        foreach (@$refR) { $seenR{$_}++ }
        return (\%seenL, \%seenR);
    } else {
        return ($refL, $refR);
    }
}

sub _equiv_engine {
    my ($hrefL, $hrefR) = @_;
    my (%intersection, %Lonly, %Ronly, %LorRonly);
    my $LequivalentR_status = 0;

    foreach (keys %{$hrefL}) {
        exists ${$hrefR}{$_} ? $intersection{$_}++ : $Lonly{$_}++;
    }

    foreach (keys %{$hrefR}) {
        $Ronly{$_}++ unless (exists $intersection{$_});
    }

    $LorRonly{$_}++ foreach ( (keys %Lonly), (keys %Ronly) );
    $LequivalentR_status = 1 if ( (keys %LorRonly) == 0);
    return $LequivalentR_status;
}

sub _argument_checker_0 {
    my @args = @_;
    my $first_ref = ref($args[0]);
    my @temp = @args[1..$#args];
    my ($testing);
    my $condition = 1;
    while (defined ($testing = shift(@temp)) ) {
        unless (ref($testing) eq $first_ref) {
            $condition = 0;
            last;
        }
    }
    croak "Arguments must be either all array references or all hash references: $!"
        unless $condition;
    _validate_seen_hash(@args) if $first_ref eq 'HASH';
    return (@args);
}

sub _argument_checker {
    my $argref = shift;
    croak "'$argref' must be an array ref" unless ref($argref) eq 'ARRAY';
    my @args = _argument_checker_0(@{$argref});
    return (@args);
}

sub _argument_checker_1 {
    my $argref = shift;
    my @args = @{$argref};
    croak "Subroutine call requires 2 references as arguments:  $!"
        unless @args == 2;
    return (_argument_checker($args[0]), ${$args[1]}[0]);
}

sub _argument_checker_2 {
    my $argref = shift;
    my @args = @$argref;
    croak "Subroutine call requires 2 references as arguments:  $!"
        unless @args == 2;
    return (_argument_checker($args[0]), $args[1]);
}

# _argument_checker_3 is currently set-up to handle either 1 or 2 arguments
# in get_unique and get_complement
# The first argument is an arrayref holding refs to lists ('unsorted' has been
# stripped off).
# The second argument is an arrayref holding a single item (index number of
# item being tested)
# Note:  Currently we're only checking for the quantity of arguments -- not
# their types.  This should be fixed.
sub _argument_checker_3 {
    my $argref = shift;
    my @args = @{$argref};
    if (@args == 1) {
        return (_argument_checker($args[0]), 0);
    } elsif (@args == 2) {
        return (_argument_checker($args[0]), ${$args[1]}[0]);
    } else {
        croak "Subroutine call requires 1 or 2 references as arguments:  $!";
    }
}

sub _argument_checker_3a {
    my $argref = shift;
    my @args = @{$argref};
    if (@args == 1) {
        return [ _argument_checker($args[0]) ];
    } else {
        croak "Subroutine call requires exactly 1 reference as argument:  $!";
    }
}

sub _argument_checker_4 {
    my $argref = shift;
    my @args = @{$argref};
    if (@args == 1) {
        return (_argument_checker($args[0]), [0,1]);
    } elsif (@args == 2) {
        if (@{$args[1]} == 2) {
            my $last_index = $#{$args[0]};
            foreach my $i (@{$args[1]}) {
		        croak "No element in index position $i in list of list references passed as first argument to function: $!"
                    unless ($i =~ /^\d+$/ and $i <= $last_index);
            }
            return (_argument_checker($args[0]), $args[1]);
        } else {
            croak "Must provide index positions corresponding to two lists: $!";
        }
    } else {
        croak "Subroutine call requires 1 or 2 references as arguments: $!";
    }
}

sub _calc_seen1 {
    my @listrefs = @_;
    # _calc_seen1() is applied after _argument_checker(), which checks to make
    # sure that the references in its output are either all arrayrefs
    # or all seenhashrefs
    # hence, _calc_seen1 only needs to determine whether it's dealing with
    # arrayrefs or seenhashrefs, then, if arrayrefs, calculate seenhashes
    if (ref($listrefs[0]) eq 'ARRAY') {
        my (@seenrefs);
        foreach my $aref (@listrefs) {
            my (%seenthis);
            foreach my $j (@{$aref}) {
                $seenthis{$j}++;
            }
            push(@seenrefs, \%seenthis);
        }
        return \@seenrefs;
    } else {
        return \@listrefs;
    }
}

# _alt_construct_tester prepares for _argument_checker in
# get_union get_intersection get_symmetric_difference get_shared get_nonintersection
sub _alt_construct_tester {
    my @args = @_;
    my ($argref, $unsorted);
    if (@args == 1 and (ref($args[0]) eq 'HASH')) {
       my $hashref = shift;
       croak "$bad_lists_msg: $!"
           unless ( ${$hashref}{'lists'}
                and (ref(${$hashref}{'lists'}) eq 'ARRAY') );
       $argref = ${$hashref}{'lists'};
       $unsorted = ${$hashref}{'unsorted'} ? 1 : '';
    } else {
        $unsorted = shift(@args)
            if ($args[0] eq '-u' or $args[0] eq '--unsorted');
        $argref = shift(@args);
    }
    return ($argref, $unsorted);
}

# _alt_construct_tester_1 prepares for _argument_checker_1 in
# is_member_which is_member_which_ref is_member_any
sub _alt_construct_tester_1 {
    my @args = @_;
    my ($argref);
    if (@args == 1 and (ref($args[0]) eq 'HASH')) {
        my (@returns);
        my $hashref = $args[0];
       croak "$bad_lists_msg: $!"
           unless ( ${$hashref}{'lists'}
                and (ref(${$hashref}{'lists'}) eq 'ARRAY') );
        croak "If argument is single hash ref, you must have an 'item' key: $!"
           unless ${$hashref}{'item'};
        @returns = ( ${$hashref}{'lists'}, [${$hashref}{'item'}] );
        $argref = \@returns;
    } else {
        $argref = \@args;
    }
    return $argref;
}

# _alt_construct_tester_2 prepares for _argument_checker_2 in
# are_members_which are_members_any
sub _alt_construct_tester_2 {
    my @args = @_;
    if (@args == 1 and (ref($args[0]) eq 'HASH')) {
        my $hashref = $args[0];
       croak "$bad_lists_msg: $!"
           unless ( ${$hashref}{'lists'}
                and (ref(${$hashref}{'lists'}) eq 'ARRAY') );
        croak "If argument is single hash ref, you must have an 'items' key whose value is an array ref: $!"
           unless ( ${$hashref}{'items'}
                and (ref(${$hashref}{'items'}) eq 'ARRAY') );
        return [ (${$hashref}{'lists'}, ${$hashref}{'items'}) ];
    } else {
        return \@args;
    }
}

# _alt_construct_tester_3 prepares for _argument_checker_3 in
# get_unique get_complement
sub _alt_construct_tester_3 {
    my @args = @_;
    my ($argref, $unsorted);
    if (@args == 1 and (ref($args[0]) eq 'HASH')) {
        my (@returns);
        my $hashref = $args[0];
       croak "$bad_lists_msg: $!"
           unless ( ${$hashref}{'lists'}
                and (ref(${$hashref}{'lists'}) eq 'ARRAY') );
        @returns = defined ${$hashref}{'item'}
                        ? (${$hashref}{'lists'}, [${$hashref}{'item'}])
                        : (${$hashref}{'lists'});
        $argref = \@returns;
        $unsorted = ${$hashref}{'unsorted'} ? 1 : '';
    } else {
        $unsorted = shift(@args) if ($args[0] eq '-u' or $args[0] eq '--unsorted');
        $argref = \@args;
    }
    return ($argref, $unsorted);
}

# _alt_construct_tester_4 prepares for _argument_checker_4 in
# is_LsubsetR is_RsubsetL is_LequivalentR is_LdisjointR
sub _alt_construct_tester_4 {
    my @args = @_;
    my ($argref);
    if (@args == 1 and (ref($args[0]) eq 'HASH')) {
        my (@returns);
        my $hashref = $args[0];
       croak "$bad_lists_msg: $!"
           unless ( ${$hashref}{'lists'}
                and (ref(${$hashref}{'lists'}) eq 'ARRAY') );
        @returns = defined ${$hashref}{'pair'}
                        ? (${$hashref}{'lists'}, ${$hashref}{'pair'})
                        : (${$hashref}{'lists'});
        $argref = \@returns;
    } else {
        $argref = \@args;
    }
    return $argref;
}

# _alt_construct_tester_5 prepares for _argument_checker in
# print_subset_chart print_equivalence_chart
sub _alt_construct_tester_5 {
    my @args = @_;
    my ($argref);
    if (@args == 1) {
        if (ref($args[0]) eq 'HASH') {
           my $hashref = shift;
           croak "Need to define 'lists' key properly: $!"
               unless ( ${$hashref}{'lists'}
                    and (ref(${$hashref}{'lists'}) eq 'ARRAY') );
           $argref = ${$hashref}{'lists'};
        } else {
           $argref = shift(@args);
        }
    } else {
        croak "Subroutine call requires exactly 1 reference as argument:  $!";
    }
    return $argref;
}

1;

__END__

=head1 NAME

List::Compare::Base::_Auxiliary - Internal use only

=head1 VERSION

This document refers to version 0.52 of List::Compare::Base::_Auxiliary.
This version was released May 21 2015.

=head1 SYNOPSIS

This module contains subroutines used within List::Compare and
List::Compare::Functional.  They are not intended to be publicly callable.

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).  When sending correspondence, please
include 'List::Compare' or 'List-Compare' in your subject line.

Creation date:  May 20, 2002.  Last modification date:  February 25 2015.
Copyright (c) 2002-15 James E. Keenan.  United States.  All rights reserved.
This is free software and may be distributed under the same terms as Perl
itself.

=cut

