<?php
system("/home/mansis/Projects/proton/SCRATCH/list_of_file -file ../data_1/top");
$file = "list_of_file.txt";
$lines = file($file, FILE_IGNORE_NEW_LINES);
for($i=0;$i< count($lines);$i++){
  $file_name = basename($lines[$i]);
  system(copy($lines[$i],"./".$file_name));
}
?>
<?php
