#!/usr/bin/perl -w
use strict;
use ConflictGraphUtil;

my $ConnectivityThresh = 0;
my $MAX_CREDIT_FOR_SRC = 0;
my $DEBUG = 0;
my $DEBUGFILE = 0;
my $conflictFile = "conflict.txt";
my $conflictMultiFile = "conflict-multi.txt";
my $txIntervalFile = "txInterval.txt";
my $prune_thresh = $ARGV[0];
my $startNodeId = $ARGV[1]; # starting nodeId (0 for lowerbound, and 1 for qualnet)
my $defaultCapacity = $ARGV[2];
my $lossFile = $ARGV[3];

#my $multicastFile = "topo.group";
my @src_array=();
my @dst_array=();

my $fid;

#convert_conflict_graph_multi(); #ejr needed for get_route.txt

## STEP 1: read conflict graph file ##

my ($graph,$flows,$mgC, $rIns)=read_conflict_graph($conflictFile, $lossFile);
my %mgroupContains=%$mgC;
my %recvIns=%$rIns;

if ($DEBUG) 
{
    print "<print graph>\n";
    printGraph($graph);
    print "\n";
    print "<print flows>\n";
    printFlows($flows);
    print "\n";
}

## STEP 2: compute all flow shortest path
foreach $fid (0 .. $flows->{num_flow}-1)
{
    my $t_flow=$flows->{flow}{$fid};
    my $f_src=$t_flow->{src};
    my $f_dst=$t_flow->{dst};
    push @src_array, $f_src;
    push @dst_array, $f_dst;
}

my @root=(0 .. $graph->{num_node}-1);
my ($ddist,$ppath)=shortest_path(\@root,$graph);
my %path = %$ppath;
my %dist = %$ddist;
## now,
## path and dist have entries for (from each f_src to all nodes)

my @fwd_list=();
my @fwd_etx_list=();
remove_files();

&create_interval_file();

my %all_multicast=();

my ($forwarders);

