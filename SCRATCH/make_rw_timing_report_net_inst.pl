#!/usr/bin/perl -w
#require "make_Timing_Report_package";
require "make_Timing_Report_NET_INST_package";
#&read_report_timing("-s_mtrx z8_nex3_z8_nrw_z8_nrw_reg_NRW_RWA_REG_data_out_reg_0q_31d.rpt");
#&read_report_timing("-f z8_nex3_z8_nrw_z8_nrw_reg_NRW_RWA_REG_data_out_reg_0q_31d.rpt");
&read_report_timing("-f test.rpt");
#&read_report_timing("-f t");
&write_rpt_timing;

sub read_report_timing {
my $noOfArguments = @_;
if ( $noOfArguments < 1 ) {print "Usage: read_report_timing -f <input file>\n";
                           print "                          -s_mtrx <input file>\n";
                          }#if
else {
      my $input_file = 0;
      my $smtrx_file = 0;
  	for ( my $x = 0 ; $x < $noOfArguments ; $x++ ) {
  	      if($_[$x] =~ /-f/) {$INPUTREPORTFILE = (split(/\s+/,$_[$x]))[1];$input_file = 1;}
  	      if($_[$x] =~ /-s_mtrx/) {$S_MATRIX = (split(/\s+/,$_[$x]))[1];$smtrx_file = 1;}
  	}#for
  if($input_file == 1){
     #&read_rpt_timing($INPUTREPORTFILE);
     &read_report_timing_wth_hd($INPUTREPORTFILE);
  }#if
  elsif($smtrx_file == 1){
	&read_smatrix_rpt_timing($S_MATRIX);
  }#elsif
}#else
}#sub read_report_timing

sub read_rpt_timing {
%TRDB = ();
my $inputReportFile = $_[0];
if( -e "$inputReportFile" ) {
open (READ,"$inputReportFile");
my $hd_st = 0;
while (<READ>) {
chomp();
if($_ =~ (/Path/)||(/PATH/)){($pathNum)=(split(/\s+/,$_))[1];
                              $pathNum =~ s/://;
                              $TRDB{$pathNum} = TimingRptDB::new();
                              $TRDB{$pathNum}->dbTRptSetPathNum($pathNum);
                            }#if path

elsif($_ =~ /^Endpoint/){   s/Endpoint:\s+//;
                         s/\(.*\)//;
                         s/\s+//;
                         $end_point = $_;
                         $TRDB{$pathNum}->dbTRptSetEndPoint($end_point);
                     }#elsif end point
elsif($_ =~ /^Beginpoint/){s/Beginpoint:\s+//;
                           s/\(.*\)//;
                           s/\s+//;
                           $begin_point = $_;
                           $TRDB{$pathNum}->dbTRptSetbeginPoint($begin_point);
                          }#elsif begin point
elsif($_ =~ /Slack Time/){$slack_time = (split(/\s+/,$_))[3];
                             $TRDB{$pathNum}->dbTRptSetSlkTime($slack_time);
                            }#elsif slack time
elsif($_ =~/\+--.*/){$hd_st = 1;}
      if($hd_st == 1){
         if($_ =~ /\+.*/){next;}
	 elsif($_ =~/\-\>/){
             my @temp_array =(split(/\s+\|\s+/,$_));
             my ($instanceName,$instloc,$arc)=@temp_array[1,2,3];
   	     my	 ($cell,$delay,$load,$artime,$reqtime) = @temp_array[4,5,6,7,8];
		    $data = $instanceName.":".$instloc.":".$cell.":".$delay.":".$load.":".$artime.":".$reqtime.":".$arc;
		    $TRDB{$pathNum}->dbTRptAddInstData($data);
        }#elsif
	elsif($_ =~ /\^/ ) {
		my @temp_array =(split(/\|/,$_));
		my ($instanceName,$instloc,$arc,$cell,$delay,$load,$artime,$reqtime)=@temp_array[1,2,3,4,5,6,7,8];
		    $data = $instanceName.":".$instloc.":".$cell.":".$delay.":".$load.":".$artime.":".$reqtime.":".$arc;
		    $TRDB{$pathNum}->dbTRptAddInstData($data);
        }#elsif
        else {
             my @temp_array =(split(/\|/,$_));
             my ($instanceName,$instloc,$arc,$cell,$delay,$load,$artime,$reqtime)=@temp_array[1,2,3,4,5,6,7,8];                 
                 if($_ =~ /\,/){
                    $data = $instanceName.":".$instloc.":".$cell.":".$delay.":".$load.":".$artime.":".$reqtime.":".$arc;
                    $TRDB{$pathNum}->dbTRptAddInstData($data);
                 }#if
        }#else
      }#if $hd_st
    }#while
   }#if file exists
}#sub read_rpt_timing

