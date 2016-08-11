# ServerGUI::pm - module for talking to Proton daemon
package ServerGUI;

use Frontier::Client;

my $DEFAULT_HOST = '192.168.20.20';
my $DEFAULT_PORT = 1200;

my $server;

# ======================================================================
#  List of commands
# ======================================================================

sub getLefMacroList {
  my $argv = shift;
  return &sendGUIServerRPC($argv, 'flxGetLefMacroList');
}# sub getLefMacroList

sub getLefMacroData {
  my $argv = shift;
  return &sendGUIServerRPC($argv, 'flxGetLefMacroData', @_);
}# sub getLefMacroData

sub getLefPins {
  my $argv = shift;
  return &sendGUIServerRPC($argv, 'flxGetLefPins', @_);
}# sub getLefPins

sub getLefMacroBulk {
  my $argv = shift;
  return &sendGUIServerRPC($argv, 'flxGetLefMacroBulk', @_);
}# sub getLefMacroBulk

sub getLefLayers {
  my $argv = shift;
  return &sendGUIServerRPC($argv, 'flxGetLefLayers');
}# sub getLefLayers

sub pingServerCGI {
  my $argv = shift;
  my ($host, $port) = @{$argv};
  return "<root><errmsg><host>" . $host . "</host><port>" . $port .
         "</port></errmsg></root>";
}# sub getLefLayers


# ======================================================================
#  Server connection
# ======================================================================
sub sendGUIServerRPC {
  my $argv = shift;
  my ($host, $port) = @{$argv};
  my $rpcarg = join(', ', @_);

  # connect to daemon
  unless ( defined $server ) {
    unless ( defined $host ) { $host = $DEFAULT_HOST; }
    unless ( defined $port ) { $port = $DEFAULT_PORT; }
    my $server_url = "http://$host:$port/RPC2";
    $server = Frontier::Client->new(url => $server_url);
    # always returns something, cannot tell success or failure
  }

  my $connect = '$server->call(' . $rpcarg . ')';
  my $result = eval($connect);
  if ( $@ ) {   # error exception handler
    my $errmsg = "<root><errmsg>Remote call '" . $rpcarg . "' to server ";
    $errmsg .= "'$host' at port '$port' failed. ";
    $errmsg .= "Error: '" . $@ . "'</errmsg></root>";
    return $errmsg;
  }
  return $result;

}# sub sendGUIServerRPC

1;
