#!/usr/bin/perl -w

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('Temperatures')
    -> handle;

package Temperatures;

  sub f2c {
      my ($class, $f) = @_;
      return 5/9*($f-32);
  }

  sub c2f {
      my ($class, $c) = @_;
      return 32+$c*9/5;
  }
