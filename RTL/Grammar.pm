package Grammar;

use Hardware::Verilog::StdLogic;
use Parse::RecDescent;
#use strict;
use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
@ISA = qw(Exporter);
@EXPORT = qw( &getGrammar);
# %port %net %reg %input %inout %out %msb %lsb %inst %func %param);


my %port;
my %net;
my %reg;
my %inp;
my %inout;
my %out;
my %msb;
my %lsb;
my %inst;
my %func;
my %param;


my $grammar;

sub new {

my $junk;
my @junk;
my %junk;


$grammar = <<'_EOGRAMMAR_';

	{
  use Exporter;
  use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
  push @ISA, 'Exporter';

	#### autoactions here
	my $junk;
	my @junk;
	my %junk;


	}

	eofile : /^\Z/

###############################
# source text
###############################

design_file :  
	design_unit(s) eofile { $return = $item[1] }

design_unit : 
        module_declaration | udp_declaration

module_declaration : 
        ( 'module'  |  'macromodule' )
	<commit>

	{
	%main::net = (); 
	%main::reg = (); 
	%main::port = (); 
	%main::inp = (); 
	%main::inout = (); 
	%main::out = (); 
	%main::msb = (); 
	%main::lsb = (); 
	%main::inst = ();
	%main::func = ();
	%main::param = ();

	1; 
	}

        module_declaration_identifier
        list_of_ports(?)
        ';'
        module_item(s?)
        'endmodule'

	{
	print "module $item{module_declaration_identifier} \n\n\n";

	print "contained the following input ports:\n";
	@junk = keys(%main::inp);
	@junk = sort(@junk);
	foreach $junk (@junk)
		{
		print "\t$junk";
		unless ( $main::msb{$junk} eq 'no_value' )
			{ print ' [ '.$main::msb{$junk}->numeric.' : '.$main::lsb{$junk}->numeric.' ] ';}
		print "\n";
		}
	print "\n\n";


	print "contained the following inout ports:\n";
	@junk = keys(%main::inout);
	@junk = sort(@junk);
	foreach $junk (@junk)
		{
		print "\t$junk";
		unless ( $main::msb{$junk} eq 'no_value' )
			{ print ' [ '.$main::msb{$junk}->numeric.' : '.$main::lsb{$junk}->numeric.' ] ';}
		print "\n";
		}
	print "\n\n";


	print "contained the following output ports:\n";
	@junk = keys(%main::out);
	@junk = sort(@junk);
	foreach $junk (@junk)
		{
		print "\t$junk";
		unless ( $main::msb{$junk} eq 'no_value' )
			{ print ' [ '.$main::msb{$junk}->numeric.' : '.$main::lsb{$junk}->numeric.' ] ';}
		print "\n";
		}
	print "\n\n";


	print "contained the following wires:\n";
	@junk = keys(%main::net);
	@junk = sort(@junk);
	foreach $junk (@junk)
		{
		print "\t type $main::net{$junk} ";
		print "\t$junk";
		unless ( $main::msb{$junk} eq 'no_value' )
			{ print ' [ '.$main::msb{$junk}->numeric.' : '.$main::lsb{$junk}->numeric.' ] ';}
		print "\n";
		}
	print "\n\n";

	print "contained the following regs:\n";
	@junk = keys(%main::reg);
	@junk = sort(@junk);
	foreach $junk (@junk)
		{
		print "\t$junk";
		unless ( $main::msb{$junk} eq 'no_value' )
			{ print ' [ '.$main::msb{$junk}->numeric.' : '.$main::lsb{$junk}->numeric.' ] ';}
		print "\n";
		}
	print "\n\n";



	print "contained the following instances:\n";
	@junk = keys(%main::inst);
	@junk = sort(@junk);
	foreach $junk (@junk)
		{
		print "\t$junk is instance of $main::inst{$junk} \n";
		}
	print "\n\n";


	print "contained the following function declarations :\n";
	@junk = keys(%main::func);
	@junk = sort(@junk);
	foreach $junk (@junk)
		{
		print "\t$junk\n";
		}
	print "\n\n";

	print "contained the following parameters :\n";
	@junk = keys(%main::param);
	@junk = sort(@junk);
	foreach $junk (@junk)
		{
		print "\t$junk\n";
		}
	print "\n\n";


	1;
	}
	| <error?> <reject>

list_of_ports : 
        '(' 
	port
	comma_port(s?)
        ')'

comma_port :
	','
	port

port : 
        port_expression(?) |
        dot_port_identifier_and_port_expression

dot_port_identifier_and_port_expression :
        '.'
        port_identifier
        '('
        port_expression(?)
        ')'
        
port_expression : 
	port_reference
	comma_port_reference(s?)

comma_port_reference :
	','
	port_reference

port_reference : 
	port_identifier
        port_bit_selection_or_bit_slice(?)
	{ 
	$main::port{$item{port_identifier}} = 1;
	}

port_bit_selection_or_bit_slice :
        bit_selection_or_bit_slice(?)


module_item : 
	  'assign' continuous_assignment  
	| 'always' always_construct
	| 'initial' initial_construct  
	| 'specify' specify_block  
	| 'defparam' parameter_override  
	| gate_instantiation  
	| udp_instantiation  
	| module_item_declaration  
	| module_instantiation  

module_item_declaration :
          reg_declaration  
        | net_declaration  
        | input_declaration  
        | output_declaration  
        | inout_declaration  
        | parameter_declaration  
        | integer_declaration 
        | real_declaration  
        | time_declaration  
        | realtime_declaration  
        | event_declaration  
        | task_declaration  
        | function_declaration

parameter_override :
        parameter_assignment_comma_parameter_assignment
        ';'
	| <error>

parameter_assignment_comma_parameter_assignment :
	parameter_assignment
	comma_parameter_assignment(s?)

comma_parameter_assignment :
	','
	parameter_assignment

###################################################################
# declarations
###################################################################


parameter_declaration :  
        'parameter' 
	<commit>
        parameter_assignment_comma_parameter_assignment
        ';'
	| <error?> <reject>

parameter_assignment : 
        parameter_identifier
        '=' 
        constant_expression
	{
	$main::param{$item{parameter_identifier}} = $item{constant_expression};
	}


input_declaration :
        'input'
	<commit>
        range(?)
        direction_port_identifier_list[$item[1],@{$item{range}->[0]}]
        ';'
	| <error?> <reject>

output_declaration :
        'output'
	<commit>
        range(?)
        direction_port_identifier_list[$item[1],@{$item{range}->[0]}]
       ';'
	| <error?> <reject>

inout_declaration :
        'inout'
	<commit>
        range(?)
        direction_port_identifier_list[$item[1],@{$item{range}->[0]}]
       ';'
	| <error?> <reject>

direction_port_identifier_list :
	direction_port_identifier[@arg]
	comma_direction_port_identifier[@arg](s?)

comma_direction_port_identifier :
	','
	<commit>
	direction_port_identifier[@arg]
	| <error?> <reject>

direction_port_identifier :
	port_identifier
	{
	my $dir = $arg[0];
	my $msb = $arg[1];
	my $lsb = $arg[2];
	my $net_name = $item{port_identifier};

	$msb = 'no_value' unless(defined($msb));
	$lsb = 'no_value' unless(defined($lsb));

	$main::msb{$net_name} = $msb;
	$main::lsb{$net_name} = $lsb;


	if ($dir eq 'input')
		{
		$main::inp{$net_name} = 1;
		$main::net{$net_name} = 'wire';
		1; 
		}

	elsif ($dir eq 'inout')
		{
		if(exists($main::inout{$net_name}))
			{
			$junk{'direction'} = 'inout';
			$junk{'name'} = $net_name;
			undef;
			}
		else
			{
			$main::inout{$net_name} = 1;
			$main::net{$net_name} = 'wire';
			1; 
			}
		}

	elsif ($dir eq 'output')
		{
		if(exists($main::out{$net_name}))
			{
			$junk{'direction'} = 'output';
			$junk{'name'} = $net_name;
			undef;
			}
		else
			{
			$main::out{$net_name} = 1;
			$main::net{$net_name} = 'wire';
			1; 
			}
		}


	}
	| <error: redeclaring $junk{'direction'} "$junk{'name'}">



reg_declaration :  
        'reg'
 	<commit>
       range(?) 
        declare_register_name_comma_declare_register_name[$item[1],@{$item{range}->[0]}]
        ';'
	| <error?> <reject>

time_declaration :  
        'time'
	<commit>
        declare_register_name_comma_declare_register_name[$item[1],'no_value', 'no_value']
        ';'

integer_declaration :  
        'integer'
 	<commit>
       declare_register_name_comma_declare_register_name[$item[1],'no_value', 'no_value']
        ';'
	| <error?> <reject>

declare_register_name_comma_declare_register_name :
	declare_register_name[@arg]
	comma_declare_register_name[@arg](s?)

comma_declare_register_name :
	','
	<commit>
	declare_register_name[@arg]
	| <error?> <reject>

declare_register_name :
	register_name
	range(?)
	{ 

	$main::msb{$item{register_name}} = $arg[1];
	$main::lsb{$item{register_name}} = $arg[2];
	if(exists($main::reg{$item{register_name}}))
		{
		$junk{register_name} = $item{register_name};
		$return = undef;
		undef;
		}
	else
		{
		$main::reg{$item{register_name}} = 1;
		# if it was a port, remove it from the list of nets.
		if(exists($main::port{$item{register_name}}))
			{
			delete($main::net{$item{register_name}});
			}
		1; 
		}
	}
	| <error: redeclaring reg "$junk{register_name}">

real_declaration :  
        'real'
	<commit>
        real_identifier_comma_real_identifier
        ';'
	| <error?> <reject>
real_identifier_comma_real_identifier :
	real_identifier
	comma_real_identifier(s?)

comma_real_identifier :
	','
	<commit>
	real_identifier
	| <error?> <reject>
realtime_declaration :  
        'realtime'
	<commit>
        real_identifier_comma_real_identifier
        ';'
	| <error?> <reject>
event_declaration :
	'event'
	<commit>
	 event_identifier_comma_event_identifier
        ';'
	| <error?> <reject>
event_identifier_comma_event_identifier :
	event_identifier
	comma_event_identifier(s?)

comma_event_identifier :
	','
	<commit>
	event_identifier
	| <error?> <reject>
register_name : 
        register_identifier | 
        memory_identifier     range(?)

range :
        '[' 
	<commit>
        msb_constant_expression 
        ':'  
        lsb_constant_expression 
        ']'
	{
	my $msb = $item{msb_constant_expression};
	$msb = 'no_value' unless (defined($msb));
	my $lsb = $item{lsb_constant_expression};
	$lsb = 'no_value' unless (defined($lsb));
	$return = [ $msb , $lsb ];
	}

	|
	{
	$return = [ 'no_value' , 'no_value' ];
	}
	
	| <error?> <reject>



msb_constant_expression :
	constant_expression

lsb_constant_expression :
	constant_expression

net_declaration : 
          net_type_vectored_scalared_range_delay3_list_of_net_identifiers  
        | net_type_vectored_scalared_drive_strength_range_delay3_list_of_net_decl
        | trireg_vectored_scalared_charge_strength_range_delay3_list_of_net 

net_type_vectored_scalared_range_delay3_list_of_net_identifiers : 
        net_type
	<commit>
        vectored_or_scalared(?)
        range(?)
        delay3(?)
        declaring_net_identifier_comma_declaring_net_identifier[$item{net_type},@{$item{range}->[0]}]
        ';'
	| <error?> <reject>

declaring_net_identifier_comma_declaring_net_identifier :
	declaring_net_identifier[@arg]
	comma_declaring_net_identifier[@arg](s?)

comma_declaring_net_identifier :
	','
	<commit>
	declaring_net_identifier[@arg]
	| <error?> <reject>

declaring_net_identifier : 
	net_identifier
	{
	my $net_name = $item{net_identifier};
	$main::net{$item{net_identifier}} = $arg[0];
	$main::msb{$net_name} = $arg[1];
	$main::lsb{$net_name} = $arg[2];
	1; 
	}
	| <error: redeclaring net "$junk[0]">

trireg_vectored_scalared_charge_strength_range_delay3_list_of_net : 
        'trireg' 
	<commit>
        vectored_or_scalared(?)
        charge_strength(?)
        range(?)
        delay3(?)                
        declaring_net_identifier_comma_declaring_net_identifier[ 'trireg' ,@{$item{range}->[0]}]
        ';'
	| <error?> <reject>

net_type_vectored_scalared_drive_strength_range_delay3_list_of_net_decl :
        net_type
	<commit>
        vectored_or_scalared(?)
        drive_strength(?)
        range(?)
        delay3(?)
        net_decl_assignment_comma_net_decl_assignment
        ';'
	| <error?> <reject>

net_decl_assignment_comma_net_decl_assignment :
	net_decl_assignment
	comma_net_decl_assignment(s?)

comma_net_decl_assignment :
	','
	<commit>
	net_decl_assignment
	| <error?> <reject>

vectored_or_scalared :
	'vectored' | 'scalared'

net_type :  
        'wire'  	{$return = 'wire';}     |  
        'supply0'  	{$return = 'supply0';}  |
        'supply1'  	{$return = 'supply1';}  |  
        'triand'  	{$return = 'triand';}   |  
        'trior' 	{$return = 'trior';}    |
        'tril'  	{$return = 'tril';}     |  
        'tri0'  	{$return = 'tri0';}     | 
        'tri'  		{$return = 'tri';}      |  
        'wand'   	{$return = 'wand';}     |  
        'wor' 	 	{$return = 'wor';}        


drive_strength : 
        '('
        (
        	  strength0_comma_strength1 
        	| strength1_comma_strength0 
        	| strength0_comma_highz1 
        	| strength1_comma_highz0 
        	| highz1_comma_strength0 
        	| highz0_comma_strength1 
        )
        ')'

strength0_comma_strength1 : 
        strength0 ',' strength1
                        
strength1_comma_strength0 : 
        strength1 ',' strength0

strength0_comma_highz1 : 
        strength0 ',' 'highz1'

strength1_comma_highz0 : 
        strength1 ',' 'highz0'


highz1_comma_strength0 : 
        'highz1' ',' strength0


highz0_comma_strength1 : 
        'highz0' ',' strength1

strength0 : 
	'supply0'  |  'strong0'  |  'pull0'  |  'weak0' 

strength1 : 
	'supply1'  |  'strong1'  |  'pull1'  |  'weak1' 

charge_strength :  
	'small'    |  'medium'      |  'large'  



#
#
#    need to clean up "delay" rule definitions.
#
#

delay3 :  
	'#'
	(
		paren_up_to_3_delay_values
		| delay_value
	)

paren_up_to_3_delay_values :
	'('
	<commit>
	delay_value
	comma_delay_value(?)
	comma_delay_value(?)
	')'
	| <error?> <reject>

delay2 :  
	'#'
	(
		paren_up_to_2_delay_values
		| delay_value
	)

paren_up_to_2_delay_values :
	'('
	<commit>
	delay_value
	comma_delay_value(?)
	')'
	| <error?> <reject>


comma_delay_value :
	','
	<commit>
	delay_value
	| <error?> <reject>


delay_value :  
          constant_mintypmax_expression

net_decl_assignment :

        net_identifier 
        '='
        expression

function_declaration : 
        'function'
	<commit>
        range_or_type(?)
        function_identifier 
        ';'
        function_item_declaration(s)
        statement
        'endfunction'
	{
	$main::func{$item{function_identifier}} = 1;
	}
	| <error?> <reject>

range_or_type :
	range  |  'integer'  |  'real'  |  'realtime'  |  'time'

function_item_declaration : 
        input_declaration |
        block_item_declaration

task_declaration : 
        'task'
	<commit>
        task_identifier
        ';'
        task_item_declaration(s?)
        statement_or_null
        'endtask'
	| <error?> <reject>

task_item_declaration : 
        block_item_declaration | 
        input_declaration | 
        output_declaration | 
        inout_declaration


block_item_declaration : 
        parameter_declaration | 
        reg_declaration | 
        integer_declaration | 
        real_declaration | 
        time_declaration | 
        realtime_declaration | 
        event_declaration


###################################################################
# primitive instances
###################################################################


gate_instantiation : 
        n_input_gatetype_drive_strength_delay2_n_input_gate_instance | 
        n_output_gatetype_drive_strength_delay2_n_output_gate_instance | 
        enable_gatetype_drive_strength_delay3_enable_gate_instance | 
        mos_switchtype_delay3_mos_switch_instance | 
        pass_switchtype_pass_switch_instance | 
        pass_en_switchtype_delay3_pass_enable_switch_instance | 
        cmos_switchtype_delay3_cmos_switch_instance | 
        pullup_pullup_strength_pull_gate_instance | 
        pulldown_pulldown_strength_pull_gate_instance 


n_input_gatetype_drive_strength_delay2_n_input_gate_instance :
        n_input_gatetype
	<commit>
        drive_strength(?)
        delay2(?)
        n_input_gate_instance_comma_n_input_gate_instance
        ';'
	| <error?> <reject>

n_input_gate_instance_comma_n_input_gate_instance : 
	n_input_gate_instance
	comma_n_input_gate_instance(s?)

comma_n_input_gate_instance : 
	','
	<commit>
	n_input_gate_instance
	| <error?> <reject>

n_output_gatetype_drive_strength_delay2_n_output_gate_instance : 
        n_output_gatetype
	<commit>
        drive_strength(?) 
        delay2(?)
        n_output_gate_instance_comma_n_output_gate_instance
        ';'
	| <error?> <reject>

n_output_gate_instance_comma_n_output_gate_instance :
	n_output_gate_instance
	comma_n_output_gate_instance(s?)

comma_n_output_gate_instance :
	','
	<commit>
	n_output_gate_instance
	| <error?> <reject>

enable_gatetype_drive_strength_delay3_enable_gate_instance : 
        enable_gatetype
	<commit>
        drive_strength(?)
        delay3(?)
        enable_gate_instance_comma_enable_gate_instance
        ';'
	| <error?> <reject>

enable_gate_instance_comma_enable_gate_instance :
	enable_gate_instance
	comma_enable_gate_instance(s?)

comma_enable_gate_instance :
	','
	<commit>
	enable_gate_instance
	| <error?> <reject>

mos_switchtype_delay3_mos_switch_instance :
        mos_switchtype
	<commit>
        delay3(?)
        mos_switch_instance_comma_mos_switch_instance
        ';'
	| <error?> <reject>

mos_switch_instance_comma_mos_switch_instance :
	mos_switch_instance
	comma_mos_switch_instance(s?)

comma_mos_switch_instance :
	','
	<commit>
	mos_switch_instance
	| <error?> <reject>

pass_switchtype_pass_switch_instance : 
        pass_switchtype
	<commit>
        pass_switch_instance_comma_pass_switch_instance
        ';'
	| <error?> <reject>

pass_switch_instance_comma_pass_switch_instance :
	pass_switch_instance
	comma_pass_switch_instance(s?)

comma_pass_switch_instance :
	','
	<commit>
	pass_switch_instance
	| <error?> <reject>

pass_en_switchtype_delay3_pass_enable_switch_instance : 
        pass_en_switchtype
	<commit>
        delay3(?)
        pass_enable_switch_instance_comma_pass_enable_switch_instance
        ';'
	| <error?> <reject>

pass_enable_switch_instance_comma_pass_enable_switch_instance :
	pass_enable_switch_instance 
	comma_pass_enable_switch_instance(s?)

comma_pass_enable_switch_instance : 
	','
	<commit>
	pass_enable_switch_instance
	| <error?> <reject>

cmos_switchtype_delay3_cmos_switch_instance : 
        cmos_switchtype
 	<commit>
        delay3(?)
        cmos_switch_instance_comma_cmos_switch_instance
        ';'
	| <error?> <reject>

cmos_switch_instance_comma_cmos_switch_instance : 
	cmos_switch_instance
	comma_cmos_switch_instance(s?)

comma_cmos_switch_instance :
	','
	<commit>
	cmos_switch_instance
	| <error?> <reject>

pullup_pullup_strength_pull_gate_instance : 
        'pullup'
	<commit>
        pullup_strength(?)
        pull_gate_instance_comma_pull_gate_instance
        ';'
	| <error?> <reject>

pull_gate_instance_comma_pull_gate_instance :
	pull_gate_instance
	comma_pull_gate_instance(s?)

comma_pull_gate_instance :
	','
	<commit>
	pull_gate_instance
	| <error?> <reject>

pulldown_pulldown_strength_pull_gate_instance : 
        'pulldown'
	<commit>
        pulldown_strength(?)
        pull_gate_instance_comma_pull_gate_instance
        ';'
	| <error?> <reject>

n_input_gate_instance : 
        name_of_gate_instance(?) 
        '(' 
         output_terminal 
	',' 
         input_terminal_comma_input_terminal 
        ')'

input_terminal_comma_input_terminal :
	input_terminal
	comma_input_terminal(s?)

comma_input_terminal :
	','
	<commit>
	input_terminal
	| <error?> <reject>

n_output_gate_instance : 
        name_of_gate_instance(?) 
        '('
        output_terminal_comma_output_terminal 

	# rules need to figure out what is an output terminal and what is an input terminal
	# otherwise, above rule sucks up all the terminals, and
	# the rest of the rule, i.e. ( ',' input_terminal ) fails.
	#  ',' input_terminal
        ')'

output_terminal_comma_output_terminal :
	output_terminal
	comma_output_terminal(s?)

comma_output_terminal :
	','
	<commit>
	output_terminal
	| <error?> <reject>

enable_gate_instance : 
        name_of_gate_instance(?) 
        '('
        output_terminal ','
        input_terminal ','
        enable_terminal
        ')'


mos_switch_instance : 
        name_of_gate_instance(?) 
        '('
         output_terminal ','
         input_terminal ','
         enable_terminal
        ')'


pass_switch_instance : 
        name_of_gate_instance(?) 
        '('
         inout_terminal ','
         inout_terminal 
        ')'

pass_enable_switch_instance : 
        name_of_gate_instance(?) 
        '('
         inout_terminal ','
         inout_terminal ','
         enable_terminal
        ')'

cmos_switch_instance : 
        name_of_gate_instance(?) 
        '('
         output_terminal   ','
         input_terminal    ','
         ncontrol_terminal ','
         pcontrol_terminal
        ')'

pull_gate_instance : 
        name_of_gate_instance(?) 
        '('
         output_terminal 
        ')'

name_of_gate_instance :  
        gate_instance_identifier
        range(?)



pullup_strength : 
        '('
        (
        strength0_comma_strength1 |
        strength1_comma_strength0 |
        strength1
        )
        ')'


pulldown_strength : 
        '('
        (
        strength0_comma_strength1 |
        strength1_comma_strength0 |
        strength0
        )
        ')'


input_terminal :  
        scalar_expression 

enable_terminal :   
        scalar_expression 

ncontrol_terminal :  
        scalar_expression 

pcontrol_terminal :  
        scalar_expression 

output_terminal :        
        terminal_identifier  bit_selection(?)

inout_terminal : 
        terminal_identifier  bit_selection(?)


bit_selection :
	'['
	<commit>
	expression
	']'
	| <error?> <reject>


n_input_gatetype :  
	'and'  |  'nand'  |  'or'  |  'nor'  |  'xor'  |  'xnor'  

n_output_gatetype :  
	'buf'  |  'not' 

enable_gatetype :  
	'bufifo'  |  'bufdl'  |  'notifo'  |  'notifl'  

mos_switchtype :  
	'nmos'  |  'pmos'  |  'rnmos'  |  'rpmos'    

pass_switchtype :  
	'tran'  |  'rtran'   

pass_en_switchtype :
	'tranif0' | 'tranif1' | 'rtranif1' | 'rtranif0'  

cmos_switchtype :
	'cmos' | 'rcmos'  



##################################################################
# module instantiation
##################################################################

module_instantiation : 
        module_identifier
        parameter_value_assignment(?)
        module_instance(s)
	';'
	{
	my $module_identifier = $item{module_identifier};
	my @module_instance_list = $item{module_instance};
	foreach my $temp (@module_instance_list)
		{
		my $inst_name = $temp->[0]->[0]->[0];
		$main::inst{$inst_name} = $module_identifier;
		}

	}
	| <error>

parameter_value_assignment :
        '#' 
 	<commit>
       '(' 
        expression_comma_expression 
        ')' 
	| <error?> <reject>

module_instance :  
        name_of_instance  
        '('
        list_of_module_connections(?)
        ')'
	{
	$return = [ $item{name_of_instance}, $item{list_of_module_connections} ];
	}
	| <error>

name_of_instance : 
         module_instance_identifier
        range(?)
	{
	$return = [ $item{module_instance_identifier}, $item{range} ];
	}

list_of_module_connections :
	  named_port_connection_comma_named_port_connection 
	| ordered_port_connection_comma_ordered_port_connection 

ordered_port_connection_comma_ordered_port_connection :
	ordered_port_connection
	comma_ordered_port_connection(s?)

comma_ordered_port_connection :
	','
	<commit>
	ordered_port_connection
	{
	$return = $item{ordered_port_connection};
	}
	| <error?> <reject>

named_port_connection_comma_named_port_connection :
	named_port_connection
	comma_named_port_connection(s?)
	{
	$return = [ $item{named_port_connection}, @{$item{comma_named_port_connection}} ];
	}

comma_named_port_connection :
	','
	<commit>
	named_port_connection
	{
	$return = $item{named_port_connection};
	}
	| <error?> <reject>

ordered_port_connection :  
        expression
	{
	$return = 'expression';
	}
	|  # or nothing. ordered port connections can be U1(  ,a, ,c,  );
	{
	$return = 'no_connection';
	}



named_port_connection :
        '.' 
	<commit>
        port_identifier
        '(' expression(?) ')'
	{
	$return = $item{port_identifier};
	}
	| <error?> <reject>


##############################################################
# UDP declaration and instantiation
##############################################################

udp_declaration : 
        'primitive'
	<commit>
        udp_identifier 
        '(' udp_port_list ')' ';'
        udp_port_declaration(s)
        udp_body
        'endprimitive'
	| <error?> <reject>
udp_port_list :  
        output_port_identifier ','
        input_port_identifier_comma_input_port_identifier

input_port_identifier_comma_input_port_identifier :
	input_port_identifier
	comma_input_port_identifier(s?)

comma_input_port_identifier :
	','
	<commit>
	input_port_identifier
	| <error?> <reject>

udp_port_declaration : 
          output_declaration 
	| input_declaration 
	| reg_declaration
        

udp_body : 
         combinational_body  |  sequential_body


combinational_body : 
        'table' 
 	<commit>
        combinational_entry(s) 
        'endtable'
	| <error?> <reject>
combinational_entry :
        level_input_list ':' output_symbol ';'

sequential_body :
        udp_initial_statement(?)
        'table' 
	<commit>
        sequential_entry(s)
        'endtable'
	| <error?> <reject>
udp_initial_statement :  
        'initial' 
	<commit>
        udp_output_port_identifier 
        '=' 
        init_val
        ';'
	| <error?> <reject>
init_val : 
          "1'b0" | "1'b1" | "1'bx" | "1'bX " | 
          "1'B0" | "1'B1" | "1'Bx" | "1'BX " |
          '1' | '0' 

sequential_entry :  
        seq_input_list 
	':' 
	current_state 
	':' 	
	next_state


seq_input_list :  
        level_input_list  |  edge_input_list

level_input_list :
        level_symbol(s)

edge_input_list :
        level_symbol(s?) 
        edge_indicator
        level_symbol(s?)

edge_indicator :
        level_symbol_level_symbol_in_paran  |  edge_symbol

level_symbol_level_symbol_in_paran :
        '(' level_symbol level_symbol ')'

current_state : 
        level_symbol

next_state : 
        output_symbol | '-'

output_symbol : 
        /[01xX]/

level_symbol :
        /[01xXbB?]/ 

edge_symbol :
        'r' | 'R' | 'f' | 'F' | 'p' | 'P' | 'n' | 'N' | '*'

udp_instantiation :
        udp_identifier
        drive_strength(?)
        delay2(?)
        udp_instance_comma_udp_instance
        ';'

udp_instance_comma_udp_instance :
	udp_instance
	comma_udp_instance(s?)

comma_udp_instance :
	','
	<commit>
	udp_instance
	| <error?> <reject>
udp_instance :
        name_of_udp_instance(?)
        '('
        output_port_connection ','
        input_port_connection_comma_input_port_connection
        ';'

input_port_connection_comma_input_port_connection :
	input_port_connection
	comma_input_port_connection

comma_input_port_connection :
	','
	<commit>
	input_port_connection
	| <error?> <reject>
name_of_udp_instance :
	udp_instance_identifier
	'['
	range
	']'

input_port_connection :
	list_of_module_connections

inout_port_connection :
	list_of_module_connections

output_port_connection :
	list_of_module_connections

#####################################################################
# behavioural statements
#####################################################################

continuous_assignment : 
        drive_strength(?)			
        delay3(?)				
        net_assignment_comma_net_assignment	
        ';'
	| <error>

net_assignment_comma_net_assignment :
	net_assignment
	comma_net_assignment(s?)

comma_net_assignment :
	','
	<commit>
	net_assignment
	| <error?> <reject>

net_assignment : 
        net_lvalue '=' expression

initial_construct : 
	statement
	| <error>

always_construct : 
	statement
	| <error>

statement :
	  procedural_timing_control_statement 
	| procedural_continuous_assignment_with_semicolon 
	| seq_block 
	| conditional_statement 
	| case_statement 
	| loop_statement 
	| wait_statement 
	| disable_statement 
	| event_trigger 
	| par_block 
	| task_enable 
	| system_task_enable
	| blocking_assignment_with_semicolon
	| non_blocking_assignment_with_semicolon 

procedural_timing_control_statement : 
        delay_or_event_control 
        statement_or_null

procedural_continuous_assignment_with_semicolon :
	procedural_continuous_assignment 
	';'

seq_block : 
        'begin' 
	<commit>
        block_identifier_block_item_declaration(?)      
        statement(s?)
        'end'
	| <error?> <reject>

conditional_statement : 
        'if' 
	<commit>
	'(' expression ')'
        statement_or_null 
        else_statement_or_null(?)
	| <error?> <reject>

case_statement : 
	  casez_endcase  
	| casex_endcase
	| case_endcase  

loop_statement : 
	  forever_statement 
	| repeat_expression_statement  
	| while_expression_statement  
	| for_reg_assignment_expression_reg_assignment_statement

wait_statement : 
        'wait' 
	<commit>
        '(' 
        expression 
        ')' 
        statement_or_null
	| <error?> <reject>

disable_statement : 
        'disable' 
 	<commit>
       ( task_identifier | block_identifier ) 
        ';'                
	| <error?> <reject>

event_trigger : 
        '->' 
	<commit>
	event_identifier ';'
	| <error?> <reject>

par_block : 
        'fork' 
	<commit>
        block_identifier_block_item_declaration(?)      
        statement(s?)
        'join'
	| <error?> <reject>

task_enable : 
        task_identifier
        expression_list_in_paren(?)
        ';'

system_task_enable :
        system_task_name
        expression_list_in_paren(?)
        ';'

blocking_assignment_with_semicolon :
	blocking_assignment 
	';'

non_blocking_assignment_with_semicolon :
	non_blocking_assignment 
	';'


case_endcase :
        'case' 
	<commit>
	expression_case_item_list 'endcase'
	| <error?> <reject>

casez_endcase :
        'casez' 
	<commit>
	expression_case_item_list 'endcase'
	| <error?> <reject>

casex_endcase :
        'casex' 
	<commit>
	expression_case_item_list 'endcase'
	| <error?> <reject>


statement_or_null : 
        statement | ';'


blocking_assignment :
        reg_lvalue 
        '='
	<commit>
        delay_or_event_control(?)
        expression
	| <error?> <reject>

non_blocking_assignment :
        reg_lvalue 
        '<='
	<commit>
        delay_or_event_control(?)
        expression
	| <error?> <reject>

procedural_continuous_assignment :
          assign_reg_assignment 
	| deassign_reg_lvalue 
	| force_reg_assignment 
	| force_net_assignment 
	| release_reg_lvalue 
	| release_net_lvalue 

assign_reg_assignment :
        'assign' 
	<commit>
	reg_assignment ';'
	| <error?> <reject>

deassign_reg_lvalue :
        'deassign' 
	<commit>
	reg_lvalue ';'
	| <error?> <reject>

force_reg_assignment :
        'force' 
	reg_assignment ';'

force_net_assignment :
        'force' 
	net_assignment ';'

release_reg_lvalue :
        'release' 
	reg_lvalue ';'

release_net_lvalue :
        'release' 
	net_lvalue ';'

delay_or_event_control : 
          delay_control
        | event_control
        | repeat_expression_event_control

delay_control :
	'#' 
	<commit>
	delay_value_or_mintypmax_expression_in_paren                
	| <error?> <reject>

delay_value_or_mintypmax_expression_in_paren :
	delay_value | mintypmax_expression_in_paren

mintypmax_expression_in_paren : 
	 '(' mintypmax_expression ')'

event_control :
	'@' 
	<commit>
	event_identifier_or_event_expression_list_in_paren
	| <error?> <reject>

event_identifier_or_event_expression_list_in_paren :
	  event_expression_list_in_paren
	| event_identifier

event_expression_list_in_paren :
	'('
	event_expression or_event_expression(s?)
	')'

or_event_expression :
	'or' 
	<commit>
	event_expression
	| <error?> <reject>

event_expression : 
	  posedge_expression 
	| negedge_expression 
	| expression 
	| event_identifier 

posedge_expression :
        'posedge' 
	<commit>
        expression
	| <error?> <reject>
negedge_expression :
        'negedge' 
	<commit>
        expression
	| <error?> <reject>

repeat_expression_event_control :
	'repeat'
	<commit>
	'('
	expression
	')'
	event_control
	| <error?> <reject>


else_statement_or_null :
        'else'
	<commit>
        statement_or_null
	| <error?> <reject>

expression_case_item_list :
        '(' expression ')' case_item(s)

case_item : 
	  default_statement_or_null 
	| expression_list_statement_or_null 

expression_list_statement_or_null : 
        expression_comma_expression 
        ':'
        statement_or_null

default_statement_or_null : 
        'default' 
	<commit>
        ':'
        statement_or_null
	| <error?> <reject>

forever_statement :
        'forever'
 	<commit>
        statement
	| <error?> <reject>
repeat_expression_statement : 
        'repeat'
	<commit>
        '(' expression ')'
        statement 
	| <error?> <reject>
while_expression_statement : 
        'while'
	<commit>
        '(' expression ')'
        statement
	| <error?> <reject>
for_reg_assignment_expression_reg_assignment_statement :
        'for' 
	<commit>
	'(' 
        reg_assignment ';'
        expression ';'
        reg_assignment 
	')'
        statement
	| <error?> <reject>

reg_assignment : 
        reg_lvalue '=' expression 

block_identifier_block_item_declaration :
	':'
	<commit>
	block_identifier
	block_item_declaration(s?)
	| <error?> <reject>

expression_list_in_paren :
        '('
        expression_comma_expression
        ')'

system_task_name :
        '$'
	<skip:''>
	identifier 





##########################################################################
# specify section 
##########################################################################

specify_block :
        specify_item(s?)
        'endspecify'
	| <error>

specify_item :
	  specparam_declaration   
	| path_declaration  
	| system_timing_check 

specparam_declaration :
        'specparam'
	<commit>
        specparam_assignment_comma_specparam_assignment
        ';'
	| <error?> <reject>

specparam_assignment_comma_specparam_assignment :
	specparam_assignment
	comma_specparam_assignment(s?)

comma_specparam_assignment :
	','
	<commit>
	specparam_assignment
	| <error?> <reject>

specparam_assignment :
 	  specparam_identifier_equal_constant_expression  
	| pulse_control_specparam
 
specparam_identifier_equal_constant_expression :
        specparam_identifier
        '='
        constant_expression

pulse_control_specparam :
	  pathpulse_reject_limit_value 
	| pathpulse_specify_input_terminal_descriptor

pathpulse_reject_limit_value :
        'PATHPULSE$'
 	<commit>
       '='
        '('
        reject_limit_value
        comma_erro_limit_value(?)
        ')' ';'
	| <error?> <reject>
comma_erro_limit_value :
        ','
	<commit>
        error_limit_value
	| <error?> <reject>
pathpulse_specify_input_terminal_descriptor :
        'PATHPULSE$'
	<commit>
        specify_input_terminal_descriptor
        '$'
        specify_output_terminal_descriptor
        '='
        '(' 
        reject_limit_value
        comma_erro_limit_value(?)
        ')' ';'
	| <error?> <reject>

limit_value :
        constant_mintypmax_expression

reject_limit_value :
	limit_value

error_limit_value :
	limit_value


path_declaration :
	(
	  simple_path_declaration |
	| edge_sensitive_path_declaration |
	| state_dependent_path_declaration 
	)
        ';'

simple_path_declaration :
        (
        parallel_path_description |
        full_path_description
        )
        '='
        path_delay_value

parallel_path_description :
        '('
        specify_input_terminal_descriptor
        polarity_operator(?)
        '=>'
        specify_output_terminal_descriptor 
        ')'

full_path_description :
        '('
        list_of_path_inputs 
        polarity_operator(?)
        '*>'
        list_of_path_outputs
        ')'

list_of_path_inputs :
	specify_input_terminal_descriptor 
	comma_specify_input_terminal_descriptor(s?)

comma_specify_input_terminal_descriptor :
	','
	<commit>
	specify_input_terminal_descriptor
	| <error?> <reject>
list_of_path_outputs :
        specify_output_terminal_descriptor_comma_specify_output_terminal_descriptor

specify_output_terminal_descriptor_comma_specify_output_terminal_descriptor :
	specify_output_terminal_descriptor
	comma_specify_output_terminal_descriptor(s?)

comma_specify_output_terminal_descriptor :
	','
	<commit>
	specify_output_terminal_descriptor
	| <error?> <reject>

specify_input_terminal_descriptor : 
        input_identifier 

specify_output_terminal_descriptor : 
        output_identifier 

input_identifier : 
	  input_port_identifier 
	| inout_port_identifier

output_identifier : 
	  output_port_identifier  
	| inout_port_identifier

polarity_operator :
          '+' | '-'  


path_delay_value : 
        '('
	<commit>
        list_of_path_delay_expressions
        ')'
	| <error?> <reject>

list_of_path_delay_expressions : 
	  twelve_path_delay_expressions
	| six_path_delay_expressions 
	| three_path_delay_expressions 
	| two_path_delay_expressions 
	| one_path_delay_expression 

one_path_delay_expression :
        t_pde

two_path_delay_expressions :
        trise_pde ',' tfall_pde

three_path_delay_expressions :
        trise_pde ',' tfall_pde ',' tz_pde

six_path_delay_expressions :
        t01_pde ',' t10_pde ',' t0z_pde ','

        tz1_pde ',' t1z_pde ',' tz0_pde

twelve_path_delay_expressions :
        t01_pde ',' t10_pde ',' t0z_pde ','
        tz1_pde ',' t1z_pde ',' tz0_pde ','
        t0x_pde ',' tx1_pde ',' t1x_pde ','
        tx0_pde ',' txz_pde ',' tzx_pde

t_pde :
        path_delay_expression

trise_pde :
        path_delay_expression


tfall_pde :
        path_delay_expression

tz_pde :
        path_delay_expression

t01_pde :
        path_delay_expression

t10_pde :
        path_delay_expression

t0z_pde :
        path_delay_expression

tz1_pde :
        path_delay_expression

t1z_pde :
        path_delay_expression

tz0_pde :
        path_delay_expression

t0x_pde :
        path_delay_expression

tx1_pde :
        path_delay_expression

t1x_pde :
        path_delay_expression

tx0_pde :
        path_delay_expression

txz_pde :
        path_delay_expression

tzx_pde :
        path_delay_expression

path_delay_expression :
        constant_mintypmax_expression

edge_sensitive_path_declaration :
	  parallel_edge_sensitive_path_description_equal_path_delay_value
	| full_edge_sensitive_path_description_equal_path_delay_value

parallel_edge_sensitive_path_description_equal_path_delay_value :
        parallel_edge_sensitive_path_description 
        '=' 
        path_delay_value 

full_edge_sensitive_path_description_equal_path_delay_value : 
        full_edge_sensitive_path_description
        '='
        path_delay_value

# check this
parallel_edge_sensitive_path_description : 
        '('
        edge_identifier(?)
        specify_input_terminal_descriptor
        '=>'
        specify_output_terminal_descriptor
        polarity_operator(?)
        ':'
        data_source_expression
        ')'

# check this rule
full_edge_sensitive_path_description : 
        '('
        edge_identifier(?)
        list_of_path_inputs
        '*>'
        list_of_path_outputs
        polarity_operator(?)
        ':'
        data_source_expression 
        ')'
        

data_source_expression :
        expression

edge_identifier : 
        'posedge' | 'negedge'

state_dependent_path_declaration : 
	  ifnone_simple_path_declaration 
	| if_conditional_expression_simple_or_edge_path_declaration

if_conditional_expression_simple_or_edge_path_declaration :
        'if' 
	<commit>
        '(' conditional_expression ')'
        simple_path_or_edge_sensitive_path_declaration 
	| <error?> <reject>

simple_path_or_edge_sensitive_path_declaration :
          simple_path_declaration
        | edge_sensitive_path_declaration

ifnone_simple_path_declaration :
        'ifnone'
	<commit>
        simple_path_declaration
	| <error?> <reject>

system_timing_check : 
	  setuphold_timing_check  
	| hold_timing_check  
	| period_timing_check  
	| width_timing_check  
	| skew_timing_check   
	| recovery_timing_check  
	| setup_timing_check


setup_timing_check :
        '$setup' 			
	<commit>
        '(' 				
        timing_check_event 		
	','				
        timing_check_event 		
	','				
        timing_check_limit 		
        comma_notify_register(?)	
        ')' 				
        ';'				
	| <error?> <reject>

hold_timing_check :
        '$hold'
	<commit>
        '(' 
        timing_check_event ','
        timing_check_event ','
        timing_check_limit 
        comma_notify_register(?)
        ')' 
        ';'
	| <error?> <reject>

period_timing_check :
        '$period'
	<commit>
        '(' 
        controlled_timing_check_event ','
        timing_check_limit 
        comma_notify_register(?)
        ')' 
        ';'
	| <error?> <reject>

width_timing_check :
        '$width'
	<commit>
        '(' 
        controlled_timing_check_event ','
        timing_check_limit ','
        constant_expression 
        comma_notify_register(?)
        ')' 
        ';'
	| <error?> <reject>

skew_timing_check :
        '$skew'
	<commit>
        '(' 
        timing_check_event ','
        timing_check_event ','
        timing_check_limit 
        comma_notify_register(?)
        ')' 
        ';'
	| <error?> <reject>

recovery_timing_check :
        '$recovery'
	<commit>
        '(' 
        controlled_timing_check_event ','
        timing_check_event ','
        timing_check_limit 
        comma_notify_register(?)
        ')' 
        ';'
	| <error?> <reject>

setuphold_timing_check :
        '$setuphold'
	<commit>
        '(' 
        timing_check_event ','
        timing_check_event ','
        timing_check_limit ','
        timing_check_limit 
        comma_notify_register(?)
        ')' 
        ';'
	| <error?> <reject>

comma_notify_register :
         ',' 
	<commit>
	notify_register
	| <error?> <reject>

timing_check_event :
        timing_check_event_control(?)        	
        specify_terminal_descriptor 		
        ampersand_timing_check_condition(?) 	

ampersand_timing_check_condition : 
        '&&&' 
	<commit>
	timing_check_condition
	| <error?> <reject>

specify_terminal_descriptor :
	  specify_input_terminal_descriptor  
	| specify_output_terminal_descriptor 

controlled_timing_check_event : 
        timing_check_event_control
	<commit>
        specify_terminal_descriptor
        ampersand_timing_check_condition(?)
	| <error?> <reject>

timing_check_event_control :
	  'posedge'  
	| 'negedge'  
	| edge_control_specifier

edge_control_specifier : 
        'edge'
        '['
        edge_descriptor
        comma_edge_descriptor(?)
        ']'

comma_edge_descriptor : 
        ',' 
	<commit>
	edge_descriptor
	| <error?> <reject>

edge_descriptor :  
          '01' | '10' | '0x' | 'x1' | ' 1x' | 'x0'  

timing_check_condition : 
	  scalar_timing_check_condition  
	| scalar_timing_check_condition_in_parens

scalar_timing_check_condition_in_parens : 
        '(' scalar_timing_check_condition ')'

scalar_timing_check_condition : 
	  tilde_expression 
	| triple_equal_expression
	| double_equal_expression
	| triple_not_equal_expression 
	| double_not_equal_expression 
	| expression  

tilde_expression :
        '~' 
	<commit>
	expression
	| <error?> <reject>
double_equal_expression :
        expression 
	'==' 
	<commit>
	scalar_constant
	| <error?> <reject>
triple_equal_expression :
        expression 
	'===' 
	<commit>
	scalar_constant
	| <error?> <reject>
double_not_equal_expression :
        expression 
	<commit>
	'!=' 
	scalar_constant
	| <error?> <reject>
triple_not_equal_expression :
        expression 
	<commit>
	'!==' 
	scalar_constant
	| <error?> <reject>

timing_check_limit : 
        expression

scalar_constant :
          "1'b0" | "1'b1" | "1'B0" | "1'B1" | 
           "'b0" |  "'b1" |  "'B0" |  "'B1" | 
             '1' | '0' 

notify_register : 
        register_identifier


##############################################################
# expressions
##############################################################

expression_comma_expression : 
	expression
	comma_expression(s?)

comma_expression :
	','
	<commit>
	expression
	| <error?> <reject>

bit_selection_or_bit_slice :
	'['
	<commit>
	expression
	colon_expression(?)
	']'
	| <error?> <reject>

colon_expression :
	':'
	<commit>
	expression
	| <error?> <reject>

net_lvalue : 
	  net_concatenation
	| net_identifier_with_bit_selection


# is there any difference between net_concatenation and reg_concatenation???
net_concatenation : 
        '{' 
	expression_comma_expression 
	'}'

net_identifier_with_bit_selection :
        net_identifier
	bit_selection_or_bit_slice(?)


reg_lvalue :
	  reg_concatenation
	| reg_identifier_with_bit_selection


reg_concatenation : 
        '{' expression_comma_expression '}'

reg_identifier_with_bit_selection :
        register_identifier
	bit_selection_or_bit_slice(?)

##################################################################
# need to be able to handle any of the following:
#  3 + 4
# ( 3 + 4 )
#  4 + 3 / -2 + 1 
# ( 3 + 4 ) * ( 5 - 1 )
# 3 + 4 ? 12 * 33 : 99 - 1
# 3 + 4 ? 12 * 33 ? 11 - 3 : 3 ? 23 - 33 : 334
##################################################################
constant_expression :
	  constant_trinary_expression
	| constant_expression_in_parens

constant_expression_in_parens :
	'(' constant_expression ')'
	{
	$return = $item{constant_expression};
	}

constant_trinary_expression : 
	constant_binary_series 
	question_constant_expr_colon_constant_expr(?)
	{
	my $primary=$item{constant_binary_series};
	my $final = $primary;
	my $rule_result = $item{question_constant_expr_colon_constant_expr};
	if(defined($rule_result))
		{
		my $conditional_secondary = pop(@$rule_result);
		if(defined($conditional_secondary))
			{
			my ($conditional, $secondary) = @$conditional_secondary;
			if(defined($conditional))
				{
				$final = $primary->conditional_operator($conditional, $secondary);
				}
			}
		}
	$return = $final;
	}

question_constant_expr_colon_constant_expr :
	'?' 
	<commit>
	constant_expression 
	':' 
	constant_expression 
	{
	my $first = $item[3];
	my $secon = $item[5];
	$return = [ $first, $secon ];
	1;
	}
	| <error?> <reject>

# must be able to handle 
# 4
# 4 + 3
# ( 4 + 3 )
# (4 + 3) / 2
# 4 + ( 3 / 2 )
# 4 + 3 / 2
# 4 + 3 / -2 + 1
# (4 + 3) / (-2 + 1)
# 4 + (3 / -2) + 1
#   4 + 3 / 2 + 1  
# ( 4 + 3 / 2 + 1 )
# 2 + 3 * ( ( 4 + 5 ) * 6 ) - 7 - 3
constant_binary_series :  
	                constant_unary_expr_or_parenthetical_constant_binary_series
	binary_operator_constant_unary_expr_or_parenthetical_constant_binary_series(s?)
	{
	my $left=$item{constant_unary_expr_or_parenthetical_constant_binary_series};
	my $right = $item{binary_operator_constant_unary_expr_or_parenthetical_constant_binary_series};
	my @list;
	push(@list,$left);
	foreach my $temp (@$right)
		{
		push(@list,@$temp);
		}
	my $final = $left->BinaryOperatorChain(@list);
	$return = $final;
	}

binary_operator_constant_unary_expr_or_parenthetical_constant_binary_series :
	binary_operator
	constant_unary_expr_or_parenthetical_constant_binary_series
	{
	$return = 
		[
		$item{binary_operator}, 
		$item{constant_unary_expr_or_parenthetical_constant_binary_series}
		];
	}

constant_unary_expr_or_parenthetical_constant_binary_series :
	  constant_uni_expr
	| parenthetical_constant_binary_series

parenthetical_constant_binary_series : 
	'(' constant_binary_series ')'
	{
	$return = $item{constant_binary_series};
	}

constant_uni_expr : 
	optional_unary_operator 
	constant_primary 
	{
	my $unary_operator = $item{optional_unary_operator};
	my $obj = $item{constant_primary};
	$return = $obj->unary_operator($unary_operator);
	}


constant_primary : 
	  constant_replication	 
	| number 		
	| return_parameter_value	 
	| constant_concatenation 
	| string_literal

return_parameter_value : 
	identifier
	{
	if(defined($main::param{$item{identifier}}))
		{
		$return =  $main::param{$item{identifier}};
		1;
		}
	else
		{
		$return = undef;
		undef;
		}
	}


constant_replication :
	'{'
	number
	constant_concatenation
	'}'

constant_concatenation :
        '{' constant_expression_comma_constant_expression '}'

constant_expression_comma_constant_expression :
	constant_expression
	comma_constant_expression(s?)

comma_constant_expression :
	','
	constant_expression

constant_mintypmax_expression :
        constant_expression 
        colon_constant_expression_colon_constant_expression(?)

colon_constant_expression_colon_constant_expression :
        ':'
	<commit>
        constant_expression 
        ':'
        constant_expression 
	| <error?> <reject>

mintypmax_expression :        
        expression 
        colon_expression_colon_expression(?)

colon_expression_colon_expression :
        ':'
        expression 
        ':'
        expression 

##################################################################
##################################################################

expression :
	  trinary_expression
	| expression_in_parens

expression_in_parens :
	'(' expression ')'
	{
	$return = $item{expression};
	}

trinary_expression : 
	binary_series 
	question_expr_colon_expr(?)

question_expr_colon_expr :
	 '?' 
	expression 
	':' 
	expression 

binary_series :  
	                unary_expr_or_parenthetical_binary_series
	binary_operator_unary_expr_or_parenthetical_binary_series(s?)

binary_operator_unary_expr_or_parenthetical_binary_series :
	binary_operator
	unary_expr_or_parenthetical_binary_series

unary_expr_or_parenthetical_binary_series :
	  uni_expr
	| parenthetical_binary_series

parenthetical_binary_series : 
	'(' binary_series ')'

uni_expr : 
	optional_unary_operator 
	primary 

optional_unary_operator : 
	  '~|' 
	| '~^' 
	| '~&' 
	| '^~' 
	| '+' 
	| '-' 
	| '!' 
	| '~' 
	| '&' 
	| '|' 
	| '^' 
	| { $return = '+'; 1;}

binary_operator : 
	  '===' 
	| '!==' 
	| '==' 
	| '&&' 
	| '||' 
	| '>=' 
	| '^~' 
	| '~^' 
	| '>>' 
	| '<<'
	| '!=' 
	| '<=' 
	| '+' 
	| '-' 
	| '*' 
	| '/' 
	| '%'
	| '<' 
	| '>'
	| '&' 
	| '|' 
	| '^' 

primary : 
	  replication
	| number 
	| return_parameter_value	 
	| function_call  
	| identifier_bit_selection_or_bit_slice 
	| concatenation 
	| mintypmax_expression_in_paren 
	| string_literal

replication :
	number
	concatenation
      
identifier_bit_selection_or_bit_slice :
        identifier  bit_selection_or_bit_slice(?) 

mintypmax_expression_in_paren :
        '(' mintypmax_expression ')'

number : 
	  base_indicating_number  
	| real_number

base_indicating_number :
        size_of_based_number   # note: size is optional, rule will return an empty string if no size is given.
	"'" 
	<commit>
	based_number
		{
		$return = Hardware::Verilog::StdLogic->new($item{size_of_based_number} . "'" . $item{based_number} );
		}
	| <error?> <reject>

size_of_based_number : 
	/([0-9][0-9_]*)/
	{ $return = $1; }
	|
	{ $return = ''; 1; }

based_number : 
	<skip:''>
	  base_bin_number
	| base_hex_number
	| base_dec_number
	| base_oct_number

base_bin_number :
	/([bB]\s*[xXzZ01][xXzZ01_]*)/ 
	{ $return = $1; }

base_hex_number :
	/([oO]\s*[xXzZ0-7][xXzZ0-7_]*)/ 
	{ $return = $1; }

base_dec_number :
	/([hH]\s*[xXzZ0-9a-fA-F][xXzZ0-9a-fA-F_]*)/ 
	{ $return = $1; }

base_oct_number :
	/([dD]\s*[0-9][0-9_]*)/ 
	{ $return = $1; }

real_number : 
        optional_sign 
	unsigned_number
	<skip:''>
	decimal_point_unsigned_number(?)
	exponent(?)
		{
		my $obj = Hardware::Verilog::StdLogic->new($item{unsigned_number});
		# $obj = $obj->minus;
		$return = $obj;
		}

optional_sign :
	  '-' {$return = '-';}
	| '+' {$return = '+';}
	|     {$return = '+';}

unsigned_number : 
	/[0-9][0-9_]*/

decimal_point_unsigned_number :
	<skip:''>
	'.'
	<commit>
	unsigned_number	
	| <error?> <reject>

exponent :
	<skip:''>
	/[eE]/
	<commit>
	optional_sign 
	unsigned_number
	| <error?> <reject>






concatenation : 
        '{' 
        expression_comma_expression
        '}'

function_call : 
	  function_identifier_parameter_list 
	| test_command_line_argument_definition
	| name_of_system_function_parameter_list

function_identifier_parameter_list : 
        function_identifier 
	{
	if (defined($main::func{$item{function_identifier}}))
		{ 
		$return = 1; 
		1;
		}
	else
		{ 
		$return = undef; 
		undef;
		}
	}
	'(' 
        expression_comma_expression
        ')'

name_of_system_function_parameter_list :
        name_of_system_function
	optional_system_function_parameter_list(?)

optional_system_function_parameter_list : 
        '(' 
        expression_comma_expression
        ')'

# note, do not allow space between dollar and function name
name_of_system_function : 
        '$'
	<skip:''>
	identifier

test_command_line_argument_definition :
	'$test$plusargs'
	'('
	string_literal
	')'

string_literal : 
        /("[^\n"]*")/  
	{ 
	$return = Hardware::Verilog::StdLogic->new($1);
	}

any_string_character : 
	/[^\n]/


scalar_expression :
	expression

conditional_expression :
	expression

#################################################################
# general
#################################################################



identifier :
        /[a-zA-Z][a-zA-Z_0-9\.]*/
	# add the period '.' at the end to allow hierarchical names.
	# if result contains a period, check that it is a valid hierarchy
	# path to the resulting signal. at the very least,
	# do not allow two periods to be adjacent.

block_identifier : 
	identifier

event_identifier : 
	identifier

function_identifier : 
	identifier

gate_instance_identifier : 
	identifier

inout_port_identifier : 
	identifier_bit_selection_or_bit_slice

input_port_identifier : 
	identifier_bit_selection_or_bit_slice

memory_identifier : 
	identifier

module_declaration_identifier :
	identifier

module_identifier : 
	identifier

module_instance_identifier : 
	identifier

net_identifier : 
	identifier

output_port_identifier : 
	identifier_bit_selection_or_bit_slice

parameter_identifier : 
	identifier

port_identifier : 
	identifier

real_identifier : 
	identifier

register_identifier : 
	identifier

specparam_identifier : 
	identifier

task_identifier : 
	identifier

terminal_identifier : 
	identifier

udp_identifier : 
	identifier

udp_instance_identifier : 
	identifier

udp_output_port_identifier : 
	identifier




_EOGRAMMAR_
#end of sub grammar
} #sub new

sub getGrammar {
  return $grammar;
}

1;
