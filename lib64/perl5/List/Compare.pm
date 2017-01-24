package List::Compare;
$VERSION = '0.52';
use strict;
local $^W = 1;
use Carp;
use List::Compare::Base::_Auxiliary qw(
    _validate_2_seenhashes
    _chart_engine_regular
);

sub new {
    my $class = shift;
    my (@args, $unsorted, $accelerated);
    my ($argument_error_status, $nextarg, @testargs);
    if (@_ == 1 and (ref($_[0]) eq 'HASH')) {
        my $argref = shift;
        die "Need to pass references to 2 or more seen-hashes or \n  to provide a 'lists' key within the single hash being passed by reference"
            unless exists ${$argref}{'lists'};
        die "Need to define 'lists' key properly: $!"
            unless ( ${$argref}{'lists'}
                 and (ref(${$argref}{'lists'}) eq 'ARRAY') );
        @args = @{${$argref}{'lists'}};
        $unsorted = ${$argref}{'unsorted'} ? 1 : '';
        $accelerated = ${$argref}{'accelerated'} ? 1 : '';
    } else {
        @args = @_;
        $unsorted = ($args[0] eq '-u' or $args[0] eq '--unsorted')
            ? shift(@args) : '';
        $accelerated = shift(@args)
            if ($args[0] eq '-a' or $args[0] eq '--accelerated');
    }
    $argument_error_status = 1;
    @testargs = @args[1..$#args];
    if (ref($args[0]) eq 'ARRAY' or ref($args[0]) eq 'HASH') {
        while (defined ($nextarg = shift(@testargs))) {
            unless (ref($nextarg) eq ref($args[0])) {
                $argument_error_status = 0;
                last;
            }
        }
    } else {
        $argument_error_status = 0;
    }
    croak "Must pass all array references or all hash references: $!"
        unless $argument_error_status;

    # Compose the name of the class
    if (@args > 2) {
        if ($accelerated) {
            $class .= '::Multiple::Accelerated';
        } else {
            $class .= '::Multiple';
        }
    } elsif (@args == 2) {
        if ($accelerated) {
            $class .= '::Accelerated';
        }
    } else {
        croak "Must pass at least 2 references to \&new: $!";
    }

    # do necessary calculations and store results in a hash
    # take a reference to that hash
    my $self = bless {}, $class;
    my $dataref = $self->_init(($unsorted ? 1 : 0), @args);

    # initialize the object from the prepared values (Damian, p. 98)
    %$self = %$dataref;
    return $self;
}

sub _init {
    my $self = shift;
    my ($unsortflag, $refL, $refR) = @_;
    my (%data, @left, @right,  %seenL, %seenR);
    if (ref($refL) eq 'HASH') {
        my ($seenLref, $seenRref) =  _validate_2_seenhashes($refL, $refR);
        foreach my $key (keys %{$seenLref}) {
            for (my $j=1; $j <= ${$seenLref}{$key}; $j++) {
                push(@left, $key);
            }
        }
        foreach my $key (keys %{$seenRref}) {
            for (my $j=1; $j <= ${$seenRref}{$key}; $j++) {
                push(@right, $key);
            }
        }
        %seenL = %{$seenLref};
        %seenR = %{$seenRref};
    } else {
        foreach (@$refL) { $seenL{$_}++ }
        foreach (@$refR) { $seenR{$_}++ }
        @left  = @$refL;
        @right = @$refR;
    }
    my @bag = $unsortflag ? (@left, @right) : sort(@left, @right);
    my (%intersection, %union, %Lonly, %Ronly, %LorRonly);
    my $LsubsetR_status = my $RsubsetL_status = 1;
    my $LequivalentR_status = 0;

    foreach (keys %seenL) {
        $union{$_}++;
        exists $seenR{$_} ? $intersection{$_}++ : $Lonly{$_}++;
    }

    foreach (keys %seenR) {
        $union{$_}++;
        $Ronly{$_}++ unless (exists $intersection{$_});
    }

    $LorRonly{$_}++ foreach ( (keys %Lonly), (keys %Ronly) );

    $LequivalentR_status = 1 if ( (keys %LorRonly) == 0);

    foreach (@left) {
        if (! exists $seenR{$_}) {
            $LsubsetR_status = 0;
            last;
        }
    }
    foreach (@right) {
        if (! exists $seenL{$_}) {
            $RsubsetL_status = 0;
            last;
        }
    }

    $data{'seenL'}                = \%seenL;
    $data{'seenR'}                = \%seenR;
    $data{'intersection'}         = $unsortflag ? [      keys %intersection ]
                                                : [ sort keys %intersection ];
    $data{'union'}                = $unsortflag ? [      keys %union ]
                                                : [ sort keys %union ];
    $data{'unique'}               = $unsortflag ? [      keys %Lonly ]
                                                : [ sort keys %Lonly ];
    $data{'complement'}           = $unsortflag ? [      keys %Ronly ]
                                                : [ sort keys %Ronly ];
    $data{'symmetric_difference'} = $unsortflag ? [      keys %LorRonly ]
                                                : [ sort keys %LorRonly ];
    $data{'LsubsetR_status'}      = $LsubsetR_status;
    $data{'RsubsetL_status'}      = $RsubsetL_status;
    $data{'LequivalentR_status'}  = $LequivalentR_status;
    $data{'LdisjointR_status'}    = keys %intersection == 0 ? 1 : 0;
    $data{'bag'}                  = \@bag;
    return \%data;
}

sub get_intersection {
    return @{ get_intersection_ref(shift) };
}

sub get_intersection_ref {
    my $class = shift;
    my %data = %$class;
    return $data{'intersection'};
}

sub get_union {
    return @{ get_union_ref(shift) };
}

sub get_union_ref {
    my $class = shift;
    my %data = %$class;
    return $data{'union'};
}

sub get_shared {
    my $class = shift;
    my $method = (caller(0))[3];
    carp "When comparing only 2 lists, $method defaults to \n  ", 'get_intersection()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    get_intersection($class);
}

sub get_shared_ref {
    my $class = shift;
    my $method = (caller(0))[3];
    carp "When comparing only 2 lists, $method defaults to \n  ", 'get_intersection_ref()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    get_intersection_ref($class);
}

sub get_unique {
    return @{ get_unique_ref(shift) };
}

sub get_unique_ref {
    my $class = shift;
    my %data = %$class;
    return $data{'unique'};
}

sub get_unique_all {
    my $class = shift;
    my %data = %$class;
    return [ $data{'unique'}, $data{'complement'} ];
}

*get_Lonly = \&get_unique;
*get_Aonly = \&get_unique;
*get_Lonly_ref = \&get_unique_ref;
*get_Aonly_ref = \&get_unique_ref;

sub get_complement {
    return @{ get_complement_ref(shift) };
}

sub get_complement_ref {
    my $class = shift;
    my %data = %$class;
    return $data{'complement'};
}

sub get_complement_all {
    my $class = shift;
    my %data = %$class;
    return [ $data{'complement'}, $data{'unique'} ];
}

*get_Ronly = \&get_complement;
*get_Bonly = \&get_complement;
*get_Ronly_ref = \&get_complement_ref;
*get_Bonly_ref = \&get_complement_ref;

sub get_symmetric_difference {
    return @{ get_symmetric_difference_ref(shift) };
}

sub get_symmetric_difference_ref {
    my $class = shift;
    my %data = %$class;
    return $data{'symmetric_difference'};
}

*get_symdiff  = \&get_symmetric_difference;
*get_LorRonly = \&get_symmetric_difference;
*get_AorBonly = \&get_symmetric_difference;
*get_symdiff_ref  = \&get_symmetric_difference_ref;
*get_LorRonly_ref = \&get_symmetric_difference_ref;
*get_AorBonly_ref = \&get_symmetric_difference_ref;

sub get_nonintersection {
    my $class = shift;
    my $method = (caller(0))[3];
    carp "When comparing only 2 lists, $method defaults to \n  ", 'get_symmetric_difference()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    get_symmetric_difference($class);
}

sub get_nonintersection_ref {
    my $class = shift;
    my $method = (caller(0))[3];
    carp "When comparing only 2 lists, $method defaults to \n  ", 'get_symmetric_difference_ref()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    get_symmetric_difference_ref($class);
}

sub is_LsubsetR {
    my $class = shift;
    my %data = %$class;
    return $data{'LsubsetR_status'};
}

*is_AsubsetB = \&is_LsubsetR;

sub is_RsubsetL {
    my $class = shift;
    my %data = %$class;
    return $data{'RsubsetL_status'};
}

*is_BsubsetA = \&is_RsubsetL;

sub is_LequivalentR {
    my $class = shift;
    my %data = %$class;
    return $data{'LequivalentR_status'};
}

*is_LeqvlntR = \&is_LequivalentR;

sub is_LdisjointR {
    my $class = shift;
    my %data = %$class;
    return $data{'LdisjointR_status'};
}

sub print_subset_chart {
    my $class = shift;
    my %data = %$class;
    my @subset_array = ($data{'LsubsetR_status'}, $data{'RsubsetL_status'});
    my $title = 'Subset';
    _chart_engine_regular(\@subset_array, $title);
}

sub print_equivalence_chart {
    my $class = shift;
    my %data = %$class;
    my @equivalent_array = ($data{'LequivalentR_status'},
                            $data{'LequivalentR_status'});
    my $title = 'Equivalence';
    _chart_engine_regular(\@equivalent_array, $title);
}

sub is_member_which {
    return @{ is_member_which_ref(@_) };
}

sub is_member_which_ref {
    my $class = shift;
    croak "Method call requires exactly 1 argument (no references):  $!"
        unless (@_ == 1 and ref($_[0]) ne 'ARRAY');
    my %data = %$class;
    my ($arg, @found);
    $arg = shift;
    if (exists ${$data{'seenL'}}{$arg}) { push @found, 0; }
    if (exists ${$data{'seenR'}}{$arg}) { push @found, 1; }
    if ( (! exists ${$data{'seenL'}}{$arg}) &&
         (! exists ${$data{'seenR'}}{$arg}) )
       { @found = (); }
    return \@found;
}

sub are_members_which {
    my $class = shift;
    croak "Method call requires exactly 1 argument which must be an array reference\n    holding the items to be tested:  $!"
        unless (@_ == 1 and ref($_[0]) eq 'ARRAY');
    my %data = %$class;
    my (@args, %found);
    @args = @{$_[0]};
    for (my $i=0; $i<=$#args; $i++) {
        if (exists ${$data{'seenL'}}{$args[$i]}) { push @{$found{$args[$i]}}, 0; }
        if (exists ${$data{'seenR'}}{$args[$i]}) { push @{$found{$args[$i]}}, 1; }
        if ( (! exists ${$data{'seenL'}}{$args[$i]}) &&
             (! exists ${$data{'seenR'}}{$args[$i]}) )
           { @{$found{$args[$i]}} = (); }
    }
    return \%found;
}

sub is_member_any {
    my $class = shift;
    croak "Method call requires exactly 1 argument (no references):  $!"
        unless (@_ == 1 and ref($_[0]) ne 'ARRAY');
    my %data = %$class;
    my $arg = shift;
    ( defined $data{'seenL'}{$arg} ) ||
    ( defined $data{'seenR'}{$arg} ) ? return 1 : return 0;
}

sub are_members_any {
    my $class = shift;
    croak "Method call requires exactly 1 argument which must be an array reference\n    holding the items to be tested:  $!"
        unless (@_ == 1 and ref($_[0]) eq 'ARRAY');
    my %data = %$class;
    my (@args, %present);
    @args = @{$_[0]};
    for (my $i=0; $i<=$#args; $i++) {
    $present{$args[$i]} = ( defined $data{'seenL'}{$args[$i]} ) ||
                          ( defined $data{'seenR'}{$args[$i]} )     ? 1 : 0;
    }
    return \%present;
}

sub get_bag {
    return @{ get_bag_ref(shift) };
}

sub get_bag_ref {
    my $class = shift;
    my %data = %$class;
    return $data{'bag'};
}

sub get_version {
    return $List::Compare::VERSION;
}

1;

################################################################################

package List::Compare::Accelerated;
use Carp;
use List::Compare::Base::_Auxiliary qw(
    _argument_checker_0
    _chart_engine_regular
    _calc_seen
    _equiv_engine
);

sub _init {
    my $self = shift;
    my ($unsortflag, $refL, $refR) = @_;
    my %data = ();
    ($data{'L'}, $data{'R'}) = _argument_checker_0($refL, $refR);
    $data{'unsort'} = $unsortflag ? 1 : 0;
    return \%data;
}

sub get_intersection {
    return @{ get_intersection_ref(shift) };
}

sub get_intersection_ref {
    my $class = shift;
    my %data = %$class;
    $data{'unsort'}
      ? return          _intersection_engine($data{'L'}, $data{'R'})
      : return [ sort @{_intersection_engine($data{'L'}, $data{'R'})} ];
}

sub get_union {
    return @{ get_union_ref(shift) };
}

sub get_union_ref {
    my $class = shift;
    my %data = %$class;
    $data{'unsort'}
      ? return          _union_engine($data{'L'}, $data{'R'})
      : return [ sort @{_union_engine($data{'L'}, $data{'R'})} ];
}

sub get_shared {
    return @{ get_shared_ref(shift) };
}

sub get_shared_ref {
    my $class = shift;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing only 2 lists, \&$method defaults to \n  \&get_union_ref.  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    &get_union_ref($class);
}

sub get_unique {
    return @{ get_unique_ref(shift) };
}

sub get_unique_ref {
    my $class = shift;
    my %data = %$class;
    $data{'unsort'}
      ? return          _unique_engine($data{'L'}, $data{'R'})
      : return [ sort @{_unique_engine($data{'L'}, $data{'R'})} ];
}

sub get_unique_all {
    my $class = shift;
    return [ get_unique_ref($class), get_complement_ref($class) ];
}

*get_Lonly = \&get_unique;
*get_Aonly = \&get_unique;
*get_Lonly_ref = \&get_unique_ref;
*get_Aonly_ref = \&get_unique_ref;

sub get_complement {
    return @{ get_complement_ref(shift) };
}

sub get_complement_ref {
    my $class = shift;
    my %data = %$class;
    $data{'unsort'}
      ? return          _complement_engine($data{'L'}, $data{'R'})
      : return [ sort @{_complement_engine($data{'L'}, $data{'R'})} ];
}

sub get_complement_all {
    my $class = shift;
    return [ get_complement_ref($class), get_unique_ref($class) ];
}

*get_Ronly = \&get_complement;
*get_Bonly = \&get_complement;
*get_Ronly_ref = \&get_complement_ref;
*get_Bonly_ref = \&get_complement_ref;

sub get_symmetric_difference {
    return @{ get_symmetric_difference_ref(shift) };
}

sub get_symmetric_difference_ref {
    my $class = shift;
    my %data = %$class;
    $data{'unsort'}
      ? return          _symmetric_difference_engine($data{'L'}, $data{'R'})
      : return [ sort @{_symmetric_difference_engine($data{'L'}, $data{'R'})} ];
}

*get_symdiff  = \&get_symmetric_difference;
*get_LorRonly = \&get_symmetric_difference;
*get_AorBonly = \&get_symmetric_difference;
*get_symdiff_ref  = \&get_symmetric_difference_ref;
*get_LorRonly_ref = \&get_symmetric_difference_ref;
*get_AorBonly_ref = \&get_symmetric_difference_ref;

sub get_nonintersection {
    return @{ get_nonintersection_ref(shift) };
}

sub get_nonintersection_ref {
    my $class = shift;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing only 2 lists, \&$method defaults to \n  \&get_symmetric_difference_ref.  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    &get_symmetric_difference_ref($class);
}

sub is_LsubsetR {
    my $class = shift;
    my %data = %$class;
    return _is_LsubsetR_engine($data{'L'}, $data{'R'});
}

*is_AsubsetB  = \&is_LsubsetR;

sub is_RsubsetL {
    my $class = shift;
    my %data = %$class;
    return _is_RsubsetL_engine($data{'L'}, $data{'R'});
}

*is_BsubsetA  = \&is_RsubsetL;

sub is_LequivalentR {
    my $class = shift;
    my %data = %$class;
    return _is_LequivalentR_engine($data{'L'}, $data{'R'});
}

*is_LeqvlntR = \&is_LequivalentR;

sub is_LdisjointR {
    my $class = shift;
    my %data = %$class;
    return _is_LdisjointR_engine($data{'L'}, $data{'R'});
}

sub print_subset_chart {
    my $class = shift;
    my %data = %$class;
    _print_subset_chart_engine($data{'L'}, $data{'R'});
}

sub print_equivalence_chart {
    my $class = shift;
    my %data = %$class;
    _print_equivalence_chart_engine($data{'L'}, $data{'R'});
}

sub is_member_which {
    return @{ is_member_which_ref(@_) };
}

sub is_member_which_ref {
    my $class = shift;
    croak "Method call requires exactly 1 argument (no references):  $!"
        unless (@_ == 1 and ref($_[0]) ne 'ARRAY');
    my %data = %$class;
    return _is_member_which_engine($data{'L'}, $data{'R'}, shift);
}

sub are_members_which {
    my $class = shift;
    croak "Method call requires exactly 1 argument which must be an array reference\n    holding the items to be tested:  $!"
        unless (@_ == 1 and ref($_[0]) eq 'ARRAY');
    my %data = %$class;
    my (@args);
    @args = @{$_[0]};
    return _are_members_which_engine($data{'L'}, $data{'R'}, \@args);
}

sub is_member_any {
    my $class = shift;
    croak "Method call requires exactly 1 argument (no references):  $!"
        unless (@_ == 1 and ref($_[0]) ne 'ARRAY');
    my %data = %$class;
    return _is_member_any_engine($data{'L'}, $data{'R'}, shift);
}

sub are_members_any {
    my $class = shift;
    croak "Method call requires exactly 1 argument which must be an array reference\n    holding the items to be tested:  $!"
        unless (@_ == 1 and ref($_[0]) eq 'ARRAY');
    my %data = %$class;
    my (@args);
    @args = @{$_[0]};
    return _are_members_any_engine($data{'L'}, $data{'R'}, \@args);
}

sub get_bag {
    return @{ get_bag_ref(shift) };
}

sub get_bag_ref {
    my $class = shift;
    my %data = %$class;
    if (ref($data{'L'}) eq 'ARRAY') {
        $data{'unsort'} ? return [      @{$data{'L'}}, @{$data{'R'}}  ]
                        : return [ sort(@{$data{'L'}}, @{$data{'R'}}) ];
    } else {
        my (@left, @right);
        foreach my $key (keys %{$data{'L'}}) {
            for (my $j=1; $j <= ${$data{'L'}}{$key}; $j++) {
                push(@left, $key);
            }
        }
        foreach my $key (keys %{$data{'R'}}) {
            for (my $j=1; $j <= ${$data{'R'}}{$key}; $j++) {
                push(@right, $key);
            }
        }
        $data{'unsort'} ? return [      @left, @right  ]
                        : return [ sort(@left, @right) ];
    }
}

sub get_version {
    return $List::Compare::VERSION;
}

sub _intersection_engine {
    my ($l, $r) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my %intersection = ();
    foreach (keys %{$hrefL}) {
        $intersection{$_}++ if (exists ${$hrefR}{$_});
    }
    return [ keys %intersection ];
}

sub _union_engine {
    my ($l, $r) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my %union = ();
    $union{$_}++ foreach ( (keys %{$hrefL}), (keys %{$hrefR}) );
    return [ keys %union ];
}

sub _unique_engine {
    my ($l, $r) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my (%Lonly);
    foreach (keys %{$hrefL}) {
        $Lonly{$_}++ unless exists ${$hrefR}{$_};
    }
    return [ keys %Lonly ];
}

sub _complement_engine {
    my ($l, $r) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my (%Ronly);
    foreach (keys %{$hrefR}) {
        $Ronly{$_}++ unless (exists ${$hrefL}{$_});
    }
    return [ keys %Ronly ];
}

sub _symmetric_difference_engine {
    my ($l, $r) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my (%LorRonly);
    foreach (keys %{$hrefL}) {
        $LorRonly{$_}++ unless (exists ${$hrefR}{$_});
    }
    foreach (keys %{$hrefR}) {
        $LorRonly{$_}++ unless (exists ${$hrefL}{$_});
    }
    return [ keys %LorRonly ];
}

sub _is_LsubsetR_engine {
    my ($l, $r) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my $LsubsetR_status = 1;
    foreach (keys %{$hrefL}) {
        if (! exists ${$hrefR}{$_}) {
            $LsubsetR_status = 0;
            last;
        }
    }
    return $LsubsetR_status;
}

sub _is_RsubsetL_engine {
    my ($l, $r) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my $RsubsetL_status = 1;
    foreach (keys %{$hrefR}) {
        if (! exists ${$hrefL}{$_}) {
            $RsubsetL_status = 0;
            last;
        }
    }
    return $RsubsetL_status;
}

sub _is_LequivalentR_engine {
    my ($l, $r) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    return _equiv_engine($hrefL, $hrefR);
}

sub _is_LdisjointR_engine {
    my ($l, $r) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my %intersection = ();
    foreach (keys %{$hrefL}) {
        $intersection{$_}++ if (exists ${$hrefR}{$_});
    }
    keys %intersection == 0 ? 1 : 0;
}

sub _print_subset_chart_engine {
    my ($l, $r) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my $LsubsetR_status = my $RsubsetL_status = 1;
    foreach (keys %{$hrefL}) {
        if (! exists ${$hrefR}{$_}) {
            $LsubsetR_status = 0;
            last;
        }
    }
    foreach (keys %{$hrefR}) {
        if (! exists ${$hrefL}{$_}) {
            $RsubsetL_status = 0;
            last;
        }
    }
    my @subset_array = ($LsubsetR_status, $RsubsetL_status);
    my $title = 'Subset';
    _chart_engine_regular(\@subset_array, $title);
}

sub _print_equivalence_chart_engine {
    my ($l, $r) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my $LequivalentR_status = _equiv_engine($hrefL, $hrefR);
    my @equivalent_array = ($LequivalentR_status, $LequivalentR_status);
    my $title = 'Equivalence';
    _chart_engine_regular(\@equivalent_array, $title);
}

sub _is_member_which_engine {
    my ($l, $r, $arg) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my (@found);
    if (exists ${$hrefL}{$arg}) { push @found, 0; }
    if (exists ${$hrefR}{$arg}) { push @found, 1; }
    if ( (! exists ${$hrefL}{$arg}) &&
         (! exists ${$hrefR}{$arg}) )
       { @found = (); }
    return \@found;
}

sub _are_members_which_engine {
    my ($l, $r, $arg) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my @args = @{$arg};
    my (%found);
    for (my $i=0; $i<=$#args; $i++) {
        if (exists ${$hrefL}{$args[$i]}) { push @{$found{$args[$i]}}, 0; }
        if (exists ${$hrefR}{$args[$i]}) { push @{$found{$args[$i]}}, 1; }
        if ( (! exists ${$hrefL}{$args[$i]}) &&
             (! exists ${$hrefR}{$args[$i]}) )
           { @{$found{$args[$i]}} = (); }
    }
    return \%found;
}

sub _is_member_any_engine {
    my ($l, $r, $arg) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    ( defined ${$hrefL}{$arg} ) ||
    ( defined ${$hrefR}{$arg} ) ? return 1 : return 0;
}

sub _are_members_any_engine {
    my ($l, $r, $arg) = @_;
    my ($hrefL, $hrefR) = _calc_seen($l, $r);
    my @args = @{$arg};
    my (%present);
    for (my $i=0; $i<=$#args; $i++) {
        $present{$args[$i]} = ( defined ${$hrefL}{$args[$i]} ) ||
                              ( defined ${$hrefR}{$args[$i]} ) ? 1 : 0;
    }
    return \%present;
}

1;

################################################################################

package List::Compare::Multiple;
use Carp;
use List::Compare::Base::_Auxiliary qw(
    _validate_seen_hash
    _index_message1
    _index_message2
    _chart_engine_multiple
);

sub _init {
    my $self = shift;
    my $unsortflag = shift;
    my @listrefs = @_;
    my (@arrayrefs);
    my $maxindex = $#listrefs;
    if (ref($listrefs[0]) eq 'ARRAY') {
        @arrayrefs = @listrefs;
    } else {
        _validate_seen_hash(@listrefs);
        foreach my $href (@listrefs) {
            my (@temp);
            foreach my $key (keys %{$href}) {
               for (my $j=1; $j <= ${$href}{$key}; $j++) {
                   push(@temp, $key);
               }
            }
            push(@arrayrefs, \@temp);
        }
    }

    my @bag = ();
    foreach my $aref (@arrayrefs) {
        push @bag, $_ foreach @$aref;
    }
    @bag = sort(@bag) unless $unsortflag;

    my (@intersection, @union);
        # will hold overall intersection/union
    my @nonintersection = ();
        # will hold all items except those found in each source list
        # @intersection + @nonintersection = @union
    my @shared = ();
        # will hold all items found in at least 2 lists
    my @symmetric_difference = ();
        # will hold each item found in only one list regardless of list;
        # equivalent to @union minus all items found in the lists
        # underlying %xintersection
    my (%intersection, %union);
        # will be used to generate @intersection & @union
    my %seen = ();
        # will be hash of hashes, holding seen-hashes corresponding to
        # the source lists
    my %xintersection = ();
        # will be hash of hashes, holding seen-hashes corresponding to
        # the lists containing the intersections of each permutation of
        # the source lists
    my %shared = ();
        # will be used to generate @shared
    my @xunique = ();
        # will be array of arrays, holding the items that are unique to
        # the list whose index number is passed as an argument
    my @xcomplement = ();
        # will be array of arrays, holding the items that are found in
        # any list other than the list whose index number is passed
        # as an argument
    my @xdisjoint = ();
        # will be an array of arrays, holding an indicator as to whether
        # any pair of lists are disjoint, i.e., have no intersection

    # Calculate overall union and take steps needed to calculate overall
    # intersection, unique, difference, etc.
    for (my $i = 0; $i <= $#arrayrefs; $i++) {
        my %seenthis = ();
        foreach (@{$arrayrefs[$i]}) {
            $seenthis{$_}++;
            $union{$_}++;
        }
        $seen{$i} = \%seenthis;
        for (my $j = $i+1; $j <=$#arrayrefs; $j++) {
            my (%seenthat, %seenintersect);
            my $ilabel = $i . '_' . $j;
            $seenthat{$_}++ foreach (@{$arrayrefs[$j]});
            foreach (keys %seenthat) {
                $seenintersect{$_}++ if (exists $seenthis{$_});
            }
            $xintersection{$ilabel} = \%seenintersect;
        }
    }
    @union = $unsortflag ? keys %union : sort(keys %union);

    # At this point we now have %seen, @union and %xintersection available
    # for use in other calculations.

    # Calculate overall intersection
    # Inputs:  %xintersection
    my @xkeys = keys %xintersection;
    %intersection = %{$xintersection{$xkeys[0]}};
    for (my $m = 1; $m <= $#xkeys; $m++) {
        my %compare = %{$xintersection{$xkeys[$m]}};
        my %result = ();
        foreach (keys %compare) {
            $result{$_}++ if (exists $intersection{$_});
        }
        %intersection = %result;
    }
    @intersection = $unsortflag ? keys %intersection : sort(keys %intersection);

    # Calculate nonintersection
    # Inputs:  @union    %intersection
    foreach (@union) {
        push(@nonintersection, $_) unless (exists $intersection{$_});
    }

    # Calculate @xunique and @xdisjoint
    # Inputs:  @arrayrefs    %seen    %xintersection
    for (my $i = 0; $i <= $#arrayrefs; $i++) {
        my %seenthis = %{$seen{$i}};
        my (@uniquethis, %deductions, %alldeductions);
        # Get those elements of %xintersection which we'll need
        # to subtract from %seenthis
        foreach (keys %xintersection) {
            my ($left, $right) = split /_/, $_;
            if ($left == $i || $right == $i) {
                $deductions{$_} = $xintersection{$_};
            }
            $xdisjoint[$left][$right] = $xdisjoint[$right][$left] =
                ! (keys %{$xintersection{$_}}) ? 1 : 0;
        }
        foreach my $ded (keys %deductions) {
            foreach (keys %{$deductions{$ded}}) {
                $alldeductions{$_}++;
            }
        }
        foreach (keys %seenthis) {
            push(@uniquethis, $_) unless ($alldeductions{$_});
        }
        $xunique[$i] = \@uniquethis;
        $xdisjoint[$i][$i] = 0;
    }
    # @xunique is now available for use in further calculations,
    # such as returning the items unique to a particular source list.

    # Calculate @xcomplement
    # Inputs:  @arrayrefs    %seen    @union
    for (my $i = 0; $i <= $#arrayrefs; $i++) {
        my %seenthis = %{$seen{$i}};
        my @complementthis = ();
        foreach (@union) {
            push(@complementthis, $_) unless (exists $seenthis{$_});
        }
        $xcomplement[$i] = \@complementthis;
    }
    # @xcomplement is now available for use in further calculations,
    # such as returning the items in all lists different from those in a
    # particular source list.

    # Calculate @shared and @symmetric_difference
    # Inputs:  %xintersection    @union
    foreach my $q (keys %xintersection) {
        $shared{$_}++ foreach (keys %{$xintersection{$q}});
    }
    @shared = $unsortflag ? keys %shared : sort(keys %shared);
    foreach (@union) {
        push(@symmetric_difference, $_) unless (exists $shared{$_});
    }
    # @shared and @symmetric_difference are now available.

    my @xsubset = ();
    foreach my $i (keys %seen) {
        my %tempi = %{$seen{$i}};
        foreach my $j (keys %seen) {
            my %tempj = %{$seen{$j}};
            $xsubset[$i][$j] = 1;
            foreach (keys %tempi) {
                $xsubset[$i][$j] = 0 if (! $tempj{$_});
            }
        }
    }
    # @xsubset is now available

    my @xequivalent = ();
    for (my $f = 0; $f <= $#xsubset; $f++) {
        for (my $g = 0; $g <= $#xsubset; $g++) {
            $xequivalent[$f][$g] = 0;
            $xequivalent[$f][$g] = 1
                if ($xsubset[$f][$g] and $xsubset[$g][$f]);
        }
    }

    my (%data);
    $data{'seen'}                   = \%seen;
    $data{'maxindex'}               = $maxindex;
    $data{'intersection'}           = \@intersection;
    $data{'nonintersection'}        = \@nonintersection;
    $data{'union'}                  = \@union;
    $data{'shared'}                 = \@shared;
    $data{'symmetric_difference'}   = \@symmetric_difference;
    $data{'xunique'}                = \@xunique;
    $data{'xcomplement'}            = \@xcomplement;
    $data{'xsubset'}                = \@xsubset;
    $data{'xequivalent'}            = \@xequivalent;
    $data{'xdisjoint'}              = \@xdisjoint;
    $data{'bag'}                    = \@bag;
    return \%data;
}

sub get_intersection {
    return @{ get_intersection_ref(shift) };
}

sub get_intersection_ref {
    my $class = shift;
    my %data = %$class;
    return $data{'intersection'};
}

sub get_union {
    return @{ get_union_ref(shift) };
}

sub get_union_ref {
    my $class = shift;
    my %data = %$class;
    return $data{'union'};
}

sub get_shared {
    return @{ get_shared_ref(shift) };
}

sub get_shared_ref {
    my $class = shift;
    my %data = %$class;
    return $data{'shared'};
}

sub get_unique {
    my $class = shift;
    my %data = %$class;
    my $index = defined $_[0] ? shift : 0;
    return @{ get_unique_ref($class, $index) };
}

sub get_unique_ref {
    my $class = shift;
    my %data = %$class;
    my $index = defined $_[0] ? shift : 0;
    _index_message1($index, \%data);
    return ${$data{'xunique'}}[$index];
}

sub get_unique_all {
    my $class = shift;
    my %data = %$class;
    return $data{'xunique'};
}

sub get_Lonly {
    my ($class, $index) = @_;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias defaults to \n  ", 'get_unique()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    get_unique($class, $index);
}

sub get_Lonly_ref {
    my ($class, $index) = @_;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias defaults to \n  ", 'get_unique_ref()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    get_unique_ref($class, $index);
}

*get_Aonly = \&get_Lonly;
*get_Aonly_ref = \&get_Lonly_ref;

sub get_complement {
    my $class = shift;
    my %data = %$class;
    my $index = defined $_[0] ? shift : 0;
    return @{ get_complement_ref($class, $index) };
}

sub get_complement_ref {
    my $class = shift;
    my %data = %$class;
    my $index = defined $_[0] ? shift : 0;
    _index_message1($index, \%data);
    return ${$data{'xcomplement'}}[$index];
}

sub get_complement_all {
    my $class = shift;
    my %data = %$class;
    return $data{'xcomplement'};
}

sub get_Ronly {
    my ($class, $index) = @_;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias defaults to \n  ", 'get_complement()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    &get_complement($class, $index);
}

sub get_Ronly_ref {
    my ($class, $index) = @_;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias defaults to \n  ", 'get_complement_ref()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    &get_complement_ref($class, $index);
}

*get_Bonly = \&get_Ronly;
*get_Bonly_ref = \&get_Ronly_ref;

sub get_symmetric_difference {
    return @{ get_symmetric_difference_ref(shift) };
}

sub get_symmetric_difference_ref {
    my $class = shift;
    my %data = %$class;
    return $data{'symmetric_difference'};
}

*get_symdiff  = \&get_symmetric_difference;
*get_symdiff_ref  = \&get_symmetric_difference_ref;

sub get_LorRonly {
    my $class = shift;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias defaults to \n  ", 'get_symmetric_difference()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    get_symmetric_difference($class);
}

sub get_LorRonly_ref {
    my $class = shift;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias defaults to \n  ", 'get_symmetric_difference_ref()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    get_symmetric_difference_ref($class);
}

*get_AorBonly = \&get_LorRonly;
*get_AorBonly_ref = \&get_LorRonly_ref;

sub get_nonintersection {
    return @{ get_nonintersection_ref(shift) };
}

sub get_nonintersection_ref {
    my $class = shift;
    my %data = %$class;
    return $data{'nonintersection'};
}

sub is_LsubsetR {
    my $class = shift;
    my %data = %$class;
    my ($index_left, $index_right) = _index_message2(\%data, @_);
    my @subset_array = @{$data{'xsubset'}};
    my $subset_status = $subset_array[$index_left][$index_right];
    return $subset_status;
}

*is_AsubsetB = \&is_LsubsetR;

sub is_RsubsetL {
    my $class = shift;
    my %data = %$class;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias is restricted to \n  asking if the list which is the 2nd argument to the constructor \n    is a subset of the list which is the 1st argument.\n      For greater flexibility, please re-code with \&is_LsubsetR: $!";
    @_ = (1,0);
    my ($index_left, $index_right) = _index_message2(\%data, @_);
    my @subset_array = @{$data{'xsubset'}};
    my $subset_status = $subset_array[$index_left][$index_right];
    return $subset_status;
}

*is_BsubsetA = \&is_RsubsetL;

sub is_LequivalentR {
    my $class = shift;
    my %data = %$class;
    my ($index_left, $index_right) = _index_message2(\%data, @_);
    my @equivalent_array = @{$data{'xequivalent'}};
    my $equivalent_status = $equivalent_array[$index_left][$index_right];
    return $equivalent_status;
}

*is_LeqvlntR = \&is_LequivalentR;

sub is_LdisjointR {
    my $class = shift;
    my %data = %$class;
    my ($index_left, $index_right) = _index_message2(\%data, @_);
    my @disjoint_array = @{$data{'xdisjoint'}};
    my $disjoint_status = $disjoint_array[$index_left][$index_right];
    return $disjoint_status;
}

sub is_member_which {
    return @{ is_member_which_ref(@_) };
}

sub is_member_which_ref {
    my $class = shift;
    croak "Method call requires exactly 1 argument (no references):  $!"
        unless (@_ == 1 and ref($_[0]) ne 'ARRAY');
    my %data = %$class;
    my %seen = %{$data{'seen'}};
    my ($arg, @found);
    $arg = shift;
    foreach (sort keys %seen) {
        push @found, $_ if (exists $seen{$_}{$arg});
    }
    return \@found;
}

sub are_members_which {
    my $class = shift;
    croak "Method call requires exactly 1 argument which must be an array reference\n    holding the items to be tested:  $!"
        unless (@_ == 1 and ref($_[0]) eq 'ARRAY');
    my %data = %$class;
    my %seen = %{$data{'seen'}};
    my (@args, %found);
    @args = @{$_[0]};
    for (my $i=0; $i<=$#args; $i++) {
        my (@not_found);
        foreach (sort keys %seen) {
            exists ${$seen{$_}}{$args[$i]}
                ? push @{$found{$args[$i]}}, $_
                : push @not_found, $_;
        }
        $found{$args[$i]} = [] if (@not_found == keys %seen);
    }
    return \%found;
}

sub is_member_any {
    my $class = shift;
    croak "Method call requires exactly 1 argument (no references):  $!"
        unless (@_ == 1 and ref($_[0]) ne 'ARRAY');
    my %data = %$class;
    my %seen = %{$data{'seen'}};
    my ($arg, $k);
    $arg = shift;
    while ( $k = each %seen ) {
        return 1 if (defined $seen{$k}{$arg});
    }
    return 0;
}

sub are_members_any {
    my $class = shift;
    croak "Method call requires exactly 1 argument which must be an array reference\n    holding the items to be tested:  $!"
        unless (@_ == 1 and ref($_[0]) eq 'ARRAY');
    my %data = %$class;
    my %seen = %{$data{'seen'}};
    my (@args, %present);
    @args = @{$_[0]};
    for (my $i=0; $i<=$#args; $i++) {
        foreach (keys %seen) {
            unless (defined $present{$args[$i]}) {
                $present{$args[$i]} = 1 if $seen{$_}{$args[$i]};
            }
        }
        $present{$args[$i]} = 0 if (! defined $present{$args[$i]});
    }
    return \%present;
}

sub print_subset_chart {
    my $class = shift;
    my %data = %$class;
    my @subset_array = @{$data{'xsubset'}};
    my $title = 'Subset';
    _chart_engine_multiple(\@subset_array, $title);
}

sub print_equivalence_chart {
    my $class = shift;
    my %data = %$class;
    my @equivalent_array = @{$data{'xequivalent'}};
    my $title = 'Equivalence';
    _chart_engine_multiple(\@equivalent_array, $title);
}

sub get_bag {
    return @{ get_bag_ref(shift) };
}

sub get_bag_ref {
    my $class = shift;
    my %data = %$class;
    return $data{'bag'};
}

sub get_version {
    return $List::Compare::VERSION;
}

1;

################################################################################

package List::Compare::Multiple::Accelerated;
use Carp;
use List::Compare::Base::_Auxiliary qw(
    _argument_checker_0
    _prepare_listrefs
    _subset_subengine
    _chart_engine_multiple
    _equivalent_subengine
    _index_message3
    _index_message4
    _subset_engine_multaccel
);
use List::Compare::Base::_Auxiliary qw(:calculate);
use List::Compare::Base::_Engine    qw(
    _unique_all_engine
    _complement_all_engine
);

sub _init {
    my $self = shift;
    my $unsortflag = shift;
    my @listrefs = _argument_checker_0(@_);
    my %data = ();
    for (my $i=0; $i<=$#listrefs; $i++) {
        $data{$i} = $listrefs[$i];
    }
    $data{'unsort'} = $unsortflag ? 1 : 0;
    return \%data;
}

sub get_union {
    return @{ get_union_ref(shift) };
}

sub get_union_ref {
    my $class = shift;
    my %data = %$class;
    my $unsortflag = $data{'unsort'};
    my $aref = _prepare_listrefs(\%data);

    my $unionref = _calculate_union_only($aref);
    my @union = $unsortflag ? keys %{$unionref} : sort(keys %{$unionref});
    return \@union;
}

sub get_intersection {
    return @{ get_intersection_ref(shift) };
}

sub get_intersection_ref {
    my $class = shift;
    my %data = %$class;
    my $unsortflag = $data{'unsort'};
    my $aref = _prepare_listrefs(\%data);
    my $intermediate_ref = _calculate_intermediate($aref);
    my @intersection =
        $unsortflag ? keys %{$intermediate_ref} : sort(keys %{$intermediate_ref});
    return \@intersection;
}

sub get_nonintersection {
    return @{ get_nonintersection_ref(shift) };
}

sub get_nonintersection_ref {
    my $class = shift;
    my %data = %$class;
    my $unsortflag = $data{'unsort'};
    my $aref = _prepare_listrefs(\%data);

    my $unionref = _calculate_union_only($aref);
    my $intermediate_ref = _calculate_intermediate($aref);
    my (@nonintersection);
    foreach my $el (keys %{$unionref}) {
        push(@nonintersection, $el) unless exists $intermediate_ref->{$el};
    }
    return [ $unsortflag ? @nonintersection : sort(@nonintersection) ];
}

sub get_shared {
    return @{ get_shared_ref(shift) };
}

sub get_shared_ref {
    my $class = shift;
    my %data = %$class;
    my $unsortflag = $data{'unsort'};
    my $aref = _prepare_listrefs(\%data);
    my $aseenref = _calculate_array_seen_only($aref);
    my $intermediate = _calculate_sharedref($aseenref);
    my @shared = $unsortflag ? keys %{$intermediate} : sort(keys %{$intermediate});
    return \@shared;
}

sub get_symmetric_difference {
    return @{ get_symmetric_difference_ref(shift) };
}

sub get_symmetric_difference_ref {
    my $class = shift;
    my %data = %$class;
    my $unsortflag = $data{'unsort'};
    my $aref = _prepare_listrefs(\%data);
    my $unionref = _calculate_union_only($aref);

    my $aseenref = _calculate_array_seen_only($aref);
    my $sharedref = _calculate_sharedref($aseenref);

    my (@symmetric_difference);
    foreach my $el (keys %{$unionref}) {
        push(@symmetric_difference, $el) unless exists $sharedref->{$el};
    }
    return [ $unsortflag ? @symmetric_difference : sort(@symmetric_difference) ];
}

*get_symdiff = \&get_symmetric_difference;
*get_symdiff_ref = \&get_symmetric_difference_ref;

sub get_LorRonly {
    my $class = shift;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias defaults to \n  ", 'get_symmetric_difference()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    get_symmetric_difference($class);
}

sub get_LorRonly_ref {
    my $class = shift;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias defaults to \n  ", 'get_symmetric_difference_ref()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    get_symmetric_difference_ref($class);
}

*get_AorBonly = \&get_LorRonly;
*get_AorBonly_ref = \&get_LorRonly_ref;

sub get_unique {
    my $class = shift;
    my %data = %$class;
    my $index = defined $_[0] ? shift : 0;
    return @{ get_unique_ref($class, $index) };
}

sub get_unique_ref {
    my $class = shift;
    my %data = %$class;
    my $index = defined $_[0] ? shift : 0;
    my $aref = _prepare_listrefs(\%data);
    _index_message3($index, $#{$aref});

    my $unique_all_ref = _unique_all_engine($aref);
    return ${$unique_all_ref}[$index];
}

sub get_unique_all {
    my $class = shift;
    my %data = %$class;
    my $aref = _prepare_listrefs(\%data);
    return _unique_all_engine($aref);
}

sub get_Lonly {
    my ($class, $index) = @_;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias defaults to \n  ", 'get_unique()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    get_unique($class, $index);
}

sub get_Lonly_ref {
    my ($class, $index) = @_;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias defaults to \n  ", 'get_unique_ref()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    get_unique_ref($class, $index);
}

*get_Aonly = \&get_Lonly;
*get_Aonly_ref = \&get_Lonly_ref;

sub get_complement {
    my $class = shift;
    my %data = %$class;
    my $index = defined $_[0] ? shift : 0;
    return @{ get_complement_ref($class, $index) };
}

sub get_complement_ref {
    my $class = shift;
    my %data = %$class;
    my $index = defined $_[0] ? shift : 0;
    my $unsortflag = $data{'unsort'};
    my $aref = _prepare_listrefs(\%data);
    _index_message3($index, $#{$aref});

    my $complement_all_ref = _complement_all_engine($aref, $unsortflag );
    return ${$complement_all_ref}[$index];
}

sub get_complement_all {
    my $class = shift;
    my %data = %$class;
    my $aref = _prepare_listrefs(\%data);
    return _complement_all_engine($aref);
}

sub get_Ronly {
    my ($class, $index) = @_;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias defaults to \n  ", 'get_complement()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    &get_complement($class, $index);
}

sub get_Ronly_ref {
    my ($class, $index) = @_;
    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias defaults to \n  ", 'get_complement_ref()', ".  Though the results returned are valid, \n    please consider re-coding with that method: $!";
    &get_complement_ref($class, $index);
}

*get_Bonly = \&get_Ronly;
*get_Bonly_ref = \&get_Ronly_ref;

sub is_LsubsetR {
    my $class = shift;
    my %data = %$class;
    my $subset_status = _subset_engine_multaccel(\%data, @_);
    return $subset_status;
}

*is_AsubsetB = \&is_LsubsetR;

sub is_RsubsetL {
    my $class = shift;
    my %data = %$class;

    my $method = (caller(0))[3];
    $method =~ s/.*::(\w*)$/$1/;
    carp "When comparing 3 or more lists, \&$method or its alias is restricted to \n  asking if the list which is the 2nd argument to the constructor \n    is a subset of the list which is the 1st argument.\n      For greater flexibility, please re-code with \&is_LsubsetR: $!";
    @_ = (1,0);

    my $subset_status = _subset_engine_multaccel(\%data, @_);
    return $subset_status;
}

*is_BsubsetA = \&is_RsubsetL;

sub is_LequivalentR {
    my $class = shift;
    my %data = %$class;
    my $aref = _prepare_listrefs(\%data);
    my ($index_left, $index_right) = _index_message4($#{$aref}, @_);

    my $xequivalentref = _equivalent_subengine($aref);
    return ${$xequivalentref}[$index_left][$index_right];
}

*is_LeqvlntR = \&is_LequivalentR;

sub is_LdisjointR {
    my $class = shift;
    my %data = %$class;
    my $aref = _prepare_listrefs(\%data);
    my ($index_left, $index_right) = _index_message4($#{$aref}, @_);
    my $aseenref = _calculate_array_seen_only(
        [ $aref->[$index_left], $aref->[$index_right] ]
    );
    my $disjoint_status = 1;
    OUTER: for my $k (keys %{$aseenref->[0]}) {
        if ($aseenref->[1]->{$k}) {
            $disjoint_status = 0;
            last OUTER;
        }
    }
    return $disjoint_status;
}

sub is_member_which {
    return @{ is_member_which_ref(@_) };
}

sub is_member_which_ref {
    my $class = shift;
    croak "Method call requires exactly 1 argument (no references):  $!"
        unless (@_ == 1 and ref($_[0]) ne 'ARRAY');
    my %data = %{$class};
    my $aref = _prepare_listrefs(\%data);
    my $seenref = _calculate_seen_only($aref);
    my ($arg, @found);
    $arg = shift;
    foreach (sort keys %{$seenref}) {
        push @found, $_ if (exists ${$seenref}{$_}{$arg});
    }
    return \@found;
}

sub are_members_which {
    my $class = shift;
    croak "Method call requires exactly 1 argument which must be an array reference\n    holding the items to be tested:  $!"
        unless (@_ == 1 and ref($_[0]) eq 'ARRAY');
    my %data = %{$class};
    my $aref = _prepare_listrefs(\%data);
    my $seenref = _calculate_seen_only($aref);
    my (@args, %found);
    @args = @{$_[0]};
    for (my $i=0; $i<=$#args; $i++) {
        my (@not_found);
        foreach (sort keys %{$seenref}) {
            exists ${${$seenref}{$_}}{$args[$i]}
                ? push @{$found{$args[$i]}}, $_
                : push @not_found, $_;
        }
        $found{$args[$i]} = [] if (@not_found == keys %{$seenref});
    }
    return \%found;
}

sub is_member_any {
    my $class = shift;
    croak "Method call requires exactly 1 argument (no references):  $!"
        unless (@_ == 1 and ref($_[0]) ne 'ARRAY');
    my %data = %$class;
    my $aref = _prepare_listrefs(\%data);
    my $seenref = _calculate_seen_only($aref);
    my ($arg, $k);
    $arg = shift;
    while ( $k = each %{$seenref} ) {
        return 1 if (defined ${$seenref}{$k}{$arg});
    }
    return 0;
}

sub are_members_any {
    my $class = shift;
    croak "Method call requires exactly 1 argument which must be an array reference\n    holding the items to be tested:  $!"
        unless (@_ == 1 and ref($_[0]) eq 'ARRAY');
    my %data = %$class;
    my $aref = _prepare_listrefs(\%data);
    my $seenref = _calculate_seen_only($aref);
    my (@args, %present);
    @args = @{$_[0]};
    for (my $i=0; $i<=$#args; $i++) {
        foreach (keys %{$seenref}) {
            unless (defined $present{$args[$i]}) {
                $present{$args[$i]} = 1 if ${$seenref}{$_}{$args[$i]};
            }
        }
        $present{$args[$i]} = 0 if (! defined $present{$args[$i]});
    }
    return \%present;
}

sub print_subset_chart {
    my $class = shift;
    my %data = %$class;
    my $aref = _prepare_listrefs(\%data);
    my $xsubsetref = _subset_subengine($aref);
    my $title = 'Subset';
    _chart_engine_multiple($xsubsetref, $title);
}

sub print_equivalence_chart {
    my $class = shift;
    my %data = %$class;
    my $aref = _prepare_listrefs(\%data);
    my $xequivalentref = _equivalent_subengine($aref);
    my $title = 'Equivalence';
    _chart_engine_multiple($xequivalentref, $title);
}

sub get_bag {
    return @{ get_bag_ref(shift) };
}

sub get_bag_ref {
    my $class = shift;
    my %data = %$class;
    my $unsortflag = $data{'unsort'};
    my $aref = _prepare_listrefs(\%data);
    my (@bag);
    my @listrefs = @{$aref};
    if (ref($listrefs[0]) eq 'ARRAY') {
        foreach my $lref (@listrefs) {
            foreach my $el (@{$lref}) {
                push(@bag, $el);
            }
        }
    } else {
        foreach my $lref (@listrefs) {
            foreach my $key (keys %{$lref}) {
                for (my $j=1; $j <= ${$lref}{$key}; $j++) {
                    push(@bag, $key);
                }
            }
        }
    }
    @bag = sort(@bag) unless $unsortflag;
    return \@bag;
}

sub get_version {
    return $List::Compare::VERSION;
}

1;


#################### DOCUMENTATION ####################

=head1 NAME

List::Compare - Compare elements of two or more lists

=head1 VERSION

This document refers to version 0.52 of List::Compare.  This version was
released May 21 2015.

=head1 SYNOPSIS

The bare essentials:

    @Llist = qw(abel abel baker camera delta edward fargo golfer);
    @Rlist = qw(baker camera delta delta edward fargo golfer hilton);

    $lc = List::Compare->new(\@Llist, \@Rlist);

    @intersection = $lc->get_intersection;
    @union = $lc->get_union;

... and so forth.

=head1 DISCUSSION:  Modes and Methods

=head2 Regular Case:  Compare Two Lists

=over 4

=item * Constructor:  C<new()>

Create a List::Compare object.  Put the two lists into arrays (named or
anonymous) and pass references to the arrays to the constructor.

    @Llist = qw(abel abel baker camera delta edward fargo golfer);
    @Rlist = qw(baker camera delta delta edward fargo golfer hilton);

    $lc = List::Compare->new(\@Llist, \@Rlist);

By default, List::Compare's methods return lists which are sorted using
Perl's default C<sort> mode:  ASCII-betical sorting.  Should you
not need to have these lists sorted, you may achieve a speed boost
by constructing the List::Compare object with the unsorted option:

    $lc = List::Compare->new('-u', \@Llist, \@Rlist);

or

    $lc = List::Compare->new('--unsorted', \@Llist, \@Rlist);

=item * Alternative Constructor

If you prefer a more explicit delineation of the types of arguments passed
to a function, you may use this 'single hashref' kind of constructor to build a
List::Compare object:

    $lc = List::Compare->new( { lists => [\@Llist, \@Rlist] } );

or

    $lc = List::Compare->new( {
        lists    => [\@Llist, \@Rlist],
        unsorted => 1,
    } );

=item * C<get_intersection()>

Get those items which appear at least once in both lists (their intersection).

    @intersection = $lc->get_intersection;

=item * C<get_union()>

Get those items which appear at least once in either list (their union).

    @union = $lc->get_union;

=item * C<get_unique()>

Get those items which appear (at least once) only in the first list.

    @Lonly = $lc->get_unique;
    @Lonly = $lc->get_Lonly;    # alias

=item * C<get_complement()>

Get those items which appear (at least once) only in the second list.

    @Ronly = $lc->get_complement;
    @Ronly = $lc->get_Ronly;            # alias

=item * C<get_symmetric_difference()>

Get those items which appear at least once in either the first or the second
list, but not both.

    @LorRonly = $lc->get_symmetric_difference;
    @LorRonly = $lc->get_symdiff;       # alias
    @LorRonly = $lc->get_LorRonly;      # alias

=item * C<get_bag()>

Make a bag of all those items in both lists.  The bag differs from the
union of the two lists in that it holds as many copies of individual
elements as appear in the original lists.

    @bag = $lc->get_bag;

=item * Return references rather than lists

An alternative approach to the above methods:  If you do not immediately
require an array as the return value of the method call, but simply need
a I<reference> to an (anonymous) array, use one of the following
parallel methods:

    $intersection_ref = $lc->get_intersection_ref;
    $union_ref        = $lc->get_union_ref;
    $Lonly_ref        = $lc->get_unique_ref;
    $Lonly_ref        = $lc->get_Lonly_ref;                 # alias
    $Ronly_ref        = $lc->get_complement_ref;
    $Ronly_ref        = $lc->get_Ronly_ref;                 # alias
    $LorRonly_ref     = $lc->get_symmetric_difference_ref;
    $LorRonly_ref     = $lc->get_symdiff_ref;               # alias
    $LorRonly_ref     = $lc->get_LorRonly_ref;              # alias
    $bag_ref          = $lc->get_bag_ref;

=item * C<is_LsubsetR()>

Return a true value if the first argument passed to the constructor
('L' for 'left') is a subset of the second argument passed to the
constructor ('R' for 'right').

    $LR = $lc->is_LsubsetR;

Return a true value if R is a subset of L.

    $RL = $lc->is_RsubsetL;

=item * C<is_LequivalentR()>

Return a true value if the two lists passed to the constructor are
equivalent, I<i.e.> if every element in the left-hand list ('L') appears
at least once in the right-hand list ('R') and I<vice versa>.

    $eqv = $lc->is_LequivalentR;
    $eqv = $lc->is_LeqvlntR;            # alias

=item * C<is_LdisjointR()>

Return a true value if the two lists passed to the constructor are
disjoint, I<i.e.> if the two lists have zero elements in common (or, what
is the same thing, if their intersection is an empty set).

    $disj = $lc->is_LdisjointR;

=item * C<print_subset_chart()>

Pretty-print a chart showing whether one list is a subset of the other.

    $lc->print_subset_chart;

=item * C<print_equivalence_chart()>

Pretty-print a chart showing whether the two lists are equivalent (same
elements found at least once in both).

    $lc->print_equivalence_chart;

=item * C<is_member_which()>

Determine in I<which> (if any) of the lists passed to the constructor a given
string can be found.  In list context, return a list of those indices in the
constructor's argument list corresponding to lists holding the string being
tested.

    @memb_arr = $lc->is_member_which('abel');

In the example above, C<@memb_arr> will be:

    ( 0 )

because C<'abel'> is found only in C<@Al> which holds position C<0> in the
list of arguments passed to C<new()>.

In scalar context, the return value is the number of lists passed to the
constructor in which a given string is found.

As with other List::Compare methods which return a list, you may wish the
above method returned a (scalar) reference to an array holding the list:

    $memb_arr_ref = $lc->is_member_which_ref('baker');

In the example above, C<$memb_arr_ref> will be:

    [ 0, 1 ]

because C<'baker'> is found in C<@Llist> and C<@Rlist>, which hold positions
C<0> and C<1>, respectively, in the list of arguments passed to C<new()>.

B<Note:>  methods C<is_member_which()> and C<is_member_which_ref> test
only one string at a time and hence take only one argument.  To test more
than one string at a time see the next method, C<are_members_which()>.

=item * C<are_members_which()>

Determine in I<which> (if any) of the lists passed to the constructor one or
more given strings can be found.  The strings to be tested are placed in an
array (named or anonymous); a reference to that array is passed to the method.

    $memb_hash_ref =
        $lc->are_members_which([ qw| abel baker fargo hilton zebra | ]);

I<Note:>  In versions of List::Compare prior to 0.25 (April 2004), the
strings to be tested could be passed as a flat list.  This is no longer
possible; the argument must now be a reference to an array.

The return value is a reference to a hash of arrays.  The
key for each element in this hash is the string being tested.  Each element's
value is a reference to an anonymous array whose elements are those indices in
the constructor's argument list corresponding to lists holding the strings
being tested.  In the examples above, C<$memb_hash_ref> will be:

    {
         abel     => [ 0    ],
         baker    => [ 0, 1 ],
         fargo    => [ 0, 1 ],
         hilton   => [    1 ],
         zebra    => [      ],
    };

B<Note:>  C<are_members_which()> can take more than one argument;
C<is_member_which()> and C<is_member_which_ref()> each take only one argument.
Unlike those two methods, C<are_members_which()> returns a hash reference.

=item * C<is_member_any()>

Determine whether a given string can be found in I<any> of the lists passed as
arguments to the constructor.  Return 1 if a specified string can be found in
any of the lists and 0 if not.

    $found = $lc->is_member_any('abel');

In the example above, C<$found> will be C<1> because C<'abel'> is found in one
or more of the lists passed as arguments to C<new()>.

=item * C<are_members_any()>

Determine whether a specified string or strings can be found in I<any> of the
lists passed as arguments to the constructor.  The strings to be tested are
placed in an array (named or anonymous); a reference to that array is passed to
C<are_members_any>.

    $memb_hash_ref = $lc->are_members_any([ qw| abel baker fargo hilton zebra | ]);

I<Note:>  In versions of List::Compare prior to 0.25 (April 2004), the
strings to be tested could be passed as a flat list.  This is no longer
possible; the argument must now be a reference to an array.

The return value is a reference to a hash where an element's key is the
string being tested and the element's value is 1 if the string can be
found in I<any> of the lists and 0 if not.  In the examples above,
C<$memb_hash_ref> will be:

    {
         abel     => 1,
         baker    => 1,
         fargo    => 1,
         hilton   => 1,
         zebra    => 0,
    };

C<zebra>'s value is C<0> because C<zebra> is not found in either of the lists
passed as arguments to C<new()>.

=item * C<get_version()>

Return current List::Compare version number.

    $vers = $lc->get_version;

=back

=head2 Accelerated Case:  When User Only Wants a Single Comparison

=over 4

=item * Constructor C<new()>

If you are certain that you will only want the results of a I<single>
comparison, computation may be accelerated by passing C<'-a'> or
C<'--accelerated> as the first argument to the constructor.

    @Llist = qw(abel abel baker camera delta edward fargo golfer);
    @Rlist = qw(baker camera delta delta edward fargo golfer hilton);

    $lca = List::Compare->new('-a', \@Llist, \@Rlist);

or

    $lca = List::Compare->new('--accelerated', \@Llist, \@Rlist);

As with List::Compare's Regular case, should you not need to have
a sorted list returned by an accelerated List::Compare method, you may
achieve a speed boost by constructing the accelerated List::Compare object
with the unsorted option:

    $lca = List::Compare->new('-u', '-a', \@Llist, \@Rlist);

or

    $lca = List::Compare->new('--unsorted', '--accelerated', \@Llist, \@Rlist);

=item * Alternative Constructor

You may use the 'single hashref' constructor format to build a List::Compare
object calling for the Accelerated mode:

    $lca = List::Compare->new( {
        lists    => [\@Llist, \@Rlist],
        accelerated => 1,
    } );

or

    $lca = List::Compare->new( {
        lists    => [\@Llist, \@Rlist],
        accelerated => 1,
        unsorted => 1,
    } );

=item * Methods

All the comparison methods available in the Regular case are available to
you in the Accelerated case as well.

    @intersection     = $lca->get_intersection;
    @union            = $lca->get_union;
    @Lonly            = $lca->get_unique;
    @Ronly            = $lca->get_complement;
    @LorRonly         = $lca->get_symmetric_difference;
    @bag              = $lca->get_bag;
    $intersection_ref = $lca->get_intersection_ref;
    $union_ref        = $lca->get_union_ref;
    $Lonly_ref        = $lca->get_unique_ref;
    $Ronly_ref        = $lca->get_complement_ref;
    $LorRonly_ref     = $lca->get_symmetric_difference_ref;
    $bag_ref          = $lca->get_bag_ref;
    $LR               = $lca->is_LsubsetR;
    $RL               = $lca->is_RsubsetL;
    $eqv              = $lca->is_LequivalentR;
    $disj             = $lca->is_LdisjointR;
                        $lca->print_subset_chart;
                        $lca->print_equivalence_chart;
    @memb_arr         = $lca->is_member_which('abel');
    $memb_arr_ref     = $lca->is_member_which_ref('baker');
    $memb_hash_ref    = $lca->are_members_which(
                            [ qw| abel baker fargo hilton zebra | ]);
    $found            = $lca->is_member_any('abel');
    $memb_hash_ref    = $lca->are_members_any(
                            [ qw| abel baker fargo hilton zebra | ]);
    $vers             = $lca->get_version;

All the aliases for methods available in the Regular case are available to
you in the Accelerated case as well.

=back

=head2 Multiple Case:  Compare Three or More Lists

=over 4

=item * Constructor C<new()>

Create a List::Compare object.  Put each list into an array and pass
references to the arrays to the constructor.

    @Al     = qw(abel abel baker camera delta edward fargo golfer);
    @Bob    = qw(baker camera delta delta edward fargo golfer hilton);
    @Carmen = qw(fargo golfer hilton icon icon jerky kappa);
    @Don    = qw(fargo icon jerky);
    @Ed     = qw(fargo icon icon jerky);

    $lcm = List::Compare->new(\@Al, \@Bob, \@Carmen, \@Don, \@Ed);

As with List::Compare's Regular case, should you not need to have
a sorted list returned by a List::Compare method, you may achieve a
speed boost by constructing the object with the unsorted option:

    $lcm = List::Compare->new('-u', \@Al, \@Bob, \@Carmen, \@Don, \@Ed);

or

    $lcm = List::Compare->new('--unsorted', \@Al, \@Bob, \@Carmen, \@Don, \@Ed);

=item * Alternative Constructor

You may use the 'single hashref' constructor format to build a List::Compare
object to process three or more lists at once:

    $lcm = List::Compare->new( {
        lists    => [\@Al, \@Bob, \@Carmen, \@Don, \@Ed],
    } );

or

    $lcm = List::Compare->new( {
        lists    => [\@Al, \@Bob, \@Carmen, \@Don, \@Ed],
        unsorted => 1,
    } );

=item * Multiple Mode Methods Analogous to Regular and Accelerated Mode Methods

Each List::Compare method available in the Regular and Accelerated cases
has an analogue in the Multiple case.  However, the results produced
usually require more careful specification.

B<Note:>  Certain of the following methods available in List::Compare's
Multiple mode take optional numerical arguments where those numbers
represent the index position of a particular list in the list of arguments
passed to the constructor.  To specify this index position correctly,

=over 4

=item *

start the count at C<0> (as is customary with Perl array indices); and

=item *

do I<not> count any unsorted option (C<'-u'> or C<'--unsorted'>) preceding
the array references in the constructor's own argument list.

=back

Example:

    $lcmex = List::Compare->new('--unsorted', \@alpha, \@beta, \@gamma);

For the purpose of supplying a numerical argument to a method which
optionally takes such an argument, C<'--unsorted'> is skipped, C<@alpha>
is C<0>, C<@beta> is C<1>, and so forth.

=over 4

=item * C<get_intersection()>

Get those items found in I<each> of the lists passed to the constructor
(their intersection):

    @intersection = $lcm->get_intersection;

=item * C<get_union()>

Get those items found in I<any> of the lists passed to the constructor
(their union):

    @union = $lcm->get_union;

=item * C<get_unique()>

To get those items which appear only in I<one particular list,> provide
C<get_unique()> with that list's index position in the list of arguments
passed to the constructor (not counting any C<'-u'> or C<'--unsorted'>
option).

Example:  C<@Carmen> has index position C<2> in the constructor's C<@_>.
To get elements unique to C<@Carmen>:

    @Lonly = $lcm->get_unique(2);

If no index position is passed to C<get_unique()> it will default to 0
and report items unique to the first list passed to the constructor.

=item * C<get_complement()>

To get those items which appear in any list I<other than one particular
list,> provide C<get_complement()> with that list's index position in
the list of arguments passed to the constructor (not counting any
C<'-u'> or C<'--unsorted'> option).

Example:  C<@Don> has index position C<3> in the constructor's C<@_>.
To get elements not found in C<@Don>:

    @Ronly = $lcm->get_complement(3);

If no index position is passed to C<get_complement()> it will default to
0 and report items found in any list other than the first list passed
to the constructor.

=item * C<get_symmetric_difference()>

Get those items each of which appears in I<only one> of the lists
passed to the constructor (their symmetric_difference);

    @LorRonly = $lcm->get_symmetric_difference;

=item * C<get_bag()>

Make a bag of all items found in any list.  The bag differs from the
lists' union in that it holds as many copies of individual elements
as appear in the original lists.

    @bag = $lcm->get_bag;

=item * Return reference instead of list

An alternative approach to the above methods:  If you do not immediately
require an array as the return value of the method call, but simply need
a I<reference> to an array, use one of the following parallel methods:

    $intersection_ref = $lcm->get_intersection_ref;
    $union_ref        = $lcm->get_union_ref;
    $Lonly_ref        = $lcm->get_unique_ref(2);
    $Ronly_ref        = $lcm->get_complement_ref(3);
    $LorRonly_ref     = $lcm->get_symmetric_difference_ref;
    $bag_ref          = $lcm->get_bag_ref;

=item * C<is_LsubsetR()>

To determine whether one particular list is a subset of another list
passed to the constructor, provide C<is_LsubsetR()> with the index
position of the presumed subset (ignoring any unsorted option), followed
by the index position of the presumed superset.

Example:  To determine whether C<@Ed> is a subset of C<@Carmen>, call:

    $LR = $lcm->is_LsubsetR(4,2);

A true value (C<1>) is returned if the left-hand list is a subset of the
right-hand list; a false value (C<0>) is returned otherwise.

If no arguments are passed, C<is_LsubsetR()> defaults to C<(0,1)> and
compares the first two lists passed to the constructor.

=item * C<is_LequivalentR()>

To determine whether any two particular lists are equivalent to each
other, provide C<is_LequivalentR> with their index positions in the
list of arguments passed to the constructor (ignoring any unsorted option).

Example:  To determine whether C<@Don> and C<@Ed> are equivalent, call:

    $eqv = $lcm->is_LequivalentR(3,4);

A true value (C<1>) is returned if the lists are equivalent; a false value
(C<0>) otherwise.

If no arguments are passed, C<is_LequivalentR> defaults to C<(0,1)> and
compares the first two lists passed to the constructor.

=item * C<is_LdisjointR()>

To determine whether any two particular lists are disjoint from each other
(I<i.e.,> have no members in common), provide C<is_LdisjointR> with their
index positions in the list of arguments passed to the constructor
(ignoring any unsorted option).

Example:  To determine whether C<@Don> and C<@Ed> are disjoint, call:

    $disj = $lcm->is_LdisjointR(3,4);

A true value (C<1>) is returned if the lists are equivalent; a false value
(C<0>) otherwise.

If no arguments are passed, C<is_LdisjointR> defaults to C<(0,1)> and
compares the first two lists passed to the constructor.

=item * C<print_subset_chart()>

Pretty-print a chart showing the subset relationships among the various
source lists:

    $lcm->print_subset_chart;

=item * C<print_equivalence_chart()>

Pretty-print a chart showing the equivalence relationships among the
various source lists:

    $lcm->print_equivalence_chart;

=item * C<is_member_which()>

Determine in I<which> (if any) of the lists passed to the constructor a given
string can be found.  In list context, return a list of those indices in the
constructor's argument list (ignoring any unsorted option) corresponding to i
lists holding the string being tested.

    @memb_arr = $lcm->is_member_which('abel');

In the example above, C<@memb_arr> will be:

    ( 0 )

because C<'abel'> is found only in C<@Al> which holds position C<0> in the
list of arguments passed to C<new()>.

=item * C<is_member_which_ref()>

As with other List::Compare methods which return a list, you may wish the
above method returned a (scalar) reference to an array holding the list:

    $memb_arr_ref = $lcm->is_member_which_ref('jerky');

In the example above, C<$memb_arr_ref> will be:

    [ 3, 4 ]

because C<'jerky'> is found in C<@Don> and C<@Ed>, which hold positions
C<3> and C<4>, respectively, in the list of arguments passed to C<new()>.

B<Note:>  methods C<is_member_which()> and C<is_member_which_ref> test
only one string at a time and hence take only one argument.  To test more
than one string at a time see the next method, C<are_members_which()>.

=item * C<are_members_which()>

Determine in C<which> (if any) of the lists passed to the constructor one or
more given strings can be found.  The strings to be tested are placed in an
anonymous array, a reference to which is passed to the method.

    $memb_hash_ref =
        $lcm->are_members_which([ qw| abel baker fargo hilton zebra | ]);

I<Note:>  In versions of List::Compare prior to 0.25 (April 2004), the
strings to be tested could be passed as a flat list.  This is no longer
possible; the argument must now be a reference to an anonymous array.

The return value is a reference to a hash of arrays.  The
key for each element in this hash is the string being tested.  Each element's
value is a reference to an anonymous array whose elements are those indices in
the constructor's argument list corresponding to lists holding the strings
being tested.

In the two examples above, C<$memb_hash_ref> will be:

    {
         abel     => [ 0             ],
         baker    => [ 0, 1          ],
         fargo    => [ 0, 1, 2, 3, 4 ],
         hilton   => [    1, 2       ],
         zebra    => [               ],
    };

B<Note:>  C<are_members_which()> can take more than one argument;
C<is_member_which()> and C<is_member_which_ref()> each take only one argument.
C<are_members_which()> returns a hash reference; the other methods return
either a list or a reference to an array holding that list, depending on
context.

=item * C<is_member_any()>

Determine whether a given string can be found in I<any> of the lists passed as
arguments to the constructor.

    $found = $lcm->is_member_any('abel');

Return C<1> if a specified string can be found in I<any> of the lists
and C<0> if not.

In the example above, C<$found> will be C<1> because C<'abel'> is found in one
or more of the lists passed as arguments to C<new()>.

=item * C<are_members_any()>

Determine whether a specified string or strings can be found in I<any> of the
lists passed as arguments to the constructor.  The strings to be tested are
placed in an array (anonymous or named), a reference to which is passed to
the method.

    $memb_hash_ref = $lcm->are_members_any([ qw| abel baker fargo hilton zebra | ]);

I<Note:>  In versions of List::Compare prior to 0.25 (April 2004), the
strings to be tested could be passed as a flat list.  This is no longer
possible; the argument must now be a reference to an anonymous array.

The return value is a reference to a hash where an element's key is the
string being tested and the element's value is 1 if the string can be
found in C<any> of the lists and 0 if not.
In the two examples above, C<$memb_hash_ref> will be:

    {
         abel     => 1,
         baker    => 1,
         fargo    => 1,
         hilton   => 1,
         zebra    => 0,
    };

C<zebra>'s value will be C<0> because C<zebra> is not found in any of the
lists passed as arguments to C<new()>.

=item * C<get_version()>

Return current List::Compare version number:

    $vers = $lcm->get_version;

=back

=item * Multiple Mode Methods Not Analogous to Regular and Accelerated Mode Methods

=over 4

=item * C<get_nonintersection()>

Get those items found in I<any> of the lists passed to the constructor which
do I<not> appear in I<all> of the lists (I<i.e.,> all items except those found
in the intersection of the lists):

    @nonintersection = $lcm->get_nonintersection;

=item * C<get_shared()>

Get those items which appear in more than one of the lists passed to the
constructor (I<i.e.,> all items except those found in their symmetric
difference);

    @shared = $lcm->get_shared;

=item * C<get_nonintersection_ref()>

If you only need a reference to an array as a return value rather than a
full array, use the following alternative methods:

    $nonintersection_ref = $lcm->get_nonintersection_ref;
    $shared_ref = $lcm->get_shared_ref;

=item * C<get_unique_all()>

Get a reference to an array of array references where each of the interior
arrays holds the list of those items I<unique> to the list passed to the
constructor with the same index position.

    $unique_all_ref = $lcm->get_unique_all();

In the example above, C<$unique_all_ref> will hold:

    [
        [ qw| abel | ],
        [ ],
        [ qw| jerky | ],
        [ ],
        [ ],
    ]

=item * C<get_complement_all()>

Get a reference to an array of array references where each of the interior
arrays holds the list of those items in the I<complement> to the list
passed to the constructor with the same index position.

    $complement_all_ref = $lcm->get_complement_all();

In the example above, C<$complement_all_ref> will hold:

    [
        [ qw| hilton icon jerky | ],
        [ qw| abel icon jerky | ],
        [ qw| abel baker camera delta edward | ],
        [ qw| abel baker camera delta edward jerky | ],
        [ qw| abel baker camera delta edward jerky | ],
    ]

=back

=back

=head2 Multiple Accelerated Case:  Compare Three or More Lists but Request Only a Single Comparison among the Lists

=over 4

=item * Constructor C<new()>

If you are certain that you will only want the results of a single
comparison among three or more lists, computation may be accelerated
by passing C<'-a'> or C<'--accelerated> as the first argument to
the constructor.

    @Al     = qw(abel abel baker camera delta edward fargo golfer);
    @Bob    = qw(baker camera delta delta edward fargo golfer hilton);
    @Carmen = qw(fargo golfer hilton icon icon jerky kappa);
    @Don    = qw(fargo icon jerky);
    @Ed     = qw(fargo icon icon jerky);

    $lcma = List::Compare->new('-a',
                \@Al, \@Bob, \@Carmen, \@Don, \@Ed);

As with List::Compare's other cases, should you not need to have
a sorted list returned by a List::Compare method, you may achieve a
speed boost by constructing the object with the unsorted option:

    $lcma = List::Compare->new('-u', '-a',
                \@Al, \@Bob, \@Carmen, \@Don, \@Ed);

or

    $lcma = List::Compare->new('--unsorted', '--accelerated',
                \@Al, \@Bob, \@Carmen, \@Don, \@Ed);

As was the case with List::Compare's Multiple mode, do not count the
unsorted option (C<'-u'> or C<'--unsorted'>) or the accelerated option
(C<'-a'> or C<'--accelerated'>) when determining the index position of
a particular list in the list of array references passed to the constructor.

Example:

    $lcmaex = List::Compare->new('--unsorted', '--accelerated',
                   \@alpha, \@beta, \@gamma);

=item * Alternative Constructor

The 'single hashref' format may be used to construct a List::Compare
object which calls for accelerated processing of three or more lists at once:

    $lcmaex = List::Compare->new( {
        accelerated => 1,
        lists       => [\@alpha, \@beta, \@gamma],
    } );

or

    $lcmaex = List::Compare->new( {
        unsorted    => 1,
        accelerated => 1,
        lists       => [\@alpha, \@beta, \@gamma],
    } );

=item * Methods

For the purpose of supplying a numerical argument to a method which
optionally takes such an argument, C<'--unsorted'> and C<'--accelerated>
are skipped, C<@alpha> is C<0>, C<@beta> is C<1>, and so forth.  To get a
list of those items unique to C<@gamma>, you would call:

    @gamma_only = $lcmaex->get_unique(2);

=back

=head2 Passing Seen-hashes to the Constructor Instead of Arrays

=over 4

=item * When Seen-Hashes Are Already Available to You

Suppose that in a particular Perl program, you had to do extensive munging of
data from an external source and that, once you had correctly parsed a line
of data, it was easier to assign that datum to a hash than to an array.
More specifically, suppose that you used each datum as the key to an element
of a lookup table in the form of a I<seen-hash>:

   my %Llist = (
       abel     => 2,
       baker    => 1,
       camera   => 1,
       delta    => 1,
       edward   => 1,
       fargo    => 1,
       golfer   => 1,
   );

   my %Rlist = (
       baker    => 1,
       camera   => 1,
       delta    => 2,
       edward   => 1,
       fargo    => 1,
       golfer   => 1,
       hilton   => 1,
   );

In other words, suppose it was more convenient to compute a lookup table
I<implying> a list than to compute that list explicitly.

Since in almost all cases List::Compare takes the elements in the arrays
passed to its constructor and I<internally> assigns them to elements in a
seen-hash, why shouldn't you be able to pass (references to) seen-hashes
I<directly> to the constructor and avoid unnecessary array
assignments before the constructor is called?

=item * Constructor C<new()>

You can now do so:

    $lcsh = List::Compare->new(\%Llist, \%Rlist);

=item * Methods

I<All> of List::Compare's output methods are supported I<without further
modification> when references to seen-hashes are passed to the constructor.

    @intersection         = $lcsh->get_intersection;
    @union                = $lcsh->get_union;
    @Lonly                = $lcsh->get_unique;
    @Ronly                = $lcsh->get_complement;
    @LorRonly             = $lcsh->get_symmetric_difference;
    @bag                  = $lcsh->get_bag;
    $intersection_ref     = $lcsh->get_intersection_ref;
    $union_ref            = $lcsh->get_union_ref;
    $Lonly_ref            = $lcsh->get_unique_ref;
    $Ronly_ref            = $lcsh->get_complement_ref;
    $LorRonly_ref         = $lcsh->get_symmetric_difference_ref;
    $bag_ref              = $lcsh->get_bag_ref;
    $LR                   = $lcsh->is_LsubsetR;
    $RL                   = $lcsh->is_RsubsetL;
    $eqv                  = $lcsh->is_LequivalentR;
    $disj                 = $lcsh->is_LdisjointR;
                            $lcsh->print_subset_chart;
                            $lcsh->print_equivalence_chart;
    @memb_arr             = $lsch->is_member_which('abel');
    $memb_arr_ref         = $lsch->is_member_which_ref('baker');
    $memb_hash_ref        = $lsch->are_members_which(
                                [ qw| abel baker fargo hilton zebra | ]);
    $found                = $lsch->is_member_any('abel');
    $memb_hash_ref        = $lsch->are_members_any(
                                [ qw| abel baker fargo hilton zebra | ]);
    $vers                 = $lcsh->get_version;
    $unique_all_ref       = $lcsh->get_unique_all();
    $complement_all_ref   = $lcsh->get_complement_all();

=item * Accelerated Mode and Seen-Hashes

To accelerate processing when you want only a single comparison among two or
more lists, you can pass C<'-a'> or C<'--accelerated> to the constructor
before passing references to seen-hashes.

    $lcsha = List::Compare->new('-a', \%Llist, \%Rlist);

To compare three or more lists simultaneously, pass three or more references
to seen-hashes.  Thus,

    $lcshm = List::Compare->new(\%Alpha, \%Beta, \%Gamma);

will generate meaningful comparisons of three or more lists simultaneously.

=item * Unsorted Results and Seen-Hashes

If you do not need sorted lists returned, pass C<'-u'> or C<--unsorted> to the
constructor before passing references to seen-hashes.

    $lcshu  = List::Compare->new('-u', \%Llist, \%Rlist);
    $lcshau = List::Compare->new('-u', '-a', \%Llist, \%Rlist);
    $lcshmu = List::Compare->new('--unsorted', \%Alpha, \%Beta, \%Gamma);

As was true when we were using List::Compare's Multiple and Multiple Accelerated
modes, do not count any unsorted or accelerated option when determining the
array index of a particular seen-hash reference passed to the constructor.

=item * Alternative Constructor

The 'single hashref' form of constructor is also available to build
List::Compare objects where seen-hashes are used as arguments:

    $lcshu  = List::Compare->new( {
        unsorted => 1,
        lists    => [\%Llist, \%Rlist],
    } );

    $lcshau = List::Compare->new( {
        unsorted    => 1,
        accelerated => 1,
        lists       => [\%Llist, \%Rlist],
    } );

    $lcshmu = List::Compare->new( {
        unsorted => 1,
        lists    => [\%Alpha, \%Beta, \%Gamma],
    } );

=back

=head1 DISCUSSION:  Principles

=head2 General Comments

List::Compare is an object-oriented implementation of very common Perl
code (see "History, References and Development" below) used to
determine interesting relationships between two or more lists at a time.
A List::Compare object is created and automatically computes the values
needed to supply List::Compare methods with appropriate results.  In the
current implementation List::Compare methods will return new lists
containing the items found in any designated list alone (unique), any list
other than a designated list (complement), the intersection and union of
all lists and so forth.  List::Compare also has (a) methods to return Boolean
values indicating whether one list is a subset of another and whether any
two lists are equivalent to each other (b) methods to pretty-print very
simple charts displaying the subset and equivalence relationships among
lists.

Except for List::Compare's C<get_bag()> method, B<multiple instances of
an element in a given list count only once with
respect to computing the intersection, union, etc. of the two lists.>  In
particular, List::Compare considers two lists as equivalent if each element
of the first list can be found in the second list and I<vice versa>.
'Equivalence' in this usage takes no note of the frequency with which
elements occur in either list or their order within the lists.  List::Compare
asks the question:  I<Did I see this item in this list at all?>  Only when
you use C<List::Compare::get_bag()> to compute a bag holding the two lists do you
ask the question:  How many times did this item occur in this list?

=head2 List::Compare Modes

In its current implementation List::Compare has four modes of operation.

=over 4

=item *

Regular Mode

List::Compare's Regular mode is based on List::Compare v0.11 -- the first
version of List::Compare released to CPAN (June 2002).  It compares only
two lists at a time.  Internally, its initializer does all computations
needed to report any desired comparison and its constructor stores the
results of these computations.  Its public methods merely report these
results.

This approach has the advantage that if you need to examine more
than one form of comparison between two lists (I<e.g.,> the union,
intersection and symmetric difference of two lists), the comparisons are
pre-calculated.  This approach is efficient because certain types of
comparison presuppose that other types have already been calculated.
For example, to calculate the symmetric difference of two lists, one must
first determine the items unique to each of the two lists.

=item *

Accelerated Mode

The current implementation of List::Compare offers you the option of
getting even faster results I<provided> that you only need the
result from a I<single> form of comparison between two lists. (I<e.g.,> only
the union -- nothing else).  In the Accelerated mode, List::Compare's
initializer does no computation and its constructor stores only references
to the two source lists.  All computation needed to report results is
deferred to the method calls.

The user selects this approach by passing the option flag C<'-a'> to the
constructor before passing references to the two source lists.
List::Compare notes the option flag and silently switches into Accelerated
mode.  From the perspective of the user, there is no further difference in
the code or in the results.

Benchmarking suggests that List::Compare's Accelerated mode (a) is faster
than its Regular mode when only one comparison is requested; (b) is about as
fast as Regular mode when two comparisons are requested; and (c) becomes
considerably slower than Regular mode as each additional comparison above two
is requested.

=item *

Multiple Mode

List::Compare now offers the possibility of comparing three or more lists at
a time.  Simply store the extra lists in arrays and pass references to those
arrays to the constructor.  List::Compare detects that more than two lists
have been passed to the constructor and silently switches into Multiple mode.

As described in the Synopsis above, comparing more than two lists at a time
offers you a wider, more complex palette of comparison methods.
Individual items may appear in just one source list, in all the source lists,
or in some number of lists between one and all.  The meaning of 'union',
'intersection' and 'symmetric difference' is conceptually unchanged
when you move to multiple lists because these are properties of all the lists
considered together.  In contrast, the meaning of 'unique', 'complement',
'subset' and 'equivalent' changes because these are properties of one list
compared with another or with all the other lists combined.

List::Compare takes this complexity into account by allowing you to pass
arguments to the public methods requesting results with respect to a specific
list (for C<get_unique()> and C<get_complement()>) or a specific pair of lists
(for C<is_LsubsetR()> and C<is_LequivalentR()>).

List::Compare further takes this complexity into account by offering the
new methods C<get_shared()> and C<get_nonintersection()> described in the
Synopsis above.

=item *

Multiple Accelerated Mode

Beginning with version 0.25, introduced in April 2004, List::Compare
offers the possibility of accelerated computation of a single comparison
among three or more lists at a time.  Simply store the extra lists in
arrays and pass references to those arrays to the constructor preceded by
the C<'-a'> argument as was done with the simple (two lists only)
accelerated mode.  List::Compare detects that more than two lists have been
passed to the constructor and silently switches into Multiple Accelerated
mode.

=item *

Unsorted Option

When List::Compare is used to return lists representing various comparisons
of two or more lists (I<e.g.>, the lists' union or intersection), the lists
returned are, by default, sorted using Perl's default C<sort> mode:
ASCII-betical sorting.  Sorting produces results which are more easily
human-readable but may entail a performance cost.

Should you not need sorted results, you can avoid the potential
performance cost by calling List::Compare's constructor using the unsorted
option.  This is done by calling C<'-u'> or C<'--unsorted'> as the first
argument passed to the constructor, I<i.e.>, as an argument called before
any references to lists are passed to the constructor.

Note that if are calling List::Compare in the Accelerated or Multiple
Accelerated mode I<and> wish to have the lists returned in unsorted order,
you I<first> pass the argument for the unsorted option
(C<'-u'> or C<'--unsorted'>) and I<then> pass the argument for the
Accelerated mode (C<'-a'> or C<'--accelerated'>).

=back

=head2 Miscellaneous Methods

It would not really be appropriate to call C<get_shared()> and
C<get_nonintersection()> in Regular or Accelerated mode since they are
conceptually based on the notion of comparing more than two lists at a time.
However, there is always the possibility that a user may be comparing only two
lists (accelerated or not) and may accidentally call one of those two methods.
To prevent fatal run-time errors and to caution you to use a more
appropriate method, these two methods are defined for Regular and Accelerated
modes so as to return suitable results but also generate a carp message that
advise you to re-code.

Similarly, the method C<is_RsubsetL()> is appropriate for the Regular and
Accelerated modes but is not really appropriate for Multiple mode.  As a
defensive maneuver, it has been defined for Multiple mode so as to return
suitable results but also to generate a carp message that advises you to
re-code.

In List::Compare v0.11 and earlier, the author provided aliases for various
methods based on the supposition that the source lists would be referred to as
'A' and 'B'.  Now that you can compare more than two lists at a time, the author
feels that it would be more appropriate to refer to the elements of two-argument
lists as the left-hand and right-hand elements.  Hence, we are discouraging the
use of methods such as C<get_Aonly()>, C<get_Bonly()> and C<get_AorBonly()> as
aliases for C<get_unique()>, C<get_complement()> and
C<get_symmetric_difference()>.  However, to guarantee backwards compatibility
for the vast audience of Perl programmers using earlier versions of
List::Compare (all 10e1 of you) these and similar methods for subset
relationships are still defined.

=head2 List::Compare::SeenHash Discontinued Beginning with Version 0.26

Prior to v0.26, introduced April 11, 2004, if a user wished to pass
references to seen-hashes to List::Compare's constructor rather than
references to arrays, he or she had to call a different, parallel module:
List::Compare::SeenHash.  The code for that looked like this:

    use List::Compare::SeenHash;

    my %Llist = (
       abel     => 2,
       baker    => 1,
       camera   => 1,
       delta    => 1,
       edward   => 1,
       fargo    => 1,
       golfer   => 1,
    );

    my %Rlist = (
       baker    => 1,
       camera   => 1,
       delta    => 2,
       edward   => 1,
       fargo    => 1,
       golfer   => 1,
       hilton   => 1,
    );

    my $lcsh = List::Compare::SeenHash->new(\%Llist, \%Rlist);

B<List::Compare::SeenHash is deprecated beginning with version 0.26.>  All
its functionality (and more) has been implemented in List::Compare itself,
since a user can now pass I<either> a series of array references I<or> a
series of seen-hash references to List::Compare's constructor.

To simplify future maintenance of List::Compare, List::Compare::SeenHash.pm
will no longer be distributed with List::Compare, nor will the files in the
test suite which tested List::Compare::SeenHash upon installation be distributed.

Should you still need List::Compare::SeenHash, use version 0.25 from CPAN, or
simply edit your Perl programs which used List::Compare::SeenHash.  Those
scripts may be edited quickly with, for example, this editing command in
Unix text editor F<vi>:

    :1,$s/List::Compare::SeenHash/List::Compare/gc

=head2 A Non-Object-Oriented Interface:  List::Compare::Functional

Version 0.21 of List::Compare introduced List::Compare::Functional,
a functional (I<i.e.>, non-object-oriented) interface to list comparison
functions.  List::Compare::Functional supports the same functions currently
supported by List::Compare.  It works similar to List::Compare's Accelerated
and Multiple Accelerated modes (described above), bit it does not
require use of the C<'-a'> flag in the function call.
List::Compare::Functional will return unsorted comparisons of two lists by
passing C<'-u'> or C<'--unsorted'> as the first argument to the function.
Please see the documentation for List::Compare::Functional to learn how to
import its functions into your main package.

=head1 ASSUMPTIONS AND QUALIFICATIONS

The program was created with Perl 5.6. The use of I<h2xs> to prepare
the module's template installed C<require 5.005_62;> at the top of the
module.  This has been commented out in the actual module as the code
appears to be compatible with earlier versions of Perl; how earlier the
author cannot say.  In particular, the author would like the module to
be installable on older versions of MacPerl.  As is, the author has
successfully installed the module on Linux, Windows 9x and Windows 2000.
See L<http://testers.cpan.org/show/List-Compare.html> for
a list of other systems on which this version of List::Compare has been
tested and installed.

=head1 HISTORY, REFERENCES AND DEVELOPMENT

=head2 The Code Itself

List::Compare is based on code presented by Tom Christiansen & Nathan
Torkington in I<Perl Cookbook> L<http://www.oreilly.com/catalog/cookbook/>
(a.k.a. the 'Ram' book), O'Reilly & Associates, 1998, Recipes 4.7 and 4.8.
Similar code is presented in the Camel book:  I<Programming Perl>, by Larry
Wall, Tom Christiansen, Jon Orwant.
L<http://www.oreilly.com/catalog/pperl3/>, 3rd ed, O'Reilly & Associates,
2000.  The list comparison code is so basic and Perlish that I suspect it
may have been written by Larry himself at the dawn of Perl time.  The
C<get_bag()> method was inspired by Jarkko Hietaniemi's Set::Bag module
and Daniel Berger's Set::Array module, both available on CPAN.

List::Compare's original objective was simply to put this code in a modular,
object-oriented framework.  That framework, not surprisingly, is taken mostly
from Damian Conway's I<Object Oriented Perl>
L<http://www.manning.com/Conway/index.html>, Manning Publications, 2000.

With the addition of the Accelerated, Multiple and Multiple Accelerated
modes, List::Compare expands considerably in both size and capabilities.
Nonetheless,  Tom and Nat's I<Cookbook> code still lies at its core:
the use of hashes as look-up tables to record elements seen in lists.
Please note:  List::Compare is not concerned with any concept of 'equality'
among lists which hinges upon the frequency with which, or the order in
which, elements appear in the lists to be compared.  If this does not
meet your needs, you should look elsewhere or write your own module.

=head2 The Inspiration

I realized the usefulness of putting the list comparison code into a
module while preparing an introductory level Perl course given at the New
School University's Computer Instruction Center in April-May 2002.  I was
comparing lists left and right.  When I found myself writing very similar
functions in different scripts, I knew a module was lurking somewhere.
I learned the truth of the mantra ''Repeated Code is a Mistake'' from a
2001 talk by Mark-Jason Dominus L<http://perl.plover.com/> to the New York
Perlmongers L<http://ny.pm.org/>.
See L<http://www.perl.com/pub/a/2000/11/repair3.html>.

The first public presentation of this module took place at Perl Seminar
New York L<http://groups.yahoo.com/group/perlsemny> on May 21, 2002.
Comments and suggestions were provided there and since by Glenn Maciag,
Gary Benson, Josh Rabinowitz, Terrence Brannon and Dave Cross.

The placement in the installation tree of Test::ListCompareSpecial came
as a result of a question answered by Michael Graham in his talk
''Test::More to Test::Extreme'' given at Yet Another Perl Conference::Canada
in Ottawa, Ontario, on May 16, 2003.

In May-June 2003, Glenn Maciag made valuable suggestions which led to
changes in method names and documentation in v0.20.

Another presentation at Perl Seminar New York in
October 2003 prompted me to begin planning List::Compare::Functional.

In a November 2003 Perl Seminar New York presentation, Ben Holtzman
discussed the performance costs entailed in Perl's C<sort> function.
This led me to ask, ''Why should a user of List::Compare pay this performance
cost if he or she doesn't need a human-readable list as a result (as
would be the case if the list returned were used as the input into some
other function)?''  This led to the development of List::Compare's
unsorted option.

An April 2004 offer by Kevin Carlson to write an article for I<The Perl Journal>
(L<http://tpj.com>) led me to re-think whether a separate module
(the former List::Compare::SeenHash) was truly needed when a user wanted
to provide the constructor with references to seen-hashes rather than
references to arrays.  Since I had already adapted List::Compare::Functional
to accept both kinds of arguments, I adapted List::Compare in the same
manner.  This meant that List::Compare::SeenHash and its related installation
tests could be deprecated and deleted from the CPAN distribution.

A remark by David H. Adler at a New York Perlmongers meeting in April 2004
led me to develop the 'single hashref' alternative constructor format,
introduced in version 0.29 the following month.

Presentations at two different editions of Yet Another Perl Conference (YAPC)
inspired the development of List::Compare versions 0.30 and 0.31.  I was
selected to give a talk on List::Compare at YAPC::NA::2004 in Buffalo.  This
spurred me to improve certain aspects of the documentation.  Version 0.31
owes its inspiration to one talk at the Buffalo YAPC and one earlier talk at
YAPC::EU::2003 in Paris.  In Paris I heard Paul Johnson speak on his CPAN
module Devel::Cover and on coverage analysis more generally.  That material
was over my head at that time, but in Buffalo I heard Andy Lester discuss
Devel::Cover as part of his discussion of testing and of the Phalanx project
(L<http://qa.perl.org/phalanx>).  This time I got it, and when I returned
from Buffalo I applied Devel::Cover to List::Compare and wrote additional tests
to improve its subroutine and statement coverage.  In addition, I added two
new methods, C<get_unique_all> and C<get_complement_all>.  In writing these
two methods, I followed a model of test-driven development much more so than
in earlier versions of List::Compare and my other CPAN modules.  The result?
List::Compare's test suite grew by over 3300 tests to nearly 23,000 tests.

At the Second New York Perl Hackathon (May 02 2015), a project was created to
request performance improvements in certain List::Compare functions
(L<https://github.com/nyperlmongers/nyperlhackathon2015/wiki/List-Compare-Performance-Improvements).
Hackathon participant Michael Rawson submitted a pull request with changes to
List::Compare::Base::_Auxiliary.  After these revisions were benchmarked, a
patch embodying the pull request was accepted, leading to CPAN version 0.52.

=head2 If You Like List::Compare, You'll Love ...

While preparing this module for distribution via CPAN, I had occasion to
study a number of other modules already available on CPAN.  Each of these
modules is more sophisticated than List::Compare -- which is not surprising
since all that List::Compare originally aspired to do was to avoid typing
Cookbook code repeatedly.  Here is a brief description of the features of
these modules.  (B<Warning:>  The following discussion is only valid as
of June 2002.  Some of these modules may have changed since then.)

=over 4

=item *

Algorithm::Diff - Compute 'intelligent' differences between two files/lists
(L<http://search.cpan.org/dist/Algorithm-Diff/>)

Algorithm::Diff is a sophisticated module originally written by Mark-Jason
Dominus, later maintained by Ned Konz, now maintained by Tye McQueen. Think of
the Unix C<diff> utility  and you're on the right track.  Algorithm::Diff
exports
methods such as C<diff>, which ''computes the smallest set of additions and
deletions necessary to turn the first sequence into the second, and returns a
description of these changes.''  Algorithm::Diff is mainly concerned with the
sequence of elements within two lists.  It does not export functions for
intersection, union, subset status, etc.

=item *

Array::Compare - Perl extension for comparing arrays
(L<http://search.cpan.org/dist/Array-Compare/>)

Array::Compare, by Dave Cross, asks whether two arrays
are the same or different by doing a C<join> on each string with a
separator character and comparing the resulting strings.  Like
List::Compare, it is an object-oriented module.  A sophisticated feature of
Array::Compare is that it allows you to specify how 'whitespace' in an
array (an element which is undefined, the empty string, or whitespace
within an element) should be evaluated for purpose of determining equality
or difference.    It does not directly provide methods for intersection and
union.

=item *

List::Util - A selection of general-utility list subroutines
(L<http://search.cpan.org/dist/Scalar-List-Utils/>)

List::Util, by Graham Barr, exports a variety of simple,
useful functions for operating on one list at a time.    The C<min> function
returns the lowest numerical value in a list; the C<max> function returns
the highest value; and so forth.  List::Compare differs from List::Util in
that it is object-oriented and that it works on two strings at a time
rather than just one -- but it aims to be as simple and useful as
List::Util.  List::Util will be included in the standard Perl
distribution as of Perl 5.8.0.

Lists::Util (L<http://search.cpan.org/dist/List-MoreUtils/>),
by Tassilo von Parseval, building on code by Terrence Brannon, provides
methods
which extend List::Util's functionality.

=item *

Quantum::Superpositions
(L<http://search.cpan.org/dist/Quantum-Superpositions/>),
originally by Damian Conway, now maintained by Steven Lembark is useful if, in
addition to comparing lists, you need to emulate quantum supercomputing as
well.
Not for the eigen-challenged.

=item *

Set::Scalar - basic set operations
(L<http://search.cpan.org/dist/Set-Scalar/>)

Set::Bag - bag (multiset) class
(L<http://search.cpan.org/dist/Set-Bag/>)

Both of these modules are by Jarkko Hietaniemi.  Set::Scalar
has methods to return the intersection, union, difference and symmetric
difference of two sets, as well as methods to return items unique to a
first set and complementary to it in a second set.  It has methods for
reporting considerably more variants on subset status than does
List::Compare.  However, benchmarking suggests that List::Compare, at
least in Regular mode, is considerably faster than Set::Scalar for those
comparison methods which List::Compare makes available.

Set::Bag enables one to deal more flexibly with the situation in which one
has more than one instance of an element in a list.

=item *

Set::Array - Arrays as objects with lots of handy methods (including set
comparisons) and support for method chaining.
(L<http://search.cpan.org/dist/Set-Array/>)

Set::Array, by Daniel Berger, now maintained by Ron Savage, ''aims to provide
built-in methods for operations that people are always asking how to do,and
which already exist in languages like Ruby.''  Among the many methods in
this module are some for intersection, union, etc.  To install Set::Array,
you must first install the Want module, also available on CPAN.

=back

=head1 BUGS

There are no bug reports outstanding on List::Compare as of the most recent
CPAN upload date of this distribution.

=head1 SUPPORT

Please report any bugs by mail to C<bug-List-Compare@rt.cpan.org>
or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).  When sending correspondence, please
include 'List::Compare' or 'List-Compare' in your subject line.

Creation date:  May 20, 2002.  Last modification date:  July 4, 2014.

Development repository: L<https://github.com/jkeenan/list-compare>

=head1 COPYRIGHT

Copyright (c) 2002-15 James E. Keenan.  United States.  All rights reserved.
This is free software and may be distributed under the same terms as Perl
itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE ''AS IS'' WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

