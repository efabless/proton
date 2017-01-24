#
# Module Copyright (C) 2000 Ed Hill
# Documentation Copyright (C) 2000 Tim Peoples
#
# Apache::XMLRPC is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: XMLRPC.pm,v 1.2 2000/11/09 01:36:34 kmacleod Exp $
#

package Apache::XMLRPC;

use Apache::Constants qw(:common);
use Frontier::RPC2;

sub handler {
   my $r = shift;

   my $conf = $r->server_root_relative( $r->dir_config( "XMLRPC_Config" ) );

   if( -f $conf ) {
      unless( $rt = do $conf ) {
         die "Couldn\'t parse conf file ($conf): $@\n"   if $@;
         die "Couldn\'t compile conf file ($conf): $!\n" unless defined $rt;
         die "Couldn\'t run conf file ($conf)\n"         unless $rt;
      }
   }

   my $decoder = Frontier::RPC2->new();

   my $content;
   $r->read( $content, $r->header_in( 'Content-length' ) );

   my $answer = $decoder->serve( $content, $Apache::XMLRPC::map );

   $r->send_http_header();
   $r->print($answer);

   return OK;
}

1;

__END__

=head1 NAME

Apache::XMLRPC - serve XML-RPC requests from Apache

=head1 SYNOPSIS

   ##
   ##  Directives for your Apache config file.
   ##
   <Location /RPC2>
      SetHandler perl-script
      PerlHandler Apache::XMLRPC
      PerlSetVar XMLRPC_Config /usr/local/apache/xml-rpc/services
   </Location>


   ##
   ##  In the 'services' file referenced above by 'XMLRPC_Config'
   ##
   sub foo {
      ...
   }

   sub bar {
      ...
   }

   $map = {
      foo   => \&foo,
      bar   => \&bar,
   };

   1;

=head1 DESCRIPTION

I<Apache::XMLRPC> serves Userland XML-RPC requests from Apache/mod_perl
using the Frontier::RPC2 module.

Configuring Apache::XMLRPC to work under mod_perl is a two step process.
First, you must declare a C<E<lt>LocationE<gt>> directive in your Apache
configuration file which tells Apache to use the content handler found in
the Apache::XMLRPC module and defines a variable which tells the module
where to find your services.  Then, you must define the services.

=head2 Apache Configuration

Apache configuration is as simple as the C<E<lt>LocationE<gt>> directive
shown in the synopsis above.  Any directive allowed by Apache inside a
C<E<lt>LocationE<gt>> block is allowed here, but the three lines shown
above are required.  Pay close attention to the 'PerlSetVar XMLRPC_Config
...' line as this is where you tell Apache where to find your services.
This file may reside anywhere accessable by Apache.

=head2 Defining Services

To actually define the XML-RPC routines that will be served, they I<must>
reside in the file referenced by the 'PerlSetVar XMLRPC_Config ...'
directive in the Apache configuration file.  In this file you may place
as many Perl subroutines as you like, but only those which are explicitly
published will be available to your XML-RPC clients.

To I<publish> a subroutine, it must be included in the hash reference
named C<$map> (the hash reference I<must> have this name as this is the
variable that the I<Apache::XMLRPC> passes to I<Frontier::RPC2::serve>
to actually service each request) The hash reference I<must> be defined
in this C<services> file.

The keys of the hash are the service names visible to the XML-RPC clients
while the hash values are references to the subroutines you wish to make
public.  There is no requirement that the published service names match
those of their associated subroutines, but it does make administration
a little easier.

=head1 SEE ALSO

perl(1), Frontier::RPC2(3)

E<lt>http://www.scripting.com/frontier5/xml/code/rpc.htmlE<gt>

=head1 AUTHOR

Ed Hill E<lt>ed-hill@uiowa.eduE<gt> is the original author.

Tim Peoples E<lt>tep@colltech.comE<gt> added a few tweaks and all
the documenation.
