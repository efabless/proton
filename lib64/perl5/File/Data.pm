package File::Data;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Fcntl qw(:flock);
use FileHandle;
# use Tie::File; # <- todo
# use File::stat;
use vars qw(@ISA $VERSION $AUTOLOAD);
$VERSION = do { my @r = (q$Revision: 1.18 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
$| = 1;

=head1 NAME

File::Data - interface to file data

=head1 DESCRIPTION

Wraps all the accessing of a file into a convenient set of calls for
reading and writing data, including a simple regex interface.

Note that the file needs to exist prior to using this module!

See L<new()>

=head1 SYNOPSIS

=over 4

	use strict;

	use File::Data;

	my $o_dat = File::Data->new('./t/example');

	$o_dat->write("complete file contents\n");

	$o_dat->prepend("first line\n"); # line 0

	$o_dat->append("original second (last) line\n");

	$o_dat->insert(2, "new second line\n"); # inc. zero!

	$o_dat->replace('line', 'LINE');

	print $o_dat->READ;

Or, perhaps more seriously :-}

	my $o_sgm = File::Data->new('./sgmlfile');

	print "new SGML data: ".$o_sgm->REPLACE(
		'\<\s*((?i)tag)\s*\>\s*((?s).*)\s*\<\s*((?i)\s*\/\s*tag)\s*\>',
		qq|<tag>key="val"</tag>|,		
	) if $o_sgm;

See L<METHODS> and L<EXAMPLES>.

=back

=head1 IMPORTANT

lowercase method calls return the object itself, so you can chain calls.

	my $o_obj = $o_dat->read; # ! <= object !

UPPERCASE method calls return the data relevant to the operation.

	my @data  = $o_dat->READ; # ! <= data   !

While this may occasionally be frustrating, using the B<principle of
least surprise>, it is at least consistent.

See L<do>

=head1 EXPLANATION

=over 4

The idea is to standardise accessing of files for repetitive and straight
forward tasks, and remove the repeated and therefore error prone file
access I have seen in many sites, where varying, (with equivalently
varying success), methods are used to achieve essentially the same result
- a simple search and replace and/or a regex match.

Approaches to opening and working with files vary so much, where
one person may wish to know if a file exists, another wishes to know
whether the target is a file, or if it is readable, or writable and so on.
Sometimes, in production code even (horror), file's are opened without any
checks of whether the open was succesful.  Then there's a loop through
each line to find the first or many patterns to read and/or replace.
With a failure, normally the only message is 'permission denied', is
that read or write access, does the file even exist? etc.

This module attempts to provide a plain/generic interface to accessing
a file's data.  This will not suit every situation, but I have included
some examples which will hopefully demonstrate that it may be used
in situations where people would normally go through varying and
inconsistent, (and therefore error-prone),  procedures - to get at the
same data.

Theoretically you can mix and match your read and writes so long as you
don't open read-only.

	my $o_dat  = File::Data->new($file);

	my $i_snrd = $o_dat->append($append)->REPLACE($search, $replace);

	print $o_dat->READ;

One last thing - I'm sure this could be made more efficient, and I'd be
receptive to any suggestions to that effect.  Note though that the intention
has been to create a simple and consistent interface, rather than a complicated
one.

=back

=cut

# Methods we like:
# ================================================================
#
my @_METHODS = qw(append insert prepend read replace return search write);
my $_METHODS = join('|', @_METHODS);

=head1 METHODS

=over 4

=item new

Create a new File::Data object (default read-write).

	my $o_rw = File::Data->new($filename); # read-write

	my $o_ro = File::Data->new($filename, 'ro'); # read-only

Each file should have it's own discrete object.

Note that if you open a file read-only and then attempt to write to it,
that will be regarded as an error, even if you change the permissions
in the meantime.

Further: The file B<must> exist before succesful use of this method
is possible.  This is B<not> a replacement for modules which create and
delete files, this is purely designed as an interface to the B<data>
of existing files.  A B<create> function is a future possibility.

Look in L<EXAMPLES> for a more complete explanation of possible arguments
to the B<new()> method

=cut

sub new {
	my $class = shift;
	my $file  = shift;
	my $perms = shift || $File::Data::PERMISSIONS;
	my $h_err = shift || {};

	my $self = bless({
		'_err'	=> {},
		'_var'	=> {
			'backup'	=> 0,
			'limbo'		=> '',
			'state'	    => 'init',
			'writable'	=> 0,
		},
	}, $class);

	$self->_debug("file($file), perm($perms), h_err($h_err)") if $File::Data::DEBUG;
	my $i_ok = $self->_init($file, $perms, $h_err);

	return $i_ok == 1 ? $self : undef;
}

=item read

Read all data from file

	$o_dat = $o_dat->read; # !

	my @data = $o_dat->READ;

=cut

sub READ {
	my $self = shift;

	$self->_enter('read');
	$self->_debug('in: ') if $File::Data::DEBUG;

	my @ret = $self->_read;

	$self->_debug('out: '.Dumper(\@ret)) if $File::Data::DEBUG;
	$self->_leave('read');

	return @ret;
};

=item _internal

read

	does this...

=cut

sub _read { #
	my $self = shift;

	my $FH = $self->_fh;
	$FH->seek(0, 0);
	#
	my @ret = <$FH>;	

	return ($File::Data::REFERENCE) ? \@ret : @ret;
};

=item write

Write data to file

	my $o_dat = $o_dat->WRITE; # !

	my @written = $o_dat->write;

=cut

sub WRITE {
	my $self = shift;
	my @args = @_;
	my @ret  = ();

	$self->_enter('write');
	$self->_debug('in: '.Dumper(\@args)) if $File::Data::DEBUG;

	if ($self->_writable) {
		my $FH = $self->_fh;
		$FH->truncate(0);
		$FH->seek(0, 0);
		@ret = $self->_write(@args);
	}

	$self->_debug('out: '.Dumper(\@ret)) if $File::Data::DEBUG;
	$self->_leave('write');

	return ($File::Data::REFERENCE) ? \@ret : @ret;
};

sub _write { #
	my $self = shift;
	my @ret  = ();

	my $FH = $self->_fh;
	my $pos = $FH->tell;
	$self->_debug("writing at curpos: $pos") if $File::Data::DEBUG;
	foreach (@_) {
		push(@ret, $_) if print $FH $_;
        $self->_debug("wrote -->$_<--") if $File::Data::DEBUG;
	}

	return ($File::Data::REFERENCE) ? \@ret : @ret;
};

=item prepend

Prepend to file

	my $o_dat = $o_dat->prepen(\@lines); # !

	my @prepended = $o_dat->prepend(\@lines);

=cut

sub PREPEND {
	my $self = shift;
	my @ret  = ();

	$self->_enter('prepend');
	$self->_debug('in: '.Dumper(@_)) if $File::Data::DEBUG;

	if ($self->_writable) {
		my $FH = $self->_fh;
		$FH->seek(0, 0);
		my @data = <$FH>;
		$FH->truncate(0);
		$FH->seek(0, 0);
		@ret = @_ if $self->_write(@_, @data);
	}

	$self->_debug('out: '.Dumper(\@ret)) if $File::Data::DEBUG;
	$self->_leave('prepend');

	return ($File::Data::REFERENCE) ? \@ret : @ret;
};

=item insert

Insert data at line number, starting from '0'

	my $o_dat = $o_dat->insert($i_lineno, \@lines); # !

	my @inserted = $o_dat->INSERT($i_lineno, \@lines);

=cut

sub INSERT {
	my $self = shift;
	my $line = shift;
	my @ret  = ();

	$self->_enter('insert');
	$self->_debug('in: '.Dumper(\@_)) if $File::Data::DEBUG;

	if ($line !~ /^\d+$/) {
		$self->_error("can't go to non-numeric line($line)");
	} else {
		if ($self->_writable) {
			my $FH = $self->_fh;
			$FH->seek(0, 0);
			my $i_cnt = -1;
			my @pre  = ();
			my @post = ();
			while (<$FH>) {
				$i_cnt++; # 0..n
				my $pos = $FH->tell;
				if ($i_cnt < $line) {
					push(@pre, $_);
				} elsif ($i_cnt >= $line) {
					push(@post, $_);
				}	
			}
			$i_cnt++;
			if (!($i_cnt >= $line)) {
				my $s = ($i_cnt == 1) ? '' : 's';
				$self->_error("couldn't insert($line, ...) while only $i_cnt line$s in file");	
			} else {
				$FH->truncate(0);
				$FH->seek(0, 0);
				@ret = @_ if $self->_write(@pre, @_, @post);
			}
		}
	}

	$self->_debug('out: '.Dumper(\@ret)) if $File::Data::DEBUG;
	$self->_leave('insert');

	return ($File::Data::REFERENCE) ? \@ret : @ret;
}

=item append

Append to file

	my $o_dat = $o_dat->append(\@lines); # !

	my @appended = $o_dat->APPEND(\@lines);

=cut

sub APPEND {
	my $self = shift;
	my @ret  = ();

	$self->_enter('append');
	$self->_debug('in: '.Dumper(\@_)) if $File::Data::DEBUG;

	if ($self->_writable) {
		my $FH = $self->_fh;
		$FH->seek(0, 2);
		@ret = @_ if $self->_write(@_);
	}

	$self->_debug('out: '.Dumper(\@ret)) if $File::Data::DEBUG;
	$self->_leave('append');

	return ($File::Data::REFERENCE) ? \@ret : @ret;
};

=item search

Retrieve data out of a file, simple list of all matches found are returned.

Note - you must use capturing parentheses for this to work!

	my $o_dat = $o_dat->search('/^(.*\@.*)$/'); # !

	my @addrs = $o_dat->SEARCH('/^(.*\@.*)$/');

	my @names = $o_dat->SEARCH('/^(?:[^:]:){4}([^:]+):/');

=cut

sub SEARCH {
	my $self   = shift;
	my $search = shift;
	my @ret    = ();

	$self->_enter('search');
	$self->_debug("in: $search") if $File::Data::DEBUG;

	if ($search !~ /.+/) {
		$self->_error("no search($search) given");
	} else {
		my $file = $self->_var('filename');
		my $FH = $self->_fh;
		$FH->seek(0, 0);
		my $i_cnt = 0;
		if ($File::Data::STRING) {       # default
			my $orig = $/;    $/ = undef; # slurp
			my $data = <$FH>; $/ = $orig;
			$self->_debug("looking at data($data)") if $File::Data::DEBUG;
			@ret = ($data =~ /$search/g);
			$i_cnt = ($data =~ tr/\n/\n/);
		} else {
			while (<$FH>) {
				$self->_debug("looking at line($_)") if $File::Data::DEBUG;
				my $line = $_;
				push(@ret, ($line =~ /$search/));
				$i_cnt++;
			}
		}
		if (scalar(@ret) >= 1) {
			$self->_debug("search($search) failed(@ret) in file($file) lines($i_cnt)");
		}	
	}

	$self->_debug('out: '.Dumper(\@ret)) if $File::Data::DEBUG;
	$self->_leave('search');

	return ($File::Data::REFERENCE) ? \@ret : @ret;
}

=item replace

Replace data in a 'search and replace' manner, returns the final data.

	my $o_dat = $o_dat->replace($search, $replace); # !

	my @data = $o_dat->REPLACE($search, $replace);

	my @data = $o_dat->REPLACE(
		q|\<a href=(['"])([^$1]+)?$1| => q|'my.sales.com'|,
	);

This is B<simple>, in that you can do almost anything in the B<search> side,
but the B<replace> side is a bit more restricted, as we can't effect the
replacement modifiers on the fly.

If you really need this, perhaps B<(?{})> can help?

=cut

sub REPLACE {
	my $self = shift;
	my %args = @_;
	my @ret  = ();

	$self->_enter('replace');
	$self->_debug('in: '.Dumper(\%args)) if $File::Data::DEBUG;

	if ($self->_writable) {
		my $file = $self->_var('filename');
		my $FH = $self->_fh;
		$FH->seek(0, 0);
		my $i_cnt = 0;
		SEARCH:
		foreach my $search (keys %args) {
			my $replace = $args{$search};
			if ($File::Data::STRING) {       # default
				my $orig = $/;    $/ = undef; # slurp
				my $data = <$FH>; $/ = $orig;
				$self->_debug("initial ($data)") if $File::Data::DEBUG;
				if (($i_cnt = ($data =~ s/$search/$replace/g))) {
					@ret = $data;
				} else {
					print "unable($i_cnt) to search($search) and replace($replace)\n";
				}
			} else {
				while (<$FH>) {
					$self->_debug("initial line($_)") if $File::Data::DEBUG;
					my $line = $_;
					if ($line =~ s/$search/$replace/) {
						$i_cnt++;
					}
					push(@ret, $line);
				}
			}
            if (scalar(@ret) >= 1) {
                $FH->seek(0, 0);
                $FH->truncate(0);
                $FH->seek(0, 0);
                @ret = $self->_write(@ret);
            }
			if (!($i_cnt >= 1)) {
				$self->_debug("nonfulfilled search($search) and replace($replace) in file($file)");
			}
		}
	}

	$self->_debug('out: '.Dumper(\@ret)) if $File::Data::DEBUG;
	$self->_leave('replace');

	return ($File::Data::REFERENCE) ? \@ret : @ret;
}

=item xreturn

Returns the product of the given (or last) B<do()>, undef on failure.

    my $o_dat = $o_dat->prepend($A)->append($b)->return('prepend'); # !

    my @prepended = $o_dat->prepend($A)->append($b)->RETURN('prepend');

    my @appended  = $o_dat->prepend($A)->append($b)->RETURN; # like read()

=cut

sub RETURN {
	my $self = shift;
	my $call = uc(shift) || $self->_var('last');

	if ((defined($self->{'_var'}{$call}) &&
		     ref($self->{'_var'}{$call}) eq 'ARRAY'
	)) {
		return @{$self->_var($call)};
	} else {
		$self->_debug("not returning invalid call($call) ref($self->{'_var'}{$call})");
		return undef;
	}
}

=item create

placeholder - unsupported

=cut

sub create {
	my $self = shift;

	$self->_error("unsupported call: __FILE__(@_)");

	return ();
}

=item delete

placeholder - unsupported

=cut

sub delete {
	my $self = shift;

	$self->_error("unsupported call: __FILE__(@_)");

	return ();
}

=item close

Close the file

	my $i_closed = $o_dat->close; # 1|0

=cut

sub close {
	my $self = shift;

	return $self->_close;
}


=item info

placeholder - unsupported

=cut

# Returns File::stat object for the file.

# 	print 'File size: '.$o_dat->stat->size;

sub xFSTAT {
	my $self = shift;
	my $file = shift || '_';

	# print "file($file) stat: ".Dumper(stat($file));

	# return stat($file);

	return ();
}

sub xfstat {
	my $self = shift;
	my $file = shift || '_';

	# print "file($file) stat: ".Dumper(stat($file));

	# stat($file);

	return ();
}

sub dummy {
	my $self = shift;
	my %args = @_;
	my @ret  = ();

	$self->_enter('dummy');
	$self->_debug('in: '.Dumper(\%args)) if $File::Data::DEBUG;

	# if ($self->_writable) {
	#
	# $FH->seek(0, 2);
	# }

	$self->_debug('out: '.Dumper(\@ret)) if $File::Data::DEBUG;
	$self->_leave('dummy');

	return ($File::Data::REFERENCE) ? \@ret : @ret;
}

=back

=cut

# ================================================================

=head1 VARIABLES

Various variables may be set affecting the behaviour of the module.

=over 4

=item $File::Data::DEBUG

Set to 0 (default) or 1 for debugging information to be printed on STDOUT.

	$File::Data::DEBUG = 1;

Alternatively  set to a regex of any of the prime methods to debug them individually.

	$File::Data::DEBUG = '(ap|pre)pend';

=cut

$File::Data::DEBUG ||= $ENV{'File_Data_DEBUG'} || 0;
# $File::Data::DEBUG = 1; #

=item $File::Data::FATAL

Will die if there is any failure in accessing the file, or reading the data.

Default = 0 (don't die - just warn);

	$File::Data::FATAL = 1;	# die

=cut

$File::Data::FATAL ||= $ENV{'File_Data_FATAL'} || 0;

=item $File::Data::REFERENCE

Will return a reference, not a list, useful with large files.

Default is 0, ie; methods normally returns a list.  There may be an argument to
make returns work with references by default, feedback will decide.

	$File::Data::REFERENCE = 1;

	my $a_ref = $o_dat->search('.*');

	print "The log: \n".@{ $a_ref };

=cut

$File::Data::REFERENCE ||= $ENV{'File_Data_REFERENCE'} || 0;


=item $File::Data::SILENT

Set to something other than zero if you don't want error messages ?-\

	$File::Data::SILENT = 0; # per line

=cut

$File::Data::SILENT ||= $ENV{'File_Data_SILENT'} || 0;


=item $File::Data::STRING

Where regex's are used, default behaviour is to treate the entire file as a
single scalar string, so that, for example, B<(?ms:...)> matches are effective.

Unset if you don't want this behaviour.

	$File::Data::STRING = 0; # per line

=cut

$File::Data::STRING ||= $ENV{'File_Data_STRING'} || 1;


=item $File::Data::PERMISSIONS

File will be opened read-write (B<insert()> compatible) unless this
variable is set explicitly or given via B<new()>.  In either case,
unless it is one of our valid permission B<keys> declared below,
it will be passed on to B<FileHandle> and otherwise not modified.
We don't support fancy permission sets, just read or write.

Read-only permissions may be explicitly set using one of these B<keys>:

	$File::Data::PERMISSIONS = 'ro'; # or readonly or <

Or, equivalently, for read-write (default):

	$File::Data::PERMISSIONS = 'rw'; # or readwrite or +<

Note that it makes no sense to have an 'append only' command (>>),
we'd have to disable all of write, search and replace, and insert,
etc. in that case - just use the B<append()> method only.

This is a KISS-compatible module remember?

=cut

$File::Data::PERMISSIONS ||= $ENV{'File_Data_PERMISSIONS'} || '+<';


=back

# ================================================================

=head1 SPECIAL

...

=over 4

=item AUTOLOAD

Any unrecognised function will be passed to the FileHandle object for final
consideration, behaviour is then effectively 'o_dat ISA FileHandle'.

	$o_dat->truncate;

=cut

sub AUTOLOAD {
    my $self = shift;
    return if $AUTOLOAD =~ /::DESTROY$/o;    # protection

    my $meth = $AUTOLOAD;
	$meth =~ s/.+::([^:]+)$/$1/;

    if ($meth =~ /^($_METHODS)$/io) { 		# convenience
		$self->_debug("rerouting: $meth(@_)");
        return $self->do(uc($meth), @_);					# <-
        # return $self->do(lc($meth), @_);
    } else { 								# or fallback
		my $FH = $self->_fh;
		if ($FH->can($meth)) {
			return $FH->$meth(@_);							# <-
		} else {									
			$DB::single=2; #
			return $self->_error("no such method($meth)!"); # <-
		}
    }
}

=back

=cut

# ================================================================

=head1 EXAMPLES

Typical construction examples:

	my $o_rw = File::Data->new($filename, 'rw');

	my $o_ro = File::Data->new($filename, 'ro');

=over 4

=item complete

	my $o_dat = File::Data->new('./jabber');

	$o_dat->write("  Bewxre the Jabberwock my son,\n");

	$o_dat->prepend("The Jxbberwock by Lewis Cxrroll:\n");

	$o_dat->append("  the claws thxt snxtch,\n  ...\n");

	$o_dat->insert(2, "  the jaws which bite.\n");

	$o_dat->replace('x', 'a');

	print $o_dat->SEARCH('The.+\n')->REPLACE("The.+\n", '')->return('search');

	print $o_dat->READ;

=item error

Failure is indicated by an error routine being called, this will print
out any error to STDERR, unless warnings are declared fatal, in which
case we croak.  You can register your own error handlers for any method
mentioned in the L<METHOD> section of this document, in addition is a
special B<init> call for initial file opening and general setting up.

Create a read-write object with a callback for all errors:

	my $o_rw = File::Data->new($filename, 'ro', {
		'error'		=> \&myerror,
	});

Create a read-only object with a separate object handler for each error type:

	my $o_rw = File::Data->new($filename, 'rw', {
		'error'		=> $o_generic->error_handler,
		'insert'	=> $o_handler->insert_error,
		'open'		=> $o_open_handler,
		'read'		=> \&carp,
		'write'		=> \&write_error,
	});

=item commandline

From the command line:

	C<perl -MFile::Data -e "File::Data->new('./test.txt')->write('some stuff')">

And (very non-obfuscated)

  C<
  perl -MFile::Data -e "@x=sort qw(perl another hacker just);
    print map {split(\"\n\", ucfirst(\$_).\" \")}\
    File::Data->new(\"./t/japh\")->\
      write(shift(@x).\"\n\")->    \
      append(shift(@x).\"\n\")->   \
      prepend(shift(@x).\"\n\")->  \
      insert(2, shift(@x).\"\n\")->\
    READ;"
  >

If you still have problems, mail me the output of
		
	make test TEST_VERBOSE=1

=cut

# ================================================================

# Private methods not expected to be called by anybody, and completely
# unsupported.  Expected to metamorphose regularly - do B<not> call these - you
# have been warned!

# Variable get/set method
#
#   my $get = $o_dat->_var($key);		# get
#
#	my $set = $o_dat->_var($key, $val);	# set	

# @_METHODS, qw(append insert prepend read replace return search write);
my $_VARS = join('|', @_METHODS, qw(
	backup error errors filename filehandle last limbo permissions state writable
));

sub _var {
	my $self = shift;
	my $key  = shift;
	my $val  = shift;
	my $ret  = '';
	
	# if (!(grep(/^_$key$/, keys %{$self{'_var'}}))) {
	if ($key !~ /^($_VARS)$/io) {
		$self->_error("No such key($key) val($val)!");
	} else {
		if (defined($val)) {
			$self->{'_var'}{$key} = $val;
			# {"$File::Data::$key"} = $val;
			$self->_debug("set key($key) => val($val)");
		}
		$ret = $self->{'_var'}{$key};
	}

	return $ret;
}

# Print given args on STDOUT
#
#	$o_dat->_debug($msg) if $File::Data::DEBUG;

sub _debug {
	my $self = shift;

	my $state = $self->{'_var'}{'state'}; # ahem
	my $debug = $File::Data::DEBUG;

	if (($debug =~ /^(\d+)$/o && $1 >= 1) ||
	     $debug =~ /^(.+)$/o && $state =~ /$debug/
	) {
		print ("$state: ", @_, "\n");
	}

	return ();
}

# Return dumped env and object B<key> and B<values>
#
#	print $o_dat->_vars;

sub _vars {
	my $self  = shift;
	my $h_ret = $self;

	no strict 'refs';
	foreach my $key (keys %{File::Data::}) {
		next unless $key =~ /^[A-Z]+$/o;
		next if $key =~ /^(BEGIN|EXPORT)/o;
		my $var = "File::Data::$key";
		$$h_ret{'_pck'}{$key} = $$var;
	}

	return Dumper($h_ret);
}

# Get/set error handling methods/objects
#
#	my $c_sub = $o_dat->_err('insert'); # or default

sub _err {
	my $self  = shift;
	my $state = shift || $self->_var('state');

	my $err   = $self->{'_err'}{$state} || $self->{'_err'}{'default'};

	return $err;
}

# By default prints error to STDERR, will B<croak> if B<File::Data::FATAL> set,
# returning ().  See L<EXAMPLES> for info on how to pass your own error
# handlers in.

sub _error {
	my $self = shift;
	my @err  = @_;
	my @ret  = ();

	my $state = $self->_var('state');
	my $c_ref = $self->_err($state );
	my $error = $self->_var('error');
	unshift(@err, "$state ERROR: ");
	my $ref   = $self->_var('errors', join("\n", @err));

	# $self->_debug($self->_vars) if $File::Data::DEBUG;

		if (ref($c_ref) eq 'CODE') {
			eval { @ret = &$c_ref(@err) };
			if ($@) {
			$File::Data::FATAL >= 1
				? croak("$0 failed: $c_ref(@err)")
				: carp("$0 failed: $c_ref(@err)")
			;
		}
		} elsif (ref($c_ref) && $c_ref->can($state)) {
			eval { @ret = $c_ref->$state(@err) };
			if ($@) {
			$File::Data::FATAL >= 1
				? croak("$0 failed: $c_ref(@err)")
				: carp("$0 failed: $c_ref(@err)")
			;
		}
		} else {
			unless ($File::Data::SILENT) {
			($File::Data::FATAL >= 1) ? croak(@err) : carp(@err);
			}
		}

	return (); #
}

#	my $file = $o_dat->_mapfile($filename);

sub _mapfile {
	my $self = shift;
	my $file = shift || '';

	$file =~ s/^\s*//o;
	$file =~ s/\s*$//o;

	unless ($file =~ /\w+/o) {
		$file = '';
		$self->_error("inappropriate filename($file)");
	} else {
		my $xfile = $self->_var('filename') || '';
		if ($xfile =~ /.+/o) {
			$file = '';
			$self->_error("can't reuse ".ref($self)." object($xfile) for another file($file)");
		}
	}

	return $file;
}

# Maps given permissions to appropriate form for B<FileHandle>
#
#	my $perms = $o_dat->_mapperms('+<');	

sub _mapperms {
	my $self = shift;
	my $args = shift || '';

	$args =~ s/^\s*//o;
	$args =~ s/\s*$//o;

	my %map = ( # we only recognise
		'ro'		=> '<',
		'readonly'	=> '<',
		'rw'		=> '+<',
		'readwrite'	=> '+<',
	);
	my $ret = $map{$args} || $args;

	$self->_error("Inappropriate permissions($args) - use this: ".Dumper(\%map))
		unless $ret =~ /.+/o;

	return $ret;
}

# Map error handlers, if given
#
#	my $h_errs = $o_dat->_maperrs(\%error_handlers);

sub _mapperrs {
	my $self   = shift;
	my $h_errs = shift || {};
	
	if (ref($h_errs) ne 'HASH') {
		$self->_error("invalid error_handlers($h_errs)");
	} else {
		foreach my $key (%{$h_errs}) {
			$self->{'_err'}{$key} = $$h_errs{$key};
		}
	}	

	return $self->{'_err'};
}

# Mark the entering of a special section, or state
#
#	my $entered = $o_dat->enter('search');

sub _enter {
	my $self = shift;
	my $sect = shift;
	
	my $last = $self->_var('state');
	$self->_var('last' => $last) unless $last eq 'limbo';
	my $next  = $self->_var('state' => $sect);

	# $self->_debug("vars") if $File::Data::DEBUG;

	return $next;
}

# Mark the leaving of a special section, or state
#
#	my $left = $o_dat->_leave('search');

sub _leave {
	my $self = shift;
	my $sect = shift;
	
	my $last = $self->_var('state');
	$self->_var('last' => $last) unless $last eq 'limbo';
	my $next  = $self->_var('state' => 'limbo');

	# $self->_debug("leaving state($last) => next($next)") if $File::Data::DEBUG;

	return $last;
}

# Get and set B<FileHandle>.  Returns undef otherwise.
#
#	my $FH = $o_dat->_fh($FH);

sub _fh {
	my $self = shift;
	my $arg  = shift;

	my $FH = (defined($arg)
		? $self->_var('filehandle', $arg)
		: $self->_var('filehandle')
	);
	$self->_error("no filehandle($FH)") unless $FH;

	return $FH;
}

# ================================================================
# Return values:
#
#	1 = success
#
#	0 = failure

# Setup object, open a file, with permissions.
#
#	my $i_ok = $o_dat->_init( $file, $perm, $h_errs );

sub _init {
	my $self = shift;
	my $file = shift;
	my $perm = shift;
	my $h_err= shift;
	my $i_ok = 0;

	# $self->_enter('init');
	$self->_debug("in: file($file), perm($perm), h_err($h_err)") if $File::Data::DEBUG;

	$file  = $self->_mapfile($file  );
	$perm  = $self->_mapperms($perm ) if $file;
	$h_err = $self->_mapperrs($h_err) if $file; # if $perm

	if ($file) { # unless $h_err
		$i_ok = $self->_check_access($file, $perm);
		if ($i_ok == 1) {
			$file = $self->_var('filename', $file);
			$perm = $self->_var('permissions', $perm);
			$i_ok = $self->_open($file, $perm);
			$i_ok = $self->_backup() if $i_ok && $self->_var('backup');
		}
	}
	# $self->_error("failed for file($file) and perm($perm)") unless $i_ok == 1;

	$self->_debug("out: $i_ok") if $File::Data::DEBUG;
	$self->_leave('init');

	return $i_ok;
}

# Checks the args for existence and appropriate permissions etc.
#
#	my $i_isok = $o_dat->_check_access($filename, $permissions);

sub _check_access {
	my $self = shift;
	my $file = shift;
	my $perm = shift;
	my $i_ok = 0;

	if (!($file =~ /.+/o && $perm =~ /.+/o)) {
		$self->_error("no filename($file) or permissions($perm) given!");
	} else {
		stat($file); # just once
		if (! -e _) {
			$self->_error("target($file) does not exist!");
		} else {
			if (! -f _) {
				$self->_error("target($file) is not a file!");
			} else {	
				if (!-r _) {
					$self->_error("file($file) cannot be read by effective uid($>) or gid($))!");
				} else {
					if ($perm =~ /^<$/o) { # readable
						$i_ok++;
					} else {
						if (! -w $file) {
							$self->_error("file($file) cannot be written by effective uid($>) or gid($))!");
						} else {           # writable
							$self->_var('writable' => 1);
							$i_ok++;
						}
					}
				}
			}
		}
	}

	return $i_ok;
}

# Open the file
#
#	my $i_ok = $o_dat->_open;

sub _open {
	my $self = shift;
	my $file = $self->_var('filename');
	my $perm = $self->_var('permissions');
	my $i_ok = 0;
	
	my $open = "$perm $file";
	$self->_debug("using open($open)");

	my $FH = FileHandle->new("$perm $file") || '';
	my @file = ();
	# my $FH = tie(@file, 'Tie::File', $file) or '';
	if (!$FH) {
		$self->_error("Can't get handle($FH) for file($file) with permissions($perm)! $!");
	} else {
		# $FH = $self->_fh(\@file);
		$FH = $self->_fh($FH);
		if ($FH) {
			$i_ok++;
			$i_ok = $self->_lock(); # if $self->_writable;
		}
		$self->_debug("FH($FH) => i_ok($i_ok)");
	}

	return $i_ok;
};

# Lock the file
#
#	my $i_ok = $o_dat->_lock;

sub _lock {
	my $self = shift;
	my $FH   = $self->_fh;
	my $i_ok = 0;

	if ($FH) {
		my $file = $self->_var('filename');
		if ($self->_writable) {
			# if ($FH->flock(LOCK_EX | LOCK_NB)) {
			if (flock($FH, LOCK_EX | LOCK_NB)) {
				$i_ok++;
			} else {
				$self->_error("Can't overlock file($file) handle($FH)!");
			}
		} else {
			# if ($FH->flock(LOCK_SH | LOCK_NB)) {
			if (flock($FH, LOCK_SH | LOCK_NB)) {
				$i_ok++;
			} else {
				$self->_error("Can't lock shared file($file) handle($FH)!");
			}
		}
	}

	return $i_ok;
};

# Unlock the file
#
#	my $i_ok = $o_dat->_unlock;

sub _unlock {
	my $self = shift;
	my $FH   = $self->_fh;
	my $i_ok = 0;

	if ($FH) {
		# if (flock($FH, LOCK_UN)) { apparently there's a race, perl does it better - see close :) }
		$i_ok++;
	} else {
		my $file = $self->_var('filename');
		$self->_error("Can't unlock file($file) handle($FH)!");
	}

	return $i_ok;
}

# Close the filehandle
#
#	my $i_ok = $o_dat->_close;

sub _close {
	my $self = shift;
	my $FH   = $self->_fh if $self->_var('filehandle');
	my $i_ok = 0;

	if ($FH) {
		# $FH->untie;
		if ($FH->close) { # perl unlocks it better than we can (race)
			$i_ok++;
		} else {
			$DB::single=2; #
			my $file = $self->_var('filename');
			$self->_error("Can't close file($file) handle($FH)!");
		}
	}

	return $i_ok;
}

sub _writable {
	my $self = shift;

	my $i_ok = $self->_var('writable');

	if ($i_ok != 1) {
		my $file  = $self->_var('filename');
		my $perms = $self->_var('permissions');
		$self->_debug("$file not writable($i_ok) with permissions($perms)");
	}

	return $i_ok;
}

=item do

Simple wrapper for method calls, returning the content.

    my @inserted = $o_dat->do('insert', @this);

    my @appended = $o_dat->do('append', @this);

An addendum to this method, and to make life generally easier, is that
you can also call any of the above methods in uppercase, to call via
B<do()> eg;

    my @data = $o_dat->WRITE($this)->APPEND->($that)->read;

First argument is the method to call, followed by the arguments that
method expects.

    perl -MFile::Data -e "print File::Data->new($file)->INSERT(3,
    \"third line\n\")->READ";

If you want to get at the output of a particular called method see
L<return()>

=cut

sub DO {
	my $self = shift;
	my $call = shift;
	my @res  = ();

	$self->_enter('do');
	$self->_debug('in: '.Dumper([$call, @_])) if $File::Data::DEBUG;

	if ($call !~ /^($_METHODS)$/io) {
		$self->_error("unsupported method($call)");
	} else {
		$call = uc($call);
		$self->_var($call => []);
		my @res = $self->$call(@_);
		$self->_var($call => (ref($res[0]) ? $res[0] : \@res));
	}

	$self->_debug('out: $self') if $File::Data::DEBUG;
	$self->_leave('do');

	return @res;
}

sub do {
	my $self = shift;

	$self->DO(@_);

	return $self;
}

=back

=cut

# ================================================================

sub DESTROY {
	my $self = shift;
	$self->_close;
}

=head1 AUTHOR

"Richard Foley" <File.Data@rfi.net>

=cut

1;

