#!/usr/bin/tclsh

proc parea { poly } {
   set xprev [lindex $poly end-1]
   set yprev [lindex $poly end]
   set area 0
   foreach { x y } $poly {
       set area [expr { $area + ( ($x - $xprev) * ( $y + $yprev) ) }]
       set xprev $x; set yprev $y
   }
   return [expr { abs( $area / 2. ) }]
}

set poly { 0 0 2 0 4 2 0 2 }
set area [parea $poly]
puts "area is :$area"
