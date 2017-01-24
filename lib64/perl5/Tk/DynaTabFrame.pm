#234567890123456789012345678901234567890123456789012345678901234567890
package Tk::DynaTabFrame;

require 5.008;

use Tk;
use Tk ':variables';
use Tk::Balloon;

use base qw (Tk::Derived Tk::Frame);
use vars qw ($VERSION);
use strict;
use Carp;

$VERSION = '0.23';
#
#	indexes of our tab properties
#
use constant DTF_IDX_WIDGET => 0;
use constant DTF_IDX_CAPTION => 1;
use constant DTF_IDX_COLOR => 2;
use constant DTF_IDX_ROW => 3;
use constant DTF_IDX_COL => 4;
use constant DTF_IDX_FRAME => 5;
use constant DTF_IDX_WIDTH => 6;
use constant DTF_IDX_HEIGHT => 7;
use constant DTF_IDX_RAISECOLOR => 8;
use constant DTF_IDX_RAISECMD => 9;
use constant DTF_IDX_LABEL => 10;
use constant DTF_IDX_FLASH_COLOR => 11;
use constant DTF_IDX_FLASH_INTVL => 12;
use constant DTF_IDX_FLASH_TIME => 13;
use constant DTF_IDX_FLASH_ID => 14;
use constant DTF_IDX_FLASHED => 15;
use constant DTF_IDX_HIDDEN => 16;
use constant DTF_IDX_TABTIP => 17;

my $close_xpm = << 'end-of-close-xpm';
/* XPM */
static char * close_xpm[] = {
"8 8 3 1",
" 	s None	c None",
".	c #000000000000",
"X	c #E0E0FFFFE0E0",
"..    ..",
" ..  .. ",
"  ....  ",
"   ..   ",
"   ..   ",
"  ....  ",
" ..  .. ",
"..    .."};

end-of-close-xpm

my $close_xpm_6 = << 'end-of-close-xpm-6';
/* XPM */
static char * close_xpm[] = {
"6 6 3 1",
" 	s None	c None",
".	c #000000000000",
"X	c #E0E0FFFFE0E0",
"..  ..",
" .... ",
"  ..  ",
"  ..  ",
" .... ",
"..  ..",};

end-of-close-xpm-6

#
#	map of tabframe directives based on
#	tab orientation
#
use constant DTF_TAB_TABSIDE => 0;
use constant DTF_TAB_TABFILL => 1;
use constant DTF_TAB_TABANCHOR => 2;
use constant DTF_TAB_TABSIZER => 3;
use constant DTF_TAB_CLIENTSIDE => 4;

my %tabalign = (
#	tabframe -side, tabframe -fill, tabframe -anchor, 
#		tabframe sizing option, clientframe -side
	nw => [ 'top', 'x', 'nw', '-height', 'bottom'],
	ne => [ 'top', 'x', 'ne', '-height', 'bottom'],
	sw => [ 'bottom', 'x', 'sw', '-height', 'top'],
	se => [ 'bottom', 'x', 'se', '-height', 'top'],
	en => [ 'right', 'y', 'ne', '-width', 'left'],
	es => [ 'right', 'y', 'se', '-width', 'left'],
	wn => [ 'left', 'y', 'nw', '-width', 'right'],
	ws => [ 'left', 'y', 'sw', '-width', 'right'],
);

#
#	bitmaps for border requirements
#	based on tab orientations
#	bit 0 => Left
#	bit 1 => Right
#	bit 2 => Top
#	bit 3 => Bottom
#	'p' sides are for pseudo tabs
#
my %borders = qw(
nw 7
ne 7
sw 11
se 11
en 14
es 14
wn 13
ws 13
pnw 6
pne 5
psw 10
pse 9
pen 10
pes 6
pwn 9
pws 5
);
#
#	pack directives for the tab contents
#	[ closebtn_side, 
#		closebtn_anchor, 
#		button_side, 
#		button_anchor,
#		pseudo_anchor
#		tab direction
#	]
#
use constant DTF_ORIENT_CLOSESIDE => 0;
use constant DTF_ORIENT_CLOSEANCHOR => 1;
use constant DTF_ORIENT_BTNSIDE => 2;
use constant DTF_ORIENT_BTNANCHOR => 3;
use constant DTF_ORIENT_PSEUDOANCHOR => 4;
use constant DTF_ORIENT_DIRECTION => 5;
use constant DTF_ORIENT_ALIGN => 6;
use constant DTF_ORIENT_DOWNWARD => 7;

use constant DTF_MAX_ROWS => 20;
use constant DTF_DFLT_TIPTIME => 450;

my %taborient = (
'nw', [ 'right', 'ne', 'right', 's', 'e', 1, 0, 1, ],
'ne', [ 'right', 'ne', 'right', 's', 'w', 1, 0, 1, ],
'sw', [ 'right', 'se', 'right', 'n', 'e', 1, 1, 0, ],
'se', [ 'right', 'se', 'right', 'n', 'w', 1, 1, 0, ],
'en', [ 'top', 'ne', 'top', 's', 's', 0, 0, 0, ],
'es', [ 'top', 'ne', 'top', 's', 'n', 0, 0, 0, ],
'wn', [ 'top', 'nw', 'top', 's', 's', 0, 1, 1, ],
'ws', [ 'top', 'nw', 'top', 's', 'n', 0, 1, 1, ],
);
#
#	page options for Tk::Notebook compatibility
#
my %page_opts = (
'-tabcolor', DTF_IDX_COLOR,
'-raisecolor', DTF_IDX_RAISECOLOR,
'-image', '-image', 
'-label', DTF_IDX_LABEL,
'-raisecmd', DTF_IDX_RAISECMD,
'-state', '-state',
'-tabtip', DTF_IDX_TABTIP,
'-hidden', DTF_IDX_HIDDEN
);

Tk::Widget->Construct ('DynaTabFrame');

sub Populate {
    my $this = shift;
    $this->ConfigSpecs(
        '-borderwidth' => [['SELF', 'PASSIVE'],
        	'borderwidth', 'BorderWidth', '1'],
        '-tabcurve' => [['SELF', 'PASSIVE'], 
        	'tabcurve', 'TabCurve', 2],
        '-padx' => [['SELF', 'PASSIVE'], 'padx', 'padx', 5],
        '-pady' => [['SELF', 'PASSIVE'], 'pady', 'pady', 5],
#
#	for Tk::Notebook compatibility
#
        '-tabpadx' => [['SELF', 'PASSIVE'], 'tabpadx', 'tabpadx', 2],
        '-tabpady' => [['SELF', 'PASSIVE'], 'tabpady', 'tabpady', 2],
        '-font' => ['METHOD', 'font', 'Font', undef],
        '-current' => ['METHOD'],
        '-raised' => ['METHOD'],
        '-raised_name' => ['METHOD'],
        '-tabs' => ['METHOD'],
		'-delay' => [['SELF', 'PASSIVE'], 'delay', 'Delay', '200'],
		'-raisecmd' => [['SELF', 'PASSIVE'], 'raisecmd', 'RaiseCmd', undef],
        '-tablock' => [['SELF', 'PASSIVE'], 'tablock', 'tablock', undef],
        '-tabrotate' => [['SELF', 'PASSIVE'], 'tabrotate', 'tabrotate', 1],
        '-tabside' => ['METHOD'],
        '-tabclose' => ['METHOD'], 
        '-tabscroll' => ['METHOD'],
        '-tabcolor' => [['SELF', 'PASSIVE'], 'tabcolor', 'tabcolor', undef],
        '-tabtip' => [['SELF', 'PASSIVE'], 'tabtip', 'tabtip', undef],
        '-tiptime' => ['METHOD'],
        '-tipcolor' => ['METHOD'],
        '-textalign' => [['SELF', 'PASSIVE'], 'textalign', 'textalign', 1],
        '-backpagecolor' => [['SELF', 'PASSIVE'], 'tabcolor', 'tabcolor', undef],
        '-raisecolor' => [['SELF', 'PASSIVE'], 'raisecolor', 'raisecolor', undef],
       );

    $this->SUPER::Populate(@_);
#
#	set default tab orientation
#
	$this->{Side} = 'nw';
	$this->{_tiptime} = DTF_DFLT_TIPTIME;
	$this->{_tipcolor} = 'white';
#
#	get tab alignment info
#
	my ($tabside, $tabfill, $tabanchor, $tabsize, $clientside) =
		@{$tabalign{$this->{Side}}};
#
#	ButtonFrame is where the tabs are
#
    my $ButtonFrame = $this->{ButtonFrame} = $this->Component(
        'Frame' => 'ButtonFrame',
        -borderwidth => 0,
        -relief => 'flat',
        $tabsize => 40,
	)->pack(
        -anchor => $tabanchor,
        -side => $tabside,
        -fill => $tabfill,
	);
#
#	create the frame we return to the app
#
    my $ClientFrame = $this->{ClientFrame} = $this->Component(
        'Frame' => 'TabChildFrame',
        -relief => 'flat',
        -borderwidth => 0,
        -height => 60,
	)->pack(
        -side => $clientside,
        -expand => 1,
        -fill => 'both',
	);
#
#	a pseudo-frame used to make the raised tab smoothly connect
#	to the client frame
#
    my $Connector = $this->Component(
        'Frame' => 'Connector', 
        -relief => 'flat'
	);
#
#	list of all our current clients
#
	$this->{ClientList} = [ ];
#
#	a quick lookup by caption
#
	$this->{ClientHash} = {};
#
#	a quick lookup of row numbers
#	so a raise() can just move entire rows around
#	create first empty row
#
	$this->{RowList} = [ [] ];
#
#	plug into the configure event so we get resizes
#
	$this->{OldWidth} = $ButtonFrame->reqwidth();
	$this->{OldHeight} = $ButtonFrame->reqheight();
	$this->bind("<Configure>" => sub { $this->ConfigDebounce; });
#
#	generate the close button
#
	my $scrwd = $this->screenwidth;
	$this->{CloseImage} = $this->Pixmap(-data => (($scrwd <= 1024) ? $close_xpm_6 : $close_xpm));
    return $this;
}

sub ConfigDebounce {
	my ($this) = @_;
	my $w = $Tk::event->w;
	my $h = $Tk::event->h;
#
#	only post event if we've changed width/height
#
	return 1 if (($this->{OldWidth} == $w) && ($this->{OldHeight} == $h));

	$this->{LastConfig} = Tk::timeofday;
	$this->{LastWidth} = $w;
	$this->{LastHeight} = $h;

	$this->afterCancel($this->{LastAfterID})
		if defined($this->{LastAfterID});

	$this->{LastAfterID} = $this->after(200, # $this->cget('-delay'), 
		sub {
			$this->TabReconfig();
			delete $this->{LastAfterID};
		}
	);
	1;
}

