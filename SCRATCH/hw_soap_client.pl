#!/usr/bin/perl -w
# hw_client.pl - Hello client
#use SOAP::Lite;
use SOAP::Lite +trace => qw(debug);
#use SOAP::WSDL;

my $input = shift;
if ( !defined $input || $input eq "" ) {
  $input = "Carlos";
#  $input2 = "Carlos";
}

print "\n- Calling the SOAP server to say hello...\n\n";
print "The SOAP server says: ";

my $retval;

# OK
#$retval = SOAP::Lite -> uri('urn:Hello')
#  -> proxy('http://localhost/cgi-bin/hello.cgi') -> sayHello($input) -> result;

# OK - plan_5 gsoap
$retval = SOAP::Lite
  -> proxy('http://192.168.2.7:5001/') -> uri('urn:calc');

my $som = $retval->call('invokePlan5', $input);
my $res = $som->result;


#my $wsdl = "http://localhost/cgi-bin/HelloService.wsdl";
#my $wsdl = "file:///var/www/wsdl/HelloService.wsdl";

#print "wsdl = " . $wsdl . "\n";

#my $service = SOAP::Lite->service($wsdl);

#print "service = " . $service . "\n";

#$retval = $service->sayHello($input)->result;

print '"' . $retval . "\"\n\n";
print '"' . $res . "\"\n\n";
