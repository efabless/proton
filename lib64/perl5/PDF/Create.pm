#
# PDF::Create - create PDF files
#
# Original Author: Fabien Tassin

#
# Copyright 1999-2001 Fabien Tassin
# Copyright 2007-     Markus Baertschi <markus@markus.org>
# Copyright 2010      Gary Lieberman
#
# Please see the CHANGES and Changes file for the detailed change log
#

package PDF::Create;
use strict;
use warnings;

use Carp qw(confess croak cluck carp);
use FileHandle;
use Scalar::Util qw(weaken);
use PDF::Create::Page;
use PDF::Create::Outline;
use PDF::Image::GIF;
use PDF::Image::JPEG;

our $VERSION = '1.10';
my $DEBUG = 0;


#
# Create a new PDF file
#
sub new
{
	my $this   = shift;
	my %params = @_;

	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	$self->{'data'}    = '';
	$self->{'version'} = $params{'Version'} || "1.2";
	$self->{'trailer'} = {};

	$self->{'pages'}          = PDF::Create::Page->new();
	$self->{'current_page'}   = $self->{'pages'};
	$self->{'pages'}->{'pdf'} = $self;                     # circular reference
	weaken $self->{pages}{pdf};
	$self->{'page_count'}     = 0;

	$self->{'outline_count'} = 0;

	$self->{'crossreftblstartaddr'} = 0;                   # cross-reference table start address
	$self->{'generation_number'}    = 0;
	$self->{'object_number'}        = 0;

	if ( defined $params{'fh'} ) {
		$self->{'fh'} = $params{'fh'};
	} elsif ( defined $params{'filename'} ) {
		$self->{'filename'} = $params{'filename'};
		my $fh = FileHandle->new( "> $self->{'filename'}" );
		carp "PDF::Create.pm: $self->{'filename'}: $!\n" unless defined $fh;
		binmode $fh;
		$self->{'fh'} = $fh;
	}
	$self->{'catalog'} = {};
	$self->{'catalog'}{'PageMode'} = $params{'PageMode'}
	  if defined $params{'PageMode'};

	# Header: add version
	$self->add_version;

	# Info
	$self->{'Author'}   = $params{'Author'}   if defined $params{'Author'};
	$self->{'Creator'}  = $params{'Creator'}  if defined $params{'Creator'};
	$self->{'Title'}    = $params{'Title'}    if defined $params{'Title'};
	$self->{'Subject'}  = $params{'Subject'}  if defined $params{'Subject'};
	$self->{'Keywords'} = $params{'Keywords'} if defined $params{'Keywords'};

	# TODO: Default creation date from system date
	if ( defined $params{'CreationDate'} ) {
		$self->{'CreationDate'} =
		  sprintf "D:%4u%0.2u%0.2u%0.2u%0.2u%0.2u",
		  $params{'CreationDate'}->[5] + 1900, $params{'CreationDate'}->[4] + 1,
		  $params{'CreationDate'}->[3], $params{'CreationDate'}->[2],
		  $params{'CreationDate'}->[1], $params{'CreationDate'}->[0];
	}
	if ( defined $params{'Debug'} ) {
		print "DEBUG\n";
		$DEBUG = $params{'Debug'};

		# Enable stack trace for PDF::Create internal routines
		$Carp::Internal{ ('PDF::Create') }++;
	}
	debug( 1, "Debugging level $DEBUG" );
	return $self;
}

#
# Close does the work of creating the PDF data from the
# objects collected before.
#
sub close
{
	my $self   = shift;
	my %params = @_;

	debug( 2, "Closing PDF" );
	$self->page_stream;
	$self->add_outlines if defined $self->{'outlines'};
	$self->add_catalog;
	$self->add_pages;
	$self->add_info;
	$self->add_crossrefsection;
	$self->add_trailer;
	$self->{'fh'}->close
	  if defined $self->{'fh'} && defined $self->{'filename'};
	$self->{'data'};
}

#
# Helper function for debugging
# Prints the passed message if debug level is sufficiently high
#
sub debug
{
	my $level = shift;
	my $msg   = shift;

	return unless ( $DEBUG >= $level );

	my $s = scalar @_ ? sprintf $msg, @_ : $msg;

	warn "DEBUG ($level): $s\n";
}

#
# Set/Return the PDF version
#
sub version
{
	my $self = shift;
	my $v    = shift;

	if ( defined $v ) {

		# TODO: should test version (1.0 to 1.3)
		$self->{'version'} = $v;
	}
	$self->{'version'};
}

# Add some data to the current PDF structure.
sub add
{
	my $self = shift;
	my $data = join '', @_;
	$self->{'size'} += length $data;
	if ( defined $self->{'fh'} ) {
		my $fh = $self->{'fh'};
		print $fh $data;
	} else {
		$self->{'data'} .= $data;
	}
}

# Get the current position in the PDF
sub position
{
	my $self = shift;

	$self->{'size'};
}

# Reserve the next object number for the given object type.
sub reserve
{
	my $self = shift;
	my $name = shift;
	my $type = shift || $name;

	confess "Error: an object has already been reserved using this name '$name' "
	  if defined $self->{'reservations'}{$name};
	$self->{'object_number'}++;
	debug( 2, "reserve(): name=$name type=$type number=$self->{'object_number'} generation=$self->{'generation_number'}" );
	$self->{'reservations'}{$name} = [ $self->{'object_number'}, $self->{'generation_number'}, $type ];

	#
	# Annotations added here by Gary Lieberman
	#
	# Store the Object ID and the Generation Number for later use when we write out the /Page object
	#
	if ( $type eq 'Annotation' ) {
		$self->{'Annots'}{ $self->{'object_number'} } = $self->{'generation_number'};
	}

	#
	# Annotations code ends here
	#
	[ $self->{'object_number'}, $self->{'generation_number'} ];
}

sub add_version
{
	my $self = shift;
	debug( 2, "add_version(): $self->{'version'}" );
	$self->add( "%PDF-" . $self->{'version'} );
	$self->cr;
}

sub add_comment
{
	my $self = shift;
	my $comment = shift || '';
	debug( 2, "add_comment(): $comment" );
	$self->add( "%" . $comment );
	$self->cr;
}

