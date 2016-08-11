        

use GD::Graph::bars3d;
        my @data = ( 
           ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
           [ 1203,  3500,  3973,  2859,  3012,  3423,  1230]
        );
        my $graph = new GD::Graph::bars3d( 400, 300 );
        $graph->set( 
                x_label           => 'Day of the week',
                y_label           => 'Number of hits',
                title             => 'Daily Summary of Web Site',
        );
        my $gd = $graph->plot( \@data );
