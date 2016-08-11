#!/usr/bin/perl -w
# soapgui.cgi - Proton server GUI SOAP handler

use SOAP::Transport::HTTP;
use lib '/var/www/perl';

SOAP::Transport::HTTP::CGI
 -> dispatch_to('SoapGUI::(?:getLefLayers)')
 -> handle
;