sub read_smatrix_rpt_timing {
%TRDB = ();
my $InputReportFile = $_[0];
if( -e "$InputReportFile" ) {
open (READ_FILE,"$InputReportFile");
while (<READ_FILE>) {
chomp();
if($_ =~ (/Path/)||(/PATH/)){($pathNum)=(split(/\s+/,$_))[1];
                              $pathNum =~ s/://;
                              $TRDB{$pathNum} = TimingRptDB::new();
                              $TRDB{$pathNum}->dbTRptSetPathNum($pathNum);
                            }#if path
elsif($_ =~ /^Endpoint/){s/Endpoint:\s+//;
                         s/\(.*\)//;
                         s/\s+//;
                         $end_point = $_;
                         $TRDB{$pathNum}->dbTRptSetEndPoint($end_point);
                         }#elsif 
elsif($_ =~ /^Beginpoint/){s/Beginpoint:\s+//;
                           s/\(.*\)//;
                           s/\s+//;
                           $begin_point = $_;
                           $TRDB{$pathNum}->dbTRptSetbeginPoint($begin_point);
                          }#elsif begin point
elsif($_ =~ /Slack Time/){$slack_time = (split(/\s+/,$_))[3];
                          $TRDB{$pathNum}->dbTRptSetSlkTime($slack_time);
                         }#elsif slack time
}#while
}#if exists file
}#sub read_smatrix_rpt_timing

#----------------------------------------------------------------------------------------------------------------------#

