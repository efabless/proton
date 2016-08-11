#!/usr/bin/perl -w -s
# gui_client.pl - Proton GUI client
# To override host and port: ./gui_client.pl -host=aditya -port=1200

use SOAP::Lite;

print 'host = ' . (defined $host ? $host : '(default)') . "\n";
print 'port = ' . (defined $port ? $port : '(default)') . "\n";

print "\n- Calling the SOAP server to get layers ...\n\n";
print "The SOAP server says:\n\n";

my $retval = SOAP::Lite -> uri('urn:SoapGUI')
  -> proxy('http://localhost/cgi-bin/soapgui.cgi')
  -> getLefLayers($host, $port)
  -> result;

print '"' . $retval . "\"\n\n";
