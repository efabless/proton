 use Qt;
 my $a = Qt::Application(\@ARGV);
 my $hello = Qt::PushButton("Hello World!", undef);
 $hello->resize(160, 25);
 $a->setMainWidget($hello);
 $hello->show;
 exit $a->exec;
