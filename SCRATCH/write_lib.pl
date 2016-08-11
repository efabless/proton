#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;

use liberty;

my $noOfArguments = @ARGV;
my $input_file = "";
my $output_file = "";
my $x = 11;

if($noOfArguments < 2 || $ARGV[0] eq '-h'|| $ARGV[0] eq '-help'){
   print "Usage : ./write_lib.pl -genlib <input file>\n";
   print "                       -lib <output file (default file name will be library name)>\n";
}else{
   for(my $x = 0; $x < $noOfArguments; $x++){
       if($ARGV[$x] eq "-genlib"){ $input_file = $ARGV[$x+1];}
       if($ARGV[$x] eq "-lib"){ $output_file = $ARGV[$x+1];}
   }#foreach arg

   #$pi = liberty::si2drPIInit(\$x)
   liberty::si2drPIInit(\$x);

   my @index_1 = ();  
   my @index_2 = ();  
   my @in_index_1 = ();
   my @in_index_2 = ();
   my $rel_pin = "";
   my $cond = "";
   my $sdf_cond = "";
   my $timing_type = "";
   my $timing_sense = "";
   my $cell_rise_found = 0;

   open (READ, "$input_file");
   while(<READ>){
     chomp();
     $_ =~ s/^\s+//;
     if($_ =~ /^LIBNAME\s+/) { 
        my $lib_name = (split(/\s+/,$_))[1];
        if($output_file eq ""){ $output_file = $lib_name.".lib"}

        $group1 = liberty::si2drPICreateGroup($lib_name, "library", \$x);
        #liberty::si2drGroupSetComment($group1, "Copyright 2011 by Silverline Design Inc.", \$x);
        my $attr = liberty::si2drGroupCreateAttr($group1, "delay_model", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, "table_lookup", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1, "in_place_swap_mode", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr1, "match_footprint", \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1, "revision", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr2, "1.12", \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1, "date", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr3, "Friday April 01 14:54:29 2011", \$x);

        my $attr4 = liberty::si2drGroupCreateAttr($group1, "comment", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr4, "Copyright 2011 by Silverline Design Inc.", \$x);

        my $attr5 = liberty::si2drGroupCreateAttr($group1, "time_unit", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr5, "1ns", \$x);

        my $attr6 = liberty::si2drGroupCreateAttr($group1, "voltage_unit", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr6, "1V", \$x);

        my $attr7 = liberty::si2drGroupCreateAttr($group1, "current_unit", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr7, "1uA", \$x);

        my $attr8 = liberty::si2drGroupCreateAttr($group1, "pulling_resistance_unit", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr8, "1kohm", \$x);

        my $attr9 = liberty::si2drGroupCreateAttr($group1, "leakage_power_unit", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr9, "1nW", \$x);

        $group1_2 = liberty::si2drGroupCreateGroup($group1,"delay_template", "lu_table_template", \$x);

        my $attr10 = liberty::si2drGroupCreateAttr($group1_2, "variable_1", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr10, "input_net_transition", \$x);

        my $attr11 = liberty::si2drGroupCreateAttr($group1_2, "variable_2", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr11, "total_output_net_capacitance", \$x);

     }elsif($_ =~ /^GATE\s+/) { 
        my $cell_name = (split(/\s+/,$_))[1];
        $group1_1 = liberty::si2drGroupCreateGroup($group1,$cell_name, "cell", \$x);

     }elsif($_ =~ /^index_1\s+/){
        @index_1 = split(/\s+/,$_);
        shift @index_1;
        my $attr = liberty::si2drGroupCreateAttr($group1_2, "index_1 ", $liberty::SI2DR_COMPLEX, \$x);
        my $ind_1 = join ", " ,@index_1;
        liberty::si2drComplexAttrAddStringValue($attr, $ind_1, \$x);

     }elsif($_ =~ /^index_2\s+/){
        @index_2 = split(/\s+/,$_);
        shift @index_2;
        my $attr = liberty::si2drGroupCreateAttr($group1_2, "index_2 ", $liberty::SI2DR_COMPLEX, \$x);
        my $ind_2 = join ", " ,@index_2;
        liberty::si2drComplexAttrAddStringValue($attr, $ind_2, \$x);

     }elsif($_ =~ /^PIN\s+/){
        my ($pin, $dir) = (split(/\s+/,$_))[1,3];

        $group1_1_1 = liberty::si2drGroupCreateGroup($group1_1,$pin, "pin", \$x);  
        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "direction", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $dir, \$x);
        $cell_rise_found = 0;
        $rise_cons_found = 0;

        ##my $d = liberty::si2drCreateExpr($liberty::SI2DR_EXPR_VAL,\$x);
        #my $d = liberty::si2drCreateStringValExpr($dir,\$x);
        #print "$pin | dir : $dir , $d , $attr \n";
        #liberty::si2drSimpleAttrSetExprValue($attr, $d, \$x);

     }elsif($_ =~ /^output\s+/){
        my @out = split(/\s+/,$_);
        shift @out;
        $_ = "I".$_ foreach @out;
        my $out_str = join ",",@out;
        $group1_1_1 = liberty::si2drGroupCreateGroup($group1_1,$out_str, "ff", \$x);  

     }elsif($_ =~ /^in_index_1\s+/){
        @in_index_1 = split(/\s+/,$_);
        shift @in_index_1;

     }elsif($_ =~ /^in_index_2\s+/){
        @in_index_2 = split(/\s+/,$_);
        shift @in_index_2;

     }elsif($_ =~ /^function\s+/){
        my $function = (split(/\:/,$_))[1];
        $function =~ s/^\s+//;

        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "function", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $function, \$x);

     }elsif($_ =~ /^clocked_on\s+/){
        my $clocked_on = (split(/\s+/,$_))[1];

        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "clocked_on", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $clocked_on, \$x);

     }elsif($_ =~ /^input\s+/){
        my $next_state = (split(/\s+/,$_))[1];

        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "next_state", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $next_state, \$x);

     }elsif($_ =~ /^reset\s+/){
        my $clear = (split(/\s+/,$_))[1];

        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "clear", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $clear, \$x);

     }elsif($_ =~ /^clock\s+/){
        my $clk_val = (split(/\s+/,$_))[1];

        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "clock", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $clk_val, \$x);

     }elsif($_ =~ /^related_pin\s+/){
        $rel_pin = (split(/\s+/,$_))[1];
        $cell_rise_found = 0;
        $rise_cons_found = 0;

     }elsif($_ =~ /^condition\s+/){
        $cond = (split(/\:/,$_))[1];
        $cond =~ s/^\s+//;

     }elsif($_ =~ /^sdf_cond\s+/){
        $sdf_cond = (split(/\:/,$_))[1];
        $sdf_cond =~ s/^\s+//;

     }elsif($_ =~ /^timing_type\s+/){
        $timing_type = (split(/\:/,$_))[1];
        $timing_type =~ s/^\s+//;

     }elsif($_ =~ /^timing_sense\s+/){
        $timing_sense = (split(/\:/,$_))[1];
        $timing_sense =~ s/^\s+//;

     }elsif($_ =~ /^cell_rise\s+/){
        my @rise_delay = split(/\s+/,$_);
        $cell_rise_found = 1;
        $group1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1, "", "timing", \$x);
        if($rel_pin ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "related_pin", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $rel_pin, \$x);
        }
        if($cond ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "when", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $cond, \$x);
           $cond = "";
        }
        if($sdf_cond ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "sdf_cond", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $sdf_cond, \$x);
           $sdf_cond = "";
        }
        if($timing_type ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "timing_type", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $timing_type, \$x);
           $timing_type = "";
        }
        if($timing_sense ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "timing_sense", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $timing_sense, \$x);
           $timing_sense = "";
        }
        $group1_1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1_1, "delay_template" , "cell_rise", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_1 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_2 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "values ", $liberty::SI2DR_COMPLEX, \$x);
        shift @rise_delay;
        for(my $i=0; $i<$#rise_delay; $i=($i+$#index_2+1)){
           my @new_rise_delay = ();
           for(my $j=$i; $j<($i+$#index_2+1); $j++){
              push(@new_rise_delay, $rise_delay[$j])
           }
           my $rise_del = join ", ",@new_rise_delay;
           liberty::si2drComplexAttrAddStringValue($attr3, $rise_del, \$x);
        }

     }elsif($_ =~ /^rise_transition\s+/){
        my @rise_trans = split(/\s+/,$_);

        $group1_1_1_1_2 = liberty::si2drGroupCreateGroup($group1_1_1_1, "delay_template" , "rise_transition", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_2, "index_1", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_2, "index_2", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_2, "values", $liberty::SI2DR_COMPLEX, \$x);
        shift @rise_trans;
        for(my $i=0; $i<$#rise_trans; $i=($i+$#index_2+1)){
           my @new_rise_trans = ();
           for(my $j=$i; $j<($i+$#index_2+1); $j++){
              push(@new_rise_trans, $rise_trans[$j])
           }
           my $rise_tra = join ", ",@new_rise_trans;
           liberty::si2drComplexAttrAddStringValue($attr3, $rise_tra, \$x);
        }

     }elsif($_ =~ /^cell_fall\s+/){
        my @fall_delay = split(/\s+/,$_);
        if($cell_rise_found == 0){
           $group1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1, "", "timing", \$x);
           if($rel_pin ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "related_pin", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $rel_pin, \$x);
           }
           if($cond ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "when", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $cond, \$x);
              $cond = "";
           }
           if($sdf_cond ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "sdf_cond", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $sdf_cond, \$x);
              $sdf_cond = "";
           }
           if($timing_type ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "timing_type", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $timing_type, \$x);
              $timing_type = "";
           }
           if($timing_sense ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "timing_sense", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $timing_sense, \$x);
              $timing_sense = "";
           }
        } 
        $group1_1_1_1_3 = liberty::si2drGroupCreateGroup($group1_1_1_1, "delay_template", "cell_fall", \$x);
 
        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_3, "index_1", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_3, "index_2", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_3, "values", $liberty::SI2DR_COMPLEX, \$x);
        shift @fall_delay;
        for(my $i=0; $i<$#fall_delay; $i=($i+$#index_2+1)){
           my @new_fall_delay = ();
           for(my $j=$i; $j<($i+$#index_2+1); $j++){
              push(@new_fall_delay, $fall_delay[$j])
           }
           my $fall_del = join ", ",@new_fall_delay;
           liberty::si2drComplexAttrAddStringValue($attr3, $fall_del, \$x);
        }

     }elsif($_ =~ /^fall_transition\s+/){
        my @fall_trans = split(/\s+/,$_);

        $group1_1_1_1_4 = liberty::si2drGroupCreateGroup($group1_1_1_1, "delay_template", "fall_transition", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_4, "index_1", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_4, "index_2", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_4, "values", $liberty::SI2DR_COMPLEX, \$x);
        shift @fall_trans;
        for(my $i=0; $i<$#fall_trans; $i=($i+$#index_2+1)){
           my @new_fall_trans = ();
           for(my $j=$i; $j<($i+$#index_2+1); $j++){
              push(@new_fall_trans, $fall_trans[$j])
           }
           my $rise_tra = join ", ",@new_fall_trans;
           liberty::si2drComplexAttrAddStringValue($attr3, $rise_tra, \$x);
        }

     }elsif($_ =~ /^rise_constraint\s+/){
        my @rise_constraint = split(/\s+/,$_);
        $rise_cons_found = 1;
        $group1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1, "", "timing", \$x);
        if($rel_pin ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "related_pin", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $rel_pin, \$x);
        }
        if($timing_type ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "timing_type", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $timing_type, \$x);
        }
        my $template = "";
        if($timing_type eq "setup_rising"){$template = "setup_template"}
        if($timing_type eq "hold_rising"){$template = "hold_template"}
        if($timing_type eq "recovery_rising"){$template = "recovery_template"}
        $group1_1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1_1, $template , "rise_constraint", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_1 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@in_index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_2 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@in_index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "values ", $liberty::SI2DR_COMPLEX, \$x);
        shift @rise_constraint;
        for(my $i=0; $i<$#rise_constraint; $i=($i+$#in_index_2+1)){
           my @new_rise_cons = ();
           for(my $j=$i; $j<($i+$#in_index_2+1); $j++){
              push(@new_rise_cons, $rise_constraint[$j])
           }
           my $rise_cons = join ", ",@new_rise_cons;
           liberty::si2drComplexAttrAddStringValue($attr3, $rise_cons, \$x);
        }

     }elsif($_ =~ /^fall_constraint\s+/){
        my @fall_constraint = split(/\s+/,$_);
        if($rise_cons_found == 0){
           $group1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1, "", "timing", \$x);
           if($rel_pin ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "related_pin", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $rel_pin, \$x);
           }
           if($timing_type ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "timing_type", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $timing_type, \$x);
           }
        }
        my $template = "";
        if($timing_type eq "setup_rising"){$template = "setup_template"}
        if($timing_type eq "hold_rising"){$template = "hold_template"}
        if($timing_type eq "recovery_rising"){$template = "recovery_template"}
        $group1_1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1_1, $template , "fall_constraint", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_1 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@in_index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_2 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@in_index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "values ", $liberty::SI2DR_COMPLEX, \$x);
        shift @fall_constraint;
        for(my $i=0; $i<$#fall_constraint; $i=($i+$#in_index_2+1)){
           my @new_fall_cons = ();
           for(my $j=$i; $j<($i+$#in_index_2+1); $j++){
              push(@new_fall_cons, $fall_constraint[$j])
           }
           my $fall_cons = join ", ",@new_fall_cons;
           liberty::si2drComplexAttrAddStringValue($attr3, $fall_cons, \$x);
        }

     }else{next;}
   }#while reading 
   close READ;
   liberty::si2drWriteLibertyFile($output_file, $group1, \$x);
   liberty::si2drPIQuit(\$x);
}#if correct num of arg

my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "write_lib script took:",timestr($td),"\n";