sub read_report_timing_wth_hd {
%TRDB = ();
my $inputReportFile = $_[0];
if( -e "$inputReportFile" ) {
open (READ,"$inputReportFile");
my $hd_st = 0;
my $read_data = 0;
my @columns = () ;
my $instance_pos = -1 ;                        
my $instanceLocation_pos = -1 ;        
my $arc_pos = -1 ;              
my $cell_pos = -1 ;        
my $delay_pos = -1 ;   
my $load_pos = -1 ;  
my $arrivalTime_pos = -1 ;  
my $requiredTime_pos = -1 ;
my $slew_pos = -1;
my $instance_val = "" ;                        
my $instanceLocation_val = "" ;        
my $locationX = "";
my $locationY = "";
my $loc_val = "";
my $arc_val = "" ;              
my $cell_val = "" ;        
my $delay_val = "" ;   
my $load_val = "" ;  
my $arrivalTime_val = "" ;  
my $requiredTime_val = "" ;
my $slew_val = "";
my $path_reads = 0;
my $end_path_reads = 0;
my $pathNum = "";
while (<READ>) {
chomp();

if($_ =~ (/^\s*Path\s*\d+/)||(/^\s*PATH\s*\d+/)){$path_reads = 1;$end_path_reads = 0;}
elsif($_ =~ (/\s*End\s*Path/)||(/\s*END\s*PATH/)){$end_path_reads=1; $path_reads = 0;}

if($path_reads == 1 || $end_path_reads == 0){

if($_ =~ (/^\s*Path\s*\d+/)||(/^\s*PATH\s*\d+/)){($pathNum)=(split(/\s+/,$_))[1];
                              		   	  $pathNum =~ s/://;
                              		   	  $TRDB{$pathNum} = TimingRptDB::new();
                              		   	  $TRDB{$pathNum}->dbTRptSetPathNum($pathNum);
                                           	  @columns = () ;
                                                }#if path
elsif($_ =~ /^\s*Endpoint/){(my $end_point) = (split(/\s+/,$_))[1];
                             $TRDB{$pathNum}->dbTRptSetEndPoint($end_point);
                           }#elsif end point
elsif($_ =~ /^\s*Beginpoint/){(my $begin_point) = (split(/\s+/,$_))[1];
                               $TRDB{$pathNum}->dbTRptSetbeginPoint($begin_point);
                             }#elsif begin point
elsif($_ =~ /^\s*Other\s*End\s*Arrival\s*Time/){(my $oeat) = (split(/\s+/,$_))[4];
                                                 $TRDB{$pathNum}->dbTRptSetOEATime($oeat);
                                               }#elsif oeat 
elsif($_ =~ /^\s*-\s*Setup/){(my $setup) = (split(/\s+/,$_))[2];
                              $TRDB{$pathNum}->dbTRptSet_Setup($setup);
                            }#elsif
elsif($_ =~ /^\s*\+\s*Phase\s*Shift/){(my $phase_shift) = (split(/\s+/,$_))[3];
                                       $TRDB{$pathNum}->dbTRptSetPhaseShift($phase_shift);
                                     }#elsif
elsif($_ =~ /^\s*-\s*Uncertainty/){(my $uncer) = (split(/\s+/,$_))[2];
                                    $TRDB{$pathNum}->dbTRptSetUncertainty($uncer);
                                  }#elsif
elsif($_ =~ /^\s*Clock\s*Rise\s*Edge/){(my $clk_rise_edge) = (split(/\s+/,$_))[4];
                                        $TRDB{$pathNum}->dbTRptSetClk_Rise_Edge($clk_rise_edge);
                                      }#elsif
elsif($_ =~/^\s*\+\s*Network\s*Insertion\s*Delay/){my $ntwrk_insrt_dly = (split(/\s+/,$_))[5];
                                                   $TRDB{$pathNum}->dbTRptSetNtWrk_I_Dly($ntwrk_insrt_dly);
                                                   }#elsif
elsif($_ =~ /^\s*=\s*Beginpoint\s*Arrival\s*Time/){my $bp_arr_time = (split(/\s+/,$_))[5];
                                                   $TRDB{$pathNum}->dbTRptSet_BP_Arr_Time($bp_arr_time);
                                                   }#elsif
elsif($_ =~ /^\s*=\s*Required\s*Time\s*\d+/){my $reqtime = (split(/\s+/,$_))[3];
                                             $TRDB{$pathNum}->dbTRptSetRequiredTime($reqtime);
                                            }#elsif
elsif($_ =~ /^\s*-\s*Arrival\s*Time\s*\d+/){my $arrtime = (split(/\s+/,$_))[3];
                                            $TRDB{$pathNum}->dbTRptSetArrivalTime($arrtime);
                                           }#elsif

elsif($_ =~ /Slack\s*Time/){my $slack_time = (split(/\s+/,$_))[3];
                            $TRDB{$pathNum}->dbTRptSetSlkTime($slack_time);
                           }#elsif slack time
elsif($_ =~/^\s*\+-+\+\s*$/){
                    if($read_data ==1){
                       $read_data = 0 ;
                       $hd_st = 0;
                       next;
                    }elsif($hd_st ==0){
                      $hd_st = 1;
                      $read_data = 0; 
                      next ;
                    }#elsif
                           }#elsif
elsif($_ =~/^\s*\|(\+|-)+\|\s*$/){
                                  shift(@columns) ;
                                  for(my $i = 0 ; $i <=$#columns; $i++) {
                                      if($columns[$i] =~ (/^\s*Instance\s*$/)||(/^\s*inst\s*$/)||(/^\s*instance\s*$/)||(/^\s*InstName\s*$/)){$instance_pos = $i;}
                                      elsif($columns[$i] =~(/^\s*Instance\s*Location\s*$/)||(/^\s*loc\s*$/)||(/^\s*instloc\s*$/)||(/^\s*location\s*$/)||(/^\s*instance\s*location\s*$/)){$instanceLocation_pos = $i;}
                                      elsif($columns[$i] =~/^\s*Arc\s*$/){$arc_pos= $i;}
                                      elsif($columns[$i] =~(/^\s*Cell\s*$/)||(/^\s*cellref\s*$/)||(/^\s*cell\s*$/)||(/^\s*CELL\s*$/)||(/^\s*MACRO\s*$/)||(/^\s*instcell\s*$/)){$cell_pos = $i;}
                                      elsif($columns[$i] =~(/^\s*Delay\s*$/)||(/^\s*delay\s*$/)||(/^\s*delta\s*$/)||(/^\s*incrdly\s*$/)||(/^\s*dly\s*$/)||(/^\s*instdly\s*$/)||(/^\s*instdelay\s*$/)){$delay_pos = $i;}
                                      elsif($columns[$i] =~/^\s*Load\s*$/){$load_pos = $i;}
                                      elsif($columns[$i] =~(/^\s*Arrival Time\s*$/)||(/^\s*arrival\s*$/)||(/^\s*Arrival\s*$/)){$arrivalTime_pos = $i;}
                                      elsif($columns[$i] =~/^\s*Required Time\s*$/){$requiredTime_pos = $i;}
                                      elsif($columns[$i] =~(/^\s*Slew\s*$/)||(/^\s*slew\s*$/)||(/^\s*slope\s*$/)){$slew_pos = $i;}
                                  }#for 
                                  $hd_st = 0;$read_data = 1; 
                                  next ;}
if( $hd_st == 1 && $read_data == 0){
       my @curr_column = (split(/\s*\|\s*/,$_));
       if($#columns ==0){
         foreach $temp_col (@curr_column){
           push(@columns, $temp_col);
         }#foreach
       }else{
         my $temp_index = 0 ;
         foreach $temp_col (@curr_column){
           my $temp_val = $columns[$temp_index];
           $temp_val = $temp_val." ".$temp_col;
           $columns[$temp_index] = $temp_val;
           $temp_index++ ;
         }#foreach
       }#else
}#if hd_st
if($read_data == 1 && $hd_st == 0){
      my @curr_data = (split(/\|\s*/,$_)); 
      shift(@curr_data);
      $instance_val = $curr_data[$instance_pos] ;                        
      $instanceLocation_val = $curr_data[$instanceLocation_pos] ;        
      ($locationX,$locationY) = (split(/\s*,\s*/,$instanceLocation_val));
            $locationX =~ s/\(//;
            $locationY =~ s/\)//;
      $loc_val = $locationX." ".$locationY;
      $arc_val = $curr_data[$arc_pos] ;              
      $cell_val = $curr_data[$cell_pos] ;        
      $delay_val = $curr_data[$delay_pos] ;   
      $load_val = $curr_data[$load_pos] ;  
      $arrivalTime_val = $curr_data[$arrivalTime_pos] ;  
      $requiredTime_val = $curr_data[$requiredTime_pos] ;
      $slew_val = $curr_data[$slew_pos];
      if($arc_val ne "" && $delay_val ne ""){
        #if($instanceLocation_val ne ""){
        #   ($locationX,$locationY) = (split(/\s*,\s*/,$instanceLocation_val));
        #    $locationX =~ s/\(//;
        #    $locationY =~ s/\)//;
        #    &get_die($locationX,$locationY);   
        #    $loc_val = $locationX." ".$locationY;
            $TRDB{$pathNum}->dbTRptSetInstName($instance_val);
            $TRDB{$pathNum}->dbTRptSetInstLoc($loc_val);
            $TRDB{$pathNum}->dbTRptSetArc($arc_val);
            $TRDB{$pathNum}->dbTRptSetCell($cell_val);
            $TRDB{$pathNum}->dbTRptSetDelay($delay_val);
            $TRDB{$pathNum}->dbTRptSetLoad($load_val);
            $TRDB{$pathNum}->dbTRptSetArrTime($arrivalTime_val);
            $TRDB{$pathNum}->dbTRptSetReqTime($requiredTime_val);
            $TRDB{$pathNum}->dbTRptSetSlew($slew_val);
         #}#if inst_val  
       }#if arc_val 
       elsif ($arc_val eq "" && $delay_val ne ""){
              $TRDB{$pathNum}->dbTRptSetNetName($instance_val);
              $TRDB{$pathNum}->dbTRptSetNetLoc($loc_val);
              $TRDB{$pathNum}->dbTRptSetNetArc($arc_val);
              $TRDB{$pathNum}->dbTRptSetNetCell($cell_val);
              $TRDB{$pathNum}->dbTRptSetNetDelay($delay_val);
              $TRDB{$pathNum}->dbTRptSetNetLoad($load_val);
              $TRDB{$pathNum}->dbTRptSetNetArrTime($arrivalTime_val);
              $TRDB{$pathNum}->dbTRptSetNetReqTime($requiredTime_val);
              $TRDB{$pathNum}->dbTRptSetNetSlew($slew_val);  
       }#elsif 
}#if read_data
}#if path_reads
    }#while
}#if file exists

}#sub read_report_timing_wth_hd
#------------------------------------------------------------------------------------------------------------------------------------------------------------#

