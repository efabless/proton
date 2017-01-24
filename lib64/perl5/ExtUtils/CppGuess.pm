package ExtUtils::CppGuess;

use strict;
use warnings;

=head1 NAME

ExtUtils::CppGuess - guess C++ compiler and flags

=head1 SYNOPSIS

With L<Extutils::MakeMaker>:

    use ExtUtils::CppGuess;
    
    my $guess = ExtUtils::CppGuess->new;
    
    WriteMakefile
      ( # MakeMaker args,
        $guess->makemaker_options,
        );

With L<Module::Build>:

    my $guess = ExtUtils::CppGuess->new;
    
    my $build = Module::Build->new
      ( # Module::Build arguments
        $guess->module_build_options,
        );
    $build->create_build_script;

=head1 DESCRIPTION

C<ExtUtils::CppGuess> attempts to guess the system's C++ compiler
that is compatible with the C compiler that your perl was built with.

It can generate the necessary options to the L<Module::Build>
constructor or to L<ExtUtils::MakeMaker>'s C<WriteMakefile>
function.

=head1 METHODS

=head2 new

Creates a new C<ExtUtils::CppGuess> object.
Takes the path to the C compiler as the C<cc> argument,
but falls back to the value of C<$Config{cc}>, which should
be what you want anyway.

You can specify C<extra_compiler_flags> and C<extra_linker_flags>
(as strings) which will be merged in with the auto-detected ones.

=head2 module_build_options

Returns the correct options to the constructor of C<Module::Build>.
These are:

    extra_compiler_flags
    extra_linker_flags

=head2 makemaker_options

Returns the correct options to the C<WriteMakefile> function of
C<ExtUtils::MakeMaker>.
These are:

    CCFLAGS
    dynamic_lib => { OTHERLDFLAGS => ... }

If you specify the extra compiler or linker flags in the
constructor, they'll be merged into C<CCFLAGS> or
C<OTHERLDFLAGS> respectively.

=head2 is_gcc

Returns true if the detected compiler is in the gcc family.

=head2 is_msvc

Returns true if the detected compiler is in the MS VC family.

=head2 add_extra_compiler_flags

Takes a string as argument that is added to the string of extra compiler
flags.

=head2 add_extra_linker_flags

Takes a string as argument that is added to the string of extra linker
flags.

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

Steffen Mueller <smueller@cpan.org>

Tobias Leich <froggs@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2010, 2011 by Mattia Barbon.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use Config ();
use File::Basename qw();
use Capture::Tiny 'capture_merged';

our $VERSION = '0.09';

sub new {
    my( $class, %args ) = @_;
    my $self = bless {
      cc => $Config::Config{cc},
      %args
    }, $class;

    return $self;
}

sub guess_compiler {
    my( $self ) = @_;
    return $self->{guess} if $self->{guess};

    if( $^O =~ /^mswin/i ) {
        $self->_guess_win32() or return();
    } else {
        $self->_guess_unix() or return();
    }

    return $self->{guess};
}

sub _get_cflags {
    my( $self ) = @_;
    $self->guess_compiler || die;
    my $cflags = $self->{guess}{extra_cflags};
    $cflags .= ' ' . $self->{extra_compiler_flags}
      if defined $self->{extra_compiler_flags};
    return $cflags;
}

sub _get_lflags {
    my( $self ) = @_;
    $self->guess_compiler || die;
    my $lflags = $self->{guess}{extra_lflags};
    $lflags .= ' ' . $self->{extra_linker_flags}
      if defined $self->{extra_linker_flags};
    return $lflags;
}

sub makemaker_options {
    my( $self ) = @_;

    my $lflags = $self->_get_lflags;
    my $cflags = $self->_get_cflags;

    return ( CCFLAGS      => $cflags,
             dynamic_lib  => { OTHERLDFLAGS => $lflags },
             );
}

sub module_build_options {
    my( $self ) = @_;

    my $lflags = $self->_get_lflags;
    my $cflags = $self->_get_cflags;

    return ( extra_compiler_flags => $cflags,
             extra_linker_flags   => $lflags,
             );
}