sub TabCreate {
    my ($this, $Caption, $Color, $RaiseColor, $Image, $Text, $RaiseCmd) = @_;
#
#	always add at (0,0)
#
	my $clients = $this->{ClientList};
	my $rows = $this->{RowList};
	my $ButtonFrame = $this->{ButtonFrame};
#
#	create some pseudo tabs
#	note we only create DTF_MAX_ROWS, so if we have > DTF_MAX_ROWS+1
#	tab rows, we're in trouble
#
	unless ($this->{PseudoTabs}) {
		$this->{PseudoTabs} = [ undef ];
		push @{$this->{PseudoTabs}}, $this->PseudoCreate($_)
			foreach (1..DTF_MAX_ROWS);
	}
#
#	create default colors
#
	$this->configure(-tabcolor => 
		$this->Darken($this->cget(-background), 75))
		unless $this->cget(-tabcolor);
	$this->configure(-raisecolor => 
		$this->Darken($this->cget(-tabcolor), 130))
		unless $this->cget(-raisecolor);

	$RaiseColor = $Color ? $this->Darken($Color, 130) :
		$this->cget(-raisecolor)
		unless $RaiseColor;

	$Color = $this->cget(-tabcolor)
		unless $Color;
	
	$RaiseCmd = $this->cget(-raisecmd) 
		unless $RaiseCmd;
#
#	create a new frame for the caller
#
    my $Widget = $this->{ClientFrame}->Frame(
		-borderwidth => $this->cget ('-borderwidth'),
        -relief => 'raised');
#
#	create a new frame for a tab
#
    my $TabFrame = $ButtonFrame->Component(
        'Frame' => 'Button_'.$Widget,
        -foreground => $this->cget ('-foreground'),
        -relief => 'flat',
        -borderwidth => 0,
	);
    $TabFrame->configure(-bg => $Color)
        if $Color;

	my $to = $taborient{$this->{Side}};
#
#	build a close tab for it if requested
#
	my $CloseBtn;
    $CloseBtn = $TabFrame->Component(
        'Button' => 'CloseBtn',
        -command => [ $this->{Close}, $this, $Caption ],
        -anchor => $to->[DTF_ORIENT_CLOSEANCHOR],
        -relief => 'raised',
        -borderwidth => 1,
        -takefocus => 1,
        -padx => 0,
        -pady => 0,
        -image => $this->{CloseImage}
	)
		if $this->{Close};
#
#	build the tab for it; in future we may support images
#
	my $font = $this->cget(-font);
	$font = $this->parent()->cget(-font) unless $font;
	my $padx = $this->cget(-tabpadx);
	my $pady = $this->cget(-tabpady);
    my $Button = $TabFrame->Component(
        'Button' => 'Button',
        -command => sub { $this->configure (-current => $Widget);},
        -anchor => 'center',
        -relief => 'flat',
        -borderwidth => 0,
        -takefocus => 1,
        -padx => 1,
        -pady => 1,
	);

    $Button->configure(-bg => $Color);
    if (defined($Image)) {
    	$Button->configure(-image => $Image);
    }
    else {
    	$Button->configure(-font => $font) if $font;
    	$Text = $Caption ||= $Widget->name()
    		unless $Text;
#
#	make it vertical for side tabs
#
	    $Button->configure(-text => 
	    	($this->cget(-textalign) ?
	    		($to->[DTF_ORIENT_DIRECTION] ? $Text : RotateTabText($Text)) :
	    		($to->[DTF_ORIENT_DIRECTION] ? RotateTabText($Text) : $Text))
	    );
	}

    $TabFrame->bind('<ButtonRelease-1>' => sub {$Button->invoke();});
#
#	someday we'll have to figure out how to configure these
#	events so rolling into a tab brightens and roling out
#	darkens...wo/ repeating the event ad nauseum...
#
#	$TabFrame->bind('<Enter>', [ \&OnEnter, $Button, $TabFrame ]);
#	$TabFrame->bind('<Leave>', [ \&OnLeave, $Button, $TabFrame ]);

#	$Button->bind('<Enter>', [ \&OnEnter, $Button, $TabFrame ]);
#	$Button->bind('<Leave>', [ \&OnLeave, $Button, $TabFrame ]);

#	$Button->bind('<FocusOut>', [ \&OnFocusOut, $TabFrame ]);
#	$Button->bind('<FocusIn>', [ \&OnFocusIn, $TabFrame ]);
    $Button->bind('<Control-Tab>', 
    	sub {($this->children())[0]->focus();});
    $Button->bind ('<Return>' => sub {$Button->invoke();});
#
#	decorate the tab
#
    $this->TabBorder ($TabFrame);

	my $dark = $Button->Darken($Color, 50);
    $Button->configure(-highlightthickness => 0,
        -activebackground => $dark);

    $CloseBtn->pack(
       	-side => $to->[DTF_ORIENT_CLOSESIDE],
       	-anchor => $to->[DTF_ORIENT_CLOSEANCHOR],
        -expand => 0,
        -fill => 'none',
        -ipadx => 0,
        -ipady => 0,
        -padx => 2,
        -pady => 2,
	)
		if $CloseBtn;

    $Button->pack(
       	-side => $to->[DTF_ORIENT_BTNSIDE],
       	-anchor => $to->[DTF_ORIENT_BTNANCHOR],
        -expand => 0,
        -fill => 'none',
        -ipadx => 0,
        -ipady => 0,
        -padx => $padx,
        -pady => $pady,
	);
#
#	pack tab in our rowframe 0; redraw if needed
#	move everything over 1 column in bottom row
#
	$clients->[$_][DTF_IDX_COL]++
		foreach (@{$rows->[0]});
	unshift @{$rows->[0]}, scalar @$clients;
#
#	save the client frame, the caption, the tabcolor,
#	the current row/column coords of our tab, our tabframe,
#	and the original height of this tab; we'll be stretching
#	the button later during redraws
#
    push @$clients, [ 
    	$Widget, 		# our client frame
    	$Caption,		# our identifier 
    	$Color, 		# unraised color
    	0, 				# row number
    	0, 				# column number
    	$TabFrame, 		# our tab frame
    	($to->[DTF_ORIENT_DIRECTION] ? 	# the tab width
    		$Button->reqwidth() : $Button->reqheight() ),
    	($to->[DTF_ORIENT_DIRECTION] ? 	# the tab height
    		$Button->reqheight() : $Button->reqwidth() ),
    	$RaiseColor,	# raised color
    	$RaiseCmd,		# callback for raise operations
    	$Text,			# tab label text
    	1				# start as visible
    	];
#
#	reqwidht/height don't seem to include the padx/pady
#
	$$clients[-1][DTF_IDX_HEIGHT] += (2 *
		($to->[DTF_ORIENT_DIRECTION] ? $pady : $padx));
	$$clients[-1][DTF_IDX_WIDTH] += (2 *
		($to->[DTF_ORIENT_DIRECTION] ? $padx : $pady));
#
#	map the caption to its position in the client list,
#	so we can raise and delete it by reference
#
    $this->{ClientHash}{$Caption} = $#$clients;
#
#	redraw everything
#
	$this->TabRedraw(1);
#
#	and raise us
#
    $this->TabRaise($Widget);
	return $Widget;
}

sub PseudoCreate {
    my ($this, $row) = @_;
#
#	create a new frame for a pseudotab
#
    my $TabFrame = $this->{ButtonFrame}->Component(
        'Frame' => "Pseudo_$row",
        -foreground => $this->cget ('-foreground'),
        -relief => 'flat',
        -borderwidth => 0,
	);

    $TabFrame->Component(
    	'Label' => 'Button',
        -text => ' ',
        -anchor => $taborient{$this->{Side}}[DTF_ORIENT_PSEUDOANCHOR],
        -relief => 'flat',
        -borderwidth => 0,
        -padx => 2,
        -pady => 2,
	)->pack(
        -expand => 0,
        -fill => 'both',
        -ipadx => 0,
        -ipady => 0,
        -padx => 3,
        -pady => 3,
	);
#
#	decorate the tab
#
    $this->TabBorder ($TabFrame, 1);

	return $TabFrame;
}