sub write_rpt_timing {
my $noOfArguments  = @_;
if($noOfArguments < 0 || $_[0] eq "-h"){print "Usage : write_rpt_timing\n";
                                        print "        -inst\n";
                                        print "        -cell\n";
                                        }
else {
        my $inst = 0;
        my $arc = 0;
        my $loc = 0;
my @inst_n = ();
my @arc_n = ();
my @loc_n = ();
my @cell_n = ();
my @delay_n = ();
my @load_n = ();
my @arr_n = ();
my @req_n = ();
my @slew_n = ();
        for (my $i = 0; $i < $noOfArguments; $i++){
                if ($_[$i] eq "-inst"){$inst = 1;}
                if ($_[$i] eq "-arc"){$arc= 1;}
                if($_[$i] eq "-loc"){$loc =1;}
        }#for

     
open (WRITE,">timing_rpt");
foreach $point (keys %TRDB){
my $path = $TRDB{$point}->dbTRptGetPathNum;
print WRITE "PATH $path\n";
my $bgp = $TRDB{$point}->dbTRptGetbeginPoint;
print WRITE "Begin Point $bgp\n";
my $edp = $TRDB{$point}->dbTRptGetEndPoint;
print WRITE "End Point $edp\n";
my $oeat = $TRDB{$point}->dbTRptGetOEATime;
print WRITE "Other End Arrival Time $oeat\n";
my $stup = $TRDB{$point}->dbTRptGet_Setup;
print WRITE "Setup $stup\n";
my $phase_shift = $TRDB{$point}->dbTRptGetPhaseShift;
print WRITE "Phase Shift $phase_shift\n";
my $uncer = $TRDB{$point}->dbTRptGetUncertainty;
print WRITE "Uncertainty $uncer\n";
my $clk_rise_edge = $TRDB{$point}->dbTRptGetClk_Rise_Edge;
print WRITE "Clock Rise Edge $clk_rise_edge\n";
my $ntwrk_insrt_dly = $TRDB{$point}->dbTRptGetNtWrk_I_Dly;
print WRITE "Network Insertion Delay $ntwrk_insrt_dly \n";
my $bp_arr_time = $TRDB{$point}->dbTRptGet_BP_Arr_Time;
print WRITE "Begin Arrival Time $bp_arr_time\n";
my $reqtime = $TRDB{$point}->dbTRptGetRequiredTime;
print WRITE "Required Time $reqtime\n";
my $arrtime = $TRDB{$point}->dbTRptGetArrivalTime;
print WRITE "Arrival Time $arrtime\n";
my $slack = $TRDB{$point}->dbTRptGetSlkTime;
print WRITE "Slack Time $slack\n";
print WRITE "\n";
@inst_n = $TRDB{$point}->dbTRptGetInstName;
@arc_n = $TRDB{$point}->dbTRptGetArc;
@loc_n = $TRDB{$point}->dbTRptGetInstLoc;
@cell_n = $TRDB{$point}->dbTRptGetCell;
@delay_n = $TRDB{$point}->dbTRptGetDelay;
@load_n = $TRDB{$point}->dbTRptGetLoad;
@arr_n = $TRDB{$point}->dbTRptGetArrTime;
@req_n = $TRDB{$point}->dbTRptGetReqTime;
@slew_n = $TRDB{$point}->dbTRptGetSlew;
for(my $j =0;$j<=$#inst_n; $j++){
print WRITE " $inst_n[$j]	 $arc_n[$j]  $slew_n[$j]	$cell_n[$j]	$loc_n[$j]	 $delay_n[$j]	 $arr_n[$j]	 $req_n[$j]\n";
}
}#foreach

}#else
}#sub write_rpt_timing
#---------------------------------------------------------------------------------------------------------------------------------------------------------#
1;
