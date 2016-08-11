#! /usr/bin/perl 
#area.txt
#read.txt

#$newarea=6;
#$pattern="always";
$filename = shift;
$areafile = "area.out";
#$area=5;

open(FILE, $filename) or die "Could not open file: $!";


my $finalarea=0;
my $category=start;
my $index;
my $bitsize;
my $area;
my $sum;
my $buff;
my $newcategory;
my $addersub = addersub;   # For subtracting a number when we have an adder
my $subsub = subsub;
my %hashsum;
while(my $line=<FILE>){

  if($line =~ /(\S+)\s+(\d+)\s+(\d+)/ ) {
	$sum = 0; #print "sum = $sum\n";
        $buff=0;
        $newcategory = ${1};
        if ($category ne $newcategory) {print "changing category from $category to $newcategory\n";}
        $category = $newcategory; 
        
	$index = ${2};
        $bitsize = ${3}; 

        if ($category eq ">>") {
           $sum = $index - $bitsize ;
        }
        elsif ($category eq "<<") {
           $sum = $index - $bitsize ; 
        }
        elsif ($category eq ">>>") {
           $sum = $index - $bitsize ; 
        }
        elsif ($category eq "<<<") {
           $sum = $index - $bitsize ; 
        }
        elsif ($category eq "CASE") {
           $sum = $index + $bitsize ; 
        }
        elsif ($category eq "?:") {
           $sum = $index + $bitsize ; 
        }
        elsif ($category eq "*") {
           $sum = ($index > $bitsize) ? $index : $bitsize ; 
        }
        elsif ($category eq "+") {
                              if ($index eq $bitsize){
                                  $sum = $index; 
                                  }
                              elsif ($index > $bitsize) {
                                  $hashsum{$category} = $hashsum{$category} + $index;
                                  $sum = $index - $bitsize;
                                  $category = $addersub; }
                              elsif ($bitsize > $index) {
                                  $hashsum{$category} = $hashsum{$category} + $bitsize;
                                  $sum = $bitsize - $index;
                                  $category = $addersub; } 
        }
        elsif ($category eq "-") {
                              if ($index eq $bitsize){
                                  $sum = $index; 
                                  }
                              elsif ($index > $bitsize) {
                                  $hashsum{$category} = $index;
                                  $sum = $index - $bitsize;
                                  $category = $subsub; }
                              elsif ($bitsize > $index) {
                                  $hashsum{$category} = $bitsize;
                                  $sum = $bitsize - $index;
                                  $category = $subsub; } 
        }
        elsif ($category eq "==") {
                               $sum = ($index > $bitsize)? $index : $bitsize;
                                  }
        elsif ($category eq "!=") {
                               $sum = ($index > $bitsize)? $index : $bitsize;
                                  }
        elsif ($category eq "===") {
                               $sum = ($index > $bitsize)? $index : $bitsize;
                                  }
        elsif ($category eq "!==") {
                               $sum = ($index > $bitsize)? $index : $bitsize;
                                  }
        elsif ($category eq "&") {
                               $sum = ($index > $bitsize)? $index : $bitsize;
                                  }        
        elsif ($category eq "&&") {
                               $sum = ($index > $bitsize)? $index : $bitsize;
                                  }
        elsif ($category eq "|") {
                               $sum = ($index > $bitsize)? $index : $bitsize;
                                  }
        elsif ($category eq "||") {
                               $sum = ($index > $bitsize)? $index : $bitsize;
                                  }
        elsif ($category eq "or") {
                               $sum = ($index > $bitsize)? $index : $bitsize;
                                  }
        elsif ($category eq "and") {
                               $sum = ($index > $bitsize)? $index : $bitsize;
                                  }
        elsif ($category eq "^") {
                               $sum = ($index > $bitsize)? $index : $bitsize;
                                  }
        elsif ($category eq "IF_ELSE") {
                               $sum = $index + $bitsize;
                                  }
        elsif ($category eq "IF") {
                               $sum = $index + $bitsize;
                                  }
        elsif ($category eq "ELSE") {
                               $sum = $index + $bitsize;
                                  }
        elsif ($category eq "ELSE_IF") {
                               $sum = $index + $bitsize;
                                  }
        

        else {
        $sum = $sum + $bitsize;
        }
        
        if (exists $hashsum{$category}) {
          $sum = $sum + $hashsum{$category};
          $hashsum{$category} = $sum;
        } else {
         $hashsum{$category} = $sum;
        }

        ##print "sum = $sum\n";
  } # end of if

  elsif ($line =~ /(\d+)\s+(\d+)/ ) {
     
    if ($category eq ">>") {
           $sum = $sum + ${1} - ${2} ;
           $hashsum{$category} = $sum;
        }
        elsif ($category eq "<<") {
           $sum = $sum + ${1} - ${2} ; 
           $hashsum{$category} = $sum;
        }
        elsif ($category eq ">>>") {
           $sum = $sum + ${1} - ${2} ; 
           $hashsum{$category} = $sum;
        }
        
        elsif ($category eq "==") {
                               $sum = $sum + ((${1} > ${2})? ${1} : ${2}); 
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "!=") {
                               $sum = $sum + ((${1} > ${2})? ${1} : ${2}); 
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "===") {
                               $sum = $sum + ((${1} > ${2})? ${1} : ${2}); 
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "!==") {
                               $sum = $sum + ((${1} > ${2})? ${1} : ${2}); 
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "&") {
                               $sum = $sum + ((${1} > ${2})? ${1} : ${2}); 
                               $hashsum{$category} = $sum;
                                  }        
        elsif ($category eq "&&") {
                               $sum = $sum + ((${1} > ${2})? ${1} : ${2}); 
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "|") {
                               $sum = $sum + ((${1} > ${2})? ${1} : ${2});  
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "||") {
                               $sum = $sum + ((${1} > ${2})? ${1} : ${2}); 
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "or") {
                               $sum = $sum + ((${1} > ${2})? ${1} : ${2}); 
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "and") {
                               $sum = $sum + ((${1} > ${2})? ${1} : ${2}); 
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "^") {
                               $sum = $sum + ((${1} > ${2})? ${1} : ${2}); 
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "IF_ELSE") {
                               $sum = $sum + ${1} + ${2}; 
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "IF") {
                               $sum = $sum + ${1} + ${2}; 
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "ELSE") {
                               $sum = $sum + ${1} + ${2}; 
                               $hashsum{$category} = $sum;
                                  }
        elsif ($category eq "ELSE_IF") {
                               $sum = $sum + ${1} + ${2}; 
                               $hashsum{$category} = $sum;
                                  }    

    
        elsif ($category eq "*") {
           $sum = $sum + ((${1} > ${2})? ${1} : ${2}) ; 
           $hashsum{$category} = $sum;
        }
        
        elsif ($category eq "<<<") {
           $sum = $sum + ${1} - ${2} ; 
           $hashsum{$category} = $sum;
        }
        elsif ($category eq "CASE") {
           $sum = $sum + ${1} + ${2} ; 
           $hashsum{$category} = $sum;
        } 
        elsif ($category eq "?:") {
           $sum = $sum + ${1} + ${2} ; 
           $hashsum{$category} = $sum;
        } 
        
        else {
           $sum = $sum + ${2}; ##print "category = $category, sum = $sum\n";
           $hashsum{$category} = $sum;
        }

  }  ## end of elsif

 elsif ($line =~ /(\S+)\s+(\d+)/ ){                         ## for ~ 1
        $sum = 0; #print "sum = $sum\n";
        $newcategory = ${1};
        if ($category ne $newcategory) {print "changing category from $category to $newcategory\n";}
        $category = $newcategory; 

	$index = 1;
        $bitsize = ${2};
        
        $sum = $sum + $bitsize;      
        
        if (exists $hashsum{$category}) {
          $sum = $sum + $hashsum{$category};
          $hashsum{$category} = $sum;
        } else {
         $hashsum{$category} = $sum;
        }
       
} 
  
} #end of while

