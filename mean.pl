#!/usr/bin/perl
use strict;

my $meancolumn = 5;

my %sums = ();
my %cnt = ();
while( my $line = <> ){
  chomp($line);
  if ($line !~ /^\s*#/) {
    my @fields = split(/\,/,$line);
    if (scalar(@fields) < $meancolumn) { next;}

    my $prefix = join(',',@fields[0..$meancolumn-1]);
    my $postfix = join(',',@fields[($meancolumn+1) .. (scalar(@fields)-1)]);

    if (!defined($sums{$prefix})) {
      $sums{$prefix} = {};
      $cnt{$prefix} = {};
    }
    if (!defined($sums{$prefix}{$postfix})) {
      $sums{$prefix}{$postfix} = 0;
      $cnt{$prefix}{$postfix} = 0;
    }
    $sums{$prefix}{$postfix} += @fields[$meancolumn];
    $cnt{$prefix}{$postfix}++;
  } else {
    print "$line\n"; # to preserve the header
  }
}

foreach my $prefix (keys %sums) {
  my $hash_ref = $sums{$prefix};
  my %hash = %$hash_ref;
  foreach my $postfix (keys %hash) {
     print "$prefix,".$sums{$prefix}{$postfix}/$cnt{$prefix}{$postfix}.",$postfix\n";
  }
}

close MYDATA;

