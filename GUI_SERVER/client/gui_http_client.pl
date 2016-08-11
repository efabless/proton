#!/usr/bin/perl -w -s
# gui_http_client.pl - Proton GUI HTTP client
# To override host and port: ./gui_http_client.pl -host=aditya -port=1200

use LWP::Simple;

if ( @ARGV == 0 ) {
  die "Host and port are optional. Command is required.\n" .
      "Example: ./gui_http_client.pl -host=aditya -port=1200 getLefLayers\n" .
      "         ./gui_http_client.pl -port=1208 getLefPins AND2X2\n";
}

my $cmd = shift;
my $macro = shift;

my $URL = "http://localhost/cgi-bin/servergui.cgi?cmd=$cmd";

if ( defined $macro ) {
  $URL .= '&macro=' . $macro;
}

if ( defined $host ) {
  $URL .= '&host=' . $host;
  print 'host = ' . $host . "\n";
}
else {
  print "host = (default)\n";
}

if ( defined $port ) {
  $URL .= '&port=' . $port;
  print 'port = ' . $port . "\n";
}
else {
  print "port = (default)\n";
}

print "\n- Calling the HTTP server with URL:\n  '$URL' ...\n\n";
print "- The HTTP server says:\n\n";

my $retval;

unless (defined ($retval = get $URL)) {
   die "Could not get $URL\n";
}
print '"' . $retval . "\"\n\n";
