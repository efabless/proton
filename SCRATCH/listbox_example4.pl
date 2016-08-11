#!/usr/bin/perl
use strict;
use Tk;
use Tk::HList;
use Tk::BrowseEntry;

my $mw = MainWindow->new;

# Mainwindow: sizex/y, positionx/y
$mw->geometry("500x200+100+120");

# Default value
&create_datagrid($mw);
MainLoop;

sub create_datagrid {
    my $mother = shift;

    my @headers = ( "Financial status", "Name", "City", "Phone" );
    my @customers = (
        [ 'bad',  'Richard', 'Nuernberg', '123' ],
        [ 'good', 'Roland',  'Fuerth',    '586' ],
        [ 'fair', 'Peter',   'Zirndorf',  '933' ],
    );

    # Create dropdown to choose customer
    my $dropdown_value;
    my $dropdown = $mother->BrowseEntry(
        -label    => "Choose Customer",
        -variable => \$dropdown_value,
    )->grid(
	    -column => 0, -row => 0,
    		-sticky => 'n');
    # Populate dropdown with values
    foreach ( @customers ) {
        $dropdown->insert( 
		'end', 
		# value is the name of the customer
		$_->[1],
	);
    }

    my $grid = $mother->Scrolled(
        'HList',
        -head       => 1,
        -column    => scalar @headers,
        -scrollbars => 'e',
        -width      => 40,
        -height     => 10,
        -background => 'white',
    )->grid(-col => 1, -row => 0,
      );

    my @headers = ( "Financial status", "Name", "City", "Phone" );
    foreach my $x ( 0 .. $#headers ) {
        $grid->header(
            'create',
            $x,
            -text             => $headers[$x],
            -headerbackground => 'gray',
        );
    }

    foreach my $row_number ( 0 .. $#customers ) {
	my $unique_rowname = $customers[$row_number]->[1];
        $grid->add($unique_rowname);
        foreach my $x ( 0 .. 3 ) {
            $grid->itemCreate( $unique_rowname, $x,
                -text => $customers[$row_number]->[$x] );

            # You can change gridcontent later
            $grid->itemConfigure( $unique_rowname, $x, -text => "don't care" )
              if rand > 0.5 and $x == 0;
        }
    }

    # Set the default selection, the name of the last customer
    my $unique_rowname = $customers[-1]->[1];
    $grid->selectionSet($unique_rowname);

    # Set the initial value for the dropdown
    # i.e. the last customer
    $dropdown_value = $customers[-1]->[1];
    
    # Configure dropdown what to do when sth is selected
    $dropdown->configure(
        # What to do when an entry is selected
        -browsecmd => sub {
            foreach ( 0 .. $#customers) {
		    # $grid->selectionClear( $customers[$_]->[1] );
		    $grid->selectionClear();
		}
            $grid->selectionSet( $dropdown_value );
        },
    );




}
