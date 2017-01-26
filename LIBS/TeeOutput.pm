#  Copyright (c) 2000 by Ron Wantock. All rights reserved.
#  This program is free software; you can redistribute it and/or modify
#  it under the same terms as Perl itself.

#  Full POD documentation is availible at the end of the code


package Local::TeeOutput;
use strict;
use vars qw(@ISA @EXPORT);
require Exporter;
@ISA = ('Exporter');
@EXPORT = ('openTee', 'closeTee');

sub openTee {
	tie $_[0], 'Local::TeeOutput::NewTee', @_[1..$#_];
}

sub closeTee {
	untie $_[0];
}


#-------------------------------------------------------------

package Local::TeeOutput::NewTee;
use strict;
use Symbol;

my %fields = ();
 
sub TIEHANDLE {
	my $pkg = shift;
	my $i = 1;
	my $file = '';
	my $obj = {%fields};
	foreach $file (@_) {
		my $fh = gensym();
		if (ref(\$file) eq 'GLOB') {
			select((select($file), $|=1)[0]);
			open($fh, ">>&$file") or return 0;
			select((select($fh), $|=1)[0]);
			if ($file eq *STDERR) {
				$SIG{__WARN__} = sub { print STDERR @_; };
				$SIG{__DIE__} = sub { print STDERR @_; exit; }; 
				$obj->{"$fh"}[0] = 1;
			} else {
				$obj->{"$fh"}[0] = 0;
			}
		} else {
			if ($file =~ /^(>>?)/) {
				open($fh, "$file") or return 0;
			} else {
				open($fh, ">>$file") or return 0;
			}
			select((select($fh), $|=1)[0]);
			$obj->{"$fh"}[0] = 0;
		}
		$obj->{"$fh"}[1] = $fh;
	}
	bless $obj, $pkg;
}

sub PRINT {
	my ($obj, @string) = @_;
	my $key = '';
	my $oldWarnSig = $SIG{__WARN__};
	$SIG{__WARN__} = sub { print STDERR shortmess(@_); };
	foreach $key (keys(%$obj)) {
		my $fh = $obj->{"$key"}[1];
		#print $fh @string;
		unless (print $fh @string) {return 0}
	}
	$SIG{__WARN__} = $oldWarnSig;
	1;
}

sub PRINTF {
	my ($obj, @string) = @_;
	my $key = '';
	my $oldWarnSig = $SIG{__WARN__};
	$SIG{__WARN__} = sub { print STDERR shortmess(@_); };
	foreach $key (keys(%$obj)) {
		my $fh = $obj->{"$key"}[1];
		#printf $fh @string;
		unless (printf $fh @string) {return 0}
	}
	$SIG{__WARN__} = $oldWarnSig;
	1;
}
 


# added the fetch to fix a bug that arrises when you try to tee
# STDERR and STDOUT both to the same file at the same time.
# It doen't do anything, but the module dies without it.
sub FETCH {
}

sub DESTROY {
	my ($obj) = @_;
	my $key = '';
	foreach $key (keys(%$obj)) {
		if ($obj->{"$key"}[1]) {
			$SIG{__WARN__} = 'DEFAULT';
			$SIG{__DIE__} = 'DEFAULT';
		} 
		my $fh = $obj->{"$key"}[1];
		close($fh);
	}
}


# the shortmess and longmess subroutines are for the most part strait out of
# the Carp.pm module.  With only minor modifications to work stand alone 
# inside this module

sub shortmess {	# Short-circuit &longmess if called via multiple packages
    no strict 'refs';
    my $error = join '', @_;
    my ($prevpack) = caller(1);
    my $extra = 0;
    my $i = 2;
    my ($pack,$file,$line);
    $error =~ s/(.*) at.*\n/$1/;
    # when reporting an error, we want to report it from the context of the
    # calling package.  So what is the calling package?  Within a module,
    # there may be many calls between methods and perhaps between sub-classes
    # and super-classes, but the user isn't interested in what happens
    # inside the package.  We start by building a hash array which keeps
    # track of all the packages to which the calling package belongs.  We
    # do this by examining its @ISA variable.  Any call from a base class
    # method (one of our caller's @ISA packages) can be ignored
    my %isa = ($prevpack,1);

    # merge all the caller's @ISA packages into %isa.
    @isa{@{"${prevpack}::ISA"}} = ()
	if(defined @{"${prevpack}::ISA"});

    # now we crawl up the calling stack and look at all the packages in
    # there.  For each package, we look to see if it has an @ISA and then
    # we see if our caller features in that list.  That would imply that
    # our caller is a derived class of that package and its calls can also
    # be ignored
    while (($pack,$file,$line) = caller($i++)) {
	if(defined @{$pack . "::ISA"}) {
	    my @i = @{$pack . "::ISA"};
	    my %i;
	    @i{@i} = ();
	    # merge any relevant packages into %isa
	    @isa{@i,$pack} = ()
		if(exists $i{$prevpack} || exists $isa{$pack});
	}

	# and here's where we do the ignoring... if the package in
	# question is one of our caller's base or derived packages then
	# we can ignore it (skip it) and go onto the next (but note that
	# the continue { } block below gets called every time)
	next
	    if(exists $isa{$pack});

	# Hey!  We've found a package that isn't one of our caller's
	# clan....but wait, $extra refers to the number of 'extra' levels
	# we should skip up.  If $extra > 0 then this is a false alarm.
	# We must merge the package into the %isa hash (so we can ignore it
	# if it pops up again), decrement $extra, and continue.
	if ($extra-- > 0) {
	    %isa = ($pack,1);
	    @isa{@{$pack . "::ISA"}} = ()
		if(defined @{$pack . "::ISA"});
	}
	else {
	    # OK!  We've got a candidate package.  Time to construct the
	    # relevant error message and return it.   die() doesn't like
	    # to be given NUL characters (which $msg may contain) so we
	    # remove them first.
	    (my $msg = "$error at $file line $line.\n") =~ tr/\0//d;
	    return $msg;
	}
    }
    continue {
	$prevpack = $pack;
    }

    # uh-oh!  It looks like we crawled all the way up the stack and
    # never found a candidate package.  Oh well, let's call longmess
    # to generate a full stack trace.  We use the magical form of 'goto'
    # so that this shortmess() function doesn't appear on the stack
    # to further confuse longmess() about it's calling package.
    goto &longmess;
}


sub longmess {
    my $error = join '', @_;
    my $mess = "";
    my $i = 1 ;
    my ($pack,$file,$line,$sub,$hargs,$eval,$require);
    my (@a);
    #
    # crawl up the stack....
    #
    while (do { { package DB; @a = caller($i++) } } ) {
	# get copies of the variables returned from caller()
	($pack,$file,$line,$sub,$hargs,undef,$eval,$require) = @a;
	#
	# if the $error error string is newline terminated then it
	# is copied into $mess.  Otherwise, $mess gets set (at the end of
	# the 'else {' section below) to one of two things.  The first time
	# through, it is set to the "$error at $file line $line" message.
	# $error is then set to 'called' which triggers subsequent loop
	# iterations to append $sub to $mess before appending the "$error
	# at $file line $line" which now actually reads "called at $file line
	# $line".  Thus, the stack trace message is constructed:
	#
	#        first time: $mess  = $error at $file line $line
	#  subsequent times: $mess .= $sub $error at $file line $line
	#                                  ^^^^^^
	#                                 "called"
	if ($error =~ m/\n$/) {
	    $mess .= $error;
	} else {
	    # Build a string, $sub, which names the sub-routine called.
	    # This may also be "require ...", "eval '...' or "eval {...}"
	    if (defined $eval) {
		if ($require) {
		    $sub = "require $eval";
		} else {
		    $eval =~ s/([\\\'])/\\$1/g;
#		    if ($MaxEvalLen && length($eval) > $MaxEvalLen) {
#			substr($eval,$MaxEvalLen) = '...';
#		    }
		    $sub = "eval '$eval'";
		}
	    } elsif ($sub eq '(eval)') {
		$sub = 'eval {...}';
	    }
	    # if there are any arguments in the sub-routine call, format
	    # them according to the format variables defined earlier in
	    # this file and join them onto the $sub sub-routine string
	    if ($hargs) {
		# we may trash some of the args so we take a copy
		@a = @DB::args;	# must get local copy of args
		# don't print any more than $MaxArgNums
		if (8 and @a > 8) {
		    # cap the length of $#a and set the last element to '...'
		    $#a = 8;
		    $a[$#a] = "...";
		}
		for (@a) {
		    # set args to the string "undef" if undefined
		    $_ = "undef", next unless defined $_;
		    if (ref $_) {
			# dunno what this is for...
			$_ .= '';
			s/'/\\'/g;
		    }
		    else {
			s/'/\\'/g;
			# terminate the string early with '...' if too long
			substr($_,64) = '...'
			    if 64 and 64 < length;
		    }
		    # 'quote' arg unless it looks like a number
		    $_ = "'$_'" unless /^-?[\d.]+$/;
		    # print high-end chars as 'M-<char>' or '^<char>'
		    s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
		    s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
		}
		# append ('all', 'the', 'arguments') to the $sub string
		$sub .= '(' . join(', ', @a) . ')';
	    }
	    # here's where the error message, $mess, gets constructed
	    $mess .= "\t$sub " if $error eq "called";
	    $mess .= "$error at $file line $line\n";
	}
	# we don't need to print the actual error message again so we can
	# change this to "called" so that the string "$error at $file line
	# $line" makes sense as "called at $file line $line".
	$error = "called";
    }
    # this kludge circumvents die's incorrect handling of NUL
    my $msg = \($mess || $error);
    $$msg =~ tr/\0//d;
    $$msg;
}

1;

__END__

=head1 NAME

Local::TeeOutput - Tee a file handle to two or more destinations

=head1 SYNOPSIS

    use Local::TeeOutput;

    openTee(*FILEHANDLE, ">file1.ext", ">>file2.ext", "file3.ext", [etc...)];
    print FILEHANDLE LIST
    printf FILEHANDLE "any string, scalar, list, or array";
    closeTee(*FILEHANDLE);

    $myfile = "file2.ext"
    openTee(*STDOUT, *STDOUT, ">>file1.ext", "$myfile", [etc...]);
    print LIST;
    closeTee(*STDOUT);

    open(LOG, ">>file.ext");
    openTee(*STDOUT, *STDOUT, *LOG);

=head1 DESCRIPTION

Local::TeeOutput provides the means to send output information to multiple 
destinations via a single filehandle.  Local::TeeOutput exports
two functions, C<openTee()> and C<closeTee()>, both having a similar interface 
to their standard perl functions counterparts C<open()> and C<close()>.

=over 4

=item

=head2 Internals

C<openTee()> uses the C<tie()> function to tie the specified filehandle to an 
object.  References to filehandles for the destinations are created 
and stored within the object, and used by the object's methods to print to
the chosen destinations.  The PRINT and PRINTF methods within the object 
duplicate the operation of the standard perl functions C<print()> and 
C<printf()>.  C<closeTee()> closes the objects internal filehandles, frees 
the original filehandle so that it can be use in a normal fashion, and
destroys the object that was created. 

For the special case of the filehandle STDERR which does not require an 
explicit print statement, C<openTee> will create a hook for the __WARN__ and 
__DIE__ signal handlers that re-route the STDERR messages through an explicit
print statement.  Conversely, C<closeTee> will reset the hooks back to default
if need be.

=head2 Syntax:

=over 4

=item

C<openTee(*FILEHANDLE,> <destination>[, <destination>, etc...]);

C<print FILEHANDLE> I<LIST>;

C<printf FILEHANDLE> I<LIST>;

C<closeTee(*FILEHANDLE)>;

=back

The first parameter passed to the C<openTee()> function is the name of the
filehandle that you wish to tee.  The first parameter can be any legal
filehandle name, either previously opened, or not.  The filehandle B<must>
be passed as an I<unquoted> typeglob.

The remaining parameters are a list of destinations that you wish to tee 
to.  There is no limit to the number of destinations for the tee, 
the minimum number is one.  (For the degenerative case of I<one> destination, 
the programmer would be better served by the perl standard function C<open()>.)  
A valid destination is either a I<previously opened> filehandle, or a valid 
filename.  Filehandles as destinations B<must> be passed as I<unquoted> 
typeglobs.  A filename can be a string literal, or a scalar variable. In most
cases, filenames are passed inside of double quotes.  If a filename is being 
passed as a scalar variable, with no mode specified (see below), the 
double quotes are optional.  If the filename is a string literal, it can be 
passed inside of single quotes.

Destinations that are filehandles are B<always> opened in the append mode.  
Destinations that are filenames can be opened in overwrite (>) or append (>>) 
mode, by preceding the filename with the appropriate symbol(s).  Append is the 
default mode for filenames, if no mode is specified.

Using the same filehandle for the first parameter and as one of the remaining
parameters is acceptable provided that the filehandle has been previously opened
(either by the programmer or by the system).  This allows the programmer to 
send information both to the screen and to a report file at the same time.  
For example:

    openTee(*STDOUT, *STDOUT, ">>log.txt");

The C<print()> and C<printf()> functions perform like, and use the same syntax 
as, the standard perl functions C<print()> and C<printf()>.  Please refer to 
the documentation for those commands for details on their usage and syntax.

The C<closeTee()> function accepts a single parameter.  The parameter B<must> 
be a filehandle that was opened by the C<openTee()> function.  The filehandle 
B<must> be passed as an I<unquoted> typeglob.

=back

=head1 INSTALLATION

This module is pure perl code and therefore requires no special installation
procedures.  Based on the namespace conventions outlined in the documentation 
on the CPAN, until this module receives an official namespace, it is designed 
to be used from a "<perl-path>\lib\Local" directory.  This is not a standard directory 
in the perl distribution and will most likely need to be created.  After the 
directory has been created, copy the module to it, and it is ready to use.

If this module is (in the future) added to the CPAN, The namespace will be
changed to whatever the powers-that-be deem.  My most likely guess would
be IO::TeeOutput.

If you wish to use a namespace other than Local::TeeOutput on your system, do 
a search and replace within the module for "Local::", and change it to your 
desired directory. 


=head1 EXAMPLE

    #!perl -w
    #
    # this example does not demonstrate all the possible permutations
    # of this module.  It only shows a few of the basic (most useful)
    # possibilities.  After this script is run, the screen should show
    # the following output:
    #
    # hello world
    # This is a test
    #      one
    #           two
    #                3
    #    another      test
    # this will only print to the screen
    # this goes to the screen and the log file
    #
    # and the file logfile.txt should be created, and contain the 
    # following output:
    #
    # hello world
    # This is a test
    #      one
    #           two
    #                3
    #    another      test
    # this goes to the screen and the log file
    # this only prints to the log file


    use Local::TeeOutput;

    # tee STDOUT to a log file using a string literal
    openTee (*STDOUT, *STDOUT, ">logfile.txt");
    
    # print a string literal to the tee
    print "hello world\n";   #STDOUT is the default file handle

    # print a scalar to the tee
    $string = "This is a test";
    print STDOUT "$string\n";  #use STDOUT explicitly 

    # print a list to the tee
    @list = ("     one\n", "          two\n", "               3\n");
    print @list;

    # print using printf to the tee
    $string1 = "another";
    $string2 = "test";
    printf "%10.10s%10.10s\n", $string1,$string2;

    # close the tee
    closeTee(*STDOUT);

    # print to the "non-tee'd" STDOUT
    print "this will only print to the screen\n";

    # open a normal filehandle to the log file
    open (LOG, ">>logfile.txt");

    # tee STDOUT to the log file via the filehandle
    openTee (*STDOUT, *STDOUT, *LOG);

    # print to both STDOUT and LOG
    print "this goes to the screen and the log file\n";
    
    # print to only the log file
    print LOG "this only prints to the log file\n";

    __END__

=head1 CAVEATS

This code has only been tested in some of the more basic of the many
possible ways it could potentially be used.  There are many untested 
scenarios that may produce bugs.  

This module has been reported to work on all Win32 platforms, and 
Red Hat linux 5.0 (NL only termination).  It should function on all
other platforms as well, but they have not been verified.

=head1 BUGS

When STDERR is tee-ed, the use of the C<eval> function as an exception
handler is disabled. 

Compile time errors and warning cannot be tee-ed.  Actually this is not 
really a bug.  The module was not designed to do this sort of thing.  For 
this capability, refer to Tie::STDERR

When STDERR is tee-ed, warnings and errors caused by printing to the tee will 
produce multiple messages, one for each tee'ed location

Implicit prints to STDOUT do not get tee'ed.  For example the standard output 
created by a call to the system() function will only print to the screen.
As a work around to this, tee STDOUT and then print the return value from a 
backticks operator (print `<command>`;)

=head1 SEE ALSO

perlfunc(1), perltie(1),

=head1 VERSION

This man page documents "Local::TeeOutput" version 0.14.

=head1 HISTORY

 0.14 | Dec. 20, 2000 | minor documentation changes 
 0.13 | July 22, 1998 | implemented stack trace subroutines allowing
                      | stderr messages to point to the main code
                      | rather than the module 
 0.12 | July 21, 1998 | added ability to tee both 
                      | STDERR and STDOUT to the same file
 0.11 | July 13, 1998 | added support for STDERR
 0.10 | June 6, 1998  | original release

=head1 AUTHOR

Ron Wantock <ron.wantock@bench.com>ron.wantock@bench.com

=head1 COPYRIGHT

Copyright (c) 2000 by Ron Wantock. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 THANKS TO

Milivoj Ivkovic for his "bug hunting efforts"

Jan Pazdziora for the Tie::STDERR module from which I got the idea for
solving the STDERR tee-ing problem, and Doug MacEachern for pointing me
towards it.

The author of the Carp.pm module, for the stack trace subroutines

=cut


