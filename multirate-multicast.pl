#!/user/local/bin/perl -w
# validate.pl -- (c) UT Austin, Lili Qiu, Wed Oct 24 2007
#   <lili@cs.utexas.edu>
#
########################################################
use strict;
use common;
use genloss;

use constant OBJ_MAX_GOODPUT  => 1;
use constant OBJ_MAX_FAIRNESS => 2;
use constant OBJ_MAX_PROP_FAIRNESS => 3;
use constant OBJ_MAX_PROP_FAIRNESS2 => 4;

use constant NO_MODEL => 0;
use constant WiFi_MODEL => 1;
use constant CG_MODEL => 2;

use constant INF_DEMAND => 1;
use constant RAND_DEMAND => 2;

use constant SPP => 1;
use constant PRO => 2;
use constant MORE => 3;
use constant MIMO => 4;

use constant MORE_BASED_FWD_SELECTION => 0;
use constant PRO_BASED_FWD_SELECTION => 1;

my $source_MIMO = 1;
my $dest_MIMO = 1;
my $NUM_ANTENNAS_MIMO = 2;
my %num_antennas = (); 

my $RANDOM_RUN = 0;
my $FIXED_RUN = 1;

my $ninit = 3;

my $nflows=$ARGV[0];
my $nColumns=$ARGV[1];
my $nRows = $ARGV[2];
my $randSeed=$ARGV[3];
my $w_ratelimit=$ARGV[4];
my $topologyType=$ARGV[5];      # 1 for grid and 0 for random topologies
my $demandType=$ARGV[6];        # 1 for infinite demand for each flow, and 0 for zipf demand
my $dist=$ARGV[7];
my $max_hop=$ARGV[8];
my $PowerFile = $ARGV[9];  
my $RateFile = $ARGV[10];
my $default_power = $ARGV[11];
my $default_rate = $ARGV[12];
my $isBER = $ARGV[13];
my $runType = $ARGV[14];
my $group_size = $ARGV[15];
my $isSim = $ARGV[16];
my $isMultiRate = $ARGV[17];
my $routingObj = $ARGV[18];
my $pruningMode = $ARGV[19];
my $model = $ARGV[20];
my $mac = $ARGV[21];
my $measureOneHop = $ARGV[22];
my $protocol = $ARGV[23];

$NUM_ANTENNAS_MIMO = $ARGV[24];		## add by yichao
my $demandMode = INF_DEMAND; # $ARGV[24]; ## modified by yichao

my $errorRange = $ARGV[25];
my $overprovision = $ARGV[26];

$mac = 1 if(!defined($mac));
my $mac_str;

if($mac == 1)
{
    $mac_str="11a";
}else{
    $mac_str="11b";
}

$runType = $RANDOM_RUN if (!defined($runType));
$isSim   = 1 if (!defined($isSim));
$group_size = 1 if (!defined($group_size));
$isMultiRate = 1 if (!defined($isMultiRate));
$overprovision = 0 if (!defined($overprovision));
$demandMode = INF_DEMAND if (!defined($demandMode));
$errorRange = 0 if(!defined($errorRange));



# global constants
my $compressShared = 1;

my $ETX = 0;
my $ETT = 1;
my $sim_time = 20;              # XXX: 20 seconds simulation
my $transport = 1;              # 0 for TCP and 1 for UDP
#my $mac = 1;                    # 1 for 802.11a and 0 for 802.11b
my $np = 0;                     # single path
my $nc = 1;
my $mr = 0;

#my $TR = 230; # 235             # communication range
#my $IR = 253;                   # interference range (double check)
#my $CarrierSenseRange = 253;    # carrier sense range

my $TR;
my $IR;
my $CarrierSenseRange ;

if ($mac == 0){
    if($default_rate == 11){
	$TR = 452.91472221866; #      # communication range
    }elsif($default_rate == 1){
	$TR = 1027.799111221291;
    }elsif($default_rate == 2){
	$TR = 741.31540545662;
    }else{ # default_rate = 5.5
	$TR = 631.53106522855;
    }
    $IR = 1090.5117766974669;                    # interference range (double check)
    $CarrierSenseRange = 1090.5117766974669;    # carrier sense range

}else{
    $default_rate = 6;
    $TR = 230.09555965; # communication range ( < TR link exists, >= TR doesn't exist)
    $IR = 253.6418194590;                   # interference range (double check)
    $CarrierSenseRange = 253.6418194590;    # carrier sense range ( < CS can carrier sense)
}



my $GAMMA = 0;                  # weight of fairness 
my $EPSILON = 0.0001;            # minimum throughput for each flow
my $ETA = 0;                    # importance of loop freeness
my $FWD_PRUNE_THRESH = 0.1;     # used for MORE pruning fwd list

## added by mikie start

my @TR_multi = ();
my @IR_multi = ();
my @CarrierSenseRangeMulti =();

# global file names
my $AntennaFile = "antenna.txt";
my $neighborFile = "neighbor.txt";
my $topoFile = "topology.txt";
my $qualnetTopoFile = "topo.nodes";
my $qualnetSPPAppFile = "topo-spp-nrl.app";
my $qualnetSPPRLAppFile = "topo-spp.app";
my $qualnetORAppFile = "topo-or.app";
my $qualnetFaultFile = "topo.fault";            # fault for MORE OUR
my $qualnetFaultMultiFile = "topo-multi.fault"; # fault for MORE2 OUR2
my $qualnetPowerFile = "topo.power";            # added by mikie 
my $conflictFile = "conflict.txt";
my $conflictLinkFile = "conflict-link.txt";     # link level conflict
my $conflictMultiFile = "conflict-multi.txt";   # added by mikie
my $conflictInFile = "conflict-in.txt";
my $lossFile = "loss.txt";
my $lossFileBoth = "loss2.txt";

my $trafficFile = "traffic.txt";
my $lpFile = "lp.txt";
my $lpResultFile = "lp_result.txt";
my $matlabResultFile = "matlab_result.txt";
my $indepFile="indept.txt";
my $indepMultiFile = "indept-multi.txt";
my $fwdLstFile = "fwdNodePruned.txt";
my $fwdSharedFile = "fwdShared.txt";
my $minIntervalFile = "min-interval.txt";
my $qualnetTXIntervalFile = "topo.txinterval";
my $qualnetACKRoute = "topo.routes-ack";
my $qualnetACKRouteMulti = "topo-multi.routes-ack";
my $fwdRatioFile = "fwdRatioQ.txt";
my $varFile = "var.txt";
my $flowFile = "flow.txt"; # added by mikie because flow_rate sometimes just give 1 line instead of $nflows line
my $routeFile = "topo.route-static";
my $multicastGroupFileQ = "topo.group";
my $sppMcastFileQ = "topo.route-spp-multicast";

my $startTimeRange = 0.1;

# MIMO related
my $compositeLinkFile = "composite.txt";
my $totalCompositeLinks = 0;
my @composite_link = ();
my @composite_link_conflict = ();
my %neighbor_single_rate = ();
my @composite_link_single_antenna_sender = ();

# for rate limited SPP
my $rawLossFileBoth = "raw_loss2.txt";
my $flowAllocFile = "flow_alloc.txt";

my $etxFile = "etx-r0-b0.txt";

my $lpOutFormat = 4;
my $payload = 1024;

# e2e ACK uses the same packet header as the DATA packet.
# 20 (default) + 32 (pkt_type,flowId, batch_no, multicast flow info)
# + 64 byte (code_vector when batchsize is 64) = 116 byte
my $opr_ackSize = 116;        # 116-byte e2e header size
my $ackSize = -20;            # substract 20 bytes since compute_tx_time adds 20-byte IP header  
my $etxProbSize = 1024;
my $batch_size = 16;

my $MAX_THROUGHPUT = 1;       # to normalize for processing stat files
my $maxLinkLossRate = 0.5;    # prune an edge if its loss rate exceeds 90% (consistent with testbed)	## yichao: 0.9 -> 0.5
my $effort = 3000;

my $SINGLE_PATH = "SPP";      # single path routing
my $OUR = "OUR";              # our opportunistic routing (restrict fwdList)
my $OUR2 = "OUR2";            # opr-general.pl
my $MORE = "MORE";            # MORE (more.pl)
my $MORE2 = "MORE2";          # more-general.pl
my $MIMO = "MIMO";	      # add by yichao

my %TF;
my %FR;
my %G;
my %id2link;
my @flow;
my @est_flow;
my %neighbors;
my %cost;
my $min_interval;
my $minIntervalScaleFactor = 1;
my $totalNodes;
my $totalLinks_defaultRate = 0;
my $totalLinks_allRate = 0;
my $totalLogicalNodes_allRate = 0;
my %loss;
my %ber;
my %fwdLst;
my %shared;
my @x;
my @y;
my @conflict;

my %allRates;
my %allPowers;
my $numRate;
my $numPowerLevel;

my $isMulticast = 0;
my %multicastGroup = ();
my @num_subgroup = (); # num subgroup by flow 
my %conflictMulti = ();
my %lossMulti = ();
my %berMulti = ();
my %neighborsMulti = ();
my %lossMeasure = ();

# types of rate limit algorithms
my $OUR_RateLimit = 1;
my $LP_RateLimit = 2;
my $No_RateLimit = 3;

my %linkid = ();
my %linkid_defaultRate = ();
my %pnode2logical;

my $total_rate_model = 0;
my @rate_perflow_model = ();

$isMulticast = 1 if ($group_size > 1);
srand(0);

open qualnetPowerFile, ">$qualnetPowerFile " or die "can't open $qualnetPowerFile for writing\n";
my $maxRate = &read_power_rate();
my $InfDemand = $maxRate*$NUM_ANTENNAS_MIMO; 
close(qualnetPowerFile);

# compute InfDemand
# my $tx_time = &compute_tx_time($transport, $mac, $payload, $maxRate, 1, 0);
# my $max_thruput = $payload*8/$tx_time/1e6;

$min_interval = $payload*8/$maxRate*1e-6;

$totalNodes = $nRows * $nColumns;

# open files
open topoFile, ">$topoFile" or die "can't open $topoFile for writing !\n";
open qualnetTopoFile, ">$qualnetTopoFile" or die "can't open $qualnetTopoFile for writing\n";
open qualnetSPPAppFile, ">$qualnetSPPAppFile" or die "can't open $qualnetSPPAppFile for writing\n";
open qualnetORAppFile, ">$qualnetORAppFile" or die "can't open $qualnetORAppFile for writing\n";
open flowFile, ">$flowFile" or die "can't open $flowFile for writing!\n";
open qualnetFaultFile, ">$qualnetFaultFile" or die "can't open $qualnetFaultFile for writing\n";
open minIntervalFile, ">$minIntervalFile" or die "can't open $minIntervalFile for writing\n";
open qualnetFaultMultiFile, ">$qualnetFaultMultiFile" or die "can't open $qualnetFaultMultiFile for writing\n";
open multicastGroupFileQ,">$multicastGroupFileQ" or die "can't open $multicastGroupFileQ for writing\n";
open rawLossFileBoth, ">$rawLossFileBoth" or die "can't open $rawLossFileBoth for writing!\n";

&generate_min_interval_file();
&generate_topo($topologyType, $nRows, $nColumns, $totalNodes);
&generate_neighbors();
srand($randSeed);

if($measureOneHop == 0){ # if not measuring then it means we already have measured data in one-hop-11b or one-hop 
    &read_one_hop();
}

&generate_loss_multi();

# foreach my $i ( 0 .. 11)
# {
#    foreach my $j ( 0 .. 11)
#    {
#	my($r) = has_common_neighbors($i,$j);
#	print "common_neighbor: $i $j $r\n";
#    }
# }
# exit(0);

if ($runType == $RANDOM_RUN)
{
    &generate_traffic2($totalNodes);
}
else
{
    &generate_traffic_fixed($totalNodes);
}
print "nflows=$nflows\n";


&copy_loss_multi();        # copy lossMulti to loss under default power & rate

close(topoFile);
close(flowFile);
close(qualnetTopoFile);
close(qualnetSPPAppFile);
close(qualnetORAppFile);
close(qualnetFaultFile);
close(minIntervalFile);
close(qualnetFaultMultiFile);
close(multicastGroupFileQ);
close(rawLossFileBoth);

if($measureOneHop == 1)
{
    exit(0);
}

system("ConflictGraph-sigcomm-camera-ready/ConflictGraph $topoFile $conflictLinkFile bidireclink 1>/dev/null");
generate_BcastConflict_multi_rate_power($totalNodes);
print "totalLinks_defaultRate = $totalLinks_defaultRate\n";

generate_loss_traffic_file();
findIndepSetsMulti($totalNodes,$effort,$indepMultiFile,\%conflictMulti,\%allRates,$numPowerLevel);

print "perl get_shortest_path.pl 0 $routeFile 1 1 0 $default_power $default_rate $ETX $lossFileBoth 0\n";
system("perl get_shortest_path.pl 0 $routeFile 1 1 0 $default_power $default_rate $ETX $lossFileBoth 0");

&read_etx(); 
&generate_init_traffic_file(); 
&generate_num_antennas();

