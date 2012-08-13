#! /usr/bin/perl -w
eval 'exec /usr/bin/perl -S $0 "$*"'
	if undef;

package ConflictGraphUtil;

### export

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	read_conflict_graph read_conflict_graph_scale read_conflict_graph_multi pick_nexthop_forwarders_based_only_on_etx pick_all_forwarders_based_only_on_etx sort_by_etx solve_algorithm shortest_path printGraph printFlows print_array find get_connected_nodes get_all_loss_probability sum_array get_pruned_forwarders is_feasible_pruning
	);
@EXPORT_OK = qw(1);

### sub routine prototype

$INFINITY = 99999999999;

sub shortest_path ($$);		   # dijkstra's shortest path algorithm
sub read_conflict_graph ($$);
sub read_conflict_graph_scale ($$$$);
sub read_conflict_graph_multi ($$$$$$);
sub printGraph($);
sub printFlows($);
sub print_array($);
sub sum_array($);
sub pick_nexthop_forwarders_based_only_on_etx($$$$$$);
sub pick_all_forwarders_based_only_on_etx($$$$$);
sub get_connected_nodes($$$);
sub sort_by_etx($$);
sub find($$);
sub solve_algorithm($$$); # MORE's algorithm
sub get_all_loss_probability($$$); ## called by solve_algorithm
sub get_pruned_forwarders($$$$$$$$);
sub is_feasible_pruning($$$$);
### global constants

BEGIN {
   # $Exporter::Verbose=1;
    $INFINIT = 10000000000000.0;
    $FORWARDER_ETX_THRESH = 100;
    $PRUNE_THRESH=0.01;
    $NUM_PKT_RECV_PRUNE_THRESH=0.01; #denominator of eq (3)  txcredit (num pkt received)
    $DEBUG=0;
}

### sub routine implementation