sub TabRaise {
    my ($this, $Widget, $silent) = (shift, @_);
#
#	locate the tab row
#	if its not the first row, then we need to move rows around
#	and redraw
#	else just raise it
#
    my $ButtonFrame = $this->{ButtonFrame};
    my $TabFrame = $ButtonFrame->Subwidget('Button_'.$Widget);
    my $rotate = $this->cget(-tabrotate);
#
#	find our client
#
	my $clients = $this->{ClientList};
#
#	strange timing issue sometimes leaves a null
#	entry at our tail
#
	pop @$clients unless defined($clients->[-1]);

	my $client;
#
#	locate the currently raised tab and restore its
#	unraised color
#
	foreach $client (@$clients) {
		last unless $this->{Raised};
		next unless ($client->[DTF_IDX_WIDGET] eq $this->{Raised});
		my $Button = $client->[DTF_IDX_FRAME]->Subwidget('Button');
		$client->[DTF_IDX_FRAME]->configure(-bg => $client->[DTF_IDX_COLOR]);
		$Button->configure(-bg => $client->[DTF_IDX_COLOR],
	        -activebackground => $client->[DTF_IDX_COLOR],
		);
		last;
	}

	my $raised = 0;
	$raised++
		while (($raised <= $#$clients) && 
			($clients->[$raised][DTF_IDX_WIDGET] ne $Widget));
		
	return 1 unless ($raised <= $#$clients);
	$client = $clients->[$raised];
	my ($r, $c) = ($client->[DTF_IDX_ROW], $client->[DTF_IDX_COL]);
	my $rows = $this->{RowList};
#
#	undraw the Connector
#
    my $Connector = $this->Subwidget('Connector');
	$Connector->placeForget(); # if $Connector->is_mapped;
	delete $this->{Raised};

	if ($rotate) {
#
#	3 cases:
#		we're already at row 0, so just raise
#		else rotate rows off bottom to top until
#			raised row is bottom row
#
		if ($r != 0) {
#
#	middle row, or last row that fills the frame:
#	move the preceding to top, and move the selected row
#	to the bottom
#
			my $rowcnt = $r;
			push(@$rows, (shift @$rows)),
			$rowcnt--
				while ($rowcnt);
#
#	update client coords
#
			foreach my $i (0..$#$rows) {
				$clients->[$_][DTF_IDX_ROW] = $i
					foreach (@{$rows->[$i]});
			}
			$this->TabRedraw;
		}
#
#	first, lower everything below the raised tab
#	in row 0
#
		my $lowest = $raised;
		my $pseudos = $this->{PseudoTabs};
		foreach (@{$rows->[0]}) {
			$clients->[$_][DTF_IDX_FRAME]->lower($clients->[$lowest][DTF_IDX_FRAME]),
			$lowest = $_
				unless ($_ == $raised);
		}
#
#	now lower everything below its left neighbor
#
		foreach my $i (1..$#$rows) {
			$clients->[$_][DTF_IDX_FRAME]->lower($clients->[$lowest][DTF_IDX_FRAME]),
			$lowest = $_
				foreach (@{$rows->[$i]});
		}
#
#	now make all pseudos lower
#
		if ($#$rows > 0) {
			$pseudos->[1]->lower($clients->[$lowest][DTF_IDX_FRAME]);
			$pseudos->[$_]->lower($pseudos->[$_-1])
				foreach (2..$#$rows);
		}
	    $TabFrame->Subwidget('Button')->raise();
	    $TabFrame->raise();
	}	# if rotate
    $TabFrame->Subwidget('Button')->focus();
#
#	lower the current frame, and then raise the new one
#	!!!NOTE: we can't use pack() here, as it tends to
#	expand the area of our container
#
	$Widget->place(-x => 0, -y => 0, -relheight => 1.0, -relwidth => 1.0);
	$this->{CurrentFrame} = $Widget;

	pop @$clients unless defined($clients->[-1]);
	foreach (0..$#$clients) {
		$clients->[$_][DTF_IDX_WIDGET]->lower($Widget)
			if ($clients->[$_] && $clients->[$_][DTF_IDX_WIDGET] &&
				($clients->[$_][DTF_IDX_WIDGET] ne $Widget));
	}

	my $raisecolor = $client->[DTF_IDX_RAISECOLOR];
#
#	used to smoothly connect raised tab to client frame
#	but only if in row 0
#
	if ($client->[DTF_IDX_ROW] == 0) {
	    $this->update;	# make sure the tabs are redrawn

		my ($connectx, $connectw, $connecty, $connecth);
		my $horizontal = $taborient{$this->{Side}}[DTF_ORIENT_DIRECTION];
		my $inside = $taborient{$this->{Side}}[DTF_ORIENT_ALIGN];
	    my $extra = $this->{Close} ? 12 : -3;
		if ($horizontal) { # 
		    $connectx = $TabFrame->x + 2;
		    $connectw = $client->[DTF_IDX_WIDTH] + $extra;
#
#	Y location of connector is either at top (for nw/ne) 
#	or bottom (for sw/se) of the client frame
#
		    $connecty = $inside ? 
		    	$this->{ClientFrame}->height() - 2 : # may need to adjust this offset
		    	$this->{ClientFrame}->rooty() - $this->rooty() - 7;
		    $connecth = $this->{ClientFrame}->cget(-borderwidth) + 3;
		}
		else {	# vertical
#
#	if tabs at left, then position at left edge of client
#	else position at rt edge
#
			$connectx = $inside ? 
				$this->{ClientFrame}->rootx() - $this->rootx() - 8 :
				$this->{ClientFrame}->width() - 3;	# may need to adjust this offset
			$connectw = $this->{ClientFrame}->cget(-borderwidth) + 3;

		    $connecty = $TabFrame->y + 3;
		    $connecth = $client->[DTF_IDX_WIDTH] + $extra;
		}
	    $Connector->place(
	        -x => $connectx,
	        -y => $connecty,
	        -height => $connecth,
	        -width => $connectw,
	        -anchor => 'nw',
		);

	    $Connector->configure(-background => $raisecolor);
	    $Connector->raise();
	}	# end if raise in row 0

	$this->{Raised} = $Widget;
#
#	turn off flashing
#
	$this->deflash($client->[DTF_IDX_CAPTION])
		if $client->[DTF_IDX_FLASH_ID];
#
#	set raised color
#
    $TabFrame->configure(-background => $raisecolor),
    $TabFrame->Subwidget('Button')->configure(
    	-bg => $raisecolor,
		-activebackground => $raisecolor);
#
#	callback if defined && allowed
#
	unless ($silent) {
		my $raisecb = $client->[DTF_IDX_RAISECMD];
		&$raisecb($client->[DTF_IDX_CAPTION])
			if ($raisecb && (ref $raisecb) && (ref $raisecb eq 'CODE'));
	}
    return $Widget;
}
#
#	render tab borders
#
sub TabBorder {
    my ($this, $TabFrame, $forpseudo) = @_;
    my $LineWidth = $this->cget(-borderwidth);
    my $Background = $this->cget(-background);
    my $InnerBackground = $TabFrame->Darken($Background, 120),
    my $Curve = $this->cget (-tabcurve);
    
    my $mask = $forpseudo ? $borders{'p' . $this->{Side}} :
    	$borders{$this->{Side}};
#
#	left border
#	outer:
	$TabFrame->Frame(
        -background => 'white',
        -borderwidth => 0,
   	)->place(
   	    -x => 0,
   	    -y => $Curve - 1,
   	    -width => $LineWidth,
   	    -relheight => 1.0,
	),
#
#	inner:
   	$TabFrame->Frame(
   	    -background => $InnerBackground,
   	    -borderwidth => 0,
	)->place(
   	    -x => $LineWidth,
   	    -y => $Curve - 1,
   	    -width => $LineWidth,
   	    -relheight => 1.0,
	)
		if ($mask & 1);
#
#	right border
#	outer:
   	$TabFrame->Frame(
       	-background => 'black',
       	-borderwidth => 0,
    )->place(
        -x => - ($LineWidth),
        -relx => 1.0,
        -width => $LineWidth,
        -relheight => 1.0,
        -y => $Curve,
	),
#
#	inner:
	$TabFrame->Frame(
       	-background => $TabFrame->Darken($Background, 80),
       	-borderwidth => 0,
    )->place(
        -x => - ($LineWidth * 2),
        -width => $LineWidth,
        -relheight => 1.0,
        -y => $Curve / 2,
        -relx => 1.0,
	)
		if ($mask & 2);
#
#	top border
#	outer:
   	$TabFrame->Frame(
       	-background => 'white',
       	-borderwidth => 0,
    )->place(
        -x => $Curve - 1,
        -y => 0,
        -relwidth => 1.0,
        -height => $LineWidth,
        -width => - ($Curve * 2),
	),
#
#	inner:
   	$TabFrame->Frame(
       	-background => $InnerBackground,
       	-borderwidth => 0,
    )->place(
        -x => $Curve - 1,
        -y => $LineWidth,
        -relwidth => 1.0,
        -height => $LineWidth,
        -width => - ($Curve * 2),
	)
		if ($mask & 4);
#
#	bottom border
#	outer:
   	$TabFrame->Frame(
       	-background => $InnerBackground,
       	-borderwidth => 0,
    )->place(
        -x => $Curve - 1,
#        -y => - ($LineWidth),
        -rely => 1.0,
        -relwidth => 1.0,
        -height => $LineWidth,
        -width => - ($Curve),
	),
#
#	inner:
   	$TabFrame->Frame(
		-background => 'black',
		-borderwidth => 0,
       	-height => $LineWidth,
    )->place(
        -x => $Curve - 1,
        -y => - ($LineWidth),
        -rely => 1.0,
        -relwidth => 1.0,
        -height => $LineWidth,
        -width => - ($Curve),
	)
		if ($mask & 8);
}

sub TabCurrent {
    return defined ($_[1]) ?
        $_[0]->TabRaise($_[1]) :
        $_[0]{Raised};
}
#
#	returns the width of a row
#
sub GetButtonRowWidth {
    my ($Width, $this, $row) = (0, shift, shift);

	return 0
		unless ($this->{RowList} && ($#{$this->{RowList}} >= $row));

	my $rowlist = $this->{RowList}[$row];
	my $tablist = $this->{ClientList};
	my $extra = 5 + ($this->{Close} ? 15 : 0);
	my $horizontal = $taborient{$this->{Side}}[DTF_ORIENT_DIRECTION];
    foreach my $Client (@$rowlist) {
        $Width += $extra + ($tablist->[$Client][DTF_IDX_WIDTH])
	   		if defined($tablist->[$Client]);
	}

    return $Width ? $Width - 10 : 0;
}
#
#	returns the accumulated height of all our rows
#
sub GetButtonRowHeight {
    my ($Height, $this, $row) = (0, shift, shift);

	return 0
		unless ($this->{RowList} && ($#{$this->{RowList}} >= $row));

	my $total_ht = 0;
	$total_ht += $this->GetRowHeight($_)
		foreach (0..$row);
    return $total_ht;
}
#
#	returns the height of a single row
#
sub GetRowHeight {
    my ($Height, $this, $row) = (0, shift, shift);
    my $ButtonFrame = $this->{ButtonFrame};

	return 0 
		unless ($this->{RowList} && ($#{$this->{RowList}} >= $row));

	my $rowlist = $this->{RowList}[$row];
	my $tablist = $this->{ClientList};
	my $total_ht = 0;
	my $newht = 0;
   	foreach (@$rowlist) {
   		next unless defined($tablist->[$_]);
   	    $newht = $tablist->[$_][DTF_IDX_HEIGHT];
   	    $Height = $newht if ($newht > $Height);
	}
    return $Height;
}

sub Font {
    my ($this, $Font) = (shift, @_);

	my $font = $this->{Font};
	$font = $this->parent()->cget(-font) unless $font;

    return ($font) 
    	unless (defined ($Font));

    my $tablist = $this->{ClientList};

	$_->[DTF_IDX_FRAME]->Subwidget('Button')->configure(-font => $Font)
    	foreach (@$tablist);
#
#	we need to redraw, since this may change our tab layout
#
	$this->TabRedraw(1);
    return ($this->{Font} = $Font);
}
#
#	Reconfigure the tabs on resize event
#
sub TabReconfig {
	my $this = shift;
  	return 1 
  		if ($this->{Updating} || 
  			($this->cget(-tablock) && (! $this->cget(-tabclose))));
	my $buttons = $this->{ButtonFrame};
	my $clients = $this->{ClientList};
#
#	if nothing to draw, then just update context
#
  	$this->{OldWidth} = $this->width,
  	$this->{OldHeight} = $this->height,
	return 1 
		unless ($#$clients >= 0);
#
#	compute current max row width
#	compare to current frame width
#	if maxrow > frame
#		redraw
#	elsif maxrow - frame > threshold
#		redraw
#
	my $rows = $this->{RowList};
  	my $w = $buttons->width();
	my $h = $buttons->height();

	my $maxw = 0;
	foreach (0..$#$rows) {
		my $rw = $this->GetButtonRowWidth($_);
		$maxw = $rw if ($maxw < $rw);
	}
#
#	return unless significantly different from old size
#
  	$this->{OldWidth} = $this->width,
  	$this->{OldHeight} = $this->height,
	return 1 
		unless (($maxw > $w) || ($w - $maxw > 10));
#
#	just redraw everything
#
	$this->{Updating} = 1;
	$this->TabRedraw(1);
	$this->{Updating} = undef;
  	$this->{OldWidth} = $this->width;
  	$this->{OldHeight} = $this->height;
  	return 1;
}
#
#	redraw our tabs
#
sub TabRedraw {
	my ($this, $rearrange) = @_;
#
#	compute new display ordering
#
	return 1 unless ($#{$this->{ClientList}} >= 0);
	my $ButtonFrame = $this->{ButtonFrame};
	my $clients = $this->{ClientList};
	my $rows = $this->{RowList};
#
#	if nothing to draw, bail out
#
	return 1 if (($#$rows < 0) || 
		(($#$rows == 0) && ($#{$rows->[0]} < 0)));

	my $pseudos = $this->{PseudoTabs};
	my $pseudoht;
	my $Raised = $this->{Raised};	# save for later
	my $roww = 0;
	my $raised_row = undef;
	my $horizontal = $taborient{$this->{Side}}[DTF_ORIENT_DIRECTION];
	my $alignment = $taborient{$this->{Side}}[DTF_ORIENT_PSEUDOANCHOR];
	my $downward = $taborient{$this->{Side}}[DTF_ORIENT_DOWNWARD];
	my $extra = $this->{Close} ? 15 : 0;
#
#	tabspace determined based on orientation
#
	my $w = $horizontal ? $ButtonFrame->width() : $ButtonFrame->height();
	$w -= 5;

	if ($rearrange) {
#
#	rearrange tabs to fit new frame width
#
		my @newrows = ([]);
		my @tclients = ();
		foreach my $row (@$rows) {
			foreach (@$row) {
				my $client = $clients->[$_];
				next
					if $client->[DTF_IDX_HIDDEN];

				my $btnw = $extra + $client->[DTF_IDX_WIDTH];
				my $row = $#$rows;

				$roww = 0,
				push @newrows, [ ]
					if (($roww + $btnw > $w) && ($#{$newrows[0]} >= 0));

				$roww += $btnw;
				push @{$newrows[-1]}, $_;
				$tclients[$_] = [ $#newrows, $#{$newrows[-1]} ];
				$raised_row = $#newrows 
					if ($Raised && $client->[DTF_IDX_WIDGET] && 
						($client->[DTF_IDX_WIDGET] eq $Raised));
			}
		}
#
#	if number of rows exceeds our limit
#
		return undef
			if ($#newrows > DTF_MAX_ROWS);
#
#	save the new row lists
#
		$this->{RowList} = \@newrows;
		$rows = \@newrows;
		foreach my $row (@$rows) {
			$clients->[$_]->[DTF_IDX_ROW] = $tclients[$_][0],
			$clients->[$_]->[DTF_IDX_COL] = $tclients[$_][1]
				foreach (@$row);
		}
	}
#
#	purge all our pseudotabs
#
	foreach (@$pseudos) {
		next unless $_;
		$_->placeForget()
			if $_->ismapped();
	}
#
#	undraw all our buttons
#
	foreach my $i (0..$#$rows) {
		foreach (@{$rows->[$i]}) {
			$clients->[$_][DTF_IDX_FRAME]->placeForget()
				if $clients->[$_][DTF_IDX_FRAME]->ismapped();
		}
	}
#
#	adjust our frame height to accomodate the rows
#
	my $dim = $horizontal ? '-height' : '-width';
	$ButtonFrame->configure(
		$dim => $this->GetButtonRowHeight($#$rows) + 
			($downward ? 5 : 7));
#
#	reconfig tabs to match height of tallest tab in row
#
	my @hts = ();
	push @hts, $this->GetRowHeight($_)
		foreach (0..$#$rows);
#
#	redraw all our buttons, starting from the top row
#	note: we force each button to fully fill the button frame;
#	this improves the visual effect when an upper tab extends
#	to the right of the end of the row below it
#
    my $Connector = $this->Subwidget('Connector');
    $Connector->placeForget(); # if $Connector->is_mapped();
	my ($i, $x, $y, $client, $frame);
	if ($horizontal) {
		if ($downward) {
#
#	top tabs:
#		draw from outermost row to innermost
#
			$i = $#$rows;
			$y = 0;
			$x = 0;
			while ($i >= 0) {
				$x = ($alignment eq 'e') ? 0 : $ButtonFrame->width() - 8;

				foreach (0..$#{$rows->[$i]}) {
					$client = $clients->[$rows->[$i][$_]];
					$frame = $client->[DTF_IDX_FRAME];
					$x -= ($client->[DTF_IDX_WIDTH] + $extra)
						if ($alignment eq 'w');
					$frame->Subwidget('Button')->configure(
						-height => $hts[$i]);
					$frame->place(
						-x => $x, 
						-y => $y,
						-height => $hts[$i] + 6
					);

					$x += $client->[DTF_IDX_WIDTH] + $extra
						if ($alignment eq 'e');
				}
#
#	draw pseudotabs if needed
#
				$y = $y + $this->GetRowHeight($i)
					if $i;
				$pseudoht = $this->GetButtonRowHeight($i-1) + 6,
				$pseudos->[$i]->place(
					-x => 0, 
					-y => $y + 4,
					-width => $ButtonFrame->width() - 8,
					-height => $pseudoht) 
					if $i;
				$i--;
			}
		}
		else {
#
#	bottom tabs:
#		draw from innermost row to innermost
#
			$i = 0;
			$y = 0;
			while ($i <= $#$rows) {
				$x = ($alignment eq 'e') ? 0 : $ButtonFrame->width() - 8;

				foreach (0..$#{$rows->[$i]}) {
					$client = $clients->[$rows->[$i][$_]];
					$frame = $client->[DTF_IDX_FRAME];
					$x -= ($client->[DTF_IDX_WIDTH] + $extra)
						if ($alignment eq 'w');

					$frame->Subwidget('Button')->configure(
						-height => $hts[$i]);
					$frame->place(
						-x => $x, 
						-y => $y,
						-height => $hts[$i] + 6
					);

					$x += $client->[DTF_IDX_WIDTH] + $extra
						if ($alignment eq 'e');
				}
#
#	draw pseudotabs if needed
#
				$pseudoht = $this->GetButtonRowHeight($i-1) + 1,
				$pseudos->[$i]->place(
					-x => 0, 
					-y => 0,
					-width => $ButtonFrame->width() - 8,
					-height => $pseudoht) 
					if $i;

				$y = $y + $this->GetRowHeight($i);
				$i++;
			}	# end while
		}	# end if downward...else...
	}	# end if horizontal
	else { # vertical tabs
		if ($downward) {
#
#	left tabs:
#		draw from outermost row to innermost
#
			$i = $#$rows;
			$x = 0;
			while ($i >= 0) {
				$y = ($alignment eq 's') ? 0 : $ButtonFrame->height() - 8;

				foreach (0..$#{$rows->[$i]}) {
					$client = $clients->[$rows->[$i][$_]];
					$frame = $client->[DTF_IDX_FRAME];
					$y -= ($client->[DTF_IDX_WIDTH] + $extra)
						if ($alignment eq 'n');

					$frame->Subwidget('Button')->configure(-width => $hts[$i]);
					$frame->place(
						-x => $x, 
						-y => $y,
						-width => $hts[$i] + 6
					);

					$y +=  $client->[DTF_IDX_WIDTH] + $extra
						if ($alignment eq 's');
				}
#
#	draw pseudotabs if needed
#
				$x += $this->GetRowHeight($i);
				$pseudoht = $this->GetButtonRowWidth($i-1) + 6,
				$pseudos->[$i]->place(
					-x => $x + 4, 
					-y => 0,
					-width => $pseudoht,
					-height => $ButtonFrame->height() - 8) 
					if $i;
				$i--;
			}
		}
		else {
#
#	right tabs:
#		draw from innermost row to innermost
#
			$i = 0;
			$x = 0;
			while ($i <= $#$rows) {
				$y = ($alignment eq 's') ? 0 : $ButtonFrame->height() - 8;

				foreach (0..$#{$rows->[$i]}) {
					$client = $clients->[$rows->[$i][$_]];
					$frame = $client->[DTF_IDX_FRAME];
					$y -= ($client->[DTF_IDX_WIDTH] + $extra)
						if ($alignment eq 'n');

					$frame->Subwidget('Button')->configure(-width => $hts[$i]);
					$frame->place(
						-x => $x, 
						-y => $y,
						-width => $hts[$i] + 6
					);

					$y +=  $client->[DTF_IDX_WIDTH] + $extra
						if ($alignment eq 's');
				}
#
#	draw pseudotabs if needed
#
				$pseudoht = $this->GetButtonRowHeight($i-1),
				$pseudos->[$i]->place(
					-x => $x - $pseudoht, 
					-y => 0,
					-width => $pseudoht + 1,
					-height => $ButtonFrame->height() - 8) 
					if $i;
				$x += $this->GetRowHeight($i);
				$i++;
			}	# end while
		}	# end if downward...else...
	}	# end if horizontal...else...
#
#	and reapply our tab order
#
	$this->TabOrder;
#
#	and reraise in case raised ended up somewhere other than
#	bottom row
#
	$this->TabRaise($Raised, 1) if $Raised;

	return 1;
}
#
#	remove a single tab and re-org the tabs
#
sub TabRemove {
	my ($this, $Caption) = @_;
	$this->{Updating} = 1;
#
#	remove a tab
#
	return undef 
		unless defined($this->{ClientHash}{$Caption});
	
	my $rows = $this->{RowList};
	my $clients = $this->{ClientList};
	my $listsz = $#$clients;
	my $clientno = $this->{ClientHash}{$Caption};
	my $client = $clients->[$clientno];
	my $Widget = $client->[DTF_IDX_WIDGET];
	my ($r, $c) = ($client->[DTF_IDX_ROW], $client->[DTF_IDX_COL]);
#
#	if its the raised widget, then we need to raise 
#	a tab to replace it (unless its the only widget)
#	...whatever is left at 0,0 sounds good to me...
#
	my $row = $rows->[$r];
	my $newcurrent = ($client->[DTF_IDX_WIDGET] eq $this->{Raised}) ? 1 : undef;
#
#	remove client from lists
#
	delete $this->{ClientHash}{$Caption};
	
	if ($clientno eq $#$clients) {
	# Perl bug ? we seem to not get spliced out at ends
		pop @$clients;
	}
	else {
		splice @$clients, $clientno, 1;
	}
	splice @$row, $c, 1;
#
#	adjust client positions in this row
#
	$clients->[$row->[$_]][DTF_IDX_COL]--
		foreach ($c..$#$row);
#
#	adjust client indices in the hash
#
	foreach (keys %{$this->{ClientHash}}) {
		$this->{ClientHash}{$_} -= 1
			if ($this->{ClientHash}{$_} > $clientno);
	}
#
#	adjust all our row index lists
#
	foreach my $row (@$rows) {
		foreach (0..$#$row) {
			$row->[$_]-- if ($row->[$_] > $clientno);
		}
	}
	
    my $TabFrame = $client->[DTF_IDX_FRAME];
	$TabFrame->packForget();
	$TabFrame->destroy();
	$Widget->destroy();
#
#	if only tab in row, remove the row
#	and adjust the clients in following rows
#
	if ($#$row < 0) {
		foreach my $i ($r+1..$#$rows) {
			$row = $rows->[$i];
			$clients->[$_][DTF_IDX_ROW] -= 1
				foreach (@$row);
		}
		splice @$rows, $r, 1;
	}

	if ($#$rows < 0) {
#
#	no rows left, clear everything
#
		$this->{Raised} = undef;
		$this->Subwidget('Connector')->placeForget();
		$this->{CurrentFrame} = undef;
	}
	elsif ($newcurrent) {
		$this->{Raised} = $clients->[$rows->[0][0]][DTF_IDX_WIDGET];
	}
#
#	redraw everything
#
	$this->TabRedraw(1);
	$this->{Updating} = undef;
#
#	odd behavior (maybe Resize timing issue):
#	we occasionally end up with an undef entry at the tail
#
	pop @$clients
		unless (($listsz - 1) == $#$clients);
	return 1;
}
#
#	reveal a previously hidden tab and re-org the tabs
#
sub TabReveal {
	my ($this, $Caption) = @_;
	$this->{Updating} = 1;

	return undef
		unless defined($this->{ClientHash}{$Caption});

	my $clients = $this->{ClientList};
	my $rows = $this->{RowList};
	my $clientno = $this->{ClientHash}{$Caption};
	my $client = $clients->[$clientno];
	return 1
		unless $client->[DTF_IDX_HIDDEN];
#
#	make visible and redraw; note we don't
#	make it raised yet
#
	$client->[DTF_IDX_HIDDEN] = undef;
#
#	pack tab in our rowframe 0; redraw if needed
#	move everything over 1 column in bottom row
#
	$clients->[$_][DTF_IDX_COL]++
		foreach (@{$rows->[0]});
	unshift @{$rows->[0]}, $clientno;
#
#	redraw everything
#
	$this->TabRedraw(1);
	$this->{Updating} = undef;
#
#	if nothing is raised, then raise us
#
	$this->raise($Caption)
		unless $this->{Raised};
	return 1;
}
#
#	hide a single tab and re-org the tabs
#
sub TabHide {
	my ($this, $Caption) = @_;
	$this->{Updating} = 1;

	return undef 
		unless defined($this->{ClientHash}{$Caption});
	
	my $rows = $this->{RowList};
	my $clients = $this->{ClientList};
	my $listsz = $#$clients;
	my $clientno = $this->{ClientHash}{$Caption};
	my $client = $clients->[$clientno];
	my $Widget = $client->[DTF_IDX_WIDGET];
	my ($r, $c) = ($client->[DTF_IDX_ROW], $client->[DTF_IDX_COL]);
#
#	if its the raised widget, then we need to raise 
#	a tab to replace it (unless its the only widget)
#	...whatever is left at 0,0 sounds good to me...
#
	my $row = $rows->[$r];
	my $newcurrent = ($client->[DTF_IDX_WIDGET] eq $this->{Raised}) ? 1 : undef;
#
#	hide the client
#
	$client->[DTF_IDX_HIDDEN] = 1;
	$client->[DTF_IDX_ROW] = undef;
	$client->[DTF_IDX_COL] = undef;
	
	splice @$row, $c, 1;
#
#	adjust client positions in this row
#
	$clients->[$row->[$_]][DTF_IDX_COL]--
		foreach ($c..$#$row);
#
#	adjust all our row index lists
#
#	foreach my $row (@$rows) {
#		foreach (0..$#$row) {
#			$row->[$_]-- if ($row->[$_] > $clientno);
#		}
#	}
#
#	force us into unraised color
#
    my $TabFrame = $this->{ButtonFrame}->Subwidget('Button_'.$Widget);
    $TabFrame->configure(-background => $client->[DTF_IDX_COLOR]);
    $TabFrame->Subwidget('Button')->configure(
    	-bg => $client->[DTF_IDX_COLOR],
		-activebackground => $client->[DTF_IDX_COLOR]);

	$client->[DTF_IDX_FRAME]->placeForget()
		if $client->[DTF_IDX_FRAME]->ismapped();
#
#	if only tab in row, remove the row
#	and adjust the clients in following rows
#
	if ($#$row < 0) {
		foreach my $i ($r+1..$#$rows) {
			$row = $rows->[$i];
			$clients->[$_][DTF_IDX_ROW] -= 1
				foreach (@$row);
		}
		splice @$rows, $r, 1;
	}

	if ($#$rows < 0) {
#
#	no rows left, clear everything
#
		$this->{Raised} = undef;
		$this->Subwidget('Connector')->placeForget();
		$this->{CurrentFrame} = undef;
	}
	elsif ($newcurrent) {
		$this->{Raised} = $clients->[$rows->[0][0]][DTF_IDX_WIDGET];
	}
#
#	redraw everything
#
	$this->TabRedraw(1);
	$this->{Updating} = undef;
	return 1;
}
#
#	compute the tabbing traversal order
#	note an anomaly:
#	if the top row doesn't fill the frame, and a top
#	row button is tabbed to, it is automatically moved
#	to the 0,0, and its tab order it recomputed. This
#	means that its impossible to tab to any tab
#	in the top row except the first tab. We may eventually
#	change TabRaise to bring the entire top row down
#	if a top row tab is raised.
#
sub TabOrder {
	my ($this) = @_;
	
	my $rows = $this->{RowList};
	my $clients = $this->{ClientList};
	my ($prev, $next);
	
	foreach my $i (0..$#$rows) {
		my $row = $rows->[$i];
		foreach my $j (0..$#$row) {
			if ($j == 0) {
				$prev = ($i == 0) ? $rows->[-1][-1] : $rows->[$i-1][-1];
				$next = ($#$row == 0) ? 
					($i == $#$rows) ? $rows->[0][0] : $rows->[$i+1][0] :
					$row->[$j+1];
			}
			elsif ($j == $#$row) {
				$prev = $row->[$j-1];
				$next = ($i == $#$rows) ? $rows->[0][0] : $rows->[$i+1][0];
			}
			else {
				$prev = $row->[$j-1];
				$next = $row->[$j+1];
			}

			my $button = $clients->[$row->[$j]][DTF_IDX_FRAME]->Subwidget('Button');
			my $prevwgt = $clients->[$prev][DTF_IDX_WIDGET];
			my $prevbtn = $clients->[$prev][DTF_IDX_FRAME]->Subwidget('Button');
			my $nextwgt = $clients->[$next][DTF_IDX_WIDGET];
			my $nextbtn = $clients->[$next][DTF_IDX_FRAME]->Subwidget('Button');

			# bind us
	        $button->bind ('<Shift-Tab>', sub {$prevbtn->focus();});
	        $button->bind ('<Left>', sub {$this->TabRaise($prevwgt);});
	        $button->bind ('<Tab>', sub {$nextbtn->focus();});
	        $button->bind ('<Right>', sub {$this->TabRaise($nextwgt);});
		}
	}
	return 1;
}
#
#	create a tooltip for the tab
#
sub CreateTabTip {
	my ($this, $w, $btn, $tiptext) = @_;
#
#	create balloon if none exists
#
	$this->{Balloon} = $this->Component(
		'Balloon' => 'Balloon',
		-state => 'balloon', 
		-balloonposition => 'widget',
		-initwait => $this->{_tiptime},
		-background => $this->{_tipcolor})
		unless $this->{Balloon};
#
#	attach a balloon if tiptext requested
#
	$w->[DTF_IDX_TABTIP] = $tiptext;
	return $this->{Balloon}->attach($btn, -balloonmsg => $tiptext);
}
#
#	change tab's tip text
#
sub UpdateTabTip {
	my ($this, $w, $btn, $tiptext) = @_;

	return undef unless $this->{Balloon};
#
#	attach a balloon if tiptext requested
#
	$this->{Balloon}->detach($btn)
		if $w->[DTF_IDX_TABTIP];
	$w->[DTF_IDX_TABTIP] = $tiptext;
	return $this->{Balloon}->attach($btn, -balloonmsg => $tiptext);
}

#
#	remove a tooltip from the tab
#
sub RemoveTabTip {
	my ($this, $w, $btn) = shift;

	return 1 unless $this->{Balloon};

	$w->[DTF_IDX_TABTIP] = undef;
	return $this->{Balloon}->detach($btn);
}

sub current {
	shift->TabCurrent (@_);
}

sub add {
    my $this = shift;
#
#	make this Notebook compatible
#
    my $caption;
    $caption = shift
    	unless ($_[0]=~/^-(caption|tabcolor|raisecolor|tabtip|hidden|state|label|image|text)$/);
    my %args = @_;
	$caption = $args{-caption} unless $caption;
	return undef unless defined($caption);
    my $frame = $this->TabCreate(
        $caption,
        delete $args{'-tabcolor'},
        delete $args{'-raisecolor'},
        delete $args{'-image'},
        delete $args{'-label'},
        delete $args{'-raisecmd'},
       );
#
#	pick up any attributes we didn't process during creation
#
    $this->pageconfigure($caption, %args)
    	if ($frame && %args);
	return $frame;
}
#
#	turn off flashing tab
#
sub deflash {
	my ($this, $page) = @_;

	return undef 
		unless defined($this->{ClientHash}{$page});
	
    my $w = $this->{ClientList}[$this->{ClientHash}{$page}];    
	my $color = (defined($this->{Raised}) &&
		($w->[DTF_IDX_WIDGET] eq $this->{Raised})) ?
		$w->[DTF_IDX_RAISECOLOR] :
		$w->[DTF_IDX_COLOR];
	my $frame = $w->[DTF_IDX_FRAME];
	$frame->configure(-bg => $color),
	$frame->Subwidget('Button')->configure(
		-bg => $color, -activebackground => $color),
	$frame->afterCancel($w->[DTF_IDX_FLASH_ID]),
	$w->[DTF_IDX_FLASH_ID] = $w->[DTF_IDX_FLASHED] = 
		$w->[DTF_IDX_FLASH_TIME] = undef
		if $w->[DTF_IDX_FLASH_ID];
	return $this;
}
#
#	flash a tab
#
sub flash {
	my ($this, $page, %args) = @_;
	
	return undef 
		unless defined($this->{ClientHash}{$page});
	
    my $w = $this->{ClientList}[$this->{ClientHash}{$page}];
#
#	don't start new flash if we already are
#
    return $this if $w->[DTF_IDX_FLASH_ID];
	$args{-interval} = 300 unless $args{-interval};
	$args{-duration} = 5000 unless $args{-duration};
	
	$w->[DTF_IDX_FLASH_COLOR] = $args{-color} ||= 'blue';
	$w->[DTF_IDX_FLASH_INTVL] = $args{-interval};
	$w->[DTF_IDX_FLASH_TIME] = Tk::timeofday() + ($args{-duration}/1000);
	
	$w->[DTF_IDX_FLASH_ID] = $w->[DTF_IDX_FRAME]->repeat(
		$w->[DTF_IDX_FLASH_INTVL], 
		sub {
			my $color = (defined($this->{Raised}) &&
				($w->[DTF_IDX_WIDGET] eq $this->{Raised})) ?
				$w->[DTF_IDX_RAISECOLOR] :
				$w->[DTF_IDX_COLOR];
			my $frame = $w->[DTF_IDX_FRAME];
			$frame->afterCancel($w->[DTF_IDX_FLASH_ID]),
			$frame->configure(-bg => $color),
			$frame->Subwidget('Button')->configure(
				-bg => $color, -activebackground => $color),
			$w->[DTF_IDX_FLASH_ID] = $w->[DTF_IDX_FLASHED] = 
				$w->[DTF_IDX_FLASH_TIME] = undef,
			return 1
				if (Tk::timeofday() > $w->[DTF_IDX_FLASH_TIME]);

			$color = $w->[DTF_IDX_FLASH_COLOR] unless $w->[DTF_IDX_FLASHED];
			$frame->configure(-bg => $color);
			$frame->Subwidget('Button')->configure(
				-bg => $color, -activebackground => $color);
			$w->[DTF_IDX_FLASHED] = ! $w->[DTF_IDX_FLASHED];
			return 1;
		}
	);
	return $this;
}

sub raised {
	shift->TabCurrent (@_);
}
#
#	return caption of current raised widget
#
sub raised_name {
	my $this = shift;

	return undef unless $this->{Raised};
	my $clients = $this->{ClientList};
	foreach my $client (@$clients) {
		return $client->[DTF_IDX_CAPTION]
			if ($client->[DTF_IDX_WIDGET] eq $this->{Raised});
	}
    return undef;
}
#
#	Notebook compatible methods
#
sub pagecget {
	my ($this, $page, $option) = @_;

	return undef 
		unless (defined($this->{ClientHash}{$page}) &&
			defined($page_opts{$option}));
	
	return $page if ($option eq '-caption');

    my $w = $this->{ClientList}[$this->{ClientHash}{$page}];    
	return ($page_opts{$option}=~/^\d+/) ?
		$w->[$page_opts{$option}] :
		$w->[DTF_IDX_FRAME]->Subwidget('Button')->cget($page_opts{$option});
}

sub pageconfigure {
	my ($this, $page, %args) = @_;

	return undef 
		unless defined($this->{ClientHash}{$page});
#
#	we're forgiving here if they supply an option we don't
#	support
#
    my $w = $this->{ClientList}[$this->{ClientHash}{$page}];    
	my $btn = $w->[DTF_IDX_FRAME]->Subwidget('Button');
	foreach (keys %args) {
		next unless defined($page_opts{$_});

		if ($_ eq '-hidden') {
#
#	check if hiding the page
#
			if ($args{$_}) {
				next if $w->[DTF_IDX_HIDDEN];
				$this->TabHide($page);
			}
			else {
#
#	restore the tab if its hidden
#
				$this->TabReveal($page)
					if $w->[DTF_IDX_HIDDEN];
			}
			next;
		}
#
#	make sure we apply state to the close button too
#
		if ($_ eq '-state') {
		  if ($w->[DTF_IDX_FRAME]->Subwidget('CloseBtn')) {
		    $w->[DTF_IDX_FRAME]->Subwidget('CloseBtn')->configure(-state => $args{$_});
		  }
		  $btn->configure(-state => $args{$_});
		}
		next
			if ($_ eq '-state');

		$btn->configure($page_opts{$_} => $args{$_}), next
			unless ($page_opts{$_}=~/^\d+/);
#
#	create, update, or remove the button balloon
#
		if ($_ eq '-tabtip') {
			if ($w->[DTF_IDX_TABTIP]) {
				if (defined($args{$_})) {
					$this->UpdateTabTip($w, $btn, $args{$_});
				}
				else {
					$this->RemoveTabTip($w, $btn);
				}
			}
			else {	# no current tip, create one if requested
				$this->CreateTabTip($w, $btn, $args{$_})
					if $args{$_};
			}
			next;
		}

		$w->[$page_opts{$_}] = $args{$_};
#
#	update the button text; be sure to rotate if needed
#
		$btn->configure(
			-text => ($taborient{$this->{Side}}[DTF_ORIENT_DIRECTION] ? 
				$w->[DTF_IDX_LABEL] : RotateTabText($w->[DTF_IDX_LABEL])) ),
		next
			if ($_ eq '-label');
#
#	reconfig the button and tab colors as needed
#
		$btn->configure(-bg => $args{$_}),
		$w->[DTF_IDX_FRAME]->configure(-bg => $args{$_})
			if ((($_ eq '-tabcolor') && 
				((! defined($this->{Raised})) ||
					($w->[DTF_IDX_WIDGET] ne $this->{Raised}))) ||
				(($_ eq '-raisecolor') && 
					(defined($this->{Raised}) &&
					($w->[DTF_IDX_WIDGET] eq $this->{Raised}))));
	}
	1;
}

sub pages {
	return keys %{shift->{ClientHash}};
}

sub tiptime {
	my ($this, $time) = @_;

	return $this->{_tiptime}
		unless defined($time);
	$this->{_tiptime} = $time;
	return $this->{Balloon} ?
		$this->{Balloon}->configure(-initwait => $time) : 1;
}

sub tipcolor {
	my ($this, $color) = @_;

	return $this->{_tipcolor}
		unless defined($color);
	$this->{_tipcolor} = $color;
	return $this->{Balloon} ?
		$this->{Balloon}->configure(-background => $color) : 1;
}

sub font {
	shift->Font(@_);
}
#
#	programatically raise a tab using its caption
#
sub raise {
	my ($this, $Caption) = @_;
    return defined($this->{ClientHash}{$Caption}) ?
    	$this->TabRaise($this->{ClientList}[$this->{ClientHash}{$Caption}][DTF_IDX_WIDGET]) :
    	undef;
}
#
#	programatically remove a tab using its caption
#
sub delete {
	my ($this, $Caption) = @_;
	return defined($this->{ClientHash}{$Caption}) ?
		$this->TabRemove($Caption) : undef;
}
#
#	return a hash of our tabs keyed by caption, so the
#	app can e.g., attach a Balloon to them
#
sub tabs {
	my ($this) = @_;
	my $tabs = { };
	my $clients = $this->{ClientList};

	$tabs->{$_} = $clients->[$this->{ClientHash}{$_}][DTF_IDX_FRAME]
		foreach (keys %{$this->{ClientHash}});
	return $tabs;
}

sub tabside {
	my ($this, $side) = @_;
	
	return $this->{Side} unless defined($side);
#
#	if already populated, don't permit change
#
	return undef 
		unless ($side=~/^([ns][ew]?)|([ew][ns]?)$/i);
#
#	if already populated, don't permit change
#
	return undef 
		if $this->{PseudoTabs};

	$side = lc $side;
	$side .= 'w' if (($side eq 'n') || ($side eq 's'));
	$side .= 'n' if (($side eq 'e') || ($side eq 'w'));
	return $side if ($this->{Side} eq $side);

	my $oldside = $this->{Side};
	$this->{Side} = $side;
#
#	modify all the tabs to move their buttons and closers
#
	my $to = $taborient{$side};
	my $clients = $this->{ClientList};
	my $tab;
	my $padx = $this->cget(-tabpadx);
	my $pady = $this->cget(-tabpady);
	foreach (keys %{$this->{ClientHash}}) {
		$tab = $clients->[$this->{ClientHash}{$_}];
		my $btn = $tab->[DTF_IDX_FRAME]->Subwidget('Button');
		$btn->packForget;
		if ($tab->[DTF_IDX_FRAME]->Subwidget('CloseBtn')) {
#
#	repack close tab
#
			my $closer = $tab->[DTF_IDX_FRAME]->Subwidget('CloseBtn');
			$closer->packForget;
			$closer->configure(
       			-anchor => $to->[DTF_ORIENT_CLOSEANCHOR]);
			$closer->pack(
		       	-side => $to->[DTF_ORIENT_CLOSESIDE],
		       	-anchor => $to->[DTF_ORIENT_CLOSEANCHOR],
		        -expand => 0,
		        -fill => 'none',
		        -ipadx => 0,
		        -ipady => 0,
		        -padx => 1,
		        -pady => 1,
			);
		}
#
#	rotate button text if needed
#
		$btn->configure(-text => 
			($to->[DTF_ORIENT_DIRECTION] ? $tab->[DTF_IDX_LABEL] :
				RotateTabText($tab->[DTF_IDX_LABEL])))
			if defined($btn->cget(-text));
#
#	repack the button
#
	    $btn->pack(
	       	-side => $to->[DTF_ORIENT_BTNSIDE],
	       	-anchor => $to->[DTF_ORIENT_BTNANCHOR],
	        -expand => 0,
	        -fill => 'none',
	        -ipadx => 0,
	        -ipady => 0,
	        -padx => $padx,
	        -pady => $pady,
		);
#
#	record new button size
#
		$tab->[DTF_IDX_HEIGHT] = $to->[DTF_ORIENT_DIRECTION] ? 
			$btn->reqheight + (2 * $pady) :
			$btn->reqwidth + (2 * $padx);
		$tab->[DTF_IDX_WIDTH] = $to->[DTF_ORIENT_DIRECTION] ? 
			$btn->reqwidth + (2 * $padx) : 
			$btn->reqheight + (2 * $pady); 
	}
######################################################################
#
#	we must repack the major frame components for this to work;
#	but this process may have some undesirable consequences, and probably
#	requires that we do everything in a specific order...
#
######################################################################
#
#	get tab alignment info
#
	my ($tabside, $tabfill, $tabanchor, $tabsize, $clientside) =
		@{$tabalign{$side}};
#
#	unplace the pseudo tabs,
#	and remove their current border decorations
#	(do we dare to destroy here ???)
#
	foreach (@{$this->{PseudoTabs}}) {
		next unless $_;
		$_->placeForget();
		$_->destroy;
	}
	delete $this->{PseudoTabs};
#
#	repack the buttonframe
#
    $this->{ButtonFrame}->packForget;
    $this->{ClientFrame}->packForget;

    $this->{ButtonFrame}->configure($tabsize => 40);
	$this->{ButtonFrame}->pack(
        -anchor => $tabanchor,
        -side => $tabside,
        -fill => $tabfill,
	);
#
#	repack the client frame
#
	$this->{ClientFrame}->pack(
        -side => $clientside,
        -expand => 'true',
        -fill => 'both',
	);
#
#	prep for reconfig
#
	$this->{OldWidth} = $this->{ButtonFrame}->reqwidth();
	$this->{OldHeight} = $this->{ButtonFrame}->reqheight();
#
#	recreate our pseudotabs
#
#	push @{$this->{PseudoTabs}}, $this->PseudoCreate($_)
#		foreach (1..DTF_MAX_ROWS);
#
#	finally, redraw everyone
#
	$this->TabRedraw(1);
	return $oldside;
}

sub tabscroll {
	my ($this, $scroll) = shift;

	return $this->{Scrolled} unless defined($scroll);
	return 1 
		unless ($this->{Scrolled} ^ $scroll);
#
#	set to requested state and redraw
#
	$this->{Scrolled} = $scroll;
	return $this->TabRedraw();
}

sub tabclose {
	my ($this, $close) = @_;

	return $this->{Close} unless defined($close);
	return 1 unless ($this->{Close} || $close);

	my $clients = $this->{ClientList};

	if ($this->{Close} && (! $close)) {
#
#	remove close buttons from everything
#
		delete $this->{Close};
		
		$_->[DTF_IDX_FRAME]->Subwidget('CloseBtn')->packForget,
		$_->[DTF_IDX_FRAME]->Subwidget('CloseBtn')->Destroy
			foreach (@$clients);
	}
	elsif ($close && (! $this->{Close})) {
#
#	add close buttons to everything
#
 		$this->{Close} = ((ref $close) && (ref $close eq 'CODE')) ?
 			$close : \&TabRemove;

	    $_->[DTF_IDX_FRAME]->Component(
        	'Button' => 'CloseBtn',
        	-command => [ $this->{Close}, $this, $_->[DTF_IDX_CAPTION] ],
        	-anchor => 'ne',
        	-relief => 'raised',
        	-borderwidth => 1,
        	-takefocus => 1,
        	-padx => 0,
        	-pady => 0,
        	-image => $this->{CloseImage}
       	)->pack(
	       	-side => 'top',
	       	-anchor => 'ne',
	        -expand => 0,
	        -fill => 'none',
	        -ipadx => 0,
	        -ipady => 0,
	        -padx => 0,
	        -pady => 0,
	       )
			foreach (@$clients);
 	}
	else {
#
#	reconfig everyone's close button
#
 		$this->{Close} = ((ref $close) && (ref $close eq 'CODE')) ?
 			$close : \&TabRemove;
	    $_->[DTF_IDX_FRAME]->Subwidget('CloseBtn')->configure(
        	-command => [ $this->{Close}, $this, $_->[DTF_IDX_CAPTION] ])
			foreach (@$clients);
	}
	return $this->TabRedraw(1);
}
#
#	for left/right tabs, we must convert text into
#	vertical format
#
sub RotateTabText {
	my $text = shift;
	my @segments = split /\n/, $text;
	my $maxchars = 0;
	foreach (@segments) {
		$maxchars = length($_)
			if ($maxchars < length($_));
	}

	$segments[$_] .= (' ' x ($maxchars - length($segments[$_])))
		foreach (0..$#segments);

	my @lines = ('') x $maxchars;
	my @chars;
	foreach my $segment (@segments) {
		@chars = split('', $segment);
		$lines[$_] .= $chars[$_] . '  '
			foreach (0..$#chars);
	}
	return join("\n", @lines);
}

sub OnEnter {
	my ($widget, $Button, $TabFrame, $Color) = @_;

	$Button->configure(
		-bg => $Button->Darken($Button->cget(-bg), 90));
	$TabFrame->configure(
		-bg => $TabFrame->Darken($TabFrame->cget(-bg), 90));

	$TabFrame->bind('<Enter>' => undef);
	$TabFrame->bind('<Leave>' => undef);

	$Button->bind('<Enter>' => undef);
	$Button->bind('<Leave>' => undef);
}

sub OnLeave {
	my ($widget, $Button, $TabFrame) = @_;

#print "Leaving\n";

	$Button->configure(
		-bg => $Button->Darken($Button->cget(-bg), 110));
	$TabFrame->configure(
		-bg => $TabFrame->Darken($TabFrame->cget(-bg), 110));

	$TabFrame->bind('<Enter>' => [ \&OnEnter, $Button, $TabFrame ]);
	$TabFrame->bind('<Leave>' => undef);

	$Button->bind('<Enter>' => [ \&OnEnter, $Button, $TabFrame ]);
	$Button->bind('<Leave>' => undef);
}

sub OnFocusIn {
	my ($Button, $TabFrame) = @_;

print "FocusIn\n";

	$Button->configure(
		-bg => $Button->Darken($Button->cget(-bg), 90));
	$TabFrame->configure(
		-bg => $TabFrame->Darken($TabFrame->cget(-bg), 90));
}

sub OnFocusOut {
	my ($Button, $TabFrame) = @_;

print "FocusOut\n";

	$Button->configure(
		-bg => $Button->Darken($Button->cget(-bg), 110));
	$TabFrame->configure(
		-bg => $TabFrame->Darken($TabFrame->cget(-bg), 110));
}

1;

__END__

=pod

=head1 NAME

Tk::DynaTabFrame - A NoteBook widget with orientable, dynamically stacking tabs

=head1 SYNOPSIS

    use Tk::DynaTabFrame;

    $TabbedFrame = $widget->DynaTabFrame
       (
        -font => $font,
        -raisecmd => \&raise_callback,
        -raisecolor => 'green',
        -tabclose => sub { 
        	my ($dtf, $caption) = @_; 
        	$dtf->delete($caption);
        	},
        -tabcolor => 'yellow',
        -tabcurve => 2,
        -tablock => undef,
        -tabpadx => 5,
        -tabpady => 5,
        -tabrotate => 1,
        -tabside => 'nw',
        -tabscroll => undef,
        -textalign => 1,
        -tiptime => 600,
        -tipcolor => 'yellow',
        [normal frame options...],
       );

=begin html

<h2>Download</h2><p>
<a href='http://www.presicient.com/dynatabframe/Tk-DynaTabFrame-0.23.tar.gz'>
Tk-DynaTabFrame-0.23.tar.gz</a><p>

<h2>Screenshots</h2><p>
<img src='imgs/dtfnw.gif'><p>
<img src='imgs/dtfne.gif'><p>
<img src='imgs/dtfsw.gif'><p>
<img src='imgs/dtfse.gif'><p>
<img src='imgs/dtfwn.gif'><p>
<img src='imgs/dtfws.gif'><p>
<img src='imgs/dtfen.gif'><p>
<img src='imgs/dtfes.gif'><p>

=end html

=head1 DESCRIPTION

[ NOTE: This module was based on Tk::TabFrame...
but you probably can't tell it anymore ]

A notebook widget with orientable, dynamically rearranging tabs. 
When the containing window is resized, the tabs will either stack or 
unstack as needed to fit the enclosing widget's width(height). 
Likewise, when tabs are added or removed, the tabs will stack/unstack 
as needed.

Tabs may be placed either on the top (default), bottom, left, or right
side of the widget, and may be aligned to either the 
left (default) or right edge for top or bottom tabs, or to the
top or bottom edges for left or right tabs.

Tabs are added at the innermost row adjacent to the tabbed frame
at the alignment edge, and automatically become the "raised" tab 
when added.

Separate B<-tabcolor> and B<-raisecolor> options may be specified
for each tab. B<-tabcolor> is used for the tab if it is not the
raised tab, or if no B<-raisecolor> is specified. B<-raisecolor>
is used when the tab is raised.

A tab can be raised by either clicking on the tab; by 
using left and right keyboard arrows to traverse the tabbing order;
or programmatically via the B<raise()> method.

If L<-tabrotate|-tabrotate> is enabled, when a tab in a row other than the 
innermost frame-adjacent row is raised, all rows are rotated inward, 
with the current frame-adjacent rows wrapping to the outside, until 
the raised row becomes the innermost frame adjacent row. Disabling
L<-tabrotate|-tabrotate> will leave the raised tab in its current location (assuming
the containing window has not been resized; see the L<-tablock|-tablock>
option to lock down the tabs on resize events).

A small "close" button can be applied to the tabs via the B<-tabclose>
option. By default, clicking the close button will delete the 
tab and associated frame from the DynaTabFrame. If a coderef
is supplied as the B<-tabclose> value, then the coderef will be invoked 
instead.

Either text or images can be displayed in the tab, using either
the B<-image> or B<-label> page options. A future release will permit both
in a single tab. If neither is specified, then the page name 
value will be used.

A "flash" effect may be applied to a tab (i.e., switching between the
defined background color and a flash color at a specified interval) using 
the L<flash|flash>B<()> method. Flashing continues until either the 
L<deflash|deflash>B<()> method is called, the tab is raised manually or 
programmatically, or the specified flash duration expires.

A "tabtip" I<(aka balloon or tooltip)> may be attached to each tab 
that is displayed when the mouse hovers over the tab. The number of millseconds
between the mouse entering a tab, and the display of the tabtip is determined
by the L<-tiptime|-tiptime> option (default 450). The background color
of the tabtips can be set by the L<-tipcolor|-tipcolor> option (default
white). The text of each tabtip can be set, updated, or removed, either in 
the L<add|add>() method, or via L<pageconfigure|pageconfigure>(),
using the L<-tabtip|-tabtip> option. Note that a L<Tk::Balloon> widget
is not created for the DynaTabFrame widget until a L<-tiptime|-tiptime>,
L<-tipcolor|-tipcolor>, or L<-tabtip|-tabtip> is configured.

The widget takes all the options that a Frame does. In addition,
it supports the following options:

=over 4

=item B<-font>

Font for tab text.

=item B<-raisecmd>

Code ref invoked on a raise event; passed
the caption of the raised page. B<NOTE:>This behavior
is different than L<Tk::Notebook|Tk::Notebook>, which passes
the widget to the callback.

=item B<-raisecolor>

Sets the default raisecolor; overridden by B<add(-raisecolor)>
option. Default is current widget background color.

=item B<-tabclose>

Add small close button to each tab; if set to a coderef,
the coderef is invoked when the close button is pressed, 
and is passed both the Tk::DynaTabFrame object, and the 
caption of the associated tab. If set to a 'true' scalar 
value, invokes the L<delete|delete> method on the associated tab.
Default is no close button. When enabled with L<-tablock|-tablock> 
enabled, L<-tablock|-tablock> is silently ignored. 

=item B<-tabcolor>, B<-backpagecolor>

Sets the default tabcolor; overridden by the
L<add|add>B<(-tabcolor)> option. Default is current widget background 
color.

=item B<-tabcurve>

Curve to use for top corners of tabs; set to the number of pixels
of spacing between adjoining tab borders. Default 2; I<rarely needs
adjustement>.

=item B<-tablock>

Locks the resize of the tabs; when set to a true
value, the tabs will not be rearranged when the enclosing 
window is resized; default off (ie, tabs are rearranged
on resize). Silently ignored when L<-tabclose|-tabclose> is enabled.
Note that this options does not effect the tab raise event
behavior (tab rows rotate inward). See the L<-tabrotate|-tabrotate>
option to disable that behavior.

=item B<-tabpadx>

Padding on left and right of the tab contents

=item B<-tabpady>

Padding on top and bottom of the tab contents

=item B<-tabrotate>

When enabled (the default), when a tab is raised in a row other 
than the innermost, frame-adjacent row, tab rows are rotated inward
until the raised tab is frame adjacent. Disabling this option will
leave the raised tab's row at its current location until a resize event
occurs. (See L<-tablock|-tablock> to lock down tab locations
on resize events).

=item B<-tabside>

Side of notebook to align tabs; acceptable values:

	'nw' (default) - tabs on top, aligned to the left edge
	'ne' - tabs on top, aligned to the right edge
	'sw' - tabs on bottom, aligned to the left edge
	'se' - tabs on bottom, aligned to the right edge
	'en' - tabs on right, aligned to the top edge
	'es' - tabs on right, aligned to the bottom edge
	'wn' - tabs on left, aligned to the top edge
	'ws' - tabs on left, aligned to the bottom edge
	'n'  - same as 'nw'
	's'  - same as 'sw'
	'e'  - same as 'en'
	'w'  - same as 'wn'

B<Note:> can only be set or changed prior to adding any
pages; attempts to change the B<-tabside> after pages
have been added will be silently ignored.

=item B<-tabscroll> I<(not yet implemented)>

When set to a true value, causes tabs to be restricted to
a single row, with small arrow buttons placed at either end
of the row to permit scrolling the tabs into/out of the
window. When a tab is programmatically raised, the tabs will
be scrolled until the raised tab is visible.

=item B<-textalign>

Aligns text to the tab orientation. When enabled (i.e., set to
a 'true' scalar, the default), text in tabs is aligned to the 
tab orientation (i.e., top and bottom tabs have horizontal text, 
side tabs have vertical text). When disabled (i.e., set to undef or 0),
text will be vertical for top and bottom tabs, and horizontal for
side tabs.

=item B<-tipcolor>

Sets the background color of any tabtips (default white). 
Causes creation of a L<Tk::Balloon> widget if none yet exists.

=item B<-tiptime>

Sets the integer number of milliseconds to delay between the time 
the mouse enters a tab and the display of any defined tabtip. Default 450.
Causes creation of a L<Tk::Balloon> widget if none yet exists.

=back

=head2 Additional B<cget()> I<-options>

=over 4

=item  B<-current>, B<-raised>

Returns the currently raised frame.

=item  B<-raised_name>

Returns the page name of the currently raised frame

=item  B<-tabs>

Returns a hashref of the tab Button widgets,
keyed by the associated caption.

=back 

=head1 METHODS

The following methods may be used with a DynaTabFrame object in addition
to standard methods.

=over 4

=item B<add(>I<[ pageName, ]> I<options>B<)>

Adds a page with name I<pageName> (if provided) to the notebook. 
Returns an object of type B<Frame>. If no I<pageName> is supplied,
then the B<-caption> option value will be used. If neither is
provided, then the name is the string representation of the
created page's frame. Recognized I<options> are:

=back

=over 8

=item B<-caption>

Specifies the identifying name for the page. Also used for
the tab text if no B<-label> or B<-image> is specified.
If this option is specified, and the optional I<pageName> argument
is specified, I<pageName> overrides this option.

=item B<-hidden>

When set to a true value, causes the resulting tab to be hidden from
view; can later be set to a false value to force the tab to be
visible again.

=item B<-image>

Specifies an image to display on the tab of this page. The image
is displayed only if the B<-label> option is not specified.

=item B<-label>

Specifies the text string to display on the tab of this page.

=item B<-raisecmd>

Specifies a callback to be called whenever this page is raised
by the user. Overrides the widget-level B<-raisecmd> option only for
this tab. B<NOTE:> This option's behavior is different from the
L<Tk::Notebook|Tk::Notebook>, in that the callback is passed the name
of the page, rather than the widget.

=item B<-raisecolor>

Specifies the raised background color for the tab. Overrides
the widget-level B<-raisecolor> option for only this tab.

=item B<-tabcolor>

Specifies the unraised background color for the tab. Overrides
the widget-level B<-tabcolor/-backpagecolor> option for only this tab.

=item B<-tabtip>

Specifies the text of a tabtip to attach to the created tab.
Causes creation of a L<Tk::Balloon> widget if none yet exists.

=back

=over 4

=item B<deflash(>I<pageName>B<)>

Turns off flashing for the specified I<pageName>.

=item B<delete(>I<pageName>B<)>

Deletes the page identified by I<pageName>.

=item B<flash(>I<pageName>, I<options>B<)>

Flashes the tab for the specified I<pageName>. Flashing
continues until either the B<-duration> has expired,
the tab is raised (either by clicking the tab, or programmatically),
or L<deflash|deflash> is called on the page. I<options> include

=back

=over 8

=item B<-color>

Color to use for flashing. Flashing alternates between the
current L<-tabcolor|-tabcolor> (or L<-raisecolor|-raisecolor>
if the tab is raised), and this color. Default is 'blue'.

=item B<-interval>

Number of milliseconds between flashes. Default is 300.

=item B<-duration>

Duration of the flash in milliseconds. Default is 5000
(i.e., 5 secs).

=back

=over 4

=item B<pagecget(>I<pageName>, I<-option>B<)>

Returns the current value of the configuration option given by
I<-option> in the page given by I<pageName>. I<-option> may be any of
the values accepted in the L<add|add> method, plus the B<-state> option.

=item B<pageconfigure(>I<pageName>, I<-option>B<)>

Like configure for the page indicated by I<pageName>. I<-options> may
be any of the options accepted by the L<add|add> method, plus the
B<-state> option.

Note that configuring the L<-tabtip|-tabtip> option to C<undef>
will remove the tabtip from the page.

=item B<pages>

Returns a list consisting of the names of all currently defined
pages, i.e., those created with the B<add> method.

=item B<raise(>I<pageName>B<)>

Raise the page identified by I<pageName>. Returns
the Frame widget of the page.

=item B<raised()>, B<current()>

Returns the currently raised Frame widget. B<NOTE:> This method
behavior differs from the L<Tk::Notebook|Tk::Notebook>
method of the same, which returns the page name. Use the
L<raised_name|raised_name>() method to mimic Tk::Notebook behavior.

=item  B<raised_name()>

Returns the page name of the currently raised frame

=back

=head1 CAVEATS

B<Optional> horizontal scrolled frames (ie, 'os')
seem to cause some race conditions (Config events keep 
resizing the frame up, then down). Use mandatory scrollbars
if you need horizontal scrollbars.

Support for rotated text in left or right side tabs is lacking,
due to the lack of a consistent text rotation method in Perl/Tk. 
While the issue can be alleviated using the L<-textalign|-textalign> option, 
another possible solution may be either 
L<Tk::Win32RotLabel|> on Win32 platforms, or L<Tk::CanvasRottext|>
for *nix platforms. Unfortunately, vertical text is less than
aesthetically pleasing, and can consume a rather large vertical
area; using images with attached balloons may be a preferable
alternative.

As of v. 0.20, better compatibility with L<Tk::Notebook|Tk::Notebook> 
has been provided. However, DTF is not yet fully backward compatible, 
as some methods and options of the same name could not be changed from 
prior versions of DTF in order to preserve backward compatibility.

As of V 0.20, the maximum number of tab rows is 21. This arbitrary limit
is imposed due to odd behavior when redrawing the tabs on a resize event.
"Pseudo" tabs are used to provide the illusion of tabs embedded into
a frame-spanning row. If these pseudotabs are destroyed and recreated
during a resize event B<while the mouse button is still held down
on the window resizer>, the window will snap back to its original
dimensions when the new pseudotabs are B<place()'d>. The only solution 
seems to be to create a fixed number of pseudotabs at startup, and 
B<place()> them as needed during the redraw. Eventually, a widget
attribute may be added to specify the max number of rows to permit.

L<-tabclose|-tabclose> and L<-tablock|-tablock> are mutually exclusive; 
if both are enabled, L<-tablock|-tablock> will be silently ignored.

Using L<Tk::Compound|Tk::Compound> objects as tab images appears to
cause sizing and layout issues due to the object not reporting
its true full layout size; hence, they should be avoided.

=head1 TO DO

=over 4

=item Canvas based tabs

Currently tabs are drawn as frames with a button (plus optional
close button), and the text or image is added to the button. This
limits the layout of tabs to square boxes. By converting the 
ButtonFrame to a Canvas, and just building, binding, and moving objects on
the canvas when a redraw occurs, we can have a much more flexible
tab layout (image+text, nice curved tabs, etc.).

=item Configurable B<-tabclose> button

Currently, only a "close" button is implemented with
a fixed image. In future, the button image may be
configurable, e.g., set to a "minimize" image and
set a minimize callback for an MDI-type notebook.

=item Configurable B<-tabside>

B<configure(>I<-tabside>B<)> should be permitted after pages are added.

=item Rotated tab text using L<GD>

Newer versions of L<GD> provides better font support, with 90 degree
rotation. By using L<GD> to render and rotate the tab text as an image,
sideways text can be used in tabs as images.

=item Single row, scrolled tabs

Support for scrolling tabs, rather than stacking, should be added
with small arrow buttons added at either end of the tab row when
some tabs exist beyond the beginning/end of the row.

=back

=head1 AUTHORS

Dean Arnold		<darnold@presicient.com>

Portions of the POD derived from L<Tk::Notebook|Tk::Notebook>.

Initial code derived from L<Tk::TabFrame|Tk::TabFrame>, included
in Tk-DKW bundle by Damion K. Wilson.

Copyright(c) 2003-2005, Dean Arnold, Presicient Corp., USA. All rights reserved.

Portions Copyright(c) 1998-1999 Damion K. Wilson, all rights reserved. 

This code and documentation may be distributed under the same
conditions as Perl itself.

=head1 HISTORY 

=over 4

=item May 22, 2005 : Ver. 0.22

- added -hidden page option

- added -tiptime, -tipcolor global attributes

- added -tabtip page option

=item January 10, 2005 : Ver. 0.20

- added -tabclose

- added -tabside

- added -image attribute to add() to support images in tabs

- added -label attribute to add() to support alternate text in tabs

- fixed -raisecolor behavior to revert color of prior raised tab

- fixed "roaming" tab connector frame 

- code mods for performance

- added -tabcolor/-backpagecolor, -raisecolor widget level options

- added -raisecmd attribute to add() to support event callback

- added some Tk::Notebook drop-in compatibility (pagecget(),
pageconfigure(), pages(), raised())

- POD enhancements

- added -textalign

- added -tabrotate

- added flash(), deflash()

=item March 14, 2004    : Ver. 0.07

- added -raisecolor to set the color of a tab when raised

- increased ConfigDebounce width threshold for ptk804.025beta

=item January 16, 2004  : Ver. 0.06

- fixed programmatic raise

- added (simple) install test 

- added programmatic raise button to demo app

- added flash()

=item January 13, 2004  : Ver. 0.05

- added "pseudo-tabs" to backfill the space
between the right side of last tab in a row,
and the right side of the enclosing frame

=item January 6, 2004   : Ver. 0.04

- fixed TabRemove for remove from arbitrary position

- updated demo app to exersize arbitrary position removal

- fixed apparent timing issue with TabRemove and
resizing that caused occasional phantom client entries

=item January 5, 2004   : Ver. 0.03

- added raised_name() method/-raised_name property
to return caption of currently raised page

- fixed tab ordering on resize when raised tab
gets moved to other than bottom row

=item December 29, 2003 : Ver. 0.02

- improve raise behavior

- improve tab font behavior 
(use platform/application default when none specified)

- added tablock option

=item December 25, 2003 : Ver. 0.01

- Converted from Tk::TabFrame

=cut
