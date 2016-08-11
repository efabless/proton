#!/usr/bin/perl -w
  
  use SOAP::Lite;

  my $soap = SOAP::Lite
    -> uri('ftp://anshuman.benarasdesign.com/Temperatures')
    -> proxy('ftp://anshuman.benarasdesign.com/home/rajeevs/Projects/proton/SCRATCH/temper.cgi');

  my $temperatures = $soap
    -> call(new => 100) # accept Fahrenheit  
    -> result;

  print $soap
    -> as_celsius($temperatures)
    -> result;
