#!/usr/bin/perl -w

require Parallel::Pvm ;

        ($info,@conf) = Parallel::Pvm::conf ;
          foreach $node (@conf){
           print "host id = $node->{'hi_tid'}\n";
           print "host name = $node->{'hi_name'}\n";
           print "host architecture = $node->{'hi_arch'}\n";
           print "host speed = $node->{'hi_speed'}\n";
          }