print "\n";
while (($key, $value) = each(%hashsum)){
     print $key.": ".$value."\n";}


#while (($key, $value) = each(%hashsum)){
#         if ($key eq alwayspos) { $mytotalarea = ($mytotalarea + ($value*5)); }
#	}

$totalarea = (($hashsum{'always@pos'})*5) + 
             (($hashsum{'always@neg'})*5) +
             (($hashsum{'&&'})*1) +             
	     (($hashsum{'||'})*1) +             
             (($hashsum{'IF'})*1) +
             (($hashsum{'IF_ELSE'})*1) +             
             (($hashsum{'ELSE'})*1) +             
             (($hashsum{'ELSE_IF'})*1) +
             (($hashsum{'!'})*1) +
             (($hashsum{'~'})*1) +
             (($hashsum{'+'})*4) -  (($hashsum{"addersub"})*1) +
             (($hashsum{'-'})*5.5) -  (($hashsum{"subsub"})*3) +
             (($hashsum{'^'})*2) +
             (((log(($hashsum{'for'})+1))/log(2))*12) +       # 'for' loop adder
             (((log(($hashsum{'for'})+1))/log(2))*2.5) +      # 'for' loop comparator
             (($hashsum{'&'})*1) +
             (($hashsum{'|'})*1) +
             (($hashsum{'or'})*1) +
             (($hashsum{'and'})*1) +
             (($hashsum{'CASE'})*1) +
             (($hashsum{'?:'})*1) +
             (($hashsum{'=='})*2) + 
             (($hashsum{'==='})*2) +         # === not synthesizable, but still check incase wrongly coded
             (($hashsum{'!='})*2) +
             (($hashsum{'!=='})*2) +         # !== not synthesizable, but still check incase wrongly coded
             (($hashsum{'>'})*2.5) +
             (($hashsum{'<'})*2.5) +
             (($hashsum{'>>'})*5) +
             (($hashsum{'<<'})*5) +  
             (($hashsum{'>>>'})*5) +
             (($hashsum{'<<<'})*5) + 
             (  (($hashsum{'*'})/2)*  ((($hashsum{"*"})/2)-1)  *5) ;       

print "\nTotal area of the design is $totalarea\n\n";
open(AREA, "+>", $areafile) or die "Could not open file: $!";
print AREA $totalarea;

close AREA;
close FILE;