#
#  Read from conflict.txt 
#
sub read_conflict_graph ($$)
{
    my ($ifile,$lossFile) = (@_);
    my ($line, $graph, $flow);
    my %flows=();
    my %mgroupContains=();
    my %recvIns=();

    open CONFLICT_GRAPH_INPUT, $ifile
	or die "Can't open alt graph input file $ifile: $!\n";

    if ($lossFile ne "-1")
    {
        open(lossFile, "<$lossFile") or die "Can't open $lossFile\n";
        # skip the first line in lossFile
        $line = <lossFile>;
    }

    $line = <CONFLICT_GRAPH_INPUT>; # first line is interference model
    $line = <CONFLICT_GRAPH_INPUT>; # second line is mac
    $line = <CONFLICT_GRAPH_INPUT>; # third line is number of nodes
    
    my @fld = split " ", $line;
    $graph->{num_node} = $fld[0];

    # followed by the lines, where each specifies <nodeId, bcastCapacity>
    foreach my $i ( 0 .. $graph->{num_node} - 1 ) {
        my $node;
        $line = <CONFLICT_GRAPH_INPUT>;
	$node->{index} = $i;
	$graph->{nodes}{$i} = $node;
    }

    $line = <CONFLICT_GRAPH_INPUT>; # next line is number of links
    @fld = split " ", $line;
    $graph->{num_edge} = $fld[0];

    foreach my $i ( 0 .. $graph->{num_edge} - 1 ) {
        $line = <CONFLICT_GRAPH_INPUT>;
	chop $line;
	
	my ($index, $from, $to, $channel, $rate, $loss_rate) = split " ", $line;

        # read loss from lossFile instead
        if ($lossFile ne "-1")
        {
            $line = <lossFile>;
            ($index, $skip, $from, $power, $rate, $to, $channel, $loss_rate) = split " ", $line;
        }

	my $edge;
        my $ett;
        
	## oetx is not ETT (1/delivery rate/rate)
        if ($loss_rate < 1)
        { 
	    $ett = 1/(1-$loss_rate)/$rate;
        }
        else
        {
            $ett = $INFINITY;
        }

        if (!exists $graph->{edges}{"$from $to"} || $ett < $graph->{edges}{"$from $to"})
        {
            $edge->{oetx} = $ett ; 
        }
        
	$edge->{lossP} = $loss_rate;
	$edge->{probD} = 1-$loss_rate;
	push @{$graph->{nodes}{$to}{in}}, $from;
	push @{$graph->{nodes}{$from}{out}}, $to;

	$graph->{edges}{"$from $to"} = $edge;
    }

    ## skip the conflict graph
    foreach my $i ( 0 .. $graph->{num_node} - 1 ){
	$line = <CONFLICT_GRAPH_INPUT>;
    }

    ## first line after the conflict graph is 
    ## numflow is_multipath

    $line = <CONFLICT_GRAPH_INPUT>;
    
    @fld = split " ", $line;
    $flows->{num_flow} = $fld[0];
    $flows->{is_multipth} = $fld[1];

    foreach my $index ( 0 .. $flows->{num_flow} - 1 ){
	$line = <CONFLICT_GRAPH_INPUT>;
	chop $line;
        my ($demand, $src, @rgroup) = split " ", $line;
        my $flow;
        $flow->{index} = $index;
        $flow->{src} = $src;
        $flow->{demand} = $demand;
        $flow->{dst} = (join " ", @rgroup);
        $flows->{flow}{$index} = $flow;
        foreach my $r ( 0 .. $#rgroup )
        {
            $mgroupContains{$index}{$rgroup[$r]} = 1;
            $recvIns{$rgroup[$r]}{$index} = 1;
        }
    }
    return ($graph,$flows, \%mgroupContains, \%recvIns);
}

#
#  Read from conflict.txt 
#
sub read_conflict_graph_scale ($$$$)
{
    my ($ifile,$scaleFactor,$route_metric,$bidirectional) = (@_);
    my ($line, $graph);
    my %mgroupContains=();
    my %recvIns=();
    my %flows=();
    my %linkLoss = ();
    open CONFLICT_GRAPH_INPUT, $ifile
	or die "Can't open alt graph input file $ifile: $!\n";

    $line = <CONFLICT_GRAPH_INPUT>; # first line is interference model
    $line = <CONFLICT_GRAPH_INPUT>; # second line is mac
    $line = <CONFLICT_GRAPH_INPUT>; # third line is number of nodes
    
    my @fld = split " ", $line;
    $graph->{num_node} = $fld[0];

    # followed by the lines, where each specifies <nodeId, bcastCapacity>
    foreach my $i ( 0 .. $graph->{num_node} - 1 ) {
        my $node;
        $line = <CONFLICT_GRAPH_INPUT>;
	$node->{index} = $i;
	$graph->{nodes}{$i} = $node;
    }

    $line = <CONFLICT_GRAPH_INPUT>; # next line is number of links
    @fld = split " ", $line;

    # read all edges
    foreach my $i ( 0 .. $fld[0]- 1 ) {
        $line = <CONFLICT_GRAPH_INPUT>;
	chop $line;
	my ($index, $from, $to, $channel, $rate, $loss_rate) = split " ", $line;
	$loss_rate = 1- ((1-$loss_rate)**$scaleFactor);
        $linkLoss{"$from $to $rate"} = $loss_rate;
    }

    foreach $nodePair ( keys %linkLoss )
    {
        my($from,$to,$rate) = split " ", $nodePair;
        my($loss_rate_fwd) = $linkLoss{"$from $to $rate"};
        my($loss_rate_rev) = $linkLoss{"$to $from $rate"};
        my($denominator, $oetx);
        my($edge);
        
        if ($bidirectional)
        {
            $denominator = (1-$loss_rate_fwd)*(1-$loss_rate_rev);
            
            if ($denominator > 0)
            {
                $oetx = 1/$denominator;
            }
            else
            {
                $oetx = $INFINITY;
            }
        }
        else
        {
            $denominator = (1-$loss_rate_fwd);
            if ($denominator > 0)
            {
                $oetx = 1/$denominator;
            }
            else
            {
                $oetx = $INFINITY;
            }
        }

        if ($route_metric == 1) # if ETT  
        {
            $oetx /= $rate;
        }

        $graph->{num_edge}++ if (!exists $graph->{edges}{"$from $to"});
        
        if (!exists $graph->{edges}{"$from $to"} || $graph->{edges}{"$from $to"}->{oetx} > $oetx)
        {
            $edge->{lossP} = $loss_rate_fwd;
            $edge->{probD} = 1-$loss_rate_fwd;
            $edge->{rate} = $rate;
            $edge->{oetx} = $oetx;
            
            push @{$graph->{nodes}{$to}{in}}, $from;
            push @{$graph->{nodes}{$from}{out}}, $to;

            $graph->{edges}{"$from $to"} = $edge;
        }
    }

    ## skip the conflict graph
    foreach my $i ( 0 .. $graph->{num_node} - 1 ){
	$line = <CONFLICT_GRAPH_INPUT>;
    }

    ## first line after the conflict graph is 
    ## numflow is_multipath

    $line = <CONFLICT_GRAPH_INPUT>;
    
    @fld = split " ", $line;
    $flows->{num_flow} = $fld[0];
    $flows->{is_multipth} = $fld[1];

    foreach my $index ( 0 .. $flows->{num_flow} - 1 ){
	$line = <CONFLICT_GRAPH_INPUT>;
	chop $line;
        my ($demand, $src, @rgroup) = split " ", $line;
        my $flow;
        $flow->{index} = $index;
        $flow->{src} = $src;
        $flow->{demand} = $demand;
        $flow->{dst} = (join " ", @rgroup);
        $flows->{flow}{$index} = $flow;
        foreach my $r ( 0 .. $#rgroup )
        {
            $mgroupContains{$index}{$rgroup[$r]} = 1;
            $recvIns{$rgroup[$r]}{$index} = 1;
        }
    }
    return ($graph,$flows, \%mgroupContains, \%recvIns);
}

#
#  Read from conflict-multi.txt 
#
sub read_conflict_graph_multi ($$$$$$)
{
    my ($ifile,$scaleFactor_fwd,$scaleFactor_rev,$route_metric,$bidirectional,$lossFile) = (@_);
    my ($line, $graph);
    my ($numPower, $numRate, $numLink, $edgeCount);
    my %prlInfo=();
    my %linkLoss = ();
    open CONFLICT_GRAPH_INPUT, $ifile
	or die "Can't open alt graph input file $ifile: $!\n";

    $line = <CONFLICT_GRAPH_INPUT>; # first line is num of nodes    
    my @fld = split " ", $line;
    $graph->{num_node} = $fld[0];
    $line = <CONFLICT_GRAPH_INPUT>; # second line is num of power level    
    @fld = split " ", $line;
    $numPower = $fld[0];
    $line = <CONFLICT_GRAPH_INPUT>; # third line is num of rate
    @fld = split " ", $line;
    $numRate = $fld[0];

    $line = <CONFLICT_GRAPH_INPUT>; # next line is number of links
    @fld = split " ", $line;
    $numLink = $fld[0];
    #printf "numLink is $numLink!!!\n";
    $graph->{num_edge} = 0;

    if ($lossFile ne "-1")
    {
        open(lossFile, "<$lossFile") or die "Can't open $lossFile\n";
        # skip the first line in lossFile
        $line = <lossFile>;
    }
    
    foreach my $i ( 0 .. $numLink - 1 ) {
        $line = <CONFLICT_GRAPH_INPUT>;
        my ($index, $from, $power, $rate, $to, $channel, $loss_rate) = split " ", $line;
        my ($skip);
        
        # read loss from lossFile instead
        if ($lossFile ne "-1")
        {
            $line = <lossFile>;
            ($index, $skip, $from, $power, $rate, $to, $channel, $loss_rate) = split " ", $line;
        }
        
        # $loss_rate = 1- ((1-$loss_rate)**$scaleFactor);

        $linkLoss{"$from $to $power $rate"} = $loss_rate;
        # print "$from $to $power $rate $loss_rate\n";
    }

    foreach my $from_to (keys %linkLoss)
    {
	my ($edge, $oetx);
	my ($from,$to,$power,$rate) = split " ", $from_to;
	my $loss_rate_fwd = 1 - ((1-$linkLoss{"$from $to $power $rate"})**$scaleFactor_fwd);
        my $loss_rate_rev = 1 - ((1-$linkLoss{"$to $from $power $rate"})**$scaleFactor_rev);
        my $denominator;

        print "$from $to $power $rate ", $loss_rate_fwd, " ", $loss_rate_rev,"\n";
        
        if ($bidirectional)
        {
            $denominator = (1-$loss_rate_fwd)*(1-$loss_rate_rev);
            
            if ($denominator>0)
            {
                $oetx = 1/$denominator;
            }
            else
            {
                $oetx = $INFINITY;
            }
        }
        else
        {
            $denominator = (1-$loss_rate_fwd);
            
            if ($denominator > 0)
            {
                $oetx = 1/$denominator;
            }
            else
            {
                $oetx = $INFINITY;
            }
        }

        if ($route_metric == 1) # if ETT
        {
            $oetx /= $rate;
        }
        
        $graph->{num_edge} ++ if (!exists $graph->{edges}{"$from $to"});

        # print "candidate: $from $to $power $rate $loss_rate_fwd $loss_rate_rev $oetx\n";
        if (!exists $graph->{edges}{"$from $to"} || $graph->{edges}{"$from $to"}->{oetx} > $oetx)
        {
            $edge->{lossP} = $loss_rate_fwd;
            $edge->{probD} = 1-$loss_rate_fwd;
            $edge->{power} = $power;
            $edge->{rate} = $rate;
            $edge->{oetx} = $oetx;
            push @{$graph->{nodes}{$to}{in}}, $from;
            push @{$graph->{nodes}{$from}{out}}, $to;
            $graph->{edges}{"$from $to"} = $edge;
            # print "final: $from $to $oetx\n";
        }
    }
#    exit(0);
    ## first line after the conflict graph is 
    ## numflow is_multipath

    $line = <CONFLICT_GRAPH_INPUT>;
    
    @fld = split " ", $line;
    $flows->{num_flow} = $fld[0];
    $flows->{is_multipth} = $fld[1];

    foreach my $index ( 0 .. $flows->{num_flow} - 1 ){
	$line = <CONFLICT_GRAPH_INPUT>;
	chop $line;
        my ($demand, $src, @rgroup) = split " ", $line;
        my $flow;
        $flow->{index} = $index;
        $flow->{src} = $src;
        $flow->{demand} = $demand;
        $flow->{dst} = (join " ", @rgroup);
        $flows->{flow}{$index} = $flow;
        foreach my $r ( 0 .. $#rgroup )
        {
            $mgroupContains{$index}{$rgroup[$r]} = 1;
            $recvIns{$rgroup[$r]}{$index} = 1;
        }
    }

    close(CONFLICT_GRAPH_INPUT);
    close(lossFile) if ($lossFile ne "-1");
    return ($graph,$flows,\%mgroupContains,\%recvIns);
}

sub get_connected_nodes($$$)
{
    my($nl,$el,$graph) = (@_);
    @node_list=@$nl;
    @node_etx_list=@$el;
    my $n = $#node_list;
    my @marked_list=();
    my @connected_list=();
    my @connected_etx_list=();
    my $i;

    foreach $i (0 .. $#node_list){
	push @marked_list, 0;
    }
    $marked_list[$n]=1;
    while($n>0){

	if( $marked_list[$n] == 1){
	    my $j=$n-1;
	    while ($j>=0){
		if(my $edge=$graph->{edges}{"$node_list[$n] $node_list[$j]"})
		{
		    ## fixed by mikie here
		    if($edge->{lossP}<1 && $node_etx_list[$j] < $node_etx_list[$n])
		    {
		    ## fixed by mikie here
			$marked_list[$j]=1;
			#print "mark node$node_list[$j] from node$node_list[$n]\n";
		    }
		}
		$j=$j-1;
	    }
	}
	$n=$n-1;
    }

    foreach $i (0 .. $#marked_list){
	if($marked_list[$i] == 1){
	    push @connected_list, $node_list[$i];
	    push @connected_etx_list, $node_etx_list[$i];
	}
    }
    return (\@connected_list,\@connected_etx_list);
}

sub pick_nexthop_forwarders_based_only_on_etx($$$$$$)
{
    my ($src, $dst, $graph, $ppath, $ddist, $nl) = (@_);
    my %dist=%$ddist;
    my %path=%$ppath;
    my @out_nodes=@{$graph->{nodes}{$src}{out}};
    my $src_etx=$dist{$src}{$dst};
    my (@forwarders) = ();
    my (@forwarders_etx_to_dst) = ();
    my @pruned_list=@$nl;

    if ( $src == $dst )
    {
	return (\@forwarders,\@forwarders_etx_to_dst);
    }

   #print "mikie cur node : $src\n";
    #print "mikie dst node : $dst\n";
    foreach my $ele (@out_nodes){
	## fixed by mikie here
	if(my $ed=$graph->{edges}{"$src $ele"})
	{
	    if($ed->{lossP}==1)
	    {
		next;
	    }
	}
	else
	{
	    print "error!\n";
	    exit (-1);
	}

	if ($ele == $dst){
	    push @forwarders, $ele;
	    push @forwarders_etx_to_dst, $dist{$ele}{$dst};
	    next;
	}

	if (($src_etx > $dist{$ele}{$dst}) && ## ETX(src,dst) > ETX(ele,dst) 
	    (find(\@pruned_list,$ele)==1)) ## apply pruning of MORE
	{
	    push @forwarders, $ele;
	    push @forwarders_etx_to_dst, $dist{$ele}{$dst};
	}
    }
    ($fds,$etxs)=sort_by_etx(\@forwarders,\@forwarders_etx_to_dst);
    @forwarders=@$fds;
    @forwarders_etx_to_dst=@$etxs;

    return (\@forwarders,\@forwarders_etx_to_dst);
}

sub pick_all_forwarders_based_only_on_etx($$$$$)
{
    my ($src, $dst, $graph, $ppath, $ddist) = (@_);
    my (@node_list,@etx_list)=();
    my %dist=%$ddist;
    my %path=%$ppath;
    my $numNode=$graph->{num_node};
    my $src_etx=$dist{$src}{$dst};
    my $i=0;

    if ($src == $dst )
    {
	return (\@node_list,\@etx_list);
    }

    foreach $i (0 .. $numNode-1){   
	if( ($i == $dst) || ($i == $src)){
	    next;
	}

	#my @shortest_path=@{$path{$i}{$dst}};
	
	## forwarding node selection
	## 1. include only those node that has smaller or equal etx than src node
	if (($dist{$i}{$dst}< $src_etx)) 
	{ 
	    push @node_list, $i; 
	    push @etx_list, $dist{$i}{$dst}; 
	} 
    } 
    ## push dst node to @node_list
    push @node_list, $dst;
    push @etx_list, $dist{$dst}{$dst}; # this should be zero
    
    ## push src node to @node_list
    push @node_list, $src;
    push @etx_list, $src_etx;
    
    # sort all nodes according to etx value to the destination
    ($nl,$el)=sort_by_etx(\@node_list,\@etx_list);
    my @node_list_sort = @$nl;
    my @etx_list_sort = @$el;
    if ($DEBUG)
    {
	printf "-- All Forwarders (ID, Metric) START (includes disconnect)\n";
	foreach my $i (0 .. $#node_list_sort)
	{
	    printf "%d %.9f\n",$node_list_sort[$i],  $etx_list_sort[$i];
	}
	printf "-- All Forwarder (ID, Metric) END\n";
    }
    ($nl,$el)=get_connected_nodes($nl,$el,$graph);
    return ($nl,$el);
}

sub solve_algorithm($$$)
{
    my ($nl,$el,$graph)=(@_);
#    my (@node_list,@etx_list)=(@$nl,@$el);
    my (@L_i,@z_i)=();

    my @node_list=@$nl;
    my @etx_list=@$el;

    ## initialize z_i and L_i 
    # z_i should be zero for i from 0 to N-1
    # L_i should be zero for i from 0 ... N-2 and 
    #                one for i N-1(source)
    
    foreach my $x (0 .. $#node_list)
    {
	push @L_i, 0;
	push @z_i, 0;
    }
    $L_i[$#L_i] = 1; 
    
    if ($DEBUG == 1) {
	print "initialized ::\n";
	print "node list sorted ";
	print_array(\@node_list);
	print "etx  list sorted ";
	print_array(\@etx_list);
	print "L_i              ";
	print_array(\@L_i);
	print "z_i              ";
	print_array(\@z_i);
	print "graph ", $graph->{num_node}, "\n";
    }
    ## second block of Algorithm 1 in section 5.1 of MORE paper 
    my $i = $#L_i ;
    my $P=1;
    while ( $i >= 1)
    {
	my @closer_node_list=@node_list[0 .. $i-1];
	
	my $all_loss_prob=get_all_loss_probability($graph,$node_list[$i],\@closer_node_list);
	if ($all_loss_prob == 1 )
	{
	    print "all_loss_prob must not be zero!!!";
	    die;
	}
	#else
	#{
	    #printf "all_loss_prob for node%d is %.5f\n", $node_list[$i], $all_loss_prob;
	#}

	$z_i[$i]=$L_i[$i]/(1-$all_loss_prob);
	#print "L_i is $L_i[$i] z_i is $z_i[$i] 1-all_loss is ",1-$all_loss_prob," \n";
	$P=1;
	foreach my $j (1 .. $i-1){
	    my $edge;
	    my $k=$j-1;
	    #print "i is $i j is $j k is $k\n";
	    my $node_i=$node_list[$i];
	    my $node_k=$node_list[$k];
	    my $node_j=$node_list[$j];
	    
	    if($edge=$graph->{edges}{"$node_i $node_k"})
	    {
		if($edge->{lossP} < 1){
		    $P=$P * (1 - $edge->{probD});
		    #print "P is $P loss rate($node_i,$node_k) ",1-$edge->{probD},"\n";
		}
	    }
	    if($edge=$graph->{edges}{"$node_i $node_j"})
	    {
		if($edge->{lossP} < 1 ) {
		    $L_i[$j]=$L_i[$j]+$z_i[$i]*$P*($edge->{probD});
		    #print "L[$j] is ", $L_i[$j]," z[$i] is ", $z_i[$i]," P is ",$P, " del_rate($node_i, $node_j) ", $edge->{probD},"\n";
		}
	    }
	}
	$i=$i-1;
    }
    ## Algorithm 1 end
    if ($DEBUG == 1) {
	print "*** Done solving algo1 ::\n";
	print "node list sorted ";
	print_array(\@node_list);
	print "etx  list sorted ";
	print_array(\@etx_list);
	print "L_i              ";
	print_array(\@L_i);
	print "z_i              ";
	print_array(\@z_i);
    }
    return (\@z_i,\@L_i);
}

sub get_all_loss_probability($$$)
{
    my($graph,$cur_node,$all_fd_list)=(@_);
    my @out_nodes=@{$graph->{nodes}{$cur_node}{out}};
    my @all_forwarder_list=@$all_fd_list;
    my $all_loss_rate=1;
#    print "out_nodes for node $cur_node!!!!\n";
    #print_array(\@out_nodes);
    #print_array(\@all_forwarder_list);
    foreach my $ele (@out_nodes){
	if (my $ed = $graph->{edges}{"$cur_node $ele"}){
	    if($ed->{lossP} == 1){
		next;
	    }
	}
	foreach $ele2 (@all_forwarder_list)
	{
	    if($ele == $ele2){
		my $edge=$graph->{edges}{"$cur_node $ele"};
		my $link_loss_rate=1-$edge->{probD};
		$all_loss_rate= $all_loss_rate * $link_loss_rate;
		#print "link_loss($cur_node, $ele) is $link_loss_rate cur all loss rate $all_loss_rate\n";
		last;
	    }
	}
    }
    #print "FINAL all loss rate $all_loss_rate\n";
    return $all_loss_rate;
}

sub get_num_recv($$$)
{
    my ($z_i,$fwd_list,$graph) = @_;
    my @fwd_list = @$fwd_list;
    my @z_i = @$z_i;
    my @total_num_pkt_recv=();
    foreach my $n ( 0 .. $#fwd_list)
    {
	#print "$n ";
	my $f = $fwd_list[$n];
	if ( $n < $#fwd_list )
	{
	    my @prev = ();
	    my $sum = 0;
	    foreach my $i ($n+1 .. $#fwd_list)
	    {
		my $p = $fwd_list[$i];
		my $edge;
		if( $edge = $graph->{edges}{"$p $f"} )
		{		  
		    $sum+=(1-$edge->{lossP})*$z_i[$i];
		}
	    }
	    $total_num_pkt_recv[$n] = $sum;
	}else{
	    $total_num_pkt_recv[$n] = 1;
	}
    }
    #print "\n";
    return \@total_num_pkt_recv;
}

sub get_pruned_forwarders($$$$$$$$)
{
    my ($L_i,$z_i,$prune_thresh,$graph,$f_dst,$f_src,$fwd_list,$fwd_etx_list)=@_;

    my $sum_z_i=sum_array($z_i);
    my @fwd_list=@$fwd_list;
    my @fwd_etx_list=@$fwd_etx_list;
    
    my @pruned_list = ();
    my @pruned_etx_list = ();
    my @pruned_z_i_list = ();
    @z_i = @$z_i;
    @L_i = @$L_i;
    foreach $i ( 0 .. $#fwd_list ) {
	if ( $f_dst == $fwd_list[$i] + 0) {
	    push @pruned_list, $fwd_list[$i];
	    push @pruned_etx_list, $fwd_etx_list[$i];
	    push @pruned_z_i_list,$z_i[$i];
	    next;
        }

	if ( $prune_thresh * $sum_z_i <= $z_i[$i] && $L_i[$i] > 0.01 )
	{
	    push @pruned_list, $fwd_list[$i];
	    push @pruned_etx_list, $fwd_etx_list[$i];
	    push @pruned_z_i_list,$z_i[$i];
	}else
	{
	    printf "src$f_src dst$f_dst fwd$fwd_list[$i] is pruned because low z_i value\n"
	}
    }
    @fwd_list = @pruned_list;
    @fwd_etx_list = @pruned_etx_list;
    @z_i = @pruned_z_i_list;
    print "pruned once - values should be recomputed : \n";
    print "fwd_list : ";
    print join " ",@fwd_list;
    print "\n";
    print "z_i : ";
    print join " ",@z_i;
    print "\n";
    my ($total_num_pkt_recv) = get_num_recv(\@z_i,\@fwd_list,$graph);
    my @total_num_pkt_recv = @$total_num_pkt_recv;

    print "numrev: ";
    print join " ",@total_num_pkt_recv;
    print "\n";
    @pruned_list = ();
    @pruned_etx_list = ();
    @pruned_z_i_list = ();
    foreach my $i ( 0 .. $#fwd_list )
    {
	if($f_dst == $fwd_list[$i] + 0 )
	{
	    push @pruned_list, $fwd_list[$i];
	    push @pruned_etx_list, $fwd_etx_list[$i];
	    push @pruned_z_i_list,$z_i[$i];
	    next;
	}

	if( $total_num_pkt_recv[$i] > $NUM_PKT_RECV_PRUNE_THRESH )
	{
	    push @pruned_list, $fwd_list[$i];
	    push @pruned_etx_list, $fwd_etx_list[$i];
	    push @pruned_z_i_list,$z_i[$i];
	}else
	{
	    printf "src$f_src dst$f_dst fwd$fwd_list[$i] is pruned because num recv < $NUM_PKT_RECV_PRUNE_THRESH \n"
	}   	
    }
    print "pruned twice - values should be recomputed : \n";
    print "fwd_list : "; 
    print join " ",@pruned_list;
    print "\n";
    print "z_i : ";
    print join " ",@pruned_z_i;
    print "\n";
    ($feasiblePruning,$pruned_list, $pruned_etx_list) = is_feasible_pruning($graph,$f_src,\@pruned_list,\@pruned_etx_list);

    return ($feasiblePruning,$pruned_list,$pruned_etx_list);
}

sub is_feasible_pruning($$$$)
{
    my($graph,$f_src,$pruned_list,$pruned_etx_list)=@_;

    my $feasiblePruning = 0;

    if ( find($pruned_list , $f_src ) )
    {
	
	($nl,$el) = get_connected_nodes($pruned_list,$pruned_etx_list, $graph);
	my @connected_pruned_list = @$nl;
	
	if ( @connected_pruned_list == @$pruned_list )
	{
	    $feasiblePruning = 1;
	    #print "feasible pruning!\n";
	}
    }
    return ($feasiblePruning,$pruned_list,$pruned_etx_list);
}

sub print_array($)
{
    my($a)=(@_);
    foreach $i (@$a){
	print "$i, ";
    }
    print "\n";
}

sub sum_array($)
{
    my($a)=(@_);
    my $sum=0;
    foreach $i (@$a){
	$sum=$sum+$i;
    }
    return $sum;
}

sub sort_by_etx($$)
{
    my($nnode_list,$eetx_list) = (@_);
    my @node_list=@$nnode_list;
    my @etx_list=@$eetx_list;
    my $n=$#etx_list;
    while ($n>0)
    {
	foreach $j (1 .. $n)
	{
	    if($etx_list[$j-1] > $etx_list[$j] || ($etx_list[$j-1] == $etx_list[$j] && $node_list[$j-1] > $node_list[$j] ) ){
		my $tmp;
		$tmp=$etx_list[$j];
		$etx_list[$j]=$etx_list[$j-1];
		$etx_list[$j-1]=$tmp;
		
		$tmp=$node_list[$j];
		$node_list[$j]=$node_list[$j-1];
		$node_list[$j-1]=$tmp;
	    }
	}
	$n=$n-1;
    }
    #print "node_list ", @node_list, "\n" ;
    #print "etx_list ", @etx_list, "\n";
    return (\@node_list,\@etx_list);
}

sub find($$)
{
    my($lst, $target) = @_;
    foreach $ele ( @$lst )
    {
	return 1 if ($target == $ele);
    }
    return 0;
}

sub printGraph ($) {
    my ($graph) = @_;
#    print "\n\nPrintGraph:\n";
    print $graph->{num_node}, " nodes, ", $graph->{num_edge}, " edges \n";
    foreach my $i (sort {$a cmp $b} keys %{$graph->{nodes}}) {
	my $node = $graph->{nodes}{$i};
	print "$i : in |";
	
	foreach my $inIndex (@{$graph->{nodes}{$i}{in}}) {
	    my $edge = $graph->{edges}{"$inIndex $i"};
#	    print "\n$inIndex $i\n";
	    my $wt = $edge->{lossP};
	    print $inIndex, "($wt)|";
	}
	print ", out |";
	foreach my $outIndex (@{$graph->{nodes}{$i}{out}}) {
	    my $edge = $graph->{edges}{"$i $outIndex"};
	    #print "\n$i $outIndex\n";
	    my $wt = $edge->{lossP};
	    print $outIndex, "($wt)|";
	}
	print ("\n");
    }
}

sub printFlows ($) {
    my ($flows) = @_;
    print $flows->{num_flow}, " flows \n";
    foreach my $i (sort {$a <=> $b} keys %{$flows->{flow}}){
	my $flow = $flows->{flow}{$i};
	print "$i (src", $flow->{src}," dst", $flow->{dst},")\n";
    }
    print ("\n");
}


# dijkstra's algorithm for compute shortest path from a single source

sub shortest_path ($$)
{
    my ($root, $graph, $used_edges) = (@_);
    my ($src);
    my %path = ();
    my %dist = ();
    my $edges = $graph->{edges};
    
    #print "mikie ddd:", $graph->{num_node}, "\n";
    #foreach $key (sort {$a <=> $b} keys %{$graph->{nodes}}){
    #    #print ${$graph->nodes}{$key}, "\n";
    #    print "mikie ddd: key ", $key, "\n";
    #}
    
    foreach $src ( @$root )
    {
	my @W = ();
	my %V = ();
	my %curr_dist = ();
	my %curr_path = ();
	# print "mikie ddd: src is $src\n";
	push @W, $src;
	$curr_dist{$src} = 0;
	@{$curr_path{$src}} = ($src);
	
	for $u ( sort {$a <=> $b} keys %{$graph->{nodes}})
	{
	    
	    next if $u == $src;
	    #print "mikie ddd: u is $u\n";
	    $V{$u} = 1;
	    $curr_dist{$u} = ( exists $edges->{"$src $u"} ) ?
		$edges->{"$src $u"}{oetx} : $INFINIT;
	    @{$curr_path{$u}} = ($src, $u) if ( exists $edges->{"$src $u"} );
	    #print "ddd: $src $u ",$curr_dist{$u}," ",$edges->{"$src $u"}{oetx},"\n" if ( exists $edges->{"$src $u"} );
	}
	
	# print "src=$src num_node = ", $graph->{num_node}," $src\n";
	
	# repeatedly enlarge W until W includes all verticies in V
	# @W returns number of elements in @W
	while ( @W < $graph->{num_node} )
	{
	    my $min_dist = $INFINIT;
	    my $w;
	    for $v ( keys %V )
	    {
		#print "mikie ddd : v is $v $V{$v}\n";
		if ( $curr_dist{$v} < $min_dist )
		{
		    $min_dist = $curr_dist{$v};
		    $w = $v;
		}
	    }
	    
	    # add w to W
	    #print "w = $w min_curr_dist=$min_dist ",@W+0,"\n";
	    push @W, $w;
	    delete $V{$w};
	    
	    # update the shortest distance to vertices adjacent to $w
	    for $u ( @{ $graph->{nodes}{$w}{out} } )
	    {
		next if ! exists $V{$u};
		
		my $len = $edges->{"$w $u"}{oetx};
		if ($curr_dist{$u} > $curr_dist{$w} + $len) {
		    $curr_dist{$u} = $curr_dist{$w} + $len;
		    @{$curr_path{$u}} = (@{$curr_path{$w}}, $u);
		}
	    }
	}
	
	foreach $u ( keys %curr_path )
	{
	    # print "mikie ddd : u is ",$u," curr_path is ", @{$curr_path{$u}} ,"\n";
	    @{$path{$src}{$u}} = @{$curr_path{$u}};
	    #print "mikie ddd : path is ", @{$path{$src}{$u}}, "\n";
	    $dist{$src}{$u} = $curr_dist{$u};
	    # print $u," $src ", $dist{$src}{$u}," ";
	    # print (join " ", @{$path{$src}{$u}});
	    # print "\n";
	}
	#%{$path{$src}} = %curr_path;
	#%{$dist{$src}} = %curr_dist;
    }
    
    return (\%dist, \%path);
}

__END__

