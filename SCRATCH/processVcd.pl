#!/usr/bin/perl -w

open(READ,"$ARGV[0]");
my @tmpAray = ();
my $prevSig = "";
while(<READ>) {
chomp();

#---- not print if within pattern ---#
if (/\$scope/ ... /\$upscope/ ) {
# --- do some processing here ---#
   if ($_ =~ /var wire/ ) {
   if ($_ =~/\[\d+\]/ ) {
    my $currSig = (split(/\s+/),$_)[4];
    $currSig =~ s/\[.*//;
    if ($currSig ne $prevSig ) {
            @tmpAray = specialSort(@tmpAray);
            print join("\n", @tmpAray),"\n"  if (@tmpAray > 0);
            @tmpAray = ();
            push(@tmpAray,$_);
                               } else {
    push(@tmpAray,$_);
                                      }
    $prevSig = $currSig;
                        }
 else {      
            @tmpAray = specialSort(@tmpAray);
            print join("\n", @tmpAray),"\n"  if (@tmpAray > 0);
            @tmpAray = ();
            print "$_\n"; 
      }
                          } # only process signal lines 
 else { 
            @tmpAray = specialSort(@tmpAray);
            print join("\n", @tmpAray),"\n"  if (@tmpAray > 0);
            @tmpAray = ();
print "$_\n"; } 
                                 }
 else { print "$_\n"; } 
}#while


sub specialSort {
my @inArr = @_;
my @outArr = ();
@outArr = sort { substr($b,-7,1) <=> substr($a,-7,1) } @inArr;
return(@outArr);
}