# run routing schemes individually
if ( 0 ) 
{
    if ($routingObj == OBJ_MAX_GOODPUT && $model == WiFi_MODEL)
    {
	# run shortest path routing without rate limiting
	if (!($default_rate != 6 && $isMultiRate))
	{
	    system("rm -f etx.txt ett.txt res $lpFile $lpResultFile $varFile flow_rate $routeFile");
	    &run_shortest_path_routing($ETX,$No_RateLimit);  
	}
	
	if ($default_rate == 6 && $isMultiRate)
	{
	    system("rm -f etx.txt ett.txt res $lpFile $lpResultFile $varFile flow_rate $routeFile");
	    &run_shortest_path_routing($ETT,$No_RateLimit); 
	}
	
	# MORE without rate limiting
	if (!$isMultiRate)
	{
	    system("rm -f etx.txt ett.txt res $fwdLstFile $lpFile $lpResultFile");
	    &run_or_routing($MORE); 
	}
    }

    # shortest path with rate limiting
    if (!$isMultiRate && $model == WiFi_MODEL) 
    {
	&run_shortest_path_routing($ETX,$OUR_RateLimit); 
    }
}

if ($protocol == PRO){
    # PRO: our opportunistic routing protocol with rate limiting                 
    system("rm -f $fwdLstFile res $lpFile $lpResultFile $matlabResultFile topo.credit* topo.weight*");
    &generate_link_conflict();
    print "model is $model\n";
 
    if (!$isMulticast)
    {
	&run_or_routing($OUR2);
    }
    else{ 
	&run_our_multicast;
    }
}elsif($protocol == SPP){
    if($model == WiFi_MODEL){
	# shortest path with wifi model rate limiting
	&run_shortest_path_routing($ETX,$OUR_RateLimit);
    }elsif($model == CG_MODEL){
	# shortest path with conflict graph rate limiting
	&run_shortest_path_routing($ETX,$LP_RateLimit);
    }else{ 
	# shortest path without rate limiting
	system("rm -f etx.txt ett.txt res $lpFile $lpResultFile $varFile flow_rate $routeFile");
	&run_shortest_path_routing($ETX,$No_RateLimit);
    }
}elsif($protocol == MORE) {
    # MORE
    system("rm -f etx.txt ett.txt res $fwdLstFile $lpFile $lpResultFile");
    &run_or_routing($MORE);
}elsif($protocol == MIMO) {
    &run_mimo_routing();
}else{
    print "protocol$protocol unknown protocol!!\n",
    exit(0);
}

sub generate_num_antennas
{
    open(AntennaFile,">$AntennaFile");
    foreach my $i ( 0 .. $totalNodes-1 )
    {
	if (exists $num_antennas{$i})
	{
	    print AntennaFile "$i ",$num_antennas{$i},"\n";
	}
	else
	{
	    print AntennaFile "$i 1\n";
	}
    }
    close(AntennaFile);
}

sub read_etx
{
    open(etxFile,"<$etxFile");
    
    while (<etxFile>)
    {
        my($nodeId, $dest, $curr_cost) = split " ", $_;
        $cost{$nodeId}{$dest} = $curr_cost;
    }
    close(etxFile);
}

sub read_one_hop
{
    my $dirName = "one-hop";
    if($mac == 0 ){
	$dirName = "$dirName-11b";
    }
    
    open(S1File, "<$dirName/S1.txt");
    my %send_rate = ();
    while(<S1File>)
    {
	my($sender_id, $thput) = split " ", $_;
	$sender_id--;
	$send_rate{$sender_id} = $thput;
    }
    close(S1File);

    open(R1File, "<$dirName/R1.txt");
    while(<R1File>)
    {
	my($sender_id, $rcv_id, $goodput) = split " ", $_;
	$sender_id--;
	$rcv_id--;
	$lossMeasure{$sender_id}{$rcv_id}{0}{$default_rate} = 1-($goodput/$send_rate{$sender_id});
    }
    close(R1File);
}

sub read_power_rate
{
    my($maxRate) = 0;
    print "debug $PowerFile\n";
    
    open(PowerFile,"<$PowerFile");
    my $powerIndex = 0;
    while (<PowerFile>)
    {
        print $_;
        my($curr_power, $curr_tr, $curr_ir, $curr_cs) = split " ", $_;
        $allPowers{$powerIndex} = 1;
	printf qualnetPowerFile "%d %d\n", $powerIndex, $curr_power;
	$powerIndex++;
	
        push @TR_multi, $curr_tr;
        push @CarrierSenseRangeMulti, $curr_cs;
        push @IR_multi, $curr_ir;
    }
    close(PowerFile);

    print "debug $RateFile\n";
    
    open(RateFile,"<$RateFile");
    while(<RateFile>)
    {
        print $_;
        my($curr_rate, $skip) = split " ", $_;
        $allRates{$curr_rate} = 1;
        $maxRate = $curr_rate if ($maxRate < $curr_rate);
        print "rate $curr_rate\n";
    }
    close(RateFile);

    $numRate = (keys %allRates) + 0;
    $numPowerLevel = (keys %allPowers) + 0;

    return($maxRate);
}

sub run_shortest_path_routing
{
    print "run_shortest_path_routing\n"; 
    my($route_metric,$rateLimit) = @_;
    my($cmd);
    
    my($tx_ack) = &compute_tx_size2($transport, $mac, $ackSize, $default_rate, 0, 1); # last parameter is ack
    my($tx_dat) = &compute_tx_size2($transport, $mac, $payload, $default_rate, 0, 0);
    printf "tx_ack %f tx_dat %f\n for shortest path\n", $tx_ack, $tx_dat;

    my($loss_scale_factor) = $tx_ack/$tx_dat;

    if (!$isBER)
    {
        $loss_scale_factor = 1;
    }
    
    print "ackSize = $ackSize\t loss_scale_factor = $loss_scale_factor\n";

    if ($isMulticast && $compressShared)
    {
        $cmd = "perl get_compressed_path.pl $sppMcastFileQ $routeFile $route_metric -1 1 1 $loss_scale_factor";
        print "$cmd\n";
        system($cmd);
    }
    else
    {
        # support unicast or treating one multicast group as multiple unicast flows
        # find routing
        # get forward path
        # generate_BcastConflict_multi_rate_power($SINGLE_PATH,$totalNodes);

        $cmd = "perl get_shortest_path.pl 0 $routeFile 1 $loss_scale_factor 0 $default_power $default_rate $route_metric $lossFileBoth 1";
        print "$cmd\n";
        system($cmd);
    }
    
    # cliqConsFile, rawLossFile, flowAllocFile, ackRmatFile, rateSolFile
    if ($rateLimit == $OUR_RateLimit)
    {
        # generates clique constraints that only involve active links
        my($isBcast) = 0;
        my($wRTS) = 0;
        my($tcpDelayAcks) = 0;
        my($max_tries) = 7;
        my($cliqConsFile)  = "clique_constraints.txt";
        my($ackRmatFile)   = "ack_rmat.txt";
        my($rateSolFile)   = "rate_sol.txt";

        if ($isMulticast && $compressShared)
        {
            &get_multicast_flow_alloc($totalLinks_defaultRate,0,1); # has route but not rate
        }
        else
        {
            &get_flow_alloc($totalLinks_defaultRate,0,1); # has route but not rate
        }

        # xxx: our current model only supports single data rate (no multi-rate)
        $cmd = "rm -f $lpFile; rm -f $ackRmatFile; rm topo.stat; rm $rateSolFile; touch $ackRmatFile; batch_matlab \"compute_clique_constraints2($isSim,'$conflictLinkFile','$cliqConsFile','$rawLossFileBoth','$flowAllocFile','$ackRmatFile','$rateSolFile',$transport,$mac,$isBcast,$wRTS,$tcpDelayAcks,$default_rate,$max_tries,$payload,$routingObj)\"";
        print "$cmd\n";
        system($cmd);

        # directly use the solution produced by matlab
        $cmd = "rm -f $lpResultFile; cp $rateSolFile $lpResultFile";
        print "$cmd\n";
        system($cmd);
    }elsif ($rateLimit == $LP_RateLimit)
    {
	my $lpEffort = 500;
        my $lpOutFormat = 4;
        my $obj = 1;
        my $lambda = 0;
        
        # 2nd pass and beyond can only change rate limit but not route
        #system("cp topo.route-static topo.route-static.bak2");
        #system("cp topo.route-static.bak topo.route-static");
	system("grep -v '#' topo.route-static > topo.route-static.bak2");
	system("mv topo.route-static.bak2 topo.route-static");
        $cmd = "rm -f $lpFile; upperbound/upperbound $conflictLinkFile $lpEffort $lpOutFormat $lpFile $randSeed $obj $lambda NULL $rawLossFileBoth $EPSILON $routeFile >/dev/null";
        print "$cmd\n";
	
        system($cmd);
        #system("cp topo.route-static.bak2 topo.route-static");
        # solve the resulting LP
        $cmd = "rm -f $lpResultFile; ./cplex_solve.sh $lpFile $lpResultFile 1>/dev/null 2>/dev/null";
        print "$cmd\n";

        system($cmd);
    }

    if($rateLimit == $OUR_RateLimit || $rateLimit == $LP_RateLimit){
	if ($isMulticast && $compressShared)
	{
	    &parse_lp_output_multicast();
	}
	else
	{
	    &parse_lp_output($totalNodes,$conflictLinkFile,$lpOutFormat,$lpResultFile,$varFile,$default_rate,$payload,$rateLimit);
	    
	    # update flow lower bounds
	    &get_flow_alloc($totalLinks_defaultRate,1,1);
	    
	}
    }
        
    &run_qualnet_single_path($route_metric,$rateLimit);
}

