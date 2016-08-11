#!/usr/bin/perl -w
use MIME::QuotedPrint;
use HTML::Entities;
use Mail::Sendmail 0.75; # doesn't work with v. 0.74!

$boundary = "====" . time() . "====";

$text = "HTML mail demo\n\n"
      . "This is the message text\n"
      . "Voilà du texte qui sera encodé\n";

%mail = (
         from => 'rajeev.srivastava@gmail.com',
         to => 'rajeev.srivastava@gmail.com',
         subject => 'Test HTML mail',
         'content-type' => "multipart/alternative; boundary=\"$boundary\""
        );

$plain = encode_qp $text;

$html = encode_entities($text);
$html =~ s/\n\n/\n\n<p>/g;
$html =~ s/\n/<br>\n/g;
$html = "<p><strong>" . $html . "</strong></p>";

$boundary = '--'.$boundary;

$mail{body} = <<END_OF_BODY;
$boundary
Content-Type: text/plain; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

$plain

$boundary
Content-Type: text/html; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

<html>$html</html>
$boundary--
END_OF_BODY

sendmail(%mail) || print "Error: $Mail::Sendmail::error\n";
