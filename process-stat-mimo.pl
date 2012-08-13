#!/bin/perl -w
# sum.pl -- (c) UT Austin, Lili Qiu, Thu Jan 25 2007
#   <lili@cs.utexas.edu>
#
########################################################
$comment = "";
$multicast = 0;
$SPP = 0;

while ( $_ = $ARGV[0], /^-/ ) {
    shift;
    /^-t$/ and do { $transport = shift; next };
    /^-s$/ and do { $sim_time = shift; next };
    /^-g$/ and do { $multicast = shift; next };
    /^--$/ and do { last };
    /^-c$/ and do { $comment = shift; next };
    /^-m$/ and do { $maxThroughput = shift; next };
    /^-SPP$/ and do {$SPP = 1; next };
    die "Invalid option: $_\n";
}

$i = 0;
open(FlowRate,"<flow.txt") or die "cannot open flow.txt\n";
while (<FlowRate>)
{
    @lst = split " ", $_;
    if ($multicast)
    {
        my(@dest_lst) = ();
	$src[$i] = $lst[1]+1;
        foreach my $j ( 2 .. $#lst )
        {
            $dest_lst[$j-2] = $lst[$j] + 1;
        }
	$dest[$i] = join " ", @dest_lst;
    }else{
	$src[$i] = $lst[1]+1;
	$dest[$i] = $lst[2]+1;
    }
    # print $src[$i]," ",$dest[$i],"\n";
    $i++;
}
close(FlowRate);

$conn = $i;
$total = 0;

while (<>)
{
    if ($transport) # UDP
    {
	if( $multicast && !$SPP )
	{
	    if(/Server,Client Address/){
		@lst = split ",", $_;
		@lst2 = split "=", $lst[$#lst];
		@lst3 = split /\./, $lst2[$#lst2];
		# print (join "=", @lst3);
		$curr_dest = $lst[0]+0;
		$curr_src = $lst3[$#lst3]+0;
		# print " src = $src dest = $dest\n"; 
	    }elsif(/Server,Total Bytes Received/){
		#print "here2\n";
		@lst = split "=", $_;
		$thruput{$curr_src}{$curr_dest} = ($lst[1]+0)*8/$sim_time;
		$total += $thruput{$curr_src}{$curr_dest};
	    }
	}
	else{
	
	    ## add by yichao: new throughput calculation
	    if(/number of batches/) {
		# @lst = split "=", $_;
		# $total += ($lst[1]+0)*8*12 * 1024 / 1000.0 / 1000.0 / $sim_time;
		
		@lst = split ",", $_;
		$curr_dest = $lst[0] + 0;
		@lst2 = split "=", $lst[5];
		$my_throughput{$curr_dest} = ($lst2[1]+0)*8*12 * 1024 / 1000.0 / 1000.0 / $sim_time;
		$total += ($lst2[1]+0)*8*12 * 1024 / 1000.0 / 1000.0 / $sim_time;
	    }
	    ## end add by yichao
	
	
	    if (/Server,Client address/) {
		@lst = split ",", $_;
		@lst2 = split "=", $lst[$#lst];
		@lst3 = split /\./, $lst2[$#lst2];
		# print (join "=", @lst3);
		$curr_dest = $lst[0]+0;
		$curr_src = $lst3[$#lst3]+0;
		# print " src = $src dest = $dest\n"; 
	    }
	    # elsif (/Server,Throughput/) {
	    #    @lst = split "=", $_;
	    #    $total += $lst[1];
	    #    $thruput{$curr_src}{$curr_dest} = $lst[1]+0;
	    # }
	    elsif (/Server,Total Bytes Received/) {
		@lst = split "=", $_;
		if(!defined $thruput{$curr_src}{$curr_dest}) {
			$thruput{$curr_src}{$curr_dest} = ($lst[1]+0)*8/$sim_time;
			# $total += $thruput{$curr_src}{$curr_dest};	## remove by yichao
		}
		else {
			$thruput{$curr_src}{$curr_dest} += ($lst[1]+0)*8/$sim_time;
			# $total += ($lst[1]+0)*8/$sim_time;		## remove by yichao
		}
		# $thruput{$curr_src}{$curr_dest} = ($lst[1]+0)*8/$sim_time;
		# $total += $thruput{$curr_src}{$curr_dest};
	    }
	}
    }
    else # TCP
    {
        if (/Server,Connection: Client/) {
            @lst = split ":", $_;
            @lst2 = split /\(/, $lst[1];
            $curr_src = $lst2[1]+0;
            @lst3 = split ",", $_;
            $curr_dest = $lst3[0]+0;
        }
        elsif (/Server,Total req fragment bytes received/) {
            @lst = split "=", $_;
            $thruput{$curr_src}{$curr_dest} += ($lst[1]+0)*8/$sim_time;
            $total += ($lst[1]+0)*8/$sim_time;
        }
    }
}

printf "%s ",$comment;

if ($multicast)
{
    my(@min_throughput);
    my($total) = 0;

    foreach $i ( 0 .. $conn-1 )
    {
	my @all_dst = split " ", $dest[$i]; 
	$min_throughput[$i] = -1;
        
	foreach $d ( @all_dst ){
	 
	    $thruput{$src[$i]}{$d} += 0;
	    $min_throughput[$i] = $thruput{$src[$i]}{$d} if ($min_throughput[$i] == -1 || $min_throughput[$i] > $thruput{$src[$i]}{$d});
        }

        $total += $min_throughput[$i];
    }
    
    printf "%.9f ", $total;
    foreach $i ( 0 .. $conn-1 )
    {
        printf "%.9f ", $min_throughput[$i]; 
        my @all_dst = split " ", $dest[$i];

        printf "%d ", @all_dst+0;
        
	foreach $d (@all_dst )
	{
	    printf "%.9f ", $thruput{$src[$i]}{$d};
	}
    }
}else{
    printf "%.9f ", $total;
    foreach $i ( 0 .. $conn-1 )
    {
	$thruput{$src[$i]}{$dest[$i]} += 0;
	# printf "%.9f ", $thruput{$src[$i]}{$dest[$i]}; # /$maxThroughput; ## removed by yichao
	printf "%.9f ", $my_throughput{$dest[$i]};
    }
}
print "\n";
