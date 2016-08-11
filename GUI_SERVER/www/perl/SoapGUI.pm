# SoapGUI.pm - module for talking to Proton daemon
package SoapGUI;

use Frontier::Client;

my $server;

sub getLefLayers {

  shift;  # remove class name
  my $host = shift;
  my $port = shift;

  unless ( defined $server ) {
    &connectToDaemon();
  }

  return $server->call('serGetLefLayers');
}

sub connectToDaemon {

  my $host = shift;
  my $port = shift;

  if ( $host eq "" ) {
    $host = '192.168.20.20';
  }
  if ( $port eq "" ) {
    $port = 1200;
  }

  my $server_url = "http://$host:$port/RPC2";
  $server = Frontier::Client->new(url => $server_url);
}

1;
