#!/usr/bin/perl
use POSIX qw/strftime/;
my ($auth_script, $app_script, $app_name, $out_file);
my $write_app_script = 0;

if(@ARGV < 8 || $ARGV[0] eq "-help" || $ARGV[0] eq "-h" || $ARGV[0] eq "-HELP"){
   print "Usage: ./app_auth_wrapper.pl -auth_script <auth_script>\n";
   print "                             -app_binary <app binary file path>\n";
   print "                             -app_name <app name>\n";
   print "                             -out < file name>\n";
}else{
   for(my $i=0; $i<=$#ARGV; $i++){
       if($ARGV[$i] eq "-auth_script"){$auth_script = $ARGV[$i+1];}
       if($ARGV[$i] eq "-app_binary"){$app_script = $ARGV[$i+1];}
       if($ARGV[$i] eq "-app_name"){$app_name = $ARGV[$i+1];}
       if($ARGV[$i] eq "-out"){$out_file = $ARGV[$i+1];}
   }

   my $build_date = strftime('%d-%b-%Y %H:%M:%S',localtime);

   open(WRITE_AUTH_APP, ">$out_file");
   open(READ_AUTH_SCRIPT, "$auth_script");
   READ_AUTH_LOOP: while(<READ_AUTH_SCRIPT>){
     chomp();
     if($write_app_script == 1){
        open(READ_APP_SCRIPT, "$app_script"); 
        while(<READ_APP_SCRIPT>){
          chomp();
          if($_ =~ /\/usr\/bin\/perl/){
          }elsif(($app_name eq "defViewer") && ($_ =~ /\&start_gui/)){ ##only for defviewer app
             print WRITE_AUTH_APP "\$SIG{'INT'} = 'INT_handler';\n\n";
             print WRITE_AUTH_APP "\&start_gui(1);\n\n";
             print WRITE_AUTH_APP "sub INT_handler {\n";
             print WRITE_AUTH_APP " my \$end_time = time;\n";
             print WRITE_AUTH_APP " my \$time_diff = \$end_time - \$start_time;\n";
             print WRITE_AUTH_APP " my \$end_time_result = \$server->call('end_time', \$userName,\$appName,int(\$run_count),\$end_time,\$time_diff);\n";
             print WRITE_AUTH_APP " print \"App run time is: \$time_diff\\n\";\n";
             print WRITE_AUTH_APP " exit(0);\n";
             print WRITE_AUTH_APP "}#sub INT_handler\n";
             last READ_AUTH_LOOP;
          }else{
             print WRITE_AUTH_APP "$_\n";
          }
        }
        close(READ_APP_SCRIPT);
        $write_app_script = 0;
     }elsif($_ =~ /test_app/){
        s/test_app/$app_name/;
        print WRITE_AUTH_APP "$_\n";
        print WRITE_AUTH_APP "print \"Build Date: $build_date\\n\"\;\n";
     }else{
        print WRITE_AUTH_APP "$_\n";
     }

     if($_ =~ /put script here/){
        $write_app_script = 1;
     } 
   }
   close(READ_AUTH_SCRIPT);
   close(WRITE_AUTH_APP);
}
system("chmod +x $out_file");
   

