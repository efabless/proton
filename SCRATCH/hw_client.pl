#!/usr/bin/perl -w
# hw_client.pl - Hello client
use SOAP::Lite;

my $name = shift;

print "\n- Calling the SOAP server to say hello...\n\n";
print "The SOAP server says: ";
print '"' .SOAP::Lite
  -> uri('urn:Hello')
  -> proxy('http://localhost/cgi-bin/hello.cgi')
  -> sayHello($name)
  -> result . "\"\n\n";

