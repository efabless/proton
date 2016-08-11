#!/usr/bin/perl -w
# servergui.cgi - Proton server GUI HTTP service

use lib '/var/www/perl';
require ServerGUI;

use CGI qw(param);

my $host = param('host');
my $port = param('port');
my @argv = ($host, $port);

my $cmd = param('cmd');

print "Content-type: text/xml\n\n";
if ( $cmd eq "getLefMacroList" ) {
  print ServerGUI::getLefMacroList(\@argv);
}
elsif ( $cmd eq "getLefMacroData" ) {
  my $macro = param('macro');
  print ServerGUI::getLefMacroData(\@argv, $macro);
}
elsif ( $cmd eq "getLefPins" ) {
  my $macro = param('macro');
  print ServerGUI::getLefPins(\@argv, $macro);
}
elsif ( $cmd eq "getLefMacroBulk" ) {
  my $macro = param('macro');
  print ServerGUI::getLefMacroBulk(\@argv, $macro);
}
elsif ( $cmd eq "getLefLayers" ) {
  print ServerGUI::getLefLayers(\@argv);
}
elsif ( $cmd eq "pingServerCGI" ) {
  print ServerGUI::pingServerCGI(\@argv);
}
else {
  print "<root><errmsg>Unknown GUI command</errmsg></root>";
}
