
  my $data = GD::Graph::Data->new( 
    [ [ 'A', 'B', 'C' ], [ 1, 2, 3 ], [ 11, 12, 13 ] ]);
  my $values = $data->copy;
  $values->set_y(1, 1, undef);
  $values->set_y(2, 0, undef);

  $graph->set(show_values => $values);
  $graph->plot($data);
