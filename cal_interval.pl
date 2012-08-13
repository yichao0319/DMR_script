#!/bin/perl

# $num_batch = `grep \"batch num\" tmp.out.txt | wc -l`;
# print "-->".$num_batch."\n";
# 
# $total = $num_batch * 16.0 * 8 / 1024 / 20;
# 
# printf "%.9f \n", $total;

open(CAT, "grep \"node1 start transmitting packet size(1088)\" tmp.out.txt | ") || die "Failed: $!\n";

my $pre = 0;
my $pre_line = "";
while(<CAT>) {
	# print $_;
	if($_ =~ /===(\d+) /) {
		# print $1."\n";
		# print $pre."\n";
		
		my $cur = $1;
		my $diff = $cur - $pre;
		
		if($diff > (1492 + 168 * 2 + 15*9 + 32 + 4) * 1000) {
			print $cur.": ";
		}
		print $diff."\n";
		
		$pre = $cur;
		$pre_line = $_
	}
}