sub encode
{
	my $type = shift;
	my $val  = shift;

	if ($val) {
		debug( 4, "encode(): $type $val" );
	} else {
		debug( 4, "encode(): $type (no val)" );
	}
	if ( !$type ) { cluck "PDF::Create::encode: empty argument, called by "; return 1 }
	( $type eq 'null' || $type eq 'number' ) && do {
		1;    # do nothing
	  }
	  || $type eq 'cr' && do {
		$val = "\n";
	  }
	  || $type eq 'boolean' && do {
		$val =
		    $val eq 'true'  ? $val
		  : $val eq 'false' ? $val
		  : $val eq '0'     ? 'false'
		  :                   'true';
	  }
	  || $type eq 'verbatim' && do {
		$val = "$val";
	  }
	  || $type eq 'string' && do {
		$val = '' if not defined $val;
		$val = "($val)";    # TODO: split it. Quote parentheses.
	  }
	  || $type eq 'number' && do {
		$val = "$val";
	  }
	  || $type eq 'name' && do {
		$val = '' if not defined $val;
		$val = "/$val";
	  }
	  || $type eq 'array' && do {

		# array, encode contents individually
		my $s = '[';
		for my $v (@$val) {
			$s .= &encode( $$v[0], $$v[1] ) . " ";
		}
		chop $s;    # remove the trailing space
		$val = $s . "]";
	  }
	  || $type eq 'dictionary' && do {
		my $s = '<<' . &encode('cr');
		for my $v ( keys %$val ) {
			$s .= &encode( 'name',            $v ) . " ";
			$s .= &encode( ${ $$val{$v} }[0], ${ $$val{$v} }[1] );    #  . " ";
			$s .= &encode('cr');
		}
		$val = $s . ">>";
	  }
	  || $type eq 'object' && do {
		my $s = &encode( 'number', $$val[0] ) . " " . &encode( 'number', $$val[1] ) . " obj";
		$s .= &encode('cr');
		$s .= &encode( $$val[2][0], $$val[2][1] );                    #  . " ";
		$s .= &encode('cr');
		$val = $s . "endobj";
	  }
	  || $type eq 'ref' && do {
		my $s = &encode( 'number', $$val[0] ) . " " . &encode( 'number', $$val[1] ) . " R";
		$val = $s;
	  }
	  || $type eq 'stream' && do {
		my $data = delete $$val{'Data'};
		my $s    = '<<' . &encode('cr');
		for my $v ( keys %$val ) {
			$s .= &encode( 'name',            $v ) . " ";
			$s .= &encode( ${ $$val{$v} }[0], ${ $$val{$v} }[1] );    #  . " ";
			$s .= &encode('cr');
		}
		$s .= ">>" . &encode('cr') . "stream" . &encode('cr');
		$s .= $data . &encode('cr');
		$val = $s . "endstream" . &encode('cr');
	  }
	  || confess "Error: unknown type '$type'";

	# TODO: add type 'text';
	$val;
}

sub add_object
{
	my $self = shift;
	my $v    = shift;

	my $val = &encode(@$v);
	$self->add($val);
	$self->cr;
	debug( 3, "add_object(): $v -> $val" );
	[ $$v[1][0], $$v[1][1] ];
}

sub null
{
	my $self = shift;
	[ 'null', 'null' ];
}

sub boolean
{
	my $self = shift;
	my $val  = shift;
	[ 'boolean', $val ];
}

sub number
{
	my $self = shift;
	my $val  = shift;
	[ 'number', $val ];
}

sub name
{
	my $self = shift;
	my $val  = shift;
	[ 'name', $val ];
}

sub string
{
	my $self = shift;
	my $val  = shift;
	[ 'string', $val ];
}

sub verbatim
{
	my $self = shift;
	my $val  = shift;
	[ 'verbatim', $val ];
}

sub array
{
	my $self = shift;
	[ 'array', [@_] ];
}

sub dictionary
{
	my $self = shift;
	[ 'dictionary', {@_} ];
}

sub indirect_obj
{
	my $self = shift;
	
	my ( $id, $gen, $type, $name );
	$name = $_[1];
	$type = $_[0][1]{'Type'}[1]
	  if defined $_[0][1] && ref $_[0][1] eq 'HASH' && defined $_[0][1]{'Type'};
	if ( defined $name && defined $self->{'reservations'}{$name} ) {
		( $id, $gen ) = @{ $self->{'reservations'}{$name} };
		delete $self->{'reservations'}{$name};
	} elsif ( defined $type && defined $self->{'reservations'}{$type} ) {
		( $id, $gen ) = @{ $self->{'reservations'}{$type} };
		delete $self->{'reservations'}{$type};
	} else {
		$id  = ++$self->{'object_number'};
		$gen = $self->{'generation_number'};
	}
	debug( 3, "indirect_obj(): " . $self->position );
	push @{ $self->{'crossrefsubsection'}{$gen} }, [ $id, $self->position, 1 ];
	[ 'object', [ $id, $gen, @_ ] ];
}

sub indirect_ref
{
	my $self = shift;
	[ 'ref', [@_] ];
}

sub stream
{
	my $self = shift;
	[ 'stream', {@_} ];
}

sub add_info
{
	my $self = shift;

	debug( 2, "add_info():" );
	my %params = @_;
	$params{'Author'}   = $self->{'Author'}   if defined $self->{'Author'};
	$params{'Creator'}  = $self->{'Creator'}  if defined $self->{'Creator'};
	$params{'Title'}    = $self->{'Title'}    if defined $self->{'Title'};
	$params{'Subject'}  = $self->{'Subject'}  if defined $self->{'Subject'};
	$params{'Keywords'} = $self->{'Keywords'} if defined $self->{'Keywords'};
	$params{'CreationDate'} = $self->{'CreationDate'}
	  if defined $self->{'CreationDate'};

	$self->{'info'} = $self->reserve('Info');
	my $content = { 'Producer' => $self->string("PDF::Create version $VERSION"),
					'Type'     => $self->name('Info')
				  };
	$$content{'Author'} = $self->string( $params{'Author'} )
	  if defined $params{'Author'};
	$$content{'Creator'} = $self->string( $params{'Creator'} )
	  if defined $params{'Creator'};
	$$content{'Title'} = $self->string( $params{'Title'} )
	  if defined $params{'Title'};
	$$content{'Subject'} = $self->string( $params{'Subject'} )
	  if defined $params{'Subject'};
	$$content{'Keywords'} = $self->string( $params{'Keywords'} )
	  if defined $params{'Keywords'};
	$$content{'CreationDate'} = $self->string( $params{'CreationDate'} )
	  if defined $params{'CreationDate'};
	$self->add_object( $self->indirect_obj( $self->dictionary(%$content) ), 'Info' );
	$self->cr;
}

# Catalog specification.
sub add_catalog
{
	my $self = shift;

	debug( 2, "add_catalog" );
	my %params = %{ $self->{'catalog'} };

	# Type (mandatory)
	$self->{'catalog'} = $self->reserve('Catalog');
	my $content = { 'Type' => $self->name('Catalog') };

	# Pages (mandatory) [indirected reference]
	my $pages = $self->reserve('Pages');
	$$content{'Pages'} = $self->indirect_ref(@$pages);
	$self->{'pages'}{'id'} = $$content{'Pages'}[1];

	# Outlines [indirected reference]
	$$content{'Outlines'} = $self->indirect_ref( @{ $self->{'outlines'}->{'id'} } )
	  if defined $self->{'outlines'};

	# PageMode
	$$content{'PageMode'} = $self->name( $params{'PageMode'} )
	  if defined $params{'PageMode'};

	$self->add_object( $self->indirect_obj( $self->dictionary(%$content) ) );
	$self->cr;
}

