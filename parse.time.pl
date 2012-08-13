#!/bin/perl

use strict;

# $num_batch = `grep \"batch num\" tmp.out.txt | wc -l`;
# print "-->".$num_batch."\n";
# 
# $total = $num_batch * 16.0 * 8 / 1024 / 20;
# 
# printf "%.9f \n", $total;

my @total_time;
my @qualnet_time;
my @lp_throughput;
my @qualnet_throughput;
my @links;


###################
## time
open(CAT, "grep \"elapsed time\" tmp.out.txt | ") || die "Failed: $!\n";

my $ela_time = -1;
my $cnt = 0;
while(<CAT>) {
	# print $_;
	if($_ =~ /all elapsed time: (\d+\.\d*)/) {
		# print $1."\t";
		# print $ela_time."\n";
		if($cnt %10 == 0) {
			print "\n";
		}
		$cnt ++;
		
		push(@total_time, $1);
		if($ela_time != -1) {
			push(@qualnet_time, $ela_time);
			# print $1."\t".$ela_time."\n";
		}
		else {
			push(@qualnet_time, 0);
			# print $1."\t0\n";
		}

		$ela_time = -1;
	}
	elsif($_ =~ /elapsed time: (\d+\.\d*)/) {
		# print $1."\n";
		# print $pre."\n";
		
		$ela_time = $1;
	}
}

close(CAT);



###################
## number of links
open(CAT, "grep \" links\" tmp.out.txt | ") || die "Failed: $!\n";

$cnt = 0;
while(<CAT>) {
	print $_;
	if($_ =~ /generate_conflict_composite_link: (\d+) links/) {
		if($cnt %10 == 0) {
			print "\n";
		}
		$cnt ++;
		
		push(@links, $1);
		print $1."\n";
	}
}

close(CAT);



###################
## throughput
open(CAT, "./show.summary.sh 2> /dev/null | ") || die "Failed: $!\n";

$cnt = 0;
my $lp_start = -1;
my $qualnet_start = -1;
while(<CAT>) {
	# print $_;
	if($_ =~ /summary\.lp\.MIMO\.p1\.r1.m2.MR1.R-1.11a.rl/) {
		$lp_start = 1;
		$qualnet_start = -1;
		$cnt = 0;
	}
	elsif($_ =~ /summary.\qualnet\.MIMO\.MR1.R6.11a.nrl/) {
		$lp_start = -1;
		$qualnet_start = 1;
		$cnt = 0;
	}
	elsif($lp_start == 1 || $qualnet_start == 1) {
		if($_ =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\.*\d*)\s+/) {
			my ($num_node, $num_flow, $seed, $tmp, $total_throughput) = ($1, $2, $3, $4, $5);
			if($cnt %10 == 0) {
				print "\n";
			}
			$cnt ++;
			
			if($lp_start == 1) {
				push(@lp_throughput, $total_throughput);
			}
			elsif($qualnet_start == 1) {
				push(@qualnet_throughput, $total_throughput);
			}
			print $total_throughput."\n";
		}
	}
}

close(CAT);



###################
## output
for my $cnt (0 ... scalar(@total_time)-1) {
	if($cnt %10 == 0) {
		print "\n";
	}
	
	print $lp_throughput[$cnt]."\t".$qualnet_throughput[$cnt]."\t".$total_time[$cnt]."\t".$qualnet_time[$cnt]."\t".$links[$cnt]."\n";
}

