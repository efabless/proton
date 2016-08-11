

foreach $key (sort(keys %ENV)) {
    print "$key = $ENV{$key}<br>\n";
}

$eq = $ENV{EQATOR_HOME};
print "$eq\n";