foreach $fid (0 .. $flows->{num_flow}-1 ){
    printf " -------------------flow $fid -------------------\n";
    my $f_src=$src_array[$fid] +0;
    
    if ($DEBUG){
	print "FlowID ",$fid,":" ;
	print "[src$f_src ]\n"; 
    }

    foreach my $e ( @root )
    {
	$all_multicast{max_z}{$fid}{$e} = 0; # initialize max_z to 0
    }

    foreach my $rmem (keys %{$mgroupContains{$fid}})
    {
	my ($nl, $el);
	
	($nl,$el) = pick_all_forwarders_based_only_on_etx($f_src,$rmem,$graph,\%path,\%dist);
	
	@fwd_list=@$nl;
	@fwd_etx_list=@$el;
	
	my ($zs,$Ls)=solve_algorithm(\@fwd_list,\@fwd_etx_list,$graph);
	my @z_i=@$zs; # expected num transmissions done by node i
	my @L_i=@$Ls; # expected num pkts to forward by node i
	print "before pruning : \n";
	print "fwd_list : ";
	print join " ",@fwd_list;
	print "\n";
	print "z_i : ";
	print join " ",@z_i;
	print "\n";
	my($feasiblePruning,$pruned_list,$pruned_etx_list)=get_pruned_forwarders(\@L_i,\@z_i,$prune_thresh,$graph,$rmem,$f_src,\@fwd_list,\@fwd_etx_list);
	if($feasiblePruning == 0){
	    print "Infeasible pruning! After pruning src cannot reach dst!\n";
	    print "So do not prune \n";
	    
	}else{
	    @fwd_list=@$pruned_list;
	    @fwd_etx_list=@$pruned_etx_list;
	

	    print_fw_node(\@fwd_list, $fid, $f_src, $rmem, $graph, \%path, \%dist);
	    my ($zs,$Ls)=solve_algorithm(\@fwd_list,\@fwd_etx_list,$graph);
	    @z_i=@$zs; # expected num transmissions done by node i
	    @L_i=@$Ls; # expected num pkts to forward by node i
	    print "after pruning (value recomputed): \n";
	    print "fwd_list : ";
	    print join " ",@fwd_list;
	    print "\n";
	    print "z_i : ";
	    print join " ",@z_i;
	    print "\n";
	}

	## save info
	$all_multicast{fwd}{$fid}{$rmem}=join " ", @fwd_list;

	foreach my $n ( 0 .. $#fwd_list)
	{
	    my $f = $fwd_list[$n];
	    $all_multicast{etx}{$fid}{$rmem}{$f} = $fwd_etx_list[$n];
	    $all_multicast{z_i}{$fid}{$rmem}{$f} = $z_i[$n];
	    $all_multicast{L_i}{$fid}{$rmem}{$f} = $L_i[$n];
	    if($all_multicast{z_i}{$fid}{$rmem}{$f} > $all_multicast{max_z}{$fid}{$f})
	    {
		$all_multicast{max_z}{$fid}{$f} = $all_multicast{z_i}{$fid}{$rmem}{$f};
	    }
	}
	
    }

    my $all_fwds=print_tx_credit_multicast($fid,$f_src);
    ## print info
    foreach my $rmem (keys %{$mgroupContains{$fid}})
    {
	print "src$f_src dest_member$rmem forwarders: ";
	print "$all_multicast{fwd}{$fid}{$rmem}\n";
	my @fwd_list = split " ", $all_multicast{fwd}{$fid}{$rmem};
	foreach my $n ( 0 .. $#fwd_list)
	{
	    my $f = $fwd_list[$n];
	    
	    printf "fwd%d etx%.6f z%.6f L%.6f cr%.6f maxZ%.6f\n",$f, $all_multicast{etx}{$fid}{$rmem}{$f}, $all_multicast{z_i}{$fid}{$rmem}{$f},$all_multicast{L_i}{$fid}{$rmem}{$f}, $all_multicast{credit}{$fid}{$f}, $all_multicast{max_z}{$fid}{$f};
	}
	printf "\n";
    }
    
    printf "<summary total>\n";
    foreach my $f (@$all_fwds)
    {
	printf "--fwd%d cr%.6f maxZ%.6f\n",$f, $all_multicast{credit}{$fid}{$f}, $all_multicast{max_z}{$fid}{$f};
    }
    printf "\n";
}

sub remove_files
{

    if($startNodeId == 0)
    { 
	
	system("rm -f txInterval.txt fwdNode.txt txCredit.txt fwdRatio.txt fwdNodePruned.txt txCreditPruned.txt fwdRatioPruned.txt debugFwdNodePruned.txt");
    }
    else{
	
	system("rm -f txInterval.txt fwdNodeQ.txt txCreditQ.txt fwdRatioQ.txt fwdNodePrunedQ.txt txCreditPrunedQ.txt fwdRatioPrunedQ.txt ziQ.txt prevQ.txt debugFwdNodePrunedQ.txt");
    }
}

sub create_interval_file
{
    open(txIntervalFile,">$txIntervalFile");
    foreach my $fid (0 .. $flows->{num_flow}-1)
    {
	my $t_flow = $flows->{flow}{$fid};
	my $f_src = $t_flow->{src};
	my $interval = -1;
	printf txIntervalFile "$fid 0.0.0.%d %.2f\n", $f_src+1, $interval;
    }    
    close(txIntervalFile);
}

sub print_fw_node
{
    my ($connected_list,$flow_id,$f_src,$f_dst,$graph,$path,$dist) =@_;
    my ($filename, $forwarders);
    
    if ($startNodeId == 0)
    {
	$filename="debugFwdNodePruned";
    }
    else
    {
	$filename = "debugFwdNodePrunedQ";
    }
    
    $filename = "$filename.txt";

    open(FW_NODE_OUT,">>$filename");
    foreach my $current_node (@$connected_list){
	if ($current_node == $f_dst) {
	    next;
	}
	## get forwarder nodes for current_node to this dst
	my ($fds,$fds_etx)=pick_nexthop_forwarders_based_only_on_etx($current_node,$f_dst,$graph,$path,$dist,$connected_list);
	## candidate_forwarders is sorted according to etx 
	## lower index candidate_forwarder has lower etx (preferred)
	my @candidate_forwarders=@$fds;

	printf FW_NODE_OUT "%d %d %d %d %d ",$flow_id,$f_src+$startNodeId,$f_dst+$startNodeId, $current_node+$startNodeId, $#candidate_forwarders+1;
	foreach my $i (0 .. $#candidate_forwarders){ 
	    printf FW_NODE_OUT "%d ",$candidate_forwarders[$i]+$startNodeId;	    
	}
	printf FW_NODE_OUT "\n";
	$forwarders->{candidate_fwds}{"$flow_id $current_node"}=\@candidate_forwarders;
    }
    close(FW_NODE_OUT);
    return $forwarders;
}

sub print_tx_credit_multicast
{
    my ($fid, $f_src) = @_;
    my ($filename,$filename2,$filename3,$filename4);
    if ($startNodeId == 0)
    {
	$filename="txCreditPruned.txt";
	#$filename4="fwdNodePruned.txt";
    }
    else
    {
	$filename = "txCreditPrunedQ.txt";
	$filename2 = "ziQ.txt";
	$filename3 = "prevQ.txt";
	#$filename4 = "fwdNodePrunedQ.txt";
    }    
    my %previous=();
    my %seen=();
    my %credit=();
    my @all_forwarders=();
    if ( $startNodeId > 0 )
    {
	open (Z_OUT, ">>$filename2");
	printf Z_OUT "#flowId fwdId dstId z_i\n";
	open (PREV_OUT, ">>$filename3");
	printf PREV_OUT "#flowId fwdId dstId prevId lossrate\n";
    }
    foreach my $rmem (keys %{$mgroupContains{$fid}})
    {	
	my @fwd_list = split " ", $all_multicast{fwd}{$fid}{$rmem};
	foreach my $n ( 0 .. $#fwd_list)
	{
	    my $f = $fwd_list[$n];
	    if (! $seen{$f} )
	    {
		push @all_forwarders, $f;
	    }
	    $seen{$f} = 1;
	    # print max_z
	    printf " +  flow$fid dest_member$rmem cur$f z_i%.6f  <= max_z %.6f\n", $all_multicast{z_i}{$fid}{$rmem}{$f}, $all_multicast{max_z}{$fid}{$f};
	    if ( $startNodeId > 0 )
	    {
		printf Z_OUT "$fid %d %d %.6f\n", $f+$startNodeId, $rmem+$startNodeId, $all_multicast{z_i}{$fid}{$rmem}{$f};
	    }
	    # get previous
	    if ($n < $#fwd_list )
	    {
		foreach my $i ( $n+1 .. $#fwd_list )
		{
		    my $prev = $fwd_list[$i];
		    my $edge;
		    if ( $edge = $graph->{edges}{"$prev $f"} )	
		    {
			$all_multicast{previous}{$fid}{$f}{$prev} = 1;
			$all_multicast{prev2rmem}{$fid}{$f}{$prev} = $rmem;
			printf "  ++  f$fid rm$rmem cur$f prev$prev lossrate%.9f\n", $edge->{lossP} ;
			if ($startNodeId > 0 )
			{
			    printf PREV_OUT "$fid %d %d %d %.9f\n", $f+$startNodeId, $rmem+$startNodeId,$prev+$startNodeId, $edge->{lossP};
			}
		    }
		}
	    }
	}
    }
    if ($startNodeId > 0 )
    {
	close(Z_OUT);
	close(PREV_OUT);
    }
    open(TX_CREDIT_OUT,">>$filename");
    printf TX_CREDIT_OUT "#flowId nodeId tx_credit\n";
    #open(FW_NODE_OUT,">>$filename4");
    #printf FW_NODE_OUT "%d %d %d ",$fid, $all_forwarders[0]+$startNodeId, $#all_forwarders+1;
    foreach my $f (@all_forwarders)
    {

	#printf FW_NODE_OUT "%d ", $f+$startNodeId;

	if ($f == $f_src)
	{
	    print "-------------final result for flow$fid------------------\n";
	    $all_multicast{credit}{$fid}{$f} = $MAX_CREDIT_FOR_SRC;
	    printf TX_CREDIT_OUT "%d %d %.10f\n",$fid,$f+$startNodeId,$MAX_CREDIT_FOR_SRC;
	    next;
	}

	my $sum = 0;
	print "[fwd$f] ";
	foreach my $prev_node (keys %{$all_multicast{previous}{$fid}{$f}} )
	{
	    #printf "(f$fid prev$prev_node curr$f dst%d z_j%.5f) ", $all_multicast{prev2rmem}{$fid}{$f}{$prev_node};
	    my $edge = $graph->{edges}{"$prev_node $f"};		
	    my $loss = $edge->{lossP};
	    my $z_j = $all_multicast{max_z}{$fid}{$prev_node};
	    printf "flow$fid prev$prev_node curr$f dst%d z_j%.5f loss%.5f\n", $all_multicast{prev2rmem}{$fid}{$f}{$prev_node}, $z_j,$loss;
	    $sum=$sum+$z_j*(1-$loss);
	}
	printf " ---> sum is %.5f for node$f\n",$sum;
	printf " my max z_i is %.5f\n", $all_multicast{max_z}{$fid}{$f};

	my $credit;
	if ( $sum < $ConnectivityThresh )
	{
	    if( $all_multicast{max_z}{$fid}{$f} == 0 )
	    {
		$credit = 0;
	    }
	    else
	    {
		$credit = 0;
	    }
	}
	else
	{
	    $credit = $all_multicast{max_z}{$fid}{$f}/$sum;
	}
	$all_multicast{credit}{$fid}{$f} =$credit;
	printf " == credit is %.6f\n", $credit;
	printf TX_CREDIT_OUT "%d %d %.10f\n",$fid,$f+$startNodeId,$credit;

    }
    #printf FW_NODE_OUT "\n";
    #close (FW_NODE_OUT);

    
    close(TX_CREDIT_OUT);
    return \@all_forwarders;
}

sub print_tx_credit
{
    my ($connected_list,$forwarders,$fid,$f_src,$f_dst,$z_i,$graph,$run)=@_;
    my ($prev_node, $filename, $candidate_forwarders, $z_info, $previous, $i);
    my (@connected_list) = @$connected_list;
    my (@z_i) = @$z_i;
    my @tx_credit=();
    
    ## get z_i values
    foreach $i (0 .. $#connected_list){
	$z_info->{z_i}{"$connected_list[$i]"}=$z_i[$i];
    }
    ## get previous nodes
    foreach my $current_node (@$connected_list){
	my @previous_nodes =();
	if($current_node == $f_src){
	    next;
	}
	foreach $prev_node (@$connected_list){
	    if($prev_node == $f_dst){
		next;
	    }

	    $candidate_forwarders=$forwarders->{candidate_fwds}{"$fid $prev_node"};

	    if(find($candidate_forwarders,$current_node)==1){ # if current_node is in candidate_forwarder list
		push @previous_nodes, $prev_node;
	    }
	}
	$previous->{previous_nodes}{"$fid $current_node"}=\@previous_nodes; #store previous_nodes
    }
    ## get filename
    if ($run == 0)
    {
        if ($startNodeId == 0)
        {
            $filename="txCredit.txt";
        }
        else
        {
            $filename = "txCreditQ.txt";
        }
    } else {
        if ($startNodeId == 0)
        {
            $filename="txCreditPruned.txt";
        }
        else
        {
            $filename = "txCreditPrunedQ.txt";
        }
    }
    open(TX_CREDIT_OUT,">>$filename");
    # get tx_credit
    foreach $i (0 .. $#connected_list)
    {
	if ( $connected_list[$i] == $f_src )
	{
	    next;
	}
	my $current_node = $connected_list[$i];
	my $sum = 0;
	my $previous_nodes = $previous->{previous_nodes}{"$fid $current_node"};
	foreach $prev_node (@$previous_nodes)
	{
	    my $edge = $graph->{edges}{"$prev_node $current_node"};		
	    my $loss = $edge->{lossP};
	    my $z_j = $z_info->{z_i}{"$prev_node"};
	    $sum=$sum+$z_j*(1-$loss);
	    #printf "currentNode$current_node prevNode$prev_node z_i $z_j sum$sum\n"
	}	
	my $credit;
	if ( $sum < $ConnectivityThresh )
	{
	    if( $z_i[$i] == 0 )
	    {
		$credit = 0;
	    }
	    else
	    {
		$credit = 0;
	    }
	}
	else
	{
	    $credit = $z_i[$i]/$sum;
	}
	#printf " ++ node$connected_list[$i] z_i $z_i[$i] txcredit $credit sum $sum\n";
	push @tx_credit, $credit;
    }

    push @tx_credit, $MAX_CREDIT_FOR_SRC;
    printf TX_CREDIT_OUT "#flowId nodeId tx_credit\n";
    foreach $i (0 .. $#connected_list){
	printf TX_CREDIT_OUT "%d %d %.10f\n",$fid,$connected_list[$i]+$startNodeId,$tx_credit[$i];
    }
    close(TX_CREDIT_OUT);
    return ($previous,\@tx_credit);
}


sub print_shortest_path_acknowledgement
{
    my ($shortest_path)=@_;
    my @shortest_path=@$shortest_path;
    my $filename="topo.routes-ack";
    open(SPATH_OUT,">>$filename");
    printf SPATH_OUT "#AckSrc AckDst hopCount nexthop1_nodeId nexthop0_nodeId ... data_src_nodeId\n";
    printf SPATH_OUT "#                 (shortest path is from dst to src since it is for acknowledgement)\n";
    printf SPATH_OUT "0.0.0.%d 0.0.0.%d %d ",$shortest_path[0]+1,$shortest_path[$#shortest_path]+1,$#shortest_path;
    foreach my $i (@$shortest_path){
	printf SPATH_OUT "0.0.0.%d ",$i+1;	
    }
    close(SPATH_OUT);
}

#
#  Read from conflict-multi.txt and generate conflict.txt
#
sub convert_conflict_graph_multi
{
    my ($line);
    my ($numNode,$numPower, $numRate, $numLink_multi, $numLink);
    open CONFLICT_GRAPH_INPUT, $conflictMultiFile
	or die "Can't open alt graph input file $conflictMultiFile: $!\n";

    $line = <CONFLICT_GRAPH_INPUT>; # first line is num of nodes    
    my @fld = split " ", $line;
    $numNode = $fld[0];
    $line = <CONFLICT_GRAPH_INPUT>; # second line is num of power level    
    @fld = split " ", $line;
    $numPower = $fld[0];
    $line = <CONFLICT_GRAPH_INPUT>; # third line is num of rate
    @fld = split " ", $line;
    $numRate = $fld[0];

    open (CONFLICT_OUTPUT, ">$conflictFile");
    printf CONFLICT_OUTPUT "0\n";
    printf CONFLICT_OUTPUT "1\n";
    printf CONFLICT_OUTPUT "%d\n", $numNode;
    
    foreach my $i ( 0 .. $numNode - 1)
    {
	printf CONFLICT_OUTPUT "%d %d\n", $i, $defaultCapacity;
    }

    $line = <CONFLICT_GRAPH_INPUT>; # next line is number of links
    @fld = split " ", $line;
    $numLink_multi = $fld[0];
    $numLink = 0;

    my %linkInfo =();
    foreach my $i ( 0 .. $numLink_multi - 1 ) 
    {
        $line = <CONFLICT_GRAPH_INPUT>;
	chop $line;
	
	#my ($index, $fromVertex, $to, $channel, $loss_rate) = split " ", $line;
	my ($index, $fromVertex, $power, $rate, $to, $channel, $loss_rate) = split " ", $line;
	#my ($from,$power,$rate) = split ":", $fromVertex;
	my $from = $fromVertex;
	if ( $rate == $defaultCapacity )
	{
	    $linkInfo{$numLink} = "$index $from $to $channel $rate $loss_rate\n";
	    $numLink++;
	}
    }

    printf CONFLICT_OUTPUT "%d\n", $numLink;

    foreach my $i ( 0 .. $numLink-1 )
    {
	printf CONFLICT_OUTPUT $linkInfo{$i};
    }

    foreach my $i ( 0 .. $numNode - 1 )
    {
	foreach my $j ( 0 .. $numNode - 1 )
	{
	    if ( $j == $i )
	    {
		printf CONFLICT_OUTPUT "0 "
	    }
	    else
	    {
		printf CONFLICT_OUTPUT "1 "
	    }
	}
	printf CONFLICT_OUTPUT "\n";
    }

    ## first line after the conflict graph is 
    ## numflow is_multipath

    while ($line = <CONFLICT_GRAPH_INPUT>)
    {
	printf CONFLICT_OUTPUT $line;
    }
    close (CONFLICT_GRAPH_INPUT);
    close (CONFLICT_OUTPUT);
}