sub get_multicast_flow_alloc
{
    my($totalLinks,$hasRate,$hasRoute) = @_;
    my($i, %used);
    my(@flow_rates,@routing_matrix);
    
    @flow_rates = (0) x $nflows;
    if ($hasRate)
    {
        open(flowRateFile,"<flow_rate");
        $i = 0;
        while(<flowRateFile>)
        {
            my ($src, $dest, $rate, $interval) = split " ", $_;
            $flow_rates[$i++] = $rate;
        }
        close(flowRateFile);
    }
    
    @routing_matrix = (0) x ($totalLinks*$nflows);
    if ($hasRoute)
    {
        open(sppMcastFileQ,"<$sppMcastFileQ") or die "can't open $sppMcastFileQ for reading!\n";
        while (<sppMcastFileQ>)
        {
            my($prevHop, $i, @lst, $nextHop, $curr_link_id);

            next if (/^\#/);

            @lst = split " ", $_;
            
            $i = $lst[0]; # flowId
            $prevHop = $lst[1]-1;
            
            for my $j ( 4 .. $#lst )
            {
                $nextHop = $lst[$j]-1; # qualnet id differs from conflict graph Id by 1
                next if ($prevHop == $nextHop);
                $curr_link_id = $linkid_defaultRate{$default_power}{$default_rate}{$prevHop}{$nextHop};
                print "$prevHop $nextHop curr_link_id = $curr_link_id\n";
                $routing_matrix[$i*$totalLinks+$curr_link_id] = 1.0;
            }
        }
        close(sppMcastFileQ);
    }
    
    open(flowAllocFile, ">$flowAllocFile") or die "can't open $flowAllocFile for writing $!\n";
    foreach $i ( 0 .. $totalLinks*$nflows-1 )
    {
        printf(flowAllocFile "%.10g ", $routing_matrix[$i]);
        if (($i+1) % $totalLinks == 0) {
            printf(flowAllocFile "%.10g\n", $flow_rates[int($i/$totalLinks)]);
        }
    }
    close(flowAllocFile);
}

sub parse_lp_output_multicast
{
    my(%id2value) = ();

    open(lpResultFile,"<$lpResultFile");
    while (<lpResultFile>)
    {
        if (/^x/)
        {
            my($var, $value) = split " ", $_;
            $value = $value+0;

            my(@lst) = split "x", $var;
            my($id) = $lst[1]+0;
            $id2value{$id} = $value;
        }
    }
    close(lpResultFile);

    open qualnetSPPRLAppFile, ">$qualnetSPPRLAppFile" or die "can't open $qualnetSPPRLAppFile for writing\n";
    $total_rate_model = 0;
    foreach my $i ( 0 .. $nflows-1 )
    {
        my(@lst) = split " ", $flow[$i]; # <demand> <src> <dest_lst>
        my($src) = $lst[1];
        my($rate, $interval, $startTime, $scale);
        foreach my $p ( keys %allPowers )
        {
            foreach my $r ( keys %allRates )
            {
                foreach my $nextHop ( 0 .. $totalNodes-1 )
                {
                    next if (!exists $linkid_defaultRate{$p}{$r}{$src}{$nextHop});
                    my($ll) = $linkid_defaultRate{$p}{$r}{$src}{$nextHop};
                    print "i=$i totalLinks_defaultRate=$totalLinks_defaultRate ll=$ll\n";
                    my($nf) = $i * $totalLinks_defaultRate + $ll;
                    if ($id2value{$nf} > 0)
                    {
                        $rate = $id2value{$nf}*$maxRate*1000000;
                        $interval = $payload*8/$rate;
                        print "debugggg: $src -1 $rate $interval\n";
                    }
                }
            }
        }

        $startTime = $startTimeRange*$src/$totalNodes;
        
        if ($transport)
        {
            print qualnetSPPRLAppFile "MCBR 0.0.0.", $src+1," 0.0.255.255 0 $payload $interval $startTime 0\n";
        }

        push @rate_perflow_model, $rate;
        $total_rate_model += $rate;
    }
    close(qualnetSPPRLAppFile);

    # print "total_rate_model = $total_rate_model\n";
    # print (join " ", @rate_perflow_model);
    # print "\n";
    
    # when a flow's estimated throughput, it's not yet included in rate_perflow_model since flowRateFile only includes flows with nonzero throughput
    for (my $i = @rate_perflow_model+0; $i < $nflows; $i++)
    {
        push @rate_perflow_model, 0;
    }
}

sub get_flow_alloc
{
    my($totalLinks,$hasRate,$hasRoute) = @_;
    my($i, %used);
    my(@flow_rates,@routing_matrix);
    
    @flow_rates = (0) x $nflows;
    if ($hasRate)
    {
        open(flowRateFile,"<flow_rate");
        $i = 0;
        
        while(<flowRateFile>)
        {
            my ($src, $dest, $rate, $interval) = split " ", $_;
            $flow_rates[$i++] = $rate;
        }
        close(flowRateFile);
    }

    # treating one multicast flow as multiple unicast flows
    @routing_matrix = (0) x ($totalLinks*$group_size*$nflows);
    if ($hasRoute)
    {
        open(routeFile, "<$routeFile") or die "can't open $routeFile for reading!\n";
        $i = 0;
        while (<routeFile>)
        {
            my($addr, @addr_cmp, $prevHop, $nextHop, @lst, $src, $dest, $curr_link_id);
            next if (/^\#/);
            @lst = split " ", $_;

            @addr_cmp = split /\./, $lst[1];
            $src = $addr_cmp[3]-1;
            
            @addr_cmp = split /\./, $lst[2];
            $dest = $addr_cmp[3]-1;
            
            $prevHop = $src;

            for (my $j = 7; $j <= $#lst; $j+=3)
            {
                $addr = $lst[$j];
                @addr_cmp = split /\./, $addr;
                $nextHop = $addr_cmp[3]-1; # qualnet id differs from conflict graph Id by 1
                $curr_link_id = $linkid_defaultRate{$default_power}{$default_rate}{$prevHop}{$nextHop};
                #print "curr_link_id = $curr_link_id\n";
                #print "indexxxxxxx = ",$i*$totalLinks+$curr_link_id,"\n";
                $routing_matrix[$i*$totalLinks+$curr_link_id] = 1.0;
                $prevHop = $nextHop;
            }
            $i++;
        }
        close(routeFile);
    }
    
    # treating one multicast flow as multiple unicast flows
    open(flowAllocFile, ">$flowAllocFile") or die "can't open $flowAllocFile for writing $!\n";
    foreach $i ( 0 .. $totalLinks*$group_size*$nflows-1 )
    {
        printf(flowAllocFile "%.10g ", $routing_matrix[$i]);
        if (($i+1) % $totalLinks == 0) {
            printf(flowAllocFile "%.10g\n", $flow_rates[int($i/$totalLinks)]);
        }
    }
    close(flowAllocFile);
}

sub parse_lp_output
{
    my($totalNodes,$conflictFile,$lpOutFormat,$lpResultFile,$varFile,$maxRate,$payload, $rateLimit) = @_;
    my($cmd, $src, $dest, $rate, $interval, $i,$epsilon,$scale,$startTime);

    $epsilon = $EPSILON * 0.75;
    $cmd = "perflow/perflow $conflictFile $lpOutFormat $lpResultFile $varFile $epsilon 1>/dev/null";
    print "$cmd\n";
    system($cmd);


    $cmd = "./flow_analysis.py $varFile flow_rate $routeFile $maxRate $payload $epsilon";
    print "$cmd\n";
    system($cmd);
    # system("cp flow_rate flow_rate.$routing");

    @rate_perflow_model = ();
    $total_rate_model = 0;
    
    foreach $scale ( 1 ) # 1.1, 1.2, 1.5
    {
        open(flowRateFile,"<flow_rate");
        open qualnetSPPRLAppFile, ">$qualnetSPPRLAppFile" or die "can't open $qualnetSPPRLAppFile for writing\n";
        
        while(<flowRateFile>)
        {
            ($src, $dest, $rate, $interval) = split " ", $_;
            
            $interval /= ($scale+0.0);
            $startTime = $startTimeRange*$src/$totalNodes;
            
            if ($transport)
            {
                print qualnetSPPRLAppFile "CBR 0.0.0.", $src+1," 0.0.0.", $dest+1," 0 $payload $interval $startTime 0\n";
            }
            else
            {
                # assume the simulation time < 100 seconds
                printf qualnetSPPRLAppFile "SUPER-APPLICATION 0.0.0.%d 0.0.0.%d DELIVERY-TYPE RELIABLE START-TIME DET ${startTime}S DURATION DET 0 REQUEST-NUM DET %d REQUEST-SIZE DET %d REQUEST-INTERVAL DET %.9fS REQUEST-TOS PRECEDENCE 0 REPLY-PROCESS NO\n", $src+1, $dest+1, int(100/$interval), $payload, $interval;
                # printf qualnetTokenFile "%d %d %d %d %d %.6f\n", $src+1, $dest+1, $bucketSize, int($payload/$interval), $payload, $interval;
            }
            
            if ($scale == 1)
            {
		my $pushrate = $rate*$maxRate*1000000;
		$pushrate = $rate*1000000 if($rateLimit == $LP_RateLimit);
		
                push @rate_perflow_model, $pushrate;
                print "push ",$pushrate," xxx ";
                print (join " ", @rate_perflow_model);
                print "\n";
                $total_rate_model += $pushrate;
            }
        }
        
        close(flowRateFile);
        close(qualnetSPPRLAppFile);
        # close(qualnetTokenFile);
    }

    # when a flow's estimated throughput, it's not yet included in rate_perflow_model since flowRateFile only includes flows with nonzero throughput
    for (my $i = @rate_perflow_model+0; $i < $nflows; $i++)
    {
        push @rate_perflow_model, 0;
    }
}

sub run_mimo_routing
{
    enumerate_composite_links();
    generate_conflict_composite_link();
    findIndepSets_composite($totalCompositeLinks, $effort*$nflows, $indepMultiFile, \@composite_link_conflict, \@composite_link_single_antenna_sender);

    my($target_power) = -1;
    my($target_rate) = -1;
    my($cmd) = "perl mimo.pl $mac $randSeed $GAMMA $EPSILON $target_power $target_rate 1 $routingObj $pruningMode $isMultiRate 0 $model";
    print "$cmd\n";
    system($cmd);

    $cmd = "perl revise-credit.pl";
    print "$cmd\n";
    system($cmd);
    system("mv composite-new.txt composite.txt");
    system("mv topo.credit-new.s1 topo.credit.s1");

    $cmd = "perl post-process-mimo.pl";
    print "$cmd\n";
    system($cmd);
    
    # exit(0);
    ## add by yichao: run qualnet
    my($total_goodput_model, @goodput_model);
    generate_BcastConflict("MORE", $totalNodes);
    system("perl get_fwdInfo_multicast.pl $FWD_PRUNE_THRESH 0 $default_rate $lossFileBoth");
    system("perl get_fwdInfo_multicast.pl $FWD_PRUNE_THRESH 1 $default_rate $lossFileBoth");
    run_qualnet_OR("MIMO", $total_goodput_model, @goodput_model);

}

# fwd list, parse output, take MORE output
sub run_or_routing
{
    my($scheme) = @_;
    my($maxNumFwdLists) = 1;
    my($total_goodput_model, @goodput_model, $isMulti);

    if ($scheme eq $MORE)
    {
        generate_BcastConflict($scheme,$totalNodes);
        # findIndepSets($totalNodes,$effort,$indepFile,\@conflict);
        
        $isMulti = 0;

        # if ($group_size == 1)
        # {
        #    # system("perl get_fwdInfo.pl $FWD_PRUNE_THRESH 0 $isMulti");
        #    system("perl get_fwdInfo.pl $FWD_PRUNE_THRESH 1 $isMulti");
        #}

        # fixme: fix bug in get_fwdInfo_multicast.pl
        system("perl get_fwdInfo_multicast.pl $FWD_PRUNE_THRESH 0 $default_rate $lossFileBoth");
        system("perl get_fwdInfo_multicast.pl $FWD_PRUNE_THRESH 1 $default_rate $lossFileBoth");
        # fixme: call Mikie's script to compute credit
        # system("perl get_etx.pl $isMulti etx.txt");
        # system("perl more-final.pl $randSeed $GAMMA $EPSILON -1 -1 0 1");
    }
    elsif ($scheme eq $OUR2)
    {
	generate_BcastConflict_multi_rate_power($totalNodes);
	# findIndepSetsMulti($totalNodes,$effort,$indepMultiFile,\%conflictMulti,\%allRates,$numPowerLevel);
        my($target_rate);
        my($target_power) = -1;
        
        if ($isMultiRate)
        {
            $target_rate = -1;
        }
        else
        {
            $target_rate = $default_rate;
        }

	printf "model is %d %d\n", $model, WiFi_MODEL;
 
        if ($model == WiFi_MODEL)
        {
            my $cmd = "./batch_matlab \"optimize_opr6_multirate($randSeed,'$matlabResultFile',$isSim,'$conflictLinkFile-out',$mac,$payload,$target_power,$target_rate,$routingObj,$pruningMode,$isMultiRate)\"";
            print "$cmd\n";
            system($cmd);

        }
        else
        {
            # findIndepSetsMulti($totalNodes,$effort,$indepMultiFile,\%conflictMulti,\%allRates,$numPowerLevel);
            print "perl opr-final2-multirate.pl $mac $randSeed $GAMMA $EPSILON $target_power $target_rate 1 $routingObj $pruningMode $isMultiRate 0 $model\n";
            system("perl opr-final2-multirate.pl $mac $randSeed $GAMMA $EPSILON $target_power $target_rate 1 $routingObj $pruningMode $isMultiRate 0 $model");
        }

	return if($isMulticast);

    }
    else
    {
        print "Unsupported scheme $scheme\n";
        exit(0);
    }

    # run qualnet 
    run_qualnet_OR($scheme, $total_goodput_model,@goodput_model);
}

sub run_qualnet_OUR_multicast
{
    my($scheme,$max_global_state_id) = @_;
    if (!($scheme eq $OUR2))
    {
	print "run_qualnet_OR_multicast only applies to OUR2\n";
	exit(0);
    }
    my($comment);
    $MAX_THROUGHPUT = 1000000; # do not normalize it but change it to Mbps.
    my $isopr = 1;
    my($tx_ack) = &compute_tx_size2($transport, $mac, $opr_ackSize, $default_rate, $isopr, 1); # last parameter is isack
    my($tx_dat) = &compute_tx_size2($transport, $mac, $payload, $default_rate, $isopr, 0);
    printf "tx_ack %f tx_dat %f\n for shortest path OPR \n", $tx_ack, $tx_dat;
   
    my($loss_scale_factor) = $tx_ack/$tx_dat;

    if (!$isBER)
    {
	$loss_scale_factor = 1;
    }
    system("perl get_shortest_path.pl 1 $qualnetACKRouteMulti $loss_scale_factor $loss_scale_factor 0 $default_power $default_rate $ETX $lossFile 1"); # get ack path by shortest ETT when multi

    my $weight_str="";
    foreach my $i ( 0 .. $max_global_state_id)
    {
	$weight_str="$weight_str\\nTX-CREDIT-WEIGHT-FILE[$i] topo.weight.r$i";
    }
    # run with scaled up demands
    #print "$weight_str";

    foreach my $scale ( 1 ) # ( 1.1, 1.2, 1.5 )
    {
	# next if ($scale >1);
	# my($cmd) = "sed 's/TX-CREDIT-FILE topo.credit/TX-CREDIT-FILE topo.credit.s$scale/' lp.$scheme.config > lp-s$scale.$scheme.config";
	# system($cmd);

	my $credit_str="";

	foreach my $i ( 0 .. $max_global_state_id)
	{
	    $credit_str="$credit_str\\nTX-CREDIT-FILE[$i] topo.credit.s$scale.r$i";
	}
	$credit_str="$credit_str\\n";
	#print "$credit_str";
	$comment = "$totalNodes $nflows $randSeed $max_hop ";
	
	# always credit based
	system("sed 's/TX-CREDIT-FILE topo.credit/TX-CREDIT-FILE topo.credit.s$scale/;s/SIMULATION-TIME .*/SIMULATION-TIME ${sim_time}S/' lp.$scheme.config > lp-s$scale.$scheme.config");
	system("sed 's/TX-CREDIT-FILE topo.credit.s$scale/$credit_str/;s/TX-CREDIT-WEIGHT-FILE topo.weight/$weight_str/;s/SIMULATION-TIME .*/SIMULATION-TIME ${sim_time}S/' lp-s$scale.$scheme.config > lp-s$scale-multicast.$scheme.config");
	# system("rm topo.stat");
	# system("./qualnet lp-s$scale-multicast.$scheme.config >\& /dev/null");
	# system("perl process-stat.pl -t $transport -s $sim_time -g $isMulticast -c \"$comment\" -m $MAX_THROUGHPUT topo.stat >> summary.qualnet.$scheme.p$pruningMode.r$routingObj.m$model.MR$isMultiRate.R$default_rate.$mac_str.rl");	
    }
}


sub run_qualnet_OR
{
    my($scheme, $total_goodput_model,@goodput_model) = @_;
    my($comment);

    $MAX_THROUGHPUT = 1000000; # do not normalize it but change it to Mbps.

    # system("Graph/shortest-path.py 2 $qualnetFaultFile $conflictInFile $qualnetACKRoute");
    #my($tx_ack) = &compute_tx_size($transport, $mac, $ackSize, $default_rate);
    #my($tx_dat) = &compute_tx_size(1,          $mac, $payload, $default_rate);

    my $isopr = 1;
    my($tx_ack) = &compute_tx_size2($transport, $mac, $payload, $default_rate, $isopr, 1); # last parameter is isack
    my($tx_dat) = &compute_tx_size2($transport, $mac, $payload, $default_rate, $isopr, 0);
    printf "tx_ack %f tx_dat %f\n for shortest path OPR \n", $tx_ack, $tx_dat;
   
    my($loss_scale_factor) = $tx_ack/$tx_dat;

    if (!$isBER)
    {
	$loss_scale_factor = 1;
    }

    if ( $scheme eq $MORE )
    {
	my $isMORE = 1;
        my $cmd = "perl get_shortest_path.pl 1 $qualnetACKRouteMulti $loss_scale_factor $loss_scale_factor $isMORE $default_power $default_rate $ETX $lossFileBoth 1";
        print $cmd,"\n";
	system($cmd); # get ack path by shortest ETT when multi
    }
    ## add by yichao: do the same thing as MORE
    elsif ( $scheme eq $MIMO )
    {
	my $isMORE = 1;
        my $cmd = "perl get_shortest_path.pl 1 $qualnetACKRouteMulti $loss_scale_factor $loss_scale_factor $isMORE $default_power $default_rate $ETX $lossFileBoth 1";
        print $cmd,"\n";
	system($cmd); # get ack path by shortest ETT when multi
    }
    else
    {
        my $cmd = "perl get_shortest_path.pl 1 $qualnetACKRouteMulti $loss_scale_factor $loss_scale_factor 0 $default_power $default_rate $ETX $lossFileBoth 1";
        print $cmd,"\n";
	system("$cmd"); # get ack path by shortest ETT when multi
    }

    # run OUR2 w/ RL
    if ($scheme eq $OUR2)
    {
        # run with scaled up demands

        foreach my $scale ( 1 ) # ( 1.1, 1.2, 1.5 ) # test sensitivity
        {
            next if ($scale >1 && $model != WiFi_MODEL && $routingObj != OBJ_MAX_GOODPUT);
            # my($cmd) = "sed 's/TX-CREDIT-FILE topo.credit/TX-CREDIT-FILE topo.credit.s$scale/' lp.$scheme.config > lp-s$scale.$scheme.config";
            # system($cmd);

            $comment = "$totalNodes $nflows $randSeed $max_hop ";

            # always credit based
            system("sed 's/TX-CREDIT-FILE topo.credit/TX-CREDIT-FILE topo.credit.s$scale/;s/SIMULATION-TIME .*/SIMULATION-TIME ${sim_time}S/' lp.$scheme.config > lp-s$scale.$scheme.config");


            print "run qualnet\n";
            system("rm topo.stat");
	    print "scale is $scale scheme is $scheme \n";

	    # print "./qualnet lp-s$scale.$scheme.config > /dev/null\n"; 
	    # system("./qualnet lp-s$scale.$scheme.config > /dev/null 2>&1");	    
	    print "./qualnet-$scheme lp-s$scale.$scheme.config > /dev/null\n"; 
	    system("./qualnet-$scheme lp-s$scale.$scheme.config > /dev/null 2>&1");	## yichao

            system("perl process-stat.pl -t $transport -s $sim_time -c \"$comment\" -m $MAX_THROUGHPUT topo.stat >> summary-s$scale.qualnet.$scheme.p$pruningMode.r$routingObj.m$model.MR$isMultiRate.R$default_rate.$mac_str.rl");

#            print "run qualnet-inst-ack\n";
#            system("rm topo.stat");
#            system("./qualnet-inst-ack lp-s$scale.$scheme.config >\& /dev/null");
#            system("perl process-stat.pl -t $transport -s $sim_time -c \"$comment\" -m $MAX_THROUGHPUT topo.stat >> summary-inst-ack.qualnet.$scheme.rl");

#            print "run qualnet-multibatch\n";
#            system("rm topo.stat");
#            system("echo \"NUM-BATCHES 1\" >> lp-s$scale.$scheme.config");
#            system("./qualnet-multibatch lp-s$scale.$scheme.config > /dev/null");
#            system("perl process-stat.pl -t $transport -s $sim_time -c \"$comment\" -m $MAX_THROUGHPUT topo.stat >> summary-multibatch.qualnet.$scheme.rl");
            
            # system("rm topo.stat");
            # system("sed 's/TIME-BASED-TX-CREDIT YES/TIME-BASED-TX-CREDIT NO/' lp-s$scale.$scheme.config > lp-ratio-s$scale.$scheme.config");
            # system("./qualnet lp-ratio-s$scale.$scheme.config > /dev/null");
            # system("perl process-stat.pl -t $transport -s $sim_time -c \"$comment\" -m $MAX_THROUGHPUT topo.stat >> summary-ratio.qualnet.$scheme.rl");
            
        }
    }
    else
    {
        # run MORE and OUR2 wo/ RL
        $comment = "$totalNodes $nflows $randSeed $max_hop ";
        system("rm topo.stat");
	# print "./qualnet lp-nrl.$scheme.config > /dev/null 2>&1\n";
	#         system("./qualnet lp-nrl.$scheme.config > /dev/null 2>&1");
	
	## normal
	print "./qualnet-$scheme lp-nrl.$scheme.config > /dev/null 2>&1\n";
	system("./qualnet-$scheme lp-nrl.$scheme.config");	## yichao
	
	
        ## yichao: mimo has different process-stat script
	if($scheme eq $MIMO) {
		system("perl process-stat-mimo.pl -t $transport -s $sim_time -g $isMulticast -c \"$comment\" -m $MAX_THROUGHPUT topo.stat >> summary.qualnet.$scheme.MR$isMultiRate.R$default_rate.$mac_str.nrl");
	}
	else {
		system("perl process-stat.pl -t $transport -s $sim_time -g $isMulticast -c \"$comment\" -m $MAX_THROUGHPUT topo.stat >> summary.qualnet.$scheme.MR$isMultiRate.R$default_rate.$mac_str.nrl");
	}
	# system("perl process-stat.pl -t $transport -s $sim_time -g $isMulticast -c \"$comment\" -m $MAX_THROUGHPUT topo.stat >> summary.qualnet.$scheme.MR$isMultiRate.R$default_rate.$mac_str.nrl");
	
	
#        system("rm topo.stat");
#        system("./qualnet-inst-ack lp-nrl.$scheme.config > /dev/null");
#        system("perl process-stat.pl -t $transport -s $sim_time -c \"$comment\" -m $MAX_THROUGHPUT topo.stat >> summary-inst-ack.qualnet.$scheme.nrl");

        # system("./qualnet-always-innovative lp-nrl.$scheme.config > /dev/null");
        # system("perl process-stat.pl -t $transport -s $sim_time -c \"$comment\" -m $MAX_THROUGHPUT topo.stat >> summary-always-innovative.qualnet.$scheme.nrl");
        
    }
}

sub run_qualnet_single_path
{
    my($route_metric,$rateLimit) = @_;
    my $comment;
    my $output;
    
    if ( 0 ) {
        system("/v/filer4b/v27q001/ut-wireless/qualnet-ETX lp.SPP.config > /dev/null");
        $comment = "$totalNodes $nflows $randSeed $max_hop "; 
        system("perl process-stat.pl -t $transport -s $sim_time -c \"$comment\" -m $MAX_THROUGHPUT topo.stat >> summary.qualnet.$SINGLE_PATH.$mac_str.rl");
    }

    $comment = "$totalNodes $nflows $randSeed $max_hop $total_rate_model";
    $comment = join " ", $comment, @rate_perflow_model;
    
    print "mikie mikie ";
    print join " ", @rate_perflow_model;
    print "\n";
    # $comment = "$totalNodes $nflows $randSeed $max_hop ";
    
    if ($route_metric == $ETX)
    {
        $output = "ETX";
    }
    else
    {
        $output = "ETT";
    }

    if ($rateLimit != $OUR_RateLimit && $rateLimit != $LP_RateLimit)
    {
        if ($isMulticast && $compressShared)
        {
            system("./qualnet-spp lp-nrl.SPP.Compress.config >\& /dev/null");
            my($cmd) = "perl process-stat.pl -t $transport -s $sim_time -c \"$comment\" -m $MAX_THROUGHPUT -g $isMulticast topo.stat >> summary.qualnet.$output.MR$isMultiRate.R$default_rate.$mac_str.nrl";
            print $cmd,"\n";
            system($cmd);
        }
        else
        {

            system("./qualnet-spp lp-nrl.SPP.config > /dev/null 2>&1");
            system("perl process-stat.pl -t $transport -s $sim_time -c \"$comment\" -m $MAX_THROUGHPUT -g $isMulticast -SPP topo.stat >> summary.qualnet.$output.MR$isMultiRate.R$default_rate.$mac_str.nrl");
        }
    }
    else
    {
         if ($isMulticast && $compressShared)
         {
             system("./qualnet-spp lp.SPP.Compress.config > /dev/null 2>&1");
             system("perl process-stat.pl -t $transport -s $sim_time -c \"$comment\" -m $MAX_THROUGHPUT -g $isMulticast topo.stat >> summary.qualnet.$output.r$routingObj.m$model.MR$isMultiRate.R$default_rate.$mac_str.rl");
         }
         else
         {
	     print "./qualnet-spp lp.SPP.config\n";
             system("./qualnet-spp lp.SPP.config > /dev/null 2>&1");
             system("perl process-stat.pl -t $transport -s $sim_time -c \"$comment\" -m $MAX_THROUGHPUT -g $isMulticast -SPP topo.stat >> summary.qualnet.$output.r$routingObj.m$model.MR$isMultiRate.R$default_rate.$mac_str.rl");
         }
    }
}

sub generate_link_conflict
{
    my($cmd, $line, $linkId, $curr_totalLinks_defaultRate, $skip);
    
    # system("rm $conflictLinkFile-in $conflictLinkFile-out");
    # $cmd = "../ConflictGraph-sigcomm-camera-ready/ConflictGraph $topoFile $conflictLinkFile-in bidireclink 1>/dev/null";
    # print "$cmd\n";
    # system($cmd);

    open conflictIN, "<$conflictLinkFile" or die "can't open $conflictLinkFile for reading\n";
    open conflictOUT,  ">$conflictLinkFile-out" or die "can't open $conflictLinkFile-out for writing\n";

    $line = <conflictIN>;
    print conflictOUT "$line";

    $line = <conflictIN>;
    print conflictOUT "$line";

    $line = <conflictIN>;
    print conflictOUT "$line";

    $line = <conflictIN>;
    print conflictOUT "$line";
    ($curr_totalLinks_defaultRate, $skip) = split " ", $line;
    # print conflictOUT "$curr_totalLinks_defaultRate $totalLinks_allRate $totalLogicalNodes_allRate\n";
    
    # skip link loss rate in conflictIN
    foreach $linkId ( 0 .. $curr_totalLinks_defaultRate-1)
    {
        $line = <conflictIN>;
        print conflictOUT "$line";
    }

    # print pnode2logical
    if ($isMultiRate)
    {
        printf conflictOUT "%d %d %d\n", $totalLogicalNodes_allRate, $default_power, $default_rate;
    }
    else
    {
        printf conflictOUT "%d %d %d\n", $totalNodes, $default_power, $default_rate;
        
    }
    
    foreach my $src ( 0 .. $totalNodes - 1)
    {
        foreach my $p ( 0 .. $numPowerLevel - 1 )
        {
            foreach my $r ( sort {$a<=>$b} (keys %allRates) )
            {
                next if (!$isMultiRate && $r != $default_rate);
                printf conflictOUT "%4d %3d %3d %3d\n", $pnode2logical{$p}{$r}{$src}, $src, $p, $r;
            }
        }
    }

    # print loss rate on all data rates (i.e. logical links)
    if ($isMultiRate)
    {
        print conflictOUT "$totalLinks_allRate\n";
    }
    else
    {
        print conflictOUT "$totalLinks_defaultRate\n";
    }
    
    foreach my $src ( 0 .. $totalNodes - 1)
    {
        foreach my $dest ( 0 .. $totalNodes - 1)
        {
            next if ($src == $dest) ;
            foreach my $p ( 0 .. $numPowerLevel - 1 )
            {
                foreach my $r ( sort {$a<=>$b} (keys %allRates) )
                {
                    next if (!$isMultiRate && $r != $default_rate);
                    
                    if ( distance($src,$dest) < $TR_multi[$p] )
                    {
                        if ($isMultiRate)
                        {
			    printf conflictOUT "%4d %3d %3d 0 %.6f\n", $linkid{$p}{$r}{$src}{$dest}, $pnode2logical{$p}{$r}{$src}, $dest, (1-(1-$lossMulti{$src}{$dest}{$p}{$r}) * (1-$lossMeasure{$src}{$dest}{$p}{$r}));

                        }
                        else
                        {
			    printf conflictOUT "%4d %3d %3d 0 %.6f\n", $linkid_defaultRate{$p}{$r}{$src}{$dest}, $pnode2logical{$p}{$r}{$src}, $dest, (1-(1-$lossMulti{$src}{$dest}{$p}{$r}) * (1-$lossMeasure{$src}{$dest}{$p}{$r}));

                        }
                    }
                }
            }
        }
    }
    
    while (<conflictIN>)
    {
        print conflictOUT $_;
    }
    
    close(conflictIN);
    close(conflictOUT);

}

sub generate_BcastConflict
{
    my($scheme,$totalNodes) = @_;
    my($i, $j, $line, $skip, $r, $numFlows);

    # system("rm tmp-conflict");
    # system("../ConflictGraph-sigcomm-camera-ready/ConflictGraph $topoFile $conflictInFile bidireclink > /dev/null");
    
    open conflictIN, "<$conflictLinkFile" or die "can't open $conflictLinkFile for reading\n";
    open conflictOUT, ">$conflictFile" or die "can't open $conflictFile for writing\n";
    
    $line = <conflictIN>;
    print conflictOUT "$line";

    $line = <conflictIN>;
    print conflictOUT "$line";

    $line = <conflictIN>;
    print conflictOUT "$line";
    
    # add node info.
    foreach $i ( 0 .. $totalNodes-1 )
    {
        print conflictOUT "$i $default_rate\n";
    }
    
    # add link loss rate to the last column
    $line = <conflictIN>;
    print conflictOUT $line;
    
    ($totalLinks_defaultRate, $skip) = split " ", $line;
    foreach $i ( 0 .. $totalLinks_defaultRate-1 )
    {
        $line = <conflictIN>;
        my($linkId, $src, $dest, $channel, $capacity) = split " ", $line;
        # 1 transmission power level
        if ($scheme eq $OUR || $scheme eq $MORE)
        {
	    printf conflictOUT "%d %d %d %d %.4g %.4g\n", $linkId, $src, $dest, $channel, $capacity, (1-(1-$loss{$src}{$dest}) * (1-$lossMeasure{$src}{$dest}{0}{$default_rate})); # $loss{$src}{$dest}

        }
        elsif ($scheme eq $OUR2 || $scheme eq $MORE2)
        {
            printf conflictOUT "%d %d %d %d 0 %.4g %.4g\n", $linkId, $src, $dest, $channel, $capacity, (1-(1-$loss{$src}{$dest}) * (1-$lossMeasure{$src}{$dest}{0}{$default_rate})); # $loss{$src}{$dest}
            
        }
        else
        {
            printf "Unsupported scheme! Exiting ...\n";
            exit(0);
        }
    }

    # generate broadcast conflict matrix
    foreach $i ( 0 .. $totalNodes-1 )
    {
        foreach $j ( $i+1 .. $totalNodes-1 )
        {
            if (distance($i, $j) < $TR && $loss{$i}{$j} < 1 && $loss{$j}{$i} < 1)
            {
                push @{$neighbors{$i}}, $j;
                push @{$neighbors{$j}}, $i;
            }
        }
    }
    
    foreach $i ( 0 .. $totalNodes-1 )
    {
        foreach $j ( 0 .. $totalNodes-1 )
        {
            # conflict if (i) senders carrier sense or (ii) one sender interfere with the other's receiver
            $conflict[$i][$j] = 0;
            
            next if ($i == $j);
            
            if (distance($i, $j) < $CarrierSenseRange)
            {
                $conflict[$i][$j] = 1;
            }

            next if ($conflict[$i][$j]);
            
            foreach $r ( @{$neighbors{$i}} )
            {
                if (distance($j, $r) < $IR)
                {
                    $conflict[$i][$j] = 1;
                    last;
                }
            }

            next if ($conflict[$i][$j]);
            
            foreach $r ( @{$neighbors{$j}} )
            {
                if (distance($i, $r) < $IR)
                {
                    $conflict[$i][$j] = 1;
                    last;
                }
            }
        }
    }
    
    foreach $i ( 0 .. $totalNodes-1 )
    {
        foreach $j ( 0 .. $totalNodes-1 )
        {
            print conflictOUT $conflict[$i][$j]," ";
        }
        print conflictOUT "\n";
    }

    # skip link-level conflict graph
    foreach $i ( 0 .. $totalLinks_defaultRate-1 )
    {
        $line = <conflictIN>;
    }
    
    # output flow info.
    $line = <conflictIN>;
    print conflictOUT $line;
    ($numFlows, $skip) = split " ", $line;
    
    foreach $i ( 0 .. $numFlows-1 )
    {
        $line = <conflictIN>;
        print conflictOUT $line;
    }
}

## added by mikie for qualnet multi-rate multi-power
## n0 is physical node 0 
## p0 is power level index 0 
## r0 is rate index 0 
## if we have n physical nodes using p power level and r rates,
## then we have n x p x r  "vertices" denoted as "n:p:r" 

# ...

sub generate_loss_traffic_file
{
    open(lossFileBoth, ">$lossFileBoth"); # should contain both inherent loss by qualnet signal and injected loss
    print lossFileBoth "$totalNodes $totalLogicalNodes_allRate\n";

    open(lossFile,">$lossFile");
    print lossFile "$totalNodes $totalLogicalNodes_allRate\n";
    foreach my $r ( keys %allRates )
    {
        #next if (!$isMultiRate && $r != $default_rate);
        
        foreach my $src ( 0 .. $totalNodes - 1)
        {
            foreach my $dest ( 0 .. $totalNodes - 1)
            {
                next if ($src == $dest) ;
                foreach my $p ( 0 .. $numPowerLevel - 1 )
                {
                    if ( distance($src,$dest) < $TR_multi[$p])
                    {
                        printf lossFile "%d %d %d %d %d %d 0 %.4g\n", $linkid{$p}{$r}{$src}{$dest}, $pnode2logical{$p}{$r}{$src}, $src, $p, $r, $dest, $lossMulti{$src}{$dest}{$p}{$r};

			printf lossFileBoth "%d %d %d %d %d %d 0 %.4g\n", $linkid{$p}{$r}{$src}{$dest}, $pnode2logical{$p}{$r}{$src}, $src, $p, $r, $dest, (1-(1-$lossMulti{$src}{$dest}{$p}{$r}) * (1-$lossMeasure{$src}{$dest}{0}{$default_rate}));
                    }
                }
            }
        }
    }
    close(lossFile);
    close(lossFileBoth);

    open(trafficFile,">$trafficFile");
    foreach my $i ( 0 .. $nflows-1 )
    {
        print trafficFile $est_flow[$i],"\n";
    }
    close(trafficFile);
}

sub generate_init_traffic_file
{
    system("cp $trafficFile $trafficFile-0");

    # sort demands
    my @ddd = ();
    foreach my $i ( 0 .. $nflows-1 )
    {
        my @lst = split " ", $est_flow[$i];
        print "dddd: ", $lst[1]," ",$lst[2]," ",$cost{$lst[1]}{$lst[2]},"\n";
        push @ddd, $lst[0]/$cost{$lst[1]}{$lst[2]};
    }

    $ninit = $#ddd if ($ninit > $#ddd);

    my(@sorted_idx) = sort {$ddd[$b] <=> $ddd[$a]} (0 .. $#ddd);
    
    foreach my $i ( 0 .. $ninit )
    {
        my $k = $i+1;
        open(trafficFile,">$trafficFile-$k");
        foreach my $j ( 0 .. $nflows-1 )
        {
            if ($j == $sorted_idx[$i])
            {
                print trafficFile $est_flow[$j],"\n";
            }
            else
            {
                my(@lst) = split " ", $est_flow[$j];
                #my($curr_demand) = $lst[0];
                #$curr_demand = $EPSILON*$InfDemand if ($curr_demand > $EPSILON*$InfDemand);
                my($curr_demand) = 0;
                print trafficFile $curr_demand," ";
                print trafficFile (join " ", @lst[1..$#lst]);
                print trafficFile "\n";
            }
        }
        close(trafficFile);
    }
}

sub generate_BcastConflict_multi_rate_power
{
    my($totalNodes) = @_;
    my($i, $j, $k, $l, $p, $r, $line, $skip, $numFlows, $pi, $ri, $pj, $rj, $ratei, $ratej, $rvertex, $powerr, $rater);

    open conflictMultiOUT, ">$conflictMultiFile" or die "can't open $conflictMultiFile for writing\n";
    
    print conflictMultiOUT "$totalNodes\n";
    print conflictMultiOUT "$numPowerLevel \n";
    print conflictMultiOUT "$numRate \n";

    my $numLink = 0;
    foreach $k ( 0 .. $totalNodes - 1)
    {
	foreach $l ( 0 .. $totalNodes - 1)
	{
	    next if ($k == $l);
	    foreach $p ( 0 .. $numPowerLevel - 1 )
	    {
		if ( distance($k,$l) < $TR_multi[$p] )
		{
                    if ($isMultiRate)
                    {
                        $numLink += $numRate;
                    }
                    else
                    {
                        $numLink++;
                    }
		}
	    }
	}
    }

    print conflictMultiOUT "$numLink \n";
    my $linkId = 0;
    foreach $r (keys %allRates )
    {
        next if ((!$isMultiRate) && $r!=$default_rate);
        
        foreach my $src ( 0 .. $totalNodes - 1)
        {
            foreach my $dest ( 0 .. $totalNodes - 1)
            {
                next if ($src == $dest) ;
                foreach $p ( 0 .. $numPowerLevel - 1 )
                {
                    if ( distance($src,$dest) < $TR_multi[$p])
                    {
			printf conflictMultiOUT "%d %d %d %d %d 0 %.4g\n", $linkId, $src, $p, $r, $dest, $lossMulti{$src}{$dest}{$p}{$r};
			$linkId++;
		    }
		}
	    }
	}
    }
    if ($numLink != $linkId )
    {
	printf "num link$numLink $linkId $isMultiRate $default_rate mismatch!! Exiting ...\n";
	exit(0);
    }
    
    # generate broadcast conflict matrix
    foreach $i ( 0 .. $totalNodes-1 )
    {
	foreach $pi ( 0 .. $numPowerLevel - 1)
	{
	    foreach my $ratei ( keys %allRates )
	    {
                next if ((!$isMultiRate) && $ratei!=$default_rate);
                
		foreach $j ( $i+1 .. $totalNodes-1 )
		{
		    if (distance($i, $j) < $TR_multi[$pi] && $lossMulti{$i}{$j}{$pi}{$ratei} < 1 )
		    {
			foreach $pj ( 0 .. $numPowerLevel -1 )
			{
			    foreach my $ratej ( keys %allRates )
			    {
                                next if ((!$isMultiRate) && $ratej!=$default_rate);
                                
				if($lossMulti{$j}{$i}{$pj}{$ratej} < 1)
				{
				    push @{$neighborsMulti{"$i:$pi:$ratei"}}, "$j:$pj:$ratej";
				    push @{$neighborsMulti{"$j:$pj:$ratej"}}, "$i:$pi:$ratei";
				}
			    }
			}
		    }
		}
	    }
        }
    }
    
    foreach $i ( 0 .. $totalNodes-1 )
    {
	foreach $pi ( 0 .. $numPowerLevel - 1)
	{
	    foreach $ratei ( keys %allRates )
	    {
                next if ((!$isMultiRate) && $ratei!=$default_rate);

		foreach $j ( 0 .. $totalNodes-1 )
		{
		    foreach $pj ( 0 .. $numPowerLevel - 1)
		    {
			foreach $ratej ( keys %allRates )
			{
                            next if ((!$isMultiRate) && $ratej!=$default_rate);

			    # conflict if (i) same physical node (ii) senders carrier sense or (iii) one sender interfere with the other's receiver
			    $conflictMulti{"$i:$pi:$ratei"}{"$j:$pj:$ratej"} = 0;
			    # next if ($i == $j && $pi == $pj && $ratei == $ratej);

			    if ($i == $j)
			    {
				$conflictMulti{"$i:$pi:$ratei"}{"$j:$pj:$ratej"} = 1; #(i)
			    }
			    else
			    {
				if (distance($i, $j) < $CarrierSenseRangeMulti[$pj])
				{
				    $conflictMulti{"$i:$pi:$ratei"}{"$j:$pj:$ratej"} = 1; #(ii)
				}
				
				next if ($conflictMulti{"$i:$pi:$ratei"}{"$j:$pj:$ratej"});
				
				foreach $rvertex ( @{$neighborsMulti{"$i:$pi:$ratei"}} )
				{
				    ($r,$powerr,$rater) = split ":", $rvertex;
				    if (distance($j, $r) < $IR_multi[$pj])
				    {
					$conflictMulti{"$i:$pi:$ratei"}{"$j:$pj:$ratej"} = 1; #(iii)
                                        last;
				    }
				}
			    }
			    # print "$i,$j:", $conflictMulti{"$i:$pi:$ratei"}{"$j:$pj:$ratej"}," ";
			}
		    }
		}
		# print "\n";
	    }
	}
    }

    # output flow info.
    print conflictMultiOUT "$nflows $np \n";
    foreach $i ( 0 .. $nflows-1 )
    {
        print conflictMultiOUT $est_flow[$i],"\n";
    }
    close(conflictMultiOUT);
}

sub generate_topo
{
    my($topologyType, $nRows, $nColumns, $totalNodes) = @_;
    my($i, $j, $k);
    
    if ($topologyType > 0)
    {
        # grid topology
        $k = 0;
        for ($i = 0; $i < $nColumns; $i++)
        {
            for ($j = 0; $j < $nRows; $j++) {
                $x[$k] = $i*$dist;
                $y[$k] = $j*$dist;
                $k = $k + 1;
            }
        }
    }
    else
    {
        # random topology
        for ($i = 0; $i < $totalNodes; $i++)
        {
            my($connected);
            do {
                $connected = 0;
                $x[$i] = rand($dist*$nColumns);
                $y[$i] = rand($dist*$nRows);
                
                for ($j = 0; $j < $i; $j++)
                {
                    if (distance($i,$j) < $TR)
                    {
                        $connected = 1;
                        last;
                    }
                }
            } while ($i != 0 && !$connected);
        }
    }

    print topoFile "$totalNodes $nc $mr $default_rate $TR $IR\n";

    # Note that in LP framework nodeId starts from 0
    # whereas in qualnet nodeId starts from 1
    for (my $t = 0; $t < $totalNodes; $t++)
    {
        print topoFile $t,", $x[$t], $y[$t]\n";
	printf qualnetTopoFile "%d 0 (%d, %d, 10)\n", $t+1, $x[$t], $y[$t];
    }
}

sub distance
{
    my($i, $j) = @_;
    return(sqrt(($x[$i]-$x[$j])**2+($y[$i]-$y[$j])**2));
}

sub generate_neighbors
{
    open(neighborFile,">$neighborFile");
    foreach my $i ( 0 .. $totalNodes-1 )
    {
        print neighborFile $i+1, " ";
        foreach my $j ( 0 .. $totalNodes-1 )
        {
            next if ($i == $j);
            
            if (distance($i,$j) < $TR)
            {
                print neighborFile $j+1," ";
		$neighbor_single_rate{$i}{$j} = 1;
		$neighbor_single_rate{$j}{$i} = 1;       
            }
        }
        print neighborFile "\n";
    }
    close(neighborFile);
}

sub has_common_neighbors
{
    my($i, $j) = @_;

    foreach my $n1 ( sort {$a <=> $b} keys %{$neighbor_single_rate{$i}} )
    {
	# print "n1 = $n1\n";
	next if (exists $lossMulti{$i}{$n1}{$default_power}{$default_rate} && $lossMulti{$i}{$n1}{$default_power}{$default_rate} == 1);

	foreach my $n2 ( sort {$a <=> $b} keys %{$neighbor_single_rate{$j}} )
	{
	    # print "n2 = $n2\n";
	    next if (exists $lossMulti{$j}{$n2}{$default_power}{$default_rate} && $lossMulti{$j}{$n2}{$default_power}{$default_rate} == 1);
	    return (1) if ($n1 == $n2);
	}
    }
    return (0);
}

sub copy_topo
{
    system("mv $topoFile $topoFile.prev");
    open(topoFileIN, "<$topoFile.prev");
    open(topoFile, ">$topoFile");
    my $line = <topoFileIN>;
    print topoFile "$line";

    for( my $t = 0 ; $t < $totalNodes; $t++)
    {
	$line = <topoFileIN>;
	print topoFile "$line";
    }
    $line = <topoFileIN>;
    print topoFile "$line";
    close(topoFileIN);
}

sub enumerate_multicast_group
{
    system("mv $flowFile $flowFile.org");
    open(flowFileIN, "<$flowFile.org");
    my $curr_flow_id = 0;
    while (<flowFileIN>)
    {
        my($demand, $s, @dest_lst) = split " ", $_;
	my($numDestSet) = 2**(@dest_lst+0)-1;
	$multicastGroup{$curr_flow_id}{src} = $s;
	$multicastGroup{$curr_flow_id}{demand} = $demand;
	$multicastGroup{$curr_flow_id}{all} = join " ",@dest_lst;
	$multicastGroup{$curr_flow_id}{0} = "";

	foreach my $j ( 1 .. $numDestSet )
	{
	    my (@set) = ();
	    my ($str);
	    my(@sorted_set) = ();
	    foreach my $k ( 0 .. $#dest_lst )
	    {
		if( $j%(2**($k+1))/(2**$k) >=1 )
		{
		    push @set, $dest_lst[$k];
		}
	    }
	    @sorted_set = sort {$a <=> $b } @set;
	    $multicastGroup{$curr_flow_id}{$j} = join " ",@sorted_set;
	}
	$num_subgroup[$curr_flow_id] = $numDestSet + 1; 
	$curr_flow_id++;
    }
    close(flowFileIN);
}

sub copy_credit_weight
{
    my($filenameIN,$filenameOUT,$global_info) =@_;
    open(filenameIN,"<$filenameIN");
    printf "$filenameIN \n";
    open(filenameOUT,">$filenameOUT");
    while(<filenameIN>)
    {
	my $line = $_;
	print filenameOUT "$global_info $line";
    }

    close(filenameOUT);
    close(filenameIN);
}

sub run_our_multicast
{
    # system("../ConflictGraph-sigcomm/ConflictGraph $topoFile $conflictLinkFile bidireclink 1>/dev/null");
    # &generate_link_conflict();
    
    &enumerate_multicast_group();
    
    my $run_id = 0;

    if ($#num_subgroup == 0) # 1 flow case
    {
	my $global_info;
        
	foreach my $j ( 1 .. $num_subgroup[0] - 1){
	    copy_topo();
            $global_info = generate_traffic_multicast($run_id,1,$j);
	    system("rm -f $fwdLstFile res $lpFile $lpResultFile $matlabResultFile");
	    &run_or_routing($OUR2);
	    foreach my $s ( 1, 1.1, 1.2, 1.5 )
	    {
		my $credit_filename = "topo.credit.s$s";
		my $credit_filename2 = "topo.credit.s$s.r$run_id";
		copy_credit_weight($credit_filename,$credit_filename2,$global_info);
	    }
	    my $weight_filename = "topo.weight";
	    my $weight_filename2 = "topo.weight.r$run_id";
	    copy_credit_weight($weight_filename,$weight_filename2,$global_info);
	    $run_id++;
	}
    }elsif ($#num_subgroup == 1 ){ # 2 flow case
	my $global_info;
        
	foreach my $j ( 0 .. $num_subgroup[0] - 1){
	    foreach my $j2 ( 0 .. $num_subgroup[1] - 1){
		next if ( $j == 0 && $j2 == 0 );
		copy_topo();
		$global_info = generate_traffic_multicast($run_id,2, $j, $j2);
		system("rm -f $fwdLstFile res $lpFile $lpResultFile $matlabResultFile");
		&run_or_routing($OUR2);
		foreach my $s ( 1, 1.1, 1.2, 1.5 )
		{
		    my $credit_filename = "topo.credit.s$s";
		    my $credit_filename2 = "topo.credit.s$s.r$run_id";
		    copy_credit_weight($credit_filename,$credit_filename2,$global_info);
		}
		my $weight_filename = "topo.weight";
		my $weight_filename2 = "topo.weight.r$run_id";
		copy_credit_weight($weight_filename,$weight_filename2,$global_info);
		
		$run_id++;
	    }
	}
    }else{
	print "Let's not run more than 2 flows for now $#num_subgroup\n";
	exit(0);
    }
    &run_qualnet_OUR_multicast($OUR2,$run_id-1);
}

sub get_ack_map 
{
    my ($flow_id, $sub_group_id) = @_;
    my @ack_flag = ();
    my @all = split " ",$multicastGroup{0}{all};
    my @subgroup = split " ", $multicastGroup{0}{$sub_group_id};
    foreach my $i (0 .. $#all)
    {
	$ack_flag[$i] = 1;
    }
    foreach my $i (0 .. $#all)
    {
	foreach my $j ( 0 .. $#subgroup )
	{
	    if ($all[$i] == $subgroup[$j])
	    {
		$ack_flag[$i] = 0;
		last;
	    }
	}
    }
    my $encodedNum = 0;

    foreach my $i (0 .. $#ack_flag)
    {
	if($ack_flag[$i])
	{
	    $encodedNum += 2**($#ack_flag - $i);
	}
    }
    return $encodedNum;
}

sub generate_traffic_multicast
{
    my ($run_id,$num_flow, @sub_group_id_lst) = @_;

    my @curr_group = ();
    my $flow_ack_map = "$num_flow";
    my $encodedNum = 0;

    foreach  my $flow_id ( 0 .. $num_flow - 1)
    {
	my $sub_group_id = $sub_group_id_lst[$flow_id];
	@curr_group = split " ",$multicastGroup{$flow_id}{$sub_group_id};
        if (!@curr_group){
	    $flow[$flow_id]="0 $multicastGroup{$flow_id}{src} $multicastGroup{$flow_id}{all}"; #demand is 0
	    next;
	}
	$flow[$flow_id]="$multicastGroup{$flow_id}{demand} $multicastGroup{$flow_id}{src} $multicastGroup{$flow_id}{$sub_group_id}";
	my $encodedNum = get_ack_map($flow_id,$sub_group_id);
	$flow_ack_map="$flow_ack_map $encodedNum";
    }
    open (flowFile, ">$flowFile");
    foreach my $flow_id ( 0 .. $num_flow - 1)
    {
	print topoFile $flow[$flow_id],"\n";
	print flowFile $flow[$flow_id],"\n";
    }
    close(topoFile);
    close(flowFile);
    #system ("cp $topoFile $topoFile.r$run_id");
    system ("cp $flowFile $flowFile.r$run_id");
    return $flow_ack_map;
}

# copy $lossMulti{$i}{$j}{$default_power}{$default_rate} over to $loss{$i}{$j}
sub copy_loss_multi
{
    foreach my $i ( 0 .. $totalNodes-1 )
    {
        foreach my $j ( 0 .. $totalNodes-1 )
        {
            next if (!exists $lossMulti{$i}{$j}{$default_power}{$default_rate});
            $loss{$i}{$j} = $lossMulti{$i}{$j}{$default_power}{$default_rate};
	    if( $isBER )
	    {
		my($tx_dat) = &compute_tx_size2($transport, $mac, $payload, $default_rate , 1, 0); # isopr =1, isack = 0
		my $ber = 1- ((1-$loss{$i}{$j})**(1/$tx_dat));
		printf qualnetFaultFile "LINK-BER-FAULT 0.0.0.%d 0.001S 0 0.0.0.%d %.20f\n", $j+1, $i+1, $ber;
	    }
	    else
	    {
		printf qualnetFaultFile "LINK-FAULT 0.0.0.%d 0.001S 0 0.0.0.%d %lf\n", $j+1, $i+1, $loss{$i}{$j};
	    }
        }
    }
}

sub generate_loss_multi
{
    my($i, $j, $p, $curr_loss);
    
    if ($runType != $RANDOM_RUN)
    {
        if ($totalNodes == 2)
        {
            generate_1hop_linear(\%lossMulti, $numPowerLevel,\%allRates);
        }
        elsif ($totalNodes == 3)
        {
            generate_2hop_linear(\%lossMulti, $numPowerLevel,\%allRates);
        }
        elsif ($totalNodes == 4)
        {
            #generate_1hop_linear_multi_2power_2rate(\%lossMulti);
    
            # generate_diamond(\%lossMulti,$numPowerLevel,\%allRates);

            # generate_diamond_2rate(\%lossMulti,$numPowerLevel,\%allRates);
            
            generate_3hop_linear(\%lossMulti, $numPowerLevel,\%allRates);

            # generate_tree(\%lossMulti, $numPowerLevel,\%allRates);
        }
	elsif ($totalNodes == 6)
	{
	    generate_6node(\%lossMulti,$numPowerLevel,\%allRates);
	}
	elsif ($totalNodes == 8)
	{
	    # generate_8node(\%lossMulti,$numPowerLevel,\%allRates);
	    generate_8node_3parallel(\%lossMulti,$numPowerLevel,\%allRates);
	}
        elsif ( $totalNodes == 9 )
        {
            if ($isMulticast )
            {
                generate_9node_tree(\%lossMulti,$numPowerLevel,\%allRates);
            }
        }
    }
    
    foreach $i ( 0 .. $totalNodes-1 )
    {
        foreach $j ( 0 .. $totalNodes-1 )
        {
            next if ($i == $j);
            
            foreach $p ( 0 .. $numPowerLevel-1 )
            {
                next if (distance($i,$j) >= $TR_multi[$p]);
                my $prev_rate = 0;
                
                my @sorted_rv = &sort_rand($maxLinkLossRate,$numRate);
                #print "sorted_rv: ";
                #print (join " ", @sorted_rv);
                #print "\n";
                my $rv_index  = 0;
                foreach my $rate ( sort {$a<=>$b} (keys %allRates) )
                {
                    if (0)
                    {
                        my ($lowerbound, $upperbound);
                        
                        if ( exists $lossMulti{$i}{$j}{$p-1}{$rate} )
                        {
                            $upperbound = $lossMulti{$i}{$j}{$p-1}{$rate};
                        }
                        else
                        {
                            $upperbound = 1;
                        }
                        if ( exists $lossMulti{$i}{$j}{$p}{$prev_rate} )
                        {
                            $lowerbound = $lossMulti{$i}{$j}{$p}{$prev_rate};
                        }
                        else
                        {
                            $lowerbound = 0;
                        }

                        if ($runType == $RANDOM_RUN)
                        {
                            $lossMulti{$i}{$j}{$p}{$rate} = rand($upperbound-$lowerbound)+$lowerbound;
                        }
                    }
                    else
                    {
                        if ($runType == $RANDOM_RUN)
                        {
                            $lossMulti{$i}{$j}{$p}{$rate} = $sorted_rv[$rv_index++];
#			    printf "mikie lossmulti %d %d %d %d %.5f\n", $i, $j, $p, $rate, $lossMulti{$i}{$j}{$p}{$rate};
                        }
                    }
                    
                    # update link IDs and logical node IDs
                    $linkid{$p}{$rate}{$i}{$j} = $totalLinks_allRate++;

                    $linkid_defaultRate{$p}{$rate}{$i}{$j} = $totalLinks_defaultRate++ if ($rate == $default_rate);
                    
                    if (!exists $pnode2logical{$p}{$rate}{$i}) {
                        if ($isMultiRate)
                        {
                            $pnode2logical{$p}{$rate}{$i} = $totalLogicalNodes_allRate++;
                        }
                        else
                        {
                            $pnode2logical{$p}{$rate}{$i} = $i;
                        }
                    }

                    if ($isMultiRate || $rate == $default_rate)
                    {


                        if( $isBER )
                        {
                            my($tx_dat) = &compute_tx_size2($transport, $mac, $payload, $rate, 1 , 0); # is opr
                            my $ber = 1- ((1-$lossMulti{$i}{$j}{$p}{$rate})**(1/$tx_dat));
                            printf qualnetFaultMultiFile "LINK-BER-FAULT-MULTI 0.0.0.%d %d %d 0.001S 0 0.0.0.%d %.20f\n", $j+1, $p, $rate, $i+1, $ber;
                        }
                        else
                        {
                            printf qualnetFaultMultiFile "LINK-FAULT-MULTI 0.0.0.%d %d %d 0.001S 0 0.0.0.%d %lf\n", $j+1, $p, $rate, $i+1, $lossMulti{$i}{$j}{$p}{$rate};
                        }

                        if($measureOneHop == 0){
			    printf rawLossFileBoth "%d %d %d %.6g\n",$totalLinks_defaultRate,$i,$j,(1-(1-$lossMulti{$i}{$j}{$p}{$rate})*(1-$lossMeasure{$i}{$j}{0}{$default_rate}));
			}
                    }
                    $prev_rate = $rate;
		}
            }
        }
    }
}

sub sort_rand
{
    my($range,$n) = @_;
    my(@rv);
    foreach my $i (0 .. $n-1)
    {
        $rv[$i] = rand($range);
    }
    @rv = sort {$a<=>$b} @rv;
    return(@rv);
}

sub generate_min_interval_file
{
    printf minIntervalFile "## rate_Mbps minInterval\n";
    foreach my $rate (6, 9, 12, 18, 24, 36, 48, 54, 1, 2, 5.5, 11 ) # 802.11b rates added
    {
	my $min_interval = $payload*8/$rate*1e-6; # compute_tx_time($transport, $mac, $payload, $rate, 0, 0);
	printf minIntervalFile "%d %.15g\n", $rate, $min_interval;
    }
}

sub generate_traffic_fixed
{
    my($interval) = $min_interval*$minIntervalScaleFactor;
    my($src, @dst, $dst_str, $startTime);

    print topoFile "$nflows $np\n";

    foreach my  $flowId ( 0 .. $nflows-1 ){
	if($flowId == 0 ){
	    $src = 0;
	}elsif($flowId == 1){
	    $src = 2;
	}else{
	    print "fix generate_traffic_fixed\n";
	    exit(0);
	}
	if($flowId == 0){
	    if ($group_size == 1)
	    {
		if ($totalNodes == 2)
		{
		    @dst = (1);
		}
		elsif ($totalNodes == 3)
		{
		    @dst= (2); ## change here
		}
		elsif ($totalNodes == 4)
		{
		    @dst = (3);
		}
		elsif ($totalNodes == 6)
		{
		    @dst = (5);
		}
		else
		{
		    @dst = (7);
		}
	    }
	    elsif($group_size == 2){
		if ($totalNodes == 3) {
		    @dst =(1,2);
		}elsif($totalNodes == 4){
		    @dst =(2,3);
		}
	    }elsif($group_size ==3 ){
		if($totalNodes == 4){
		    @dst=(1,2,3);
		}
	    }
	}else{
	    if($group_size == 1){
		@dst = (3);
	    }
	}
    
	$dst_str = join " ", @dst;
	
	$flow[$flowId] = "$InfDemand $src $dst_str";
	my($error) = 1;
	if ($errorRange > 0)
	{
	    $error = (1-$errorRange) + rand($errorRange*2);
	}
	$est_flow[$flowId] = join " ", $InfDemand*$error, $src, $dst_str;
	# print $flow[$flowId],"\n";
	# print $est_flow[$flowId],"\n";
    
	print topoFile $est_flow[$flowId],"\n";
	print flowFile $est_flow[$flowId],"\n";
	$startTime = $startTimeRange*$src/$totalNodes;
	if (@dst == 1)
	{
	    printf qualnetSPPAppFile "CBR 0.0.0.%d 0.0.0.%d 0 $payload $interval $startTime 0\n",$src+1,$dst[0]+1;
	    printf qualnetORAppFile "CBR 0.0.0.%d 0.0.0.%d 0 $payload $interval $startTime 0\n",$src+1,$dst[0]+1;
	    
	}
	else
	{
	    foreach my $r ( @dst )
	    {
		printf qualnetSPPAppFile "CBR 0.0.0.%d 0.0.0.%d 0 $payload $interval $startTime 0\n",$src+1,$r+1;
	    }
            
	    # fixme: ensure consistency with Mikie's qualnet app file
	    printf qualnetORAppFile "MCBR 0.0.0.%d 0.0.255.255 0 $payload $interval $startTime 0\n",$src+1;
	    
	    printf multicastGroupFileQ "%d %d %d ", $flowId, $src+1, $group_size;
	    foreach my $r (@dst)
	    {
		printf multicastGroupFileQ "%d ", $r+1;
	    }
	    printf multicastGroupFileQ "\n";
	    
	}

	$num_antennas{$src} = $NUM_ANTENNAS_MIMO if ($source_MIMO);

        if ($dest_MIMO)
        {
            foreach my $d ( @dst )
            {
                $num_antennas{$d} = $NUM_ANTENNAS_MIMO;
            }
        }
    }
}


sub generate_traffic_fixed2
{
    my($interval) = $min_interval*$minIntervalScaleFactor;
    my($src, @dst, $dst_str, $startTime);

    print topoFile "$nflows $np\n";

    foreach my  $flowId ( 0 .. $nflows-1 ){
	if($flowId == 0 ){
	    $src = 1;
	}elsif($flowId == 1){
	    $src = 2;
	}else{
	    print "fix generate_traffic_fixed\n";
	    exit(0);
	}
	if($flowId == 0){
	    @dst = (0);
	}else{
	    @dst = (3);
	}
    
	$dst_str = join " ", @dst;
	
	$flow[$flowId] = "$InfDemand $src $dst_str";
	my($error) = 1;
	if ($errorRange > 0)
	{
	    $error = (1-$errorRange) + rand($errorRange*2);
	}
	$est_flow[$flowId] = join " ", $InfDemand*$error, $src, $dst_str;
	# print $flow[$flowId],"\n";
	# print $est_flow[$flowId],"\n";
    
	print topoFile $est_flow[$flowId],"\n";
	print flowFile $est_flow[$flowId],"\n";
	$startTime = $startTimeRange*$src/$totalNodes;
	if (@dst == 1)
	{
	    printf qualnetSPPAppFile "CBR 0.0.0.%d 0.0.0.%d 0 $payload $interval $startTime 0\n",$src+1,$dst[0]+1;
	    printf qualnetORAppFile "CBR 0.0.0.%d 0.0.0.%d 0 $payload $interval $startTime 0\n",$src+1,$dst[0]+1;
	    
	}

	$num_antennas{$src} = $NUM_ANTENNAS_MIMO if ($source_MIMO);

        if ($dest_MIMO)
        {
            foreach my $d ( @dst )
            {
                $num_antennas{$d} = $NUM_ANTENNAS_MIMO;
            }
        }
    }
}


sub generate_traffic2
{
    my(%seenFlow) = ();
    my($invalid, $flowId, $interval, $startTime);
    
    $flowId = 0;

    if ($isMulticast && !$compressShared)
    {
        print topoFile $nflows*$group_size," ",$np,"\n";
    }
    else
    {
        print topoFile "$nflows $np\n";
    }
    
    foreach my $i ( 0 .. $nflows-1 )
    {
        my($s, $r, $dist_s_r);
        my($demand);
        my(@dest_lst) = ();

        # $s = int(rand($totalNodes));
	# if ($source_MIMO)
	# {
	#     $num_antennas{$s} = $NUM_ANTENNAS_MIMO;
	# }

        foreach my $j ( 1 .. $group_size )
        {
            do {
		$s = int(rand($totalNodes));
                $r = int rand($totalNodes);

                $dist_s_r = 0;
                if ($topologyType == 1) # grid topologies
                {
                    $dist_s_r = abs($x[$s]-$x[$r])/$dist + abs($y[$s]-$y[$r])/$dist;
                }
                
		# xxx: don't pick one hop flow, subject to change
		# yichao: suggested by lili
		# if (exists $seenFlow{"$s $r"} || $s == $r || $dist_s_r > $max_hop	
		# || (distance($s, $r) < $TR && exists $lossMulti{$s}{$r}{$default_power}{$default_rate} && $lossMulti{$s}{$r}{$default_power}{$default_rate} < 1)) # &has_common_neighbors($s, $r))
		if (exists $seenFlow{"$s $r"} || $s == $r || $dist_s_r > $max_hop)
                {
                    $invalid = 1;
                }
                else
                {
                    $invalid = 0;
                    $seenFlow{"$s $r"} = 1;
                }
		# print "s=$s r=$r invalid=$invalid ",distance($s,$r)," ",$lossMulti{$s}{$r}{$default_power}{$default_rate},"\n";
            } while ($invalid);
            push @dest_lst, $r;
	    if ($source_MIMO)
	    {
		$num_antennas{$s} = $NUM_ANTENNAS_MIMO;
	    }

	    if ($dest_MIMO)
	    {
		$num_antennas{$r} = $NUM_ANTENNAS_MIMO;
	    }
        } 
	@dest_lst = sort {$a <=> $b} @dest_lst;

	print "s is $s r is $r\n";

        if ($demandMode == INF_DEMAND)
        {
            $demand = $InfDemand;
            $interval=$min_interval*$minIntervalScaleFactor;
        }
        elsif ($demandMode == RAND_DEMAND)
        {
            my($frac) = rand();
            print "fraccccccccccccccccc = $frac\n";
            $demand = $InfDemand*$frac;
            $interval=$min_interval*$minIntervalScaleFactor/$frac;
            print "$InfDemand $frac $demand $min_interval $interval\n";
        }
        else
        {
            print "Incorrect demandMode $demandMode\n";
            exit(0);
        }

        $flow[$flowId] = join " ", $demand, $s, @dest_lst;
        my($error) = 1;
        if ($errorRange > 0)
        {
            $error = (1-$errorRange) + rand($errorRange*2);
        }
        $est_flow[$flowId] = join " ", $demand*$error*(1+$overprovision), $s, @dest_lst;

        # print $flow[$flowId],"\n";
        # print $est_flow[$flowId],"\n";
        
        if ($isMulticast && !$compressShared)
        {
            foreach my $dest ( sort {$a <=> $b} @dest_lst )
            {
                print topoFile "$demand $s $dest\n";
            }
        }
        else
        {
            print topoFile $est_flow[$flowId],"\n";
        }
        
	print flowFile $est_flow[$flowId],"\n";

        $startTime = $startTimeRange*$s/$totalNodes;
        print "group_size = $group_size\t compressShared = $compressShared\n";
        
        if ($group_size == 1)
        {
            print qualnetSPPAppFile "CBR 0.0.0.", $s+1," 0.0.0.", $r+1," 0 $payload $interval $startTime 0\n";
            print qualnetORAppFile "CBR 0.0.0.", $s+1," 0.0.0.", $r+1," 0 $payload $interval $startTime 0\n";
        }
        else
        {
            # SPP supports multicast by treating it as multiple unicast
            if ($compressShared)
            {
                print qualnetSPPAppFile "MCBR 0.0.0.", $s+1," 0.0.255.255 0 $payload $interval 0 0\n";
            }
            else
            {
                foreach $r ( @dest_lst )
                {
                    print qualnetSPPAppFile "CBR 0.0.0.", $s+1," 0.0.0.", $r+1," 0 $payload $interval $startTime 0\n";
                }
            }
                
            # fixme: ensure consistency with Mikie's qualnet app 
            print qualnetORAppFile "MCBR 0.0.0.", $s+1," 0.0.255.255 0 $payload $interval $startTime 0\n";
        }
        
        printf multicastGroupFileQ "%d %d %d ", $flowId, $s+1, $group_size;
        foreach my $r ( @dest_lst )
        {
            printf multicastGroupFileQ "%d ", $r+1;
        }
        printf multicastGroupFileQ "\n";

        $flowId++;
    }
}

sub genZipfDemands {
    my($maxDemand, $alpha, $numFlows) = @_;
    my($i, @zipf_demand_lst);
    
    foreach $i ( 1 .. $numFlows )
    {
        $zipf_demand_lst[$i-1] = 10**(log10($maxDemand)-$alpha*log10($i));
        printf "%d %f\n", $i, $zipf_demand_lst[$i-1];
    }
    return(@zipf_demand_lst);
}

# MIMO related 
sub enumerate_subset
{
    my($StartPruneThresh) = 8;
    my($n) = @_;
    my @res = ();
    if ($n <= $StartPruneThresh)
    {
        @res = (1 .. (2**$n-1));
    }
    else
    {
        for (my $i = 0; $i < $n; $i++)
        {
            for (my $j = $i; $j < $n; $j++)
            {
                push @res, ((1<<$i)|(1<<$j));
            }
        }
        push @res, (2**$n-1);
    }
    # print "enumerate_subset: "; print (join " ", @res); print "\n";
    return(@res);
}

sub enumerate_composite_links_old
{                                                                              
    my($cmd) = "perl get_fwdInfo_multicast.pl $FWD_PRUNE_THRESH 0 $default_rate $lossFileBoth > /dev/null";                                                   
    print "$cmd\n";                                                            
    system($cmd);                                                              
                                                                               
    my $file;                                                                  
    my $fwd_selection = MORE_BASED_FWD_SELECTION;                              
    my %fwders = ();

    if($fwd_selection == MORE_BASED_FWD_SELECTION)                             
    {                                                                          
        $file = "debugFwdNodePruned.txt";
    }else{                                                                     
        $file = "profwd.txt";                                                  
    }                                                                          
                                                                               
    open (FI, "<$file") || die;                                                
    while (<FI>) {
        my($flow, $src, $dst, $node, $numfwd, @tfwders) = split " ", $_;       
        print "got flow: $flow src: $src dst: $dst node: $node fwders: @tfwders\n";
        $fwders{$flow}{$node} = @tfwders;                                     
    }
    close(FI);
    
    # S = subset of nodes in tfwdwers that hear from each other
    # R = subset of tfwders' fwders that all hear from S
    my(%seen_composite_link) = ();
    open(compositeLinkFile,">$compositeLinkFile");
    foreach my $f ( 0 .. $nflows-1 )
    {
        my($flow_demand, $flow_src, @flow_dest) = split " ", $flow[$f];
        my(@curr_hop) = ($flow_src);

        while ($curr_hop[0] != $flow_dest[0])
        {
            # form senders from a subset of curr_hop
            foreach my $j ( &enumerate_subset(@curr_hop + 0))
            {
                my(@sender_lst) = ();
                my(@receiver_lst) = ();
                my(@all_receivers) = ();
                my($validate) = 1;

                foreach my $k ( 0 .. $#curr_hop )
                {
                    if (($j & (1<<$k)) > 0)
                    {
			foreach my $s (@sender_lst)
			{
			    if (distance($s, $curr_hop[$k]) > $TR)
			    {
				$validate = 0;
				last;
			    }
			}
                        push @sender_lst, $curr_hop[$k] if ($validate);
                    }
                }
                
                # form receivers from subset of curr_hop's fwders
                # 1) get all fwders
                foreach my $s ( @sender_lst )
                {
                    push @all_receivers, @{$fwders{$f}{$s}};
                }
                
                permute(\@all_receivers);

                # 2) get subset from all_receivers
                foreach my $r ( &enumerate_subset(@all_receivers + 0) )
                {
                    foreach my $k ( 0 .. $#all_receivers)
                    {
                        if (($r & (1<<$k)) > 0)
                        {
                            my($validate) = 1;
                            foreach my $s ( @sender_lst )
                            {
                                if (distance($all_receivers[$k], $s) > $TR)
                                {
                                    $validate = 0;
                                    last;
                                }
                            }
                            push @receiver_lst, $all_receivers[$k] if ($validate);
                        }
                    }
                }
                my($sender_str) = join " ", (sort {$a <=> $b} @sender_lst);
                my($receiver_str) = join " ", (sort {$a <=> $b} @receiver_lst);
                if (!exists $seen_composite_link{$f}{$sender_str}{$receiver_str})
                {
                    $seen_composite_link{$f}{$sender_str}{$receiver_str} = 1;
                    my($composite_link) = "$f:$sender_str:$receiver_str";
                    # print "totalCompositeLinks = $totalCompositeLinks sender=$sender_str receiver=$receiver_str\n";
                    $composite_link[$totalCompositeLinks] = "$f:$sender_str:$receiver_str";
                    print compositeLinkFile "$f:$sender_str:$receiver_str\n";
                    $totalCompositeLinks++;
                }
            }
        }
    }
    close(compositeLinkFile);
}


# (i) all nodes in R should hear all nodes in S
# (ii) all nodes in S should hear each other for synchronization
# (iii) # antennas in S = # antennas in R
# (iv) receivers are closer to the desintation than senders
sub enumerate_composite_links
{
    my(%seen) = ();
    open(compositeLinkFile,">$compositeLinkFile");
    print "enumerate_composite_links $totalNodes\n";

    foreach my $f ( 0 .. $nflows-1 )
    {
	my($demand, $src, $dest) = split " ", $flow[$f];

	foreach my $i ( 0 .. $totalNodes-1)
	{
	    # prune nodes if too far away from dest
	    next if ($cost{$i}{$dest} > $cost{$src}{$dest}-0.01 && $i != $src);

	    my(@curr_neighbors_tmp) = (keys %{$neighbor_single_rate{$i}});
	    my(@curr_neighbors) = ();

	    foreach my $neigh ( @curr_neighbors_tmp )
	    {
		next if ($cost{$neigh}{$dest} > $cost{$src}{$dest}-0.01 && $i != $src);
		push @curr_neighbors, $neigh;
	    }

	    print "i=$i:"; print (join " ", @curr_neighbors); print "\n";

	    my(@subset) = &enumerate_subset(@curr_neighbors+0);

	    foreach my $j ( 0, @subset)  
	    {
		my(@sender_lst) = ();
		my(@complement) = ();  # complement union sender_lst = (curr_neighbors, i)
		my(%curr_senders) = ();

		# pick senders
		push @sender_lst, $i;
		$curr_senders{$i} = 1;

		foreach my $k ( 0 .. $#curr_neighbors )
		{
		    my($curr) = $curr_neighbors[$k];
		    my($validate) = 1;

		    if (($j & (1<<$k)) > 0)
		    {
			foreach my $s ( @sender_lst )
			{
			    # all senders should hear each other in order to synchornize transmissions
			    if (distance($s, $curr) > $TR || 
				$lossMulti{$s}{$curr}{$default_power}{$default_rate} > 0.99 || 
				$lossMulti{$curr}{$s}{$default_power}{$default_rate} > 0.99)
			    {
				$validate = 0;
				last;
			    }
			}
			if ($validate)
			{
			    push @sender_lst, $curr;
			    $curr_senders{$curr} = 1;
			}
			else
			{
			    push @complement, $curr;
			}
		    }
		    else
		    {
			push @complement, $curr;
		    }
		}

		next if (@sender_lst + 0 == 0 || @sender_lst > @curr_neighbors+0);
		# print "sender_lst: "; print (join " ", @sender_lst); print "\n";
 
		# pick receivers
		my(@receiver_lst) = ();
		foreach my $r ( @curr_neighbors )
		{
		    next if (exists $curr_senders{$r});
		    my($validate) = 1;
		    foreach my $s ( @sender_lst )
		    {
			# receiver should be reachable from the sender
			if (distance($r, $s) > $TR || 
			    $lossMulti{$r}{$s}{$default_power}{$default_rate} > 0.99 || 
			    $lossMulti{$s}{$r}{$default_power}{$default_rate} > 0.99 ||
			    $cost{$r}{$dest} > $cost{$s}{$dest} - 0.01)
			{
			    $validate = 0;
			}
		    }
		    push @receiver_lst, $r if ($validate);
		}

		if ( 0 ) {
		    # pick receivers
		    foreach my $j2 ( &enumerate_subset(@complement+0) )
		    {
			my(@receiver_lst) = ();
			# print "j2=$j2\n";
			foreach my $k ( 0 .. $#complement )
			{
			    my($validate) = 1;
			    my($r) = $complement[$k];
			    next if ($r == $src);
			    
			    if (($j2 & (1<<$k)) > 0)
			    {
				# print "r=$r ";
				foreach my $s ( @sender_lst )
				{
				    if (distance($r, $s) > $TR || 
					$lossMulti{$r}{$s}{$default_power}{$default_rate} > 0.99 || 
					$lossMulti{$s}{$r}{$default_power}{$default_rate} > 0.99 || 
					$cost{$r}{$dest} > $cost{$s}{$dest} - 0.001)
				    {
					# print "distance = ", distance($r,$s), " ", $lossMulti{$r}{$s}{$default_power}{$default_rate}," ", $lossMulti{$s}{$r}{$default_power}{$default_rate}," ", $cost{$r}{$dest}, " ", $cost{$s}{$dest},"\n";
					$validate = 0;
					last;
				    }
				}
				push @receiver_lst, $r if ($validate);
			    }
			}
		    }
		}
		
		next if (@receiver_lst + 0 == 0);

		my($sender_str) = join " ", (sort {$a <=> $b} @sender_lst);
		my($receiver_str) = join " ", (sort {$a <=> $b} @receiver_lst);

		my($total_sender_antennas, $total_receiver_antennas) = (0, 0);
		
		foreach my $node_i ( @sender_lst )
		{
		    if (!exists $num_antennas{$node_i})
		    {
			$total_sender_antennas ++;
		    }
		    else
		    {
			$total_sender_antennas += $num_antennas{$node_i};
		    }
		}
		
		foreach my $node_i ( @receiver_lst )
		{
		    if (!exists $num_antennas{$node_i})
		    {
			$total_receiver_antennas ++;
		    }
		    else
		    {
			$total_receiver_antennas += $num_antennas{$node_i};
		    }
		}
		
		# print "antennas: $total_sender_antennas $total_receiver_antennas\n";
		
		# cannot impose this condition since maybe the only links available are those that violate the condition 
		# next if ($total_sender_antennas > $total_receiver_antennas);
		
		# print "\nreceiver_lst: "; print (join " ", @receiver_lst); print "\n";
		
		if (!exists $seen{$f}{$sender_str}{$receiver_str})
		{
		    $seen{$f}{$sender_str}{$receiver_str} = 1;
		    my($composite_link) = "$f:$sender_str:$receiver_str";
		    # print "totalCompositeLinks=$totalCompositeLinks f=$f sender=$sender_str receiver=$receiver_str\n";
		    $composite_link[$totalCompositeLinks] = "$f:$sender_str:$receiver_str";

		    push @composite_link_single_antenna_sender, $totalCompositeLinks if ($total_sender_antennas == 1); 

		    # foreach my $i ( 0 .. $#sender_lst )
		    # {
		    #    $sender_lst[$i]++;
		    # }
		    # foreach my $i ( 0 .. $#receiver_lst )
		    # {
		    #     $receiver_lst[$i]++;
		    # }
		    # $sender_str = join " ", (sort {$a <=> $b} @sender_lst);
		    # $receiver_str = join " ", (sort {$a <=> $b} @receiver_lst);
		    print compositeLinkFile "$f:$sender_str:$receiver_str\n";
		    # foreach my $sender ( @sender_lst )
		    # {
		    #    $sender2compositeLink{$sender}{$totalCompositeLinks} = 1;
		    # }
		    # $id2compositeLink{$totalCompositeLinks}{$composite_link} = 1;
		    # $compositeLink2id{$composite_link}{$totalCompositeLinks} = 1;
		    $totalCompositeLinks++;
		}
	    }
	}
    }
    close(compositeLinkFile);
}

sub get_composite_link
{
    my($i) = @_;
    my($link) = $composite_link[$i];
    my($flow, $sender_lst_str, $receiver_lst_str) = split ":", $link;
    my(@sender_lst) = split " ", $sender_lst_str;
    my(@receiver_lst) = split " ", $receiver_lst_str;
    # print "$i: ", $composite_link[$i]; print "s="; print (join " ", @sender_lst); print "r="; print (join " ", @receiver_lst); print "\n";
    return(\@sender_lst, \@receiver_lst);
}

sub generate_conflict_composite_link
{
    # composite links ({s_i},{r_j}) interferes with ({s_i'},{r_j'})
    # iff (i) exists s_i carrier senses s_i' or vice versa
    #     (ii) exists s_i within interference range of r_j' or vice versa
    foreach my $i ( 0 .. $totalCompositeLinks-1 )
    {
        my($sender_lst1, $receiver_lst1) = get_composite_link($i);
        
        foreach my $j ( $i+1 .. $totalCompositeLinks-1 )
        {
	    $composite_link_conflict[$i][$j] = 0;
	    $composite_link_conflict[$j][$i] = 0;

            my($sender_lst2, $receiver_lst2) = get_composite_link($j);
	    # print "i=$i j=$j "; print (join " ",@$sender_lst1); print ":"; print (join " ",@$sender_lst2); print "\n";
	    
            # check (i)
            foreach my $sender1 ( @$sender_lst1 )
            {
                foreach my $sender2 ( @$sender_lst2 )
                {
		    # print "sender1=$sender1 sender2=$sender2 ";
                    if (distance($sender1, $sender2) < $CarrierSenseRange)
                    {
                        $composite_link_conflict[$i][$j] = 1;
                        $composite_link_conflict[$j][$i] = 1;
                        last;
                    }
                }
            }

	    # print "($i,$j)=",$composite_link_conflict[$i][$j]," ";
	    next if ($composite_link_conflict[$i][$j]);

            # check (ii)
            foreach my $receiver1 ( @$receiver_lst1 )
            {
                foreach my $sender2 ( @$sender_lst2 )
                {
                    if (distance($sender2, $receiver1) < $IR)
                    {
                        $composite_link_conflict[$i][$j] = 1;
                        $composite_link_conflict[$j][$i] = 1;
                        last;
                    }
                }
            }
	    # print "($i,$j)=",$composite_link_conflict[$i][$j]," ";
	    next if ($composite_link_conflict[$i][$j]);

            # check (ii)
            foreach my $receiver2 ( @$receiver_lst2 )
            {
                foreach my $sender1 ( @$sender_lst1 )
                {
                    if (distance($sender1, $receiver2) < $IR)
                    {
                        $composite_link_conflict[$i][$j] = 1;
                        $composite_link_conflict[$j][$i] = 1;
                        last;
                    }
                }
            }
	    
	    # print "($i,$j)=",$composite_link_conflict[$i][$j],"\n";
        }
	# print "\n";
    }
}
