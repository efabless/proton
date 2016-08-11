#!/usr/bin/perl -w 


  package MyParser;
  use Verilog::Parser;
  @ISA = qw(Verilog::Parser);

  # parse, parse_file, etc are inherited from Verilog::Parser
  sub new {
      my $class = shift;
      #print "Class $class\n";
      my $self = $class->SUPER::new();
      bless $self, $class;
      return $self;
  }

  sub symbol {
      my $self = shift;
      my $token = shift;

      $self->{symbols}{$token}++;
  }

  sub report {
      my $self = shift;

      foreach my $sym (sort keys %{$self->{symbols}}) {
         printf "Symbol %-30s occurs %4d times\n",
         $sym, $self->{symbols}{$sym};
      }
  }

  package main;

  my $parser = MyParser->new();
  $parser->parse_file (shift);
  $str = $parser->unreadback();
   print "$str\n";
  $parser->report();