sub add_outlines
{
	my $self = shift;

	debug( 2, "add_outlines" );
	my %params   = @_;
	my $outlines = $self->reserve("Outlines");

	my ( $First, $Last );
	my @list = $self->{'outlines'}->list;
	my $i    = -1;
	for my $outline (@list) {
		$i++;
		my $name = $outline->{'name'};
		$First = $outline->{'id'} unless defined $First;
		$Last = $outline->{'id'};
		my $content = { 'Title' => $self->string( $outline->{'Title'} ) };
		if ( defined $outline->{'Kids'} && scalar @{ $outline->{'Kids'} } ) {
			my $t = $outline->{'Kids'};
			$$content{'First'} = $self->indirect_ref( @{ $$t[0]->{'id'} } );
			$$content{'Last'}  = $self->indirect_ref( @{ $$t[$#$t]->{'id'} } );
		}
		my $brothers = $outline->{'Parent'}->{'Kids'};
		my $j        = -1;
		for my $brother (@$brothers) {
			$j++;
			last if $brother == $outline;
		}
		$$content{'Next'} = $self->indirect_ref( @{ $$brothers[ $j + 1 ]->{'id'} } )
		  if $j < $#$brothers;
		$$content{'Prev'} = $self->indirect_ref( @{ $$brothers[ $j - 1 ]->{'id'} } )
		  if $j;
		$outline->{'Parent'}->{'id'} = $outlines
		  unless defined $outline->{'Parent'}->{'id'};
		$$content{'Parent'} = $self->indirect_ref( @{ $outline->{'Parent'}->{'id'} } );
		$$content{'Dest'} =
		  $self->array( $self->indirect_ref( @{ $outline->{'Dest'}->{'id'} } ),
						$self->name('Fit'), $self->null, $self->null, $self->null );
		my $count = $outline->count;
		$$content{'Count'} = $self->number($count) if $count;
		my $t = $self->add_object( $self->indirect_obj( $self->dictionary(%$content), $name ) );
		$self->cr;
	}

	# Type (required)
	my $content = { 'Type' => $self->name('Outlines') };

	# Count
	my $count = $self->{'outlines'}->count;
	$$content{'Count'} = $self->number($count) if $count;
	$$content{'First'} = $self->indirect_ref(@$First);
	$$content{'Last'}  = $self->indirect_ref(@$Last);
	$self->add_object( $self->indirect_obj( $self->dictionary(%$content) ) );
	$self->cr;
}

sub new_outline
{
	my $self = shift;

	my %params = @_;
	unless ( defined $self->{'outlines'} ) {
		$self->{'outlines'}             = PDF::Create::Outline->new();
		$self->{'outlines'}->{'pdf'}    = $self;                        # circular reference
		weaken $self->{'outlines'}->{'pdf'};
		$self->{'outlines'}->{'Status'} = 'opened';
	}
	my $parent = $params{'Parent'} || $self->{'outlines'};
	my $name = "Outline " . ++$self->{'outline_count'};
	$params{'Destination'} = $self->{'current_page'}
	  unless defined $params{'Destination'};
	my $outline = $parent->add( $self->reserve( $name, "Outline" ), $name, %params );
	$outline;
}

sub get_page_size
{
	my $self = shift;
	my $name = lc(shift);

	my %pagesizes = ( 'A0'         => [ 0, 0, 2380, 3368 ],
					  'A1'         => [ 0, 0, 1684, 2380 ],
					  'A2'         => [ 0, 0, 1190, 1684 ],
					  'A3'         => [ 0, 0, 842,  1190 ],
					  'A4'         => [ 0, 0, 595,  842 ],
					  'A4L'        => [ 0, 0, 842,  595 ],
					  'A5'         => [ 0, 0, 421,  595 ],
					  'A6'         => [ 0, 0, 297,  421 ],
					  'LETTER'     => [ 0, 0, 612,  792 ],
					  'BROADSHEET' => [ 0, 0, 1296, 1584 ],
					  'LEDGER'     => [ 0, 0, 1224, 792 ],
					  'TABLOID'    => [ 0, 0, 792,  1224 ],
					  'LEGAL'      => [ 0, 0, 612,  1008 ],
					  'EXECUTIVE'  => [ 0, 0, 522,  756 ],
					  '36X36'      => [ 0, 0, 2592, 2592 ],
					);

	if ( !$pagesizes{ uc($name) } ) {
		$name = "A4";
	}

	$pagesizes{ uc($name) };
}

sub new_page
{
	my $self = shift;

	my %params = @_;
	my $parent = $params{'Parent'} || $self->{'pages'};
	my $name   = "Page " . ++$self->{'page_count'};
	my $page   = $parent->add( $self->reserve( $name, "Page" ), $name );
	$page->{'resources'} = $params{'Resources'} if defined $params{'Resources'};
	$page->{'mediabox'}  = $params{'MediaBox'}  if defined $params{'MediaBox'};
	$page->{'cropbox'}   = $params{'CropBox'}   if defined $params{'CropBox'};
	$page->{'artbox'}    = $params{'ArtBox'}    if defined $params{'ArtBox'};
	$page->{'trimbox'}   = $params{'TrimBox'}   if defined $params{'TrimBox'};
	$page->{'bleedbox'}  = $params{'BleedBox'}  if defined $params{'BleedBox'};
	$page->{'rotate'}    = $params{'Rotate'}    if defined $params{'Rotate'};

	$self->{'current_page'} = $page;

	$page;
}

sub add_pages
{
	my $self = shift;

	debug( 2, "add_pages():" );

	# $self->page_stream;
	my %params = @_;

	# Type (required)
	my $content = { 'Type' => $self->name('Pages') };

	# Kids (required)
	my $t = $self->{'pages'}->kids;
	confess "Error: document MUST contains at least one page. Abort."
	  unless scalar @$t;
	my $kids = [];
	map { push @$kids, $self->indirect_ref(@$_) } @$t;
	$$content{'Kids'}  = $self->array(@$kids);
	$$content{'Count'} = $self->number( $self->{'pages'}->count );
	$self->add_object( $self->indirect_obj( $self->dictionary(%$content) ) );
	$self->cr;

	for my $font ( sort keys %{ $self->{'fonts'} } ) {
		debug( 2, "add_pages(): font: $font" );
		$self->{'fontobj'}{$font} = $self->reserve('Font');
		$self->add_object( $self->indirect_obj( $self->dictionary( %{ $self->{'fonts'}{$font} } ), 'Font' ) );
		$self->cr;
	}

	for my $xobject ( sort keys %{ $self->{'xobjects'} } ) {
		debug( 2, "add_pages(): xobject: $xobject" );
		$self->{'xobj'}{$xobject} = $self->reserve('XObject');
		$self->add_object( $self->indirect_obj( $self->stream( %{ $self->{'xobjects'}{$xobject} } ), 'XObject' ) );
		$self->cr;

		if ( defined $self->{'reservations'}{"ImageColorSpace$xobject"} ) {
			$self->add_object(
				 $self->indirect_obj( $self->stream( %{ $self->{'xobjects_colorspace'}{$xobject} } ), "ImageColorSpace$xobject" ) );
			$self->cr;
		}
	}

	for my $annotation ( sort keys %{ $self->{'annotations'} } ) {
		$self->{'annot'}{$annotation}{'object_info'} = $self->reserve('Annotation');
		$self->add_object( $self->indirect_obj( $self->dictionary( %{ $self->{'annotations'}{$annotation} } ), 'Annotation' ) );
		$self->cr;
	}

	for my $page ( $self->{'pages'}->list ) {
		my $name = $page->{'name'};
		debug( 2, "add_pages: page: $name" );
		my $type = 'Page' . ( defined $page->{'Kids'} && scalar @{ $page->{'Kids'} } ? 's' : '' );

		# Type (required)
		my $content = { 'Type' => $self->name($type) };

		# Resources (required, may be inherited). See page 195.
		my $resources = {};
		for my $k ( keys %{ $page->{'resources'} } ) {
			my $v = $page->{'resources'}{$k};
			( $k eq 'ProcSet' ) && do {
				my $l = [];
				if ( ref($v) eq 'ARRAY' ) {
					map { push @$l, $self->name($_) } @$v;
				} else {
					push @$l, $self->name($v);
				}
				$$resources{'ProcSet'} = $self->array(@$l);
			  }
			  || ( $k eq 'fonts' ) && do {
				my $l = {};
				map { $$l{"F$_"} = $self->indirect_ref( @{ $self->{'fontobj'}{$_} } ); } keys %{ $page->{'resources'}{'fonts'} };
				$$resources{'Font'} = $self->dictionary(%$l);
			  }
			  || ( $k eq 'xobjects' ) && do {
				my $l = {};
				map { $$l{"Image$_"} = $self->indirect_ref( @{ $self->{'xobj'}{$_} } ); }
				  keys %{ $page->{'resources'}{'xobjects'} };
				$$resources{'XObject'} = $self->dictionary(%$l);
			  };
		}
		if ( defined( $$resources{'Annotation'} ) ) {
			my $r = $self->add_object( $self->indirect_obj( $self->dictionary(%$resources) ) );
			$self->cr;
			$$content{'Resources'} = [ 'ref', [ $$r[0], $$r[1] ] ];
		}
		if ( defined( $$resources{'XObject'} ) ) {
			my $r = $self->add_object( $self->indirect_obj( $self->dictionary(%$resources) ) );
			$self->cr;
			$$content{'Resources'} = [ 'ref', [ $$r[0], $$r[1] ] ];
		} else {
			$$content{'Resources'} = $self->dictionary(%$resources)
			  if scalar keys %$resources;
		}
		for my $K ( 'MediaBox', 'CropBox', 'ArtBox', 'TrimBox', 'BleedBox' ) {
			my $k = lc $K;
			if ( defined $page->{$k} ) {
				my $l = [];
				map { push @$l, $self->number($_) } @{ $page->{$k} };
				$$content{$K} = $self->array(@$l);
			}
		}
		$$content{'Rotate'} = $self->number( $page->{'rotate'} ) if defined $page->{'rotate'};
		if ( $type eq 'Page' ) {
			$$content{'Parent'} = $self->indirect_ref( @{ $page->{'Parent'}{'id'} } );

			# Content
			if ( defined $page->{'contents'} ) {
				my $contents = [];
				map { push @$contents, $self->indirect_ref(@$_); } @{ $page->{'contents'} };
				$$content{'Contents'} = $self->array(@$contents);
			}

			#
			# Annotations added here by Gary Lieberman
			#
			# Tell the /Page object that annotations need to be drawn.
			#
			if ( defined $self->{'annot'} ) {
				my $Annots    = '[ ';
				my $is_annots = 0;
				foreach my $annot_number ( keys %{ $self->{'annot'} } ) {
					next if ( $self->{'annot'}{$annot_number}{'page_name'} ne $name );
					$is_annots = 1;
					debug( 2,
						   sprintf "annotation number:  $annot_number, page name: $self->{'annot'}{$annot_number}{'page_name'}" );
					my $object_number     = $self->{'annot'}{$annot_number}{'object_info'}[0];
					my $generation_number = $self->{'annot'}{$annot_number}{'object_info'}[1];
					debug( 2, sprintf "object_number: $object_number, generation_number: $generation_number" );
					$Annots .= sprintf( "%s %s R ", $object_number, $generation_number );
				}
				$$content{'Annots'} = $self->verbatim( $Annots . ']' ) if ($is_annots);
			}

			#
			# Annotations code ends here
			#
		} else {
			my $kids = [];
			map { push @$kids, $self->indirect_ref(@$_) } @{ $page->kids };
			$$content{'Kids'}   = $self->array(@$kids);
			$$content{'Parent'} = $self->indirect_ref( @{ $page->{'Parent'}{'id'} } )
			  if defined $page->{'Parent'};
			$$content{'Count'} = $self->number( $page->count );
		}
		$self->add_object( $self->indirect_obj( $self->dictionary(%$content), $name ) );
		$self->cr;
	}
}

sub add_crossrefsection
{
	my $self = shift;

	debug( 2, "add_crossrefsection():" );

	# <cross-reference section> ::=
	#   xref
	#   <cross-reference subsection>+
	$self->{'crossrefstartpoint'} = $self->position;
	$self->add('xref');
	$self->cr;
	confess "Fatal error: should contains at least one cross reference subsection."
	  unless defined $self->{'crossrefsubsection'};
	for my $subsection ( sort keys %{ $self->{'crossrefsubsection'} } ) {
		$self->add_crossrefsubsection($subsection);
	}
}

sub add_crossrefsubsection
{
	my $self       = shift;
	my $subsection = shift;

	debug( 2, "add_crossrefsubsection():" );

	# <cross-reference subsection> ::=
	#   <object number of first entry in subsection>
	#   <number of entries in subsection>
	#   <cross-reference entry>+
	#
	# <cross-reference entry> ::= <in-use entry> | <free entry>
	#
	# <in-use entry> ::= <byte offset> <generation number> n <end-of-line>
	#
	# <end-of-line> ::= <space> <carriage return>
	#   | <space> <linefeed>
	#   | <carriage return> <linefeed>
	#
	# <free entry> ::=
	#   <object number of next free object>
	#   <generation number> f <end-of-line>

	$self->add( 0, ' ', 1 + scalar @{ $self->{'crossrefsubsection'}{$subsection} } );
	$self->cr;
	$self->add( sprintf "%010d %05d %s ", 0, 65535, 'f' );
	$self->cr;
	for my $entry ( sort { $$a[0] <=> $$b[0] } @{ $self->{'crossrefsubsection'}{$subsection} } ) {
		$self->add( sprintf "%010d %05d %s ", $$entry[1], $subsection, $$entry[2] ? 'n' : 'f' );

		# printf "%010d %010x %05d n\n", $$entry[1], $$entry[1], $subsection;
		$self->cr;
	}

}

sub add_trailer
{
	my $self = shift;
	debug( 2, "add_trailer():" );

	# <trailer> ::= trailer
	#   <<
	#   <trailer key value pair>+
	#   >>
	#   startxref
	#   <cross-reference table start address>
	#   %%EOF

	my @keys = ( 'Size',      # integer (required)
				 'Prev',      # integer (req only if more than one cross-ref section)
				 'Root',      # dictionary (required)
				 'Info',      # dictionary (optional)
				 'ID',        # array (optional) (PDF 1.1)
				 'Encrypt'    # dictionary (req if encrypted) (PDF 1.1)
			   );

	# TODO: should check for required fields
	$self->add('trailer');
	$self->cr;
	$self->add('<<');
	$self->cr;
	$self->{'trailer'}{'Size'} = 1;
	map { $self->{'trailer'}{'Size'} += scalar @{ $self->{'crossrefsubsection'}{$_} } } keys %{ $self->{'crossrefsubsection'} };
	$self->{'trailer'}{'Root'} = &encode( @{ $self->indirect_ref( @{ $self->{'catalog'} } ) } );
	$self->{'trailer'}{'Info'} = &encode( @{ $self->indirect_ref( @{ $self->{'info'} } ) } )
	  if defined $self->{'info'};

	for my $k (@keys) {
		next unless defined $self->{'trailer'}{$k};
		$self->add( "/$k ",
					ref $self->{'trailer'}{$k} eq 'ARRAY' ? join( ' ', @{ $self->{'trailer'}{$k} } ) : $self->{'trailer'}{$k} );
		$self->cr;
	}
	$self->add('>>');
	$self->cr;
	$self->add('startxref');
	$self->cr;
	$self->add( $self->{'crossrefstartpoint'} );
	$self->cr;
	$self->add('%%EOF');
	$self->cr;
}

sub cr
{
	my $self = shift;
	debug( 3, "cr():" );
	$self->add( &encode('cr') );
}

sub page_stream
{
	my $self = shift;
	my $page = shift;

	debug( 2, "page_stream():" );

	if ( defined $self->{'reservations'}{'stream_length'} ) {
		## If it is the same page, use the same stream.
		$self->cr, return
		  if defined $page
			  && defined $self->{'stream_page'}
			  && $page == $self->{'current_page'}
			  && $self->{'stream_page'} == $page;

		# Remember the position
		my $len = $self->position - $self->{'stream_pos'} + 1;

		# Close the stream and the object
		$self->cr;
		$self->add('endstream');
		$self->cr;
		$self->add('endobj');
		$self->cr;
		$self->cr;

		# Add the length
		$self->add_object( $self->indirect_obj( $self->number($len), 'stream_length' ) );
		$self->cr;
	}

	# open a new stream if needed
	if ( defined $page ) {

		# get an object id for the stream
		my $obj = $self->reserve('stream');

		# release it
		delete $self->{'reservations'}{'stream'};

		# get another one for the length of this stream
		my $stream_length = $self->reserve('stream_length');
		push @$stream_length, 'R';
		push @{ $page->{'contents'} }, $obj;

		# write the beginning of the object
		push @{ $self->{'crossrefsubsection'}{ $$obj[1] } }, [ $$obj[0], $self->position, 1 ];
		$self->add("$$obj[0] $$obj[1] obj");
		$self->cr;
		$self->add('<<');
		$self->cr;
		$self->add( '/Length ', join( ' ', @$stream_length ) );
		$self->cr;
		$self->add('>>');
		$self->cr;
		$self->add('stream');
		$self->cr;
		$self->{'stream_pos'}  = $self->position;
		$self->{'stream_page'} = $page;             # $self->{'current_page'};
	}
}

sub font
{
	my $self = shift;

	my %params = @_;
	my $num    = 1 + scalar keys %{ $self->{'fonts'} };
	$self->{'fonts'}{$num} = { 'Subtype'  => $self->name( $params{'Subtype'}  || 'Type1' ),
							   'Encoding' => $self->name( $params{'Encoding'} || 'WinAnsiEncoding' ),
							   'BaseFont' => $self->name( $params{'BaseFont'} || 'Helvetica' ),
							   'Name'     => $self->name("F$num"),
							   'Type'     => $self->name("Font"),
							 };
	$num;
}

#
# Add an annotation object
#
# for the time beeing we only do the 'Link' - 'URI' kind
#
sub annotation
{
	my $self   = shift;
	my %params = @_;

	debug( 2, "annotation(): Subtype=$params{'Subtype'}" );

	if ( $params{'Subtype'} eq 'Link' ) {
		confess "Must specify 'URI' for Link" unless defined $params{'URI'};
		confess "Must specify 'x' for Link"   unless defined $params{'x'};
		confess "Must specify 'y' for Link"   unless defined $params{'y'};
		confess "Must specify 'w' for Link"   unless defined $params{'w'};
		confess "Must specify 'h' for Link"   unless defined $params{'h'};

		my $num = 1 + scalar keys %{ $self->{'annotations'} };

		my $action = { 'Type' => $self->name('Action'),
					   'S'    => $self->name('URI'),
					   'URI'  => $self->string( $params{'URI'} ),
					 };
		my $x2 = $params{'x'} + $params{'w'};
		my $y2 = $params{'y'} + $params{'h'};

		$self->{'annotations'}{$num} = { 'Subtype' => $self->name('Link'),
										 'Rect' => $self->verbatim( sprintf "[%f %f %f %f]", $params{'x'}, $params{'y'}, $x2, $y2 ),
										 'A'    => $self->dictionary(%$action),
									   };

		if ( defined $params{'Border'} ) {
			$self->{'annotations'}{$num}{'Border'} =
			  $self->verbatim( sprintf "[%f %f %f]", $params{'Border'}[0], $params{'Border'}[1], $params{'Border'}[2] );
		}
		$self->{'annot'}{$num}{'page_name'} = "Page " . $self->{'page_count'};
		debug( 2, "annotation(): annotation number: $num, page name: $self->{'annot'}{$num}{'page_name'}" );
		1;
	} else {
		confess "Only Annotations with Subtype 'Link' are supported for now\n";
	}
}

sub image
{
	my $self     = shift;
	my $filename = shift;

	my $num = 1 + scalar keys %{ $self->{'xobjects'} };
	my $image;

	my $colorspace;

	my @a;

	if ( $filename =~ /\.gif$/i ) {
		$self->{'images'}{$num} = PDF::Image::GIF->new();
	} elsif ( $filename =~ /\.jpg$/i || $filename =~ /\.jpeg$/i ) {
		$self->{'images'}{$num} = PDF::Image::JPEG->new();
	}

	$image = $self->{'images'}{$num};
	if ( !$image->Open($filename) ) {
		print $image->{error} . "\n";
		return 0;
	}

	$self->{'xobjects'}{$num} = { 'Subtype'          => $self->name('Image'),
								  'Name'             => $self->name("Image$num"),
								  'Type'             => $self->name('XObject'),
								  'Width'            => $self->number( $image->{width} ),
								  'Height'           => $self->number( $image->{height} ),
								  'BitsPerComponent' => $self->number( $image->{bpc} ),
								  'Data'             => $image->ReadData(),
								  'Length'           => $self->number( $image->{imagesize} ),
								};

	#indexed colorspace ?
	if ( $image->{colorspacesize} ) {
		$colorspace = $self->reserve("ImageColorSpace$num");

		$self->{'xobjects_colorspace'}{$num} = { 'Data'   => $image->{colorspacedata},
												 'Length' => $self->number( $image->{colorspacesize} ),
											   };

		$self->{'xobjects'}{$num}->{'ColorSpace'} = $self->array( $self->name('Indexed'), $self->name( $image->{colorspace} ),
																  $self->number(255),     $self->indirect_ref(@$colorspace) );
	} else {
		$self->{'xobjects'}{$num}->{'ColorSpace'} = $self->array( $self->name( $image->{colorspace} ) );
	}

	#set Filter
	$#a = -1;
	foreach my $s ( @{ $image->{filter} } ) {
		push @a, $self->name($s);
	}
	if ( $#a >= 0 ) {
		$self->{'xobjects'}{$num}->{'Filter'} = $self->array(@a);
	}

	#set additional DecodeParms
	$#a = -1;
	foreach my $s ( keys %{ $image->{decodeparms} } ) {
		push @a, $s;
		push @a, $self->number( $image->{decodeparms}{$s} );
	}
	$self->{'xobjects'}{$num}->{'DecodeParms'} = $self->array( $self->dictionary(@a) );

	#transparent ?
	if ( $image->{transparent} ) {
		$self->{'xobjects'}{$num}->{'Mask'} = $self->array( $self->number( $image->{mask} ), $self->number( $image->{mask} ) );
	}

	{ 'num' => $num, 'width' => $image->{width}, 'height' => $image->{height} };
}

sub uses_font
{
	my $self = shift;
	my $page = shift;
	my $font = shift;

	$page->{'resources'}{'fonts'}{$font} = 1;
	$page->{'resources'}{'ProcSet'} = [ 'PDF', 'Text' ];
	$self->{'fontobj'}{$font} = 1;
}

sub uses_xobject
{
	my $self    = shift;
	my $page    = shift;
	my $xobject = shift;

	$page->{'resources'}{'xobjects'}{$xobject} = 1;
	$page->{'resources'}{'ProcSet'} = [ 'PDF', 'Text' ];
	$self->{'xobj'}{$xobject} = 1;
}

sub get_data
{
	shift->{'data'};
}

1;

__END__

=encoding utf8

=head1 NAME

PDF::Create - create PDF files

=head1 SYNOPSIS

C<PDF::Create> provides an easy module to create PDF output from your
perl programs. It is designed to be easy to use and simple to install and
maintain. It provides a couple of subroutines to
handle text, fonts, images and drawing primitives. Simple documents are
easy to create with the supplied routines. 

In addition to be reasonable simple C<PDF::Create> is written in pure Perl
and has no external dependencies (libraries, other modules, etc.). It should
run on any platform where perl is available. 

For complex stuff some understanding of the underlying Postscript/PDF format 
is necessary. In this case it might be better go with the more complete
L<PDF::API2> modules to gain more features at the expense of a steeper learning
curve. 

Example PDF creation with C<PDF::Create>: 

  use PDF::Create;
  # initialize PDF
  my $pdf = PDF::Create->new('filename'     => 'mypdf.pdf',
			                'Author'       => 'John Doe',
			                'Title'        => 'Sample PDF',
			                'CreationDate' => [ localtime ], );
			                
  # add a A4 sized page
  my $a4 = $pdf->new_page('MediaBox' => $pdf->get_page_size('A4'));

  # Add a page which inherits its attributes from $a4
  my $page = $a4->new_page;

  # Prepare a font
  my $f1 = $pdf->font('BaseFont' => 'Helvetica');

  # Prepare a Table of Content
  my $toc = $pdf->new_outline('Title' => 'Title Page', 'Destination' => $page);

  # Write some text
  $page->stringc($f1, 40, 306, 426, "PDF::Create");
  $page->stringc($f1, 20, 306, 396, "version $PDF::Create::VERSION");
  $page->stringc($f1, 20, 306, 300, 'by John Doe <john.doe@example.com>');

  # Add another page
  my $page2 = $a4->new_page;
  
  # Draw some lines
  $page2->line(0, 0, 612, 792);
  $page2->line(0, 792, 612, 0);

  $toc->new_outline('Title' => 'Second Page', 'Destination' => $page2);

  # Close the file and write the PDF
  $pdf->close;

=head1 DESCRIPTION

PDF::Create allows you to create PDF documents using a number of
primitives. The result is as a PDF file or stream.

PDF stands for Portable Document Format.

Documents can have several pages, a table of content, an information
section and many other PDF elements.

=head1 Methods

=over 5

=item * new([parameters])

Create a new pdf structure for your PDF.

Example:

  my $pdf = PDF::Create->new('filename'     => 'mypdf.pdf',
                            'Version'      => 1.2,
                            'PageMode'     => 'UseOutlines',
                            'Author'       => 'John Doe',
                            'Title'        => 'My title',
			                'CreationDate' => [ localtime ],
                           );

C<new> returns an object handle used to add more stuff to the PDF. 

=over 10

=item 'filename'

destination file that will contain the resulting PDF or '-' for stdout. 

=item 'fh'

an already opened filehandle that will contain the resulting PDF.

=item 'Version'

PDF Version to claim, can be 1.0 to 1.3 (default: 1.2)

=item 'PageMode'

how the document should appear when opened. 

Allowed values are

- 'UseNone' Open document with neither outline nor thumbnails visible. This is the default value.

- 'UseOutlines' Open document with outline visible.

- 'UseThumbs' Open document with thumbnails visible.

- 'FullScreen' Open document in full-screen mode. In full-screen mode, 
there is no menu bar, window controls, nor any other window present.

=item 'Author'

the name of the person who created this document

=item 'Creator' 

If the document was converted into a PDF document
  from another form, this is the name of the application that
  created the document.

- 'Title' the title of the document

- 'Subject' the subject of the document

- 'Keywords' keywords associated with the document

- 'CreationDate' the date the document was created. This is passed
  as an anonymous array in the same format as localtime returns.
  (ie. a struct tm).

=back

If you are writing a CGI you can send your PDF on the fly to stdout 
or directly to the browser using '-' as filename.

CGI Example:

  use CGI; use PDF::Create;
  print CGI::header( -type => 'application/x-pdf', -attachment => 'sample.pdf' );
  my $pdf = PDF::Create->new('filename'     => '-', # Stdout
                            'Author'       => 'John Doe',
                            'Title'        => 'My title',
			                'CreationDate' => [ localtime ],
                           );

=item * close()

You must call close() after you have added all the contents as
most of the real work building the PDF is performed there. If
omit calling close you get no PDF output !

=item * get_data()

If you didn't ask the $pdf object to write its output to a file, you
can pick up the pdf code by calling this method. It returns a big string.
You need to call C<close> first, mind.

=item * add_comment([string])

Add a comment to the document. The string will show up in
the PDF as postscript-stype comment:

    % this is a postscript comment

=item * new_outline([parameters])

Add an outline to the document using the given parameters.
Return the newly created outline.

Parameters can be:

- 'Title' the title of the outline. Mandatory.

- 'Destination' the Destination of this outline item. In this version, it is
only possible to give a page as destination. The default destination is
the current page.

- 'Parent' the parent of this outline in the outlines tree. This is an
outline object. This way you represent the tree of your outlines.

Example:

  my $outline = $pdf->new_outline('Title' => 'Item 1');
  $pdf->new_outline('Title' => 'Item 1.1', 'Parent' => $outline);
  $pdf->new_outline('Title' => 'Item 1.2', 'Parent' => $outline);
  $pdf->new_outline('Title' => 'Item 2');


=item * new_page([parameters])

Add a page to the document using the given parameters. C<new_page> must
be called first to initialize a root page, used as model for further pages.

Example:

  my $a4 = $pdf->new_page( 'MediaBox' => $pdf->get_page_size('A4') );
  my $page1 = $a4->new_page;
  $page1->string($f1, 20, 306, 396, "some text on page 1");
  my $page2 = $a4->new_page;
  $page2->string($f1, 20, 306, 396, "some text on page 2");

Returns a handle to the newly created page.

Parameters can be:

- 'Parent' the parent of this page in the pages tree. This is a
page object.

- 'Resources' Resources required by this page.

- 'MediaBox' Rectangle specifying the natural size of the page,
for example the dimensions of an A4 sheet of paper. The coordinates
are measured in default user space units. It must be the reference
of a 4 values array. You can use C<get_page_size> to get the size of
standard paper sizes.
  C<get_page_size> knows about A0-A6, A4L (landscape), Letter, Legal,
Broadsheet, Ledger, Tabloid, Executive and 36x36.

- 'CropBox' Rectangle specifying the default clipping region for
the page when displayed or printed. The default is the value of
the MediaBox.

- 'ArtBox' Rectangle specifying an area of the page to be used when
placing PDF content into another application. The default is the value
of the CropBox. [PDF 1.3]

- 'TrimBox' Rectangle specifying the intended finished size
of the page (for example, the dimensions of an A4 sheet of paper).
In some cases, the MediaBox will be a larger rectangle, which includes
printing instructions, cut marks, or other content. The default is
the value of the CropBox. [PDF 1.3].

- 'BleedBox' Rectangle specifying the region to which all page
content should be clipped if the page is being output in a production
environment. In such environments, a bleed area is desired, to
accommodate physical limitations of cutting, folding, and trimming
equipment. The actual printed page may include printer's marks that
fall outside the bleed box. The default is the value of the CropBox.
[PDF 1.3]

- 'Rotate' Specifies the number of degrees the page should be rotated
clockwise when it is displayed or printed. This value must be zero
(the default) or a multiple of 90. The entire page, including contents
is rotated.

=item * get_page_size(<pagesize>)

Returns the size of standard paper sizes to use for MediaBox-parameter
of C<new_page>. C<get_page_size> has one required parameter to 
specify the paper name. Possible values are a0-a6, letter, broadsheet,
ledger, tabloid, legal, executive and 36x36. Default is a4.

  my $root = $pdf->new_page( 'MediaBox' => $pdf->get_page_size('A4') );

=item * font([parameters])

Prepare a font using the given arguments. This font will be added
to the document only if it is used at least once before the close method
is called.

  my $f1 = $pdf->font('BaseFont' => 'Helvetica');


Parameters can be:

- 'Subtype' Type of font. PDF defines some types of fonts. It must be
one of the predefined type Type1, Type3, TrueType or Type0.

In this version, only Type1 is supported. This is the default value.

- 'Encoding' Specifies the encoding from which the new encoding differs.
It must be one of the predefined encodings MacRomanEncoding,
MacExpertEncoding or WinAnsiEncoding.

In this version, only WinAnsiEncoding is supported. This is the default
value.

- 'BaseFont' The PostScript name of the font. It can be one of the following
base fonts: Courier, Courier-Bold, Courier-BoldOblique, Courier-Oblique,
Helvetica, Helvetica-Bold, Helvetica-BoldOblique, Helvetica-Oblique,
Times-Roman, Times-Bold, Times-Italic or Times-BoldItalic.

The Symbol or ZapfDingbats fonts are not supported in this version.

The default font is Helvetica.

=item * image(<filename>)

Prepare an XObject (image) using the given arguments. This image will be added
to the document if it is referenced at least once before the close method
is called. In this version GIF, interlaced GIF and JPEG is supported. 
Usage of interlaced GIFs are slower because they are decompressed, modified 
and compressed again.
The gif support is limited to images with a LZW minimum code size of 8. Small
images with few colors can have a smaller minimum code size and will not work.

Parameters: 

- filename: file name of image (required).

=back

=head2 URI links

URI links have two components, the text or graphics object and the area
where the mouseclick should occur.

For the object to be clicked on you'll use standard text of drawing methods.

To define the click-sensitive area and the destination URI you use the
C<annotation()> method.  

=over 5

=item * annotation([parameters])

Define an annotation. This is a sensitive area in the PDF document where
text annotations are shown or links launched. C<PDF::Create> only supports
URI links at this time. 

Example:

    # Draw a string and undeline it to show it is a link 
    $pdf->string($f1,10,450,200,'http://www.cpan.org')
    $l=$pdf->string_underline($f1,10,450,200,'http://www.cpan.org')
    # Create the hot area with the link to open on click 
    $pdf->annotation(
             Subtype => 'Link',
             URI     => 'http://www.cpan.org',
             x       => 450,
             y       => 200,
             w       => $l,
             h       => 15,
             Border  => [0,0,0]
    );

The point (x, y) is the bottom left corner of the rectangle containing hotspot 
rectangle, (w, h) are the width and height of the hotspot rectangle.
The Border describes the thickness of the border surrounding the rectangle hotspot. 

The function C<string_undeline> returns the width of the string,
this can be used directly for the width of the hotspot rectangle.

=back

=head2 Page methods

Page methods are used to draw stuff on a page. Although these
methods are packaged in the separate module C<PDF::Create::Page>
you should call them always through the $page handler you get from
the C<new_page()> method.

There are internal changes on the horizon who will break code
calling methods differently !  

=over 5

=item * new_page()

Add a sub-page to the current page.

See C<new_page> above

=item * string(font, size, x, y, text [,alignment] )

Add text to the current page using the font object at the given size and
position. The point (x, y) is the bottom left corner of the rectangle
containing the text.

The optional alignment can be 'r' for right-alignment and 'c' for centered.

Example :

    my $f1 = $pdf->font('Subtype'  => 'Type1',
 	   	        'Encoding' => 'WinAnsiEncoding',
 		        'BaseFont' => 'Helvetica');
    $page->string($f1, 20, 306, 396, "some text");

=item * string_underline(font, size, x, y, text [,alignment] )

Draw a line for underlining. The parameters are the same as for the string
function, but only the line is drawn. To draw an underlined string you
must call both, string and string_underline. 

Example :

    $page->string($f1, 20, 306, 396, "some underlined text");
    $page->string_underline($f1, 20, 306, 396, "some underlined text");

To change the color of your text use the C<setrgbcolor> function.

C<string_underline> returns the length of the string. So its return
value can be used directly for the bounding box of an annotation.

=item * stringl(font size x y text)

Same as C<string>.

=item * stringr(font size x y text)

Same as C<string> but right aligned (alignment 'r').

=item * stringc(font size x y text)

Same as C<string> but centered (alignment 'c').

=item * printnl(text font size x y)

Similar to C<string> but parses the string for newline and prints each part
on a separate line. Lines spacing is the same as the font-size. Returns the
number of lines.

Note the different parameter sequence. The first call should specify all
parameters, font is the absolute minimum, a warning will be given for the
missing y position and 800 will be assumed. All subsequent invocations can
omit all but the string parameters.

Attention: There is no provision for changing pages. If you run out of
space on the current page this will draw the string(s) outside the page and
it will be invisble !

=item * string_width(font,text)

Return the size of the text using the given font in default user space units.
This does not contain the size of the font yet, to get the length you must
multiply by the font size. 

=item * line(x1, y1, x2, y2)

Draw a line between (x1, y1) and (x2, y2).

=item * set_width(w)

Set the width of subsequent lines to C<w> points.

=item * setrgbcolor(r, g, b)

=item * setrgbcolorstroke(r, g, b)

Set the color of the subsequent drawing operations.

Valid r, g, and b values are each between 0.0 and 1.0, inclusive.

Each color ranges from 0.0 to 1.0, that is, darkest red (0.0) to
brightest red (1.0).  The same holds for green and blue.  These three
colors mix additively to produce the colors between black (0.0, 0.0,
0.0) and white (1.0, 1.0, 1.0).

PDF distinguishes between the stroke and fill operations
and provides separate color settings for each. 

- C<setrgbcolor()> sets the fill colors used for normal text or filled objects.

- C<setrgbcolorstroke()> sets the stroke color used for lines.

=item * moveto(x, y)

Moves the current point to (x, y), omitting any connecting line segment.

=item * lineto(x, y)

Appends a straight line segment from the current point to (x, y).
The current point is then set to (x, y).

=item * curveto(x1, y1, x2, y2, x3, y3)

Appends a Bezier curve to the path. The curve extends from the current
point to (x3 ,y3) using (x1 ,y1) and (x2 ,y2) as the Bezier control
points. The new current point is the set to (x3 ,y3).

=item * rectangle(x, y, w, h)

Draws a rectangle.

=item * closepath()

Closes the current subpath by appending a straight line segment
from the current point to the starting point of the path.

=item * newpath()

Ends the current path. The next drawing operation will start a new path.

=item * stroke()

Strokes (draws) the path.

=item * closestroke()

Closes and strokes the path.

=item * fill()

Fills the path using the non-zero winding number rule.

=item * fill2()

Fills the path using the even-odd rule

Example drawing: 

  # draw a filled triangle
  $page->newpath;
  $page->setrgbcolor 0.1 0.3 0.8;
  $page->moveto 100 100;
  $page->lineto 260 300;
  $page->lineto 300 100;
  $page->lineto 100 100;
  $page->fill;


=item * image( image_id, xpos, ypos, xalign, yalign, xscale, yscale, rotate, xskew, yskew)

Inserts an image.

Parameters can be:

- image: Image id returned by PDF::image (required).

- xpos, ypos: Position of image (required).

- xalign, yalign: Alignment of image. 0 is left/bottom, 1 is centered and 2 is right, top.

- xscale, yscale: Scaling of image. 1.0 is original size.

- rotate: Rotation of image. 0 is no rotation, 2*pi is 360° rotation.

- xskew, yskew: Skew of image.

Example jpeg image:

  # include a jpeg image with scaling to 20% size
  my $jpg = $pdf->image("image.jpg");
  $page->image( 'image' => $jpg, 'xscale' => 0.2, 'yscale' => 0.2, 'xpos' => 350, 'ypos' => 400 );

=back

=head1 Limitations

C<PDF::Create> comes with a couple of limitations or known caveats:

=over 5

=item PDF Size / Memory

C<PDF::Create> assembles the entire PDF in memory if you create very
large documents on a machine with a small amount of memory your program
can fail because it runs out of memory.

=item Small GIF images

Some gif images get created with a minimal lzw code size of less than 8.
C<PDF::Create> can not decode those and they must be converted.   

=back

=head1 Support

I support C<PDF::Create> in my spare time between work and family, so
the amount of work I put in is limited.

If you experience a problem make sure you are at the latest version first
many things have already been fixed.

Please register bug at the CPAN bug tracking system at L<http://rt.cpan.org>
or send email to C<bug-PDF-Create [at] rt.cpan.org>

Be sure to include the following information:

- PDF::Create Version you are running

- Perl version (perl -v)

- Operating System vendor and version

- Details about your operating environment that might be related to the issue being described

- Exact cut and pasted error or warning messages

- The shortest, clearest code you can manage to write which reproduces the bug described.

I appreciate patches against the latest released version of C<PDF::Create> which fix the bug.

B<Feature request> can be submitted like bugs. If you provide patch for a feature which
does not go against the C<PDF::Create> philosophy (keep it simple) then you have a good chance
for it to be accepted.

=head1 SEE ALSO

Adobe PDF reference L<http://www.adobe.com/devnet/pdf/pdf_reference.html>

My git repository for C<PDF::Create> L<http://github.com/markusb/pdf-create>

=head2 Other PDF procesing CPAN modules

L<PDF::Labels> Routines to produce formatted pages of mailing labels in PDF, uses PDF::Create internally

L<PDF::Haru> Perl interface to Haru Free PDF Library

L<PDF::EasyPDF> PDF creation from a one-file module, similar to PDF::Create

L<PDF::CreateSimple> Yet another PDF creation module

L<PDF::Report> A wrapper written for PDF::API2

=head1 AUTHORS

Fabien Tassin

GIF and JPEG-support: Michael Gross (info@mdgrosse.net)

Maintenance since 2007: Markus Baertschi (markus@markus.org)

=head1 COPYRIGHT

Copyright 1999-2001, Fabien Tassin. All rights reserved.
It may be used and modified freely, but I do request that
this copyright notice remain attached to the file. You may
modify this module as you wish, but if you redistribute a
modified version, please attach a note listing the modifications
you have made.

Copyright 2007-, Markus Baertschi
Copyright 2010, Gary Lieberman

=cut
