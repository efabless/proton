#!/usr/bin/perl -w

use SOAP::Lite;

print SOAP::Lite
    -> uri('http://divakar/Temperatures')
    -> proxy('http://divakar/cgi-bin/soapServer.pl')
    -> c2f(37.5)
    -> result;
