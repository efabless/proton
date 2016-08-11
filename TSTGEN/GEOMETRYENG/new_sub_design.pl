#!/usr/bin/perl 

use Getopt::Long;
my %subGraph;
&init;
&parseList;
&outGraph;

sub init {
  GetOptions (
	'subFile=s'	=> \$subFile,
	'gvizFile=s'	=> \$gvizFile,
	'graphName=s'   => \$graphName,
	'debug'		=> \$debug,
  );

  print("DBG-TST_GEOM : 001 : Subroutine Filename: $subFile\n") if ($debug);
  print("DBG-TST_GEOM : 002 : Graphviz Filename  : $gvizFile\n") if ($debug);
 }

sub parseList {
  open($hdlSubFile, "$subFile") or print("ERR-TST_GEOM : 001 : couldn't find $subFile\n");
  my $subLine = <$hdlSubFile>;
  my $subName = UNDEF;
  my $calledSubCnt = 0;
  while ($subLine ne "") {
    print $subLine if ($debug);
    if ($subLine =~ /^(\s*)(sub )(\w+)[\s+\n{]/) {#found new subreoutine definition
      $subName = $3;
      push (@{$subGraph{$subName}},"");
      print("DBG-TST_GEOM : 002 : Found new subroutine definition:$subName\n") if ($debug);
    }
    elsif ($subName && ($subLine =~ /^\s*\&(\w+)[\s+\n]/)) {#new called  - CHECK ;
      $calledSubName = $1;
      push (@{$subGraph{$subName}},$calledSubName);
      print("DBG-TST_GEOM : 003 : Found new called subroutine:$calledSubName\n") if ($debug);
    }
    elsif ($subName && ($subLine =~ /^\s*\}/)) {#end of subroutine
      print("DBG-TST_GEOM : 004 : End of subroutine definition:$subName\n") if ($debug);
      $subName = UNDEF;
      $calledSubCnt = 0;
    }
    
    $subLine = <$hdlSubFile>;
  }
}

sub outGraph {
  open($hdlGvizFile, ">$gvizFile") or print("ERR-TST_GEOM : 001 : couldn't find $gvizFile\n");
  
  #print header
  if ($graphName eq "") {$graphName = "graph1";}
  print $hdlGvizFile "digraph $graphName \{\n";
  print $hdlGvizFile "\trankdir=LR;\n";
  print $hdlGvizFile "\tsize=\"80,50\"\n";
  print $hdlGvizFile "\tnodesep=\"1\"\n";
  print $hdlGvizFile "\tratio=\"expand\"\n";
  print $hdlGvizFile "\tnode [shape = circle];\n";
  
  foreach $subName (keys %subGraph) {
    $str = "";
    $str.= "\t$subName -> ";
    foreach (@{$subGraph{$subName}}) {
       if ($_ ne "") {
         print $hdlGvizFile $str . $_ . ";\n";  
       }
    }
  }
  print $hdlGvizFile "}\n";
  close($hdlGvizFile);
}