sub _guess_win32 {
    my( $self ) = @_;
    my $c_compiler = $self->{cc};
    $c_compiler = $Config::Config{cc} if not defined $c_compiler;

    if( $self->_cc_is_gcc( $c_compiler ) ) {
        $self->{guess} = { extra_cflags => ' -xc++ ',
                           extra_lflags => ' -lstdc++ ',
                           };
    } elsif( $self->_cc_is_msvc( $c_compiler ) ) {
        $self->{guess} = { extra_cflags => ' -TP -EHsc ',
                           extra_lflags => ' msvcprt.lib ',
                           };
    } else {
        die "Unable to determine a C++ compiler for '$c_compiler'";
    }

    return 1;
}

sub _guess_unix {
    my( $self ) = @_;
    my $c_compiler = $self->{cc};
    $c_compiler = $Config::Config{cc} if not defined $c_compiler;

    if( !$self->_cc_is_gcc( $c_compiler ) ) {
        die "Unable to determine a C++ compiler for '$c_compiler'";
    }

    $self->{guess} = { extra_cflags => ' -xc++ ',
                       extra_lflags => ' -lstdc++ ',
                       };
    $self->{guess}{extra_cflags} .= ' -D_FILE_OFFSET_BITS=64' if $Config::Config{ccflags} =~ /-D_FILE_OFFSET_BITS=64/;
    $self->{guess}{extra_lflags} .= ' -lgcc_s' if $^O eq 'netbsd' && $self->{guess}{extra_lflags} !~ /-lgcc_s/;
    return 1;
}

# originally from Alien::wxWidgets::Utility

my $quotes = $^O =~ /MSWin32/ ? '"' : "'";

sub _capture {
    my @cmd = @_;
    my $out = capture_merged {
        system(@cmd);
    };
    $out = '' if not defined $out;
    return $out;
}

# capture the output of a command that is run with piping
# to stdin of the command. We immediately close the pipe.
sub _capture_empty_stdin {
    my( $cmd ) = @_;
    my $out = capture_merged {
        if (open(my $fh, '|-', $cmd)) {
          close $fh;
        }
    };
    $out = '' if not defined $out;
    return $out;
}


sub _cc_is_msvc {
    my( $self, $cc ) = @_;
    $self->{is_msvc} = ($^O =~ /MSWin32/ and File::Basename::basename( $cc ) =~ /^cl/i);
    return $self->{is_msvc};
}

sub _cc_is_gcc {
    my( $self, $cc ) = @_;

    $self->{is_gcc} = 0;
    my $cc_version = _capture( "$cc --version" );
    if (
            $cc_version =~ m/\bg(?:cc|\+\+)/i # 3.x, some 4.x
         || scalar( _capture( "$cc" ) =~ m/\bgcc\b/i ) # 2.95
         || scalar(_capture_empty_stdin("$cc -dM -E -") =~ /__GNUC__/) # more or less universal?
         || scalar($cc_version =~ m/\bcc\b.*Free Software Foundation/si) # some 4.x?
       )
    {
        $self->{is_gcc} = 1;
    }

    return $self->{is_gcc};
}

sub is_gcc {
    my( $self ) = @_;
    $self->guess_compiler || die;
    return $self->{is_gcc};
}

sub is_msvc {
    my( $self ) = @_;
    $self->guess_compiler || die;
    return $self->{is_msvc};
}

sub add_extra_compiler_flags {
    my( $self, $string ) = @_;
    $self->{extra_compiler_flags}
      = defined($self->{extra_compiler_flags})
        ? $self->{extra_compiler_flags} . ' ' . $string
        : $string;
}

sub add_extra_linker_flags {
    my( $self, $string ) = @_;
    $self->{extra_linker_flags}
      = defined($self->{extra_linker_flags})
        ? $self->{extra_linker_flags} . ' ' . $string
        : $string;
}

1;
