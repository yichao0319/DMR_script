#!/user/local/bin/perl -w
# opr-final.pl -- (c) UT Austin, Lili Qiu, Tue Feb 26 2008
#   <lili@cs.utexas.edu>
#
#
########################################################

use strict;
use common;

use constant OBJ_MAX_GOODPUT  => 1;
use constant OBJ_MAX_FAIRNESS => 2;
use constant OBJ_MAX_PROP_FAIRNESS => 3;
use constant OBJ_MAX_PROP_FAIRNESS2 => 4;

use constant WiFi_MODEL => 1;
use constant CG_MODEL => 2;
use constant INFINITY => 1000000;

my $lpFile = "lp.txt";
#my $lpFile = "/var/local/erozner/OPRCoding/lp.txt";
my $lpResultFile = "lp_result.txt";
my $matlabResultFile = "matlab_result.txt";
my $TxCreditFile = "topo.credit";
my $weightFile = "topo.weight";
my $conflictMultiFile = "conflict-multi.txt";
my $indepMultiFile = "indept-multi.txt";
my $lossFile = "loss.txt";
my $trafficFile = "traffic.txt";
my $etxFile = "etx-r0-b0.txt";
my $ackRouteFile = "topo-multi.routes-ack";

# matlab files
my $f_output = "f.txt";
my $A_output = "A.txt";
my $b_output = "b.txt";
my $Aeq_output = "Aeq.txt";
my $beq_output = "beq.txt";
my $lb_output = "lb.txt";
my $ub_output = "ub.txt";
my $meta_output = "meta.txt";
my $var_file = "var.txt";
my $var_name_file = "var_name.txt";

# matlab vars
my %f;
my %A;
my %b;
my %Aeq;
my %beq;
my %LB;
my %UB;
my %FIXED;
my %var2id;
my %linkid;
my %pnode2logical;
my %cost = ();
my $num_ineq=0;
my $num_eq=0;
my $num_var=0;
my $num_lnode = 0;

# global variables
# my $MAX_FWDLST_SIZE = 5;
# proportional fairness
my @cut_points; 
my @slope;
my @width;
my $num_cut_points; 

my $max_hop = 1000;
my $nflows = 0;
my $num_link = 0;
my $num_pnode = 0;
my $num_vnode = 0;
my $num_indeptSets = 0;
my $payload = 1024;
my $min_interval;
# my $include_more_fwdlst = 1;
my $StartPruneThresh = 10;
my $PruneThresh = 2;          # skip subset with size above this and less than @neighbors 
my $lossThresh = 1;           # considered as neighbors if loss is below that
####my $fwdThresh = 0.001;        # if fwd traffic (in Mbps) is below fwdThresh, considered 0 
my $fwdThresh = 0.00001;        # if fwd traffic (in Mbps) is below fwdThresh, considered 0 
my %indept2nodeMulti = ();

my $pruneThresh = 4;
my $transport = 1;

my $gen_lp = 1;
my $use_indeptSet;
my $model;
my $header_size = 88+28+22/8;
my $beta = 1/64*$header_size/($payload+8+$header_size); # ratio of ack vs. data overhead, xxx
    
my @flow = ();
my %cap = ();
my %loss = ();
my %pairwise_loss = ();
my %loss_edge_weight = ();
my %vloss = ();
my %indept2node = ();
my %vnodeContains = ();
my %pnodeUses = ();
my %vnode2pvnode = ();
my %reaching = (); # outgoing neighbors: to support asymmetric links
my %reached = ();  # incoming neighbors 
my %pnodeIns = ();
my %allPowers = ();
my %allRates = ();
my %R_ack = ();
my %using_T_ack = ();

my $mac = $ARGV[0];
my $randSeed = $ARGV[1];
my $gamma = $ARGV[2];
my $epsilon = $ARGV[3];
my $target_power = $ARGV[4];    # -1 if we want to use all powers, o.w. only use target_power
my $target_rate = $ARGV[5];     # -1 if we want to use all rates, o.w. only use target_rate
my $process_output = $ARGV[6];
my $OBJ = $ARGV[7];
my $pruningMode = $ARGV[8];
my $isMultiRate = $ARGV[9];
my $include_ack_overhead = $ARGV[10];

if (@ARGV >= 11)
{
    $include_ack_overhead = $ARGV[10];
}
else
{
    $include_ack_overhead = 0;
}

if (@ARGV >= 12)
{
    $model = CG_MODEL;
    $use_indeptSet = 1; 
}
else
{
    $model = WiFi_MODEL;
    $use_indeptSet = 0;
}

my $preamble;
my $rate = $target_rate;
my $DIFS;

my $batch_size = 16;
my %eff = ();

$process_output = 0 if (!defined($process_output));

#print "OOOOOOOOOOOOOBJ = $OBJ\n";

if ($OBJ == OBJ_MAX_PROP_FAIRNESS)
{
    @cut_points = (0, 0.01, 0.1, sqrt(0.1), 1, sqrt(10), 10);
    @slope = (239.7895, 24.6358, 5.2930, 1.6806, 0.5321, 0.1683, 0.100);
    @width = (0.01, 0.09, 0.2162, 0.6838, 2.1623, 6.8377);
    $num_cut_points = @cut_points+0;
}
    else
{
    @cut_points = (0, 0.005, 0.0550, 0.2081, 0.6581, 2.0811, 6.5811);
    @slope = (358.3519, 44.6718, 8.6052, 2.5513, 0.8083, 0.2558, 0.1520);
    @width = (0.0050, 0.050, 0.1531, 0.45, 1.423, 4.5);
    $num_cut_points = @cut_points+0;
}

srand($randSeed);
read_loss();

my $efficiency = &cal_efficiency($batch_size);

read_traffic();
read_etx() if ($pruningMode);
read_indept_multi() if ($use_indeptSet);
read_ackroute() if ($include_ack_overhead != 0);

map_var2id();

open lpFile,">$lpFile"  or die "cannot open $lpFile for writing!\n" if ($gen_lp);
if ($OBJ == OBJ_MAX_PROP_FAIRNESS || $OBJ == OBJ_MAX_PROP_FAIRNESS2)
{
    generate_proportion_fair_obj();
}
else
{
    generate_obj();
}
#print "num_cut_points=$num_cut_points\n";
#print (join " ", @slope);
#print "\n";

print lpFile "subject to\n" if ($gen_lp);
generate_flow_conservation();
generate_flow_bound();
generate_interference_constraints() if ($use_indeptSet);
generate_bounds();
print lpFile "end\n" if ($gen_lp);
close(lpFile) if ($gen_lp);

print_matlab_lp(); 

if ($use_indeptSet) # use indeptSet always have one pass and need to process_output right after solving LP
{
    print "using cplex\n";#ejr
    system("cplex_solve.sh $lpFile $lpResultFile"); 
    &process_output();
}
elsif ($process_output)
{
    print "using matlab\n"; #ejr
    &convert_matlab_to_cplex_result();
    &process_output();
}

sub map_var2id
{
    my($str);

    $str = "alpha";
    $var2id{$str} = $num_var++;

    if ($OBJ == OBJ_MAX_PROP_FAIRNESS || $OBJ == OBJ_MAX_PROP_FAIRNESS2)
    {
        foreach my $f ( 0 .. $nflows-1 )
        {
            foreach my $i ( 0 .. $num_cut_points-1 )
            {
                $str = "R($f,$i)";
                $var2id{$str} = $num_var++;
                print "$str ",$var2id{$str},"\n";
            }
        }
    }

    foreach my $f ( 0 .. $nflows-1 )
    {
        $str = "R($f)";
        $var2id{$str} = $num_var++;
    }
    
    foreach my $f ( 0 .. $nflows-1 )
    {
        foreach my $power ( sort {$a<=>$b} keys %allPowers )
        {
            foreach my $rate ( sort {$a<=>$b} keys %allRates )
            {
                next if ($target_power != -1 && $target_power != $power);
                next if ($target_rate != -1 && $target_rate != $rate);
                
                foreach my $i ( 0 .. $num_pnode-1 )
                {
                    $str = "T($power,$rate,$f,$i)";
                    $var2id{$str} = $num_var++;
                }
            }
        }
    }

    if ($include_ack_overhead)
    {
        foreach my $f ( 0 .. $nflows-1 )
        {
            foreach my $power ( sort {$a<=>$b} keys %allPowers )
            {
                foreach my $rate ( sort {$a<=>$b} keys %allRates )
                {
                    next if ($target_power != -1 && $target_power != $power);
                    next if ($target_rate != -1 && $target_rate != $rate);

                    foreach my $i ( 0 .. $num_pnode-1 )
                    {
                        $str = "T_ack($power,$rate,$f,$i)";
                        $var2id{$str} = $num_var++;
                    }
                }
            }
        }
    }
    
    foreach my $f ( 0 .. $nflows-1 )
    {
        my($flow_demand, $flow_src, @flow_dest) = split " ", $flow[$f];

        foreach my $curr_dest ( @flow_dest )
        {
            foreach my $power ( sort {$a<=>$b} keys %allPowers )
            {
                foreach my $rate ( sort {$a<=>$b} keys %allRates )
                {
                    next if ($target_power != -1 && $target_power != $power);
                    next if ($target_rate != -1 && $target_rate != $rate);
                    
                    foreach my $i ( 0 .. $num_pnode-1 )
                    {
                        #print "$f:$curr_dest:$power:$rate:$i\n";
                        foreach my $j ( sort {$a <=> $b} keys %{$reaching{$power}{$rate}{$i}} )
                        {
                            $str = "Y($power,$rate,$f,$curr_dest,$i,$j)";
			    $var2id{$str} = $num_var++;
                        }
                    }
                }
            }
        }
    }

    if ($use_indeptSet)
    {
        foreach my $k ( 0 .. $num_indeptSets-1 )
        {
            $str = "lambda($k)";
            $var2id{$str} = $num_var++;
        }
    }
}

sub convert_matlab_to_cplex_result
{
    my @res = ();
    open(matlab_result,"$matlabResultFile");
    open(cplex_result,">$lpResultFile");
    while(<matlab_result>)
    {
        chomp;
        push @res, $_;
    }
    printf(cplex_result "Value of objective function: %.12g\n\n", $res[0]);
    printf(cplex_result "Actual values of the variables:\n");
    foreach my $str ( sort {$var2id{$a}<=>$var2id{$b}} keys %var2id )
    {
        printf(cplex_result "%s\t%.12g\n", $str, $res[$var2id{$str}+1]);
        # print "fff1: ",$str," ",$var2id{$str},"\n";
        # print "fff3: ",$res[$var2id{$str}+1],"\n";
    }
    close(matlab_result);
    close(cplex_result);
}

sub print_matlab_lp
{
    open(meta_output,">$meta_output");
    print meta_output "$num_var $num_ineq $num_eq\n";
    close(meta_output);

    open(var_name_file,"| sort -nk1 >$var_name_file");
    foreach my $str ( keys %var2id )
    {
        print var_name_file $var2id{$str}," $str\n";
    }
    close(var_name_file);
    
    # mapping from varID to src-logical-ID
    open(var_file,"| sort -nk1 >$var_file");
    # open(var_file,">$var_file");
    foreach my $power ( sort {$a<=>$b} keys %allPowers )
    {
        foreach my $rate ( sort {$a<=>$b} keys %allRates )
        {
            next if ($target_power != -1 && $target_power != $power);
            next if ($target_rate != -1 && $target_rate != $rate);
            
            foreach my $f ( 0 .. $nflows-1 )
            {
                foreach my $i ( 0 .. $num_pnode-1 )
                {
                    my($str) = "T($power,$rate,$f,$i)";
                    print var_file $var2id{$str}+1," ",$pnode2logical{$power}{$rate}{$i}+1,"\n";
                    $str = "T_ack($power,$rate,$f,$i)";
                    if (exists $var2id{$str})
                    {
                        print var_file $var2id{$str}+1," ",$pnode2logical{$power}{$rate}{$i}+1,"\n";
                    }
                }
            }
        }
    }
    close(var_file);

    # print objective
    open(f_output,">$f_output");
    foreach my $var ( sort {$a<=>$b} keys %f )
    {
        print f_output $var+1," ", $f{$var},"\n";
    }
    close(f_output);
    
    # print A
    open(A_output,">$A_output");
    foreach my $i ( 0 .. $num_ineq-1 )
    {
        foreach my $var ( sort {$a<=>$b} keys %{$A{$i}} )
        {
            print A_output $i+1," ",$var+1," ",$A{$i}{$var},"\n" if ($A{$i}{$var} != 0);
        }
    }
    close(A_output);
    
    # print b
    open(b_output,">$b_output");
    foreach my $i ( 0 .. $num_ineq-1 )
    {
        print b_output $i+1," ", $b{$i},"\n";
    }
    close(b_output);
    
    # print Aeq
    open(Aeq_output,">$Aeq_output");
    foreach my $i ( 0 .. $num_eq-1 )
    {
        foreach my $var ( sort {$a<=>$b} keys %{$Aeq{$i}} )
        {
            print Aeq_output $i+1," ",$var+1," ",$Aeq{$i}{$var},"\n" if ($Aeq{$i}{$var} != 0);
        }
    }
    close(Aeq_output);
    
    # print beq
    open(beq_output,">$beq_output");
    foreach my $i ( 0 .. $num_eq-1 )
    {
        print beq_output $i+1," ", $beq{$i},"\n";
    }
    close(beq_output);
    
    # print LB
    open(lb_output,">$lb_output");
    foreach my $i ( 0 .. $num_var-1 )
    {
        if (exists $LB{$i})
        {
            print lb_output $i+1," ",$LB{$i},"\n";
        }
        else
        {
            print lb_output $i+1," -inf\n";
        }
    }
    close(lb_output);
    
    # print UB
    open(ub_output,">$ub_output");
    foreach my $i ( 0 .. $num_var-1 )
    {
        if (exists $UB{$i})
        {
            print ub_output $i+1," ",$UB{$i},"\n";
        }
        else
        {
            print ub_output $i+1," inf\n";
        }
    }
    close(ub_output);
}

sub read_indept_multi
{
    my($line, $i);
    my(%seen) = ();

    open(indepMultiFile, "<$indepMultiFile");
    $line = <indepMultiFile>;
    while (<indepMultiFile>)
    {
        my(@lst) = split " ", $_;
        my($str) = join " ", @lst[1..$#lst];
        
        next if (exists $seen{$str});
        $seen{$str} = 1;
        
        foreach my $vertex ( @lst[2..$#lst] )
        {
            my($i, $power, $rate) = split ":", $vertex;
            # next if ($target_power != -1 && $target_power != $power);
            # next if ($target_rate != -1 && $target_rate != $rate);
            $indept2nodeMulti{$num_indeptSets}{$i}{$power}{$rate} = 1;
        }
        $num_indeptSets++;
    }
    close(indepMultiFile);
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

sub read_ackroute
{
    open(ackRouteFile,"<$ackRouteFile");
    while (<ackRouteFile>)
    {
        next if (/^\#/);
        my(@lst) = split " ", $_;
        my($flowId,$src,$dest,$hop_count) = @lst[0..3];
        my($power) = 0;
        
        foreach my $i ( 0 .. $hop_count-1 )
        {
            my($prev_hop,$next_hop,$prev_hop_addr,$next_hop_addr,$prev_hop_rate,@tmp);
            
            $prev_hop_addr = $lst[4+$i*3];
            $prev_hop_rate = $lst[4+$i*3+2];
            $next_hop_addr = $lst[4+($i+1)*3];

            @tmp = split /\./, $prev_hop_addr;
            $prev_hop = $tmp[3]-1; # convert qualnet id to the id in loss.txt 
            @tmp = split /\./, $next_hop_addr;
            $next_hop = $tmp[3]-1; # convert qualnet id to the id in loss.txt      
	    if (!exists($loss{$power}{$prev_hop_rate}{$prev_hop}{$next_hop})) {
		die "loss{$power}{$prev_hop_rate}{$prev_hop}{$next_hop}: $loss{$power}{$prev_hop_rate}{$prev_hop}{$next_hop}";
	    }
            my($denominator) = (1-$loss{$power}{$prev_hop_rate}{$prev_hop}{$next_hop})*(1-$loss{$power}{$prev_hop_rate}{$next_hop}{$prev_hop});
            
            if ($denominator > 0)
            {
                $R_ack{$power}{$prev_hop_rate}{$flowId}{$prev_hop} = 1/$denominator;
            }
            else
            {
                $R_ack{$power}{$prev_hop_rate}{$flowId}{$prev_hop} = INFINITY;
            }
        }
    }
    close(ackRouteFile);
}

sub cal_efficiency
{
   my $PRO_Header_size = 4 + $batch_size;
   my $pktsize = ($payload+20+28+22/8)+8+ $PRO_Header_size;
   my ($DIFS,$EP,$H, $efficiency, $SIFS, $preamble, $slot, $CW);
   if ($mac == 0) {
       # 802.11b                                                                                                                     
       $SIFS      = 10;
       $preamble  = 192;
       $slot      = 20;
       $CW        = 31;
   }
   else {
       # 802.11a                                                                                                                     
       $SIFS      = 16;
       $preamble  = 20;
       $slot      = 9;
       $CW        = 15;
   }


   $DIFS = 2*$slot + $SIFS;
   $EP = $payload*8/$rate;
   $H = $preamble + ($pktsize - $payload)*8/$rate;
   # should not include CW/2                                                                                                         
   return($EP/($H + $EP + $DIFS));
}



sub read_loss
{
    my($line, $skip);

    open(lossFile,"<$lossFile");

    $line = <lossFile>;
    ($num_pnode, $num_lnode, $skip) = split " ", $line;
    #print "num_pnode = $num_pnode\n";
    while (<lossFile>)
    {
        my(@lst) = split " ", $_;
        my($curr_linkId, $lnode, $src, $curr_power, $curr_rate, $dest, $curr_channel, $curr_loss) = @lst;
        
        # assign logical node id
        $pnode2logical{$curr_power}{$curr_rate}{$src} = $lnode;
        $num_lnode = ($lnode+1 > $num_lnode) ? ($lnode+1) : $num_lnode;
        
        # target_rate and target_power is used for single rate & power
        # next if ($target_power != -1 && $target_power != $curr_power);
        # next if ($target_rate != -1 && $target_rate != $curr_rate);
        
        $allPowers{$curr_power} = 1;
        $allRates{$curr_rate} = 1;
        $target_rate = $curr_rate;

        if ( $curr_loss < $lossThresh )
        {
            $reaching{$curr_power}{$curr_rate}{$src}{$dest} = 1;
            $reached{$curr_power}{$curr_rate}{$dest}{$src} = 1;
            # $neighbors{$curr_power}{$curr_rate}{$dest}{$src} = 1;
        }
        elsif (exists $reaching{$curr_power}{$curr_rate}{$src}{$dest})
        {
            undef $reaching{$curr_power}{$curr_rate}{$src}{$dest};
            undef $reached{$curr_power}{$curr_rate}{$dest}{$src};
            # undef $neighbors{$curr_power}{$curr_rate}{$dest}{$src};
        }
        $loss{$curr_power}{$curr_rate}{$src}{$dest} = $curr_loss;
        
        # assign linkid
        $linkid{$lnode}{$dest} = $curr_linkId;
    }
    close(lossFile);
    
    #initialize losses that aren't here //ejr
    foreach my $i (0 .. $num_pnode-1) {
        foreach my $j (0 .. $num_pnode-1) {
            foreach my $power ( sort {$a <=> $b} keys %allPowers ) {
                foreach my $rate ( sort {$a <=> $b} keys %allRates ) {
                    next if ($target_power != -1 && $target_power != $power);
                    next if ($target_rate != -1 && $target_rate != $rate);

                    if (!exists($loss{$power}{$rate}{$i}{$j})) {
                        #$loss{$power}{$rate}{$i}{$j} = 0;
                        $loss{$power}{$rate}{$i}{$j} = 1;
                        if (exists $reaching{$power}{$rate}{$i}{$j})
                        {
                            undef $reaching{$power}{$rate}{$i}{$j};
                            undef $reached{$power}{$rate}{$j}{$i};
                            # undef $neighbors{$power}{$rate}{$j}{$i};
                        }
                    }
                }
            }
        }
    }
    if(0){
    foreach my $rate_m (keys %allRates)
    {
	print "mikie rate_m $rate_m\n";
    }

    foreach my $power_m (keys %allPowers)
    {
	print "mikie power_m $power_m\n";
    }
    #exit(0);
    }
}

sub read_traffic
{
    open(trafficFile,"<$trafficFile");
    while (<trafficFile>)
    {
        my(@lst) = split " ", $_;
        $flow[$nflows++] = join " ", @lst;
    }
    close(trafficFile);
}

sub generate_obj
{
    my($total_demand) = 0;
    my($str);
    
    print lpFile "maximize " if ($gen_lp);
    
    # maximize total throughput across all flows
    foreach my $f ( 0 .. $nflows-1 )
    {
        my(@lst) = split " ", $flow[$f];
        my($flow_demand) = $lst[0];
        $total_demand += $flow_demand;
        print lpFile "+ R($f)" if ($gen_lp);

        # matlab only minimizes obj
        $str = "R($f)";
        $f{$var2id{$str}} -= 1;
    }

    # gamma * alpha * total_demand
    if ($gamma > 0)
    {
        printf lpFile "+%.9f alpha ", $total_demand * $gamma if ($gen_lp);
        $str = "alpha";
        $f{$var2id{$str}} -= $total_demand*$gamma;
    }
    

   if (1) {
	#
        #ejr-- want to add objective to minimize useless transmissions
	#
	#printf lpFile "+%.9f T(%d,%.1f,%d,%d) ", 1/$rate, $power, $rate, $f, $i if ($gen_lp);
	#$str = "T($power,$rate,$f,$i)";
	my $T_weight = 0.001;
	
	foreach my $i ( 0 .. $num_pnode-1 )
	{
	    foreach my $power ( keys %allPowers )
	    {
		foreach my $rate ( keys %allRates )
		{
		    next if ($target_power != -1 && $target_power != $power);
		    next if ($target_rate != -1 && $target_rate != $rate);

		    foreach my $f ( 0 .. $nflows-1 )
		    {

			$str = "T($power,$rate,$f,$i)";
			printf lpFile "-%.9f T(%d,%d,%d,%d) ",$T_weight,$power,$rate,$f, $i; 
			$f{$var2id{$str}} = $T_weight;
		    }
		}
	    }
	}
    }

    print lpFile "\n" if ($gen_lp);
}

sub generate_proportion_fair_obj
{
    my($total_demand) = 0;
    my($str);

    print lpFile "maximize " if ($gen_lp);

    # maximize total throughput across all flows
    foreach my $f ( 0 .. $nflows-1 )
    {
        foreach my $i ( 0 .. $num_cut_points-1 )
        {
            my($curr_slope) = $slope[$i];
            print lpFile "+ $curr_slope R($f,$i)" if ($gen_lp);
        
            # matlab only minimizes obj
            $str = "R($f,$i)";
            $f{$var2id{$str}} -= $curr_slope;
        }
    }
    
    print lpFile "\n" if ($gen_lp);
}

sub generate_flow_conservation
{
    my($str);

    # T_ack(power,rate,flow,nodeId) = alpha * R(flow) * ETX
    if ($include_ack_overhead)
    {
        foreach my $f ( 0 .. $nflows-1 )
        {
            foreach my $power ( sort {$a<=>$b} keys %allPowers )
            {
                foreach my $rate ( sort {$a<=>$b} keys %allRates )
                {
                    next if ($target_power != -1 && $target_power != $power);
                    next if ($target_rate != -1 && $target_rate != $rate);
                    
                    foreach my $i ( 0 .. $num_pnode-1 )
                    {
                        next if (!exists $R_ack{$power}{$rate}{$f}{$i});
                        $using_T_ack{$power}{$rate}{$f}{$i} = 1;
                        printf lpFile "T_ack(%d,%d,%d,%d) - %.9f R(%d) = 0;\n", $power, $rate, $f, $i, $beta*$R_ack{$power}{$rate}{$f}{$i}, $f if ($gen_lp);

                        $str = "T_ack($power,$rate,$f,$i)";
                        $Aeq{$num_eq}{$var2id{$str}} = 1;
                        $str = "R($f)";
                        $Aeq{$num_eq}{$var2id{$str}} = - $beta * $R_ack{$power}{$rate}{$f}{$i}; 
                        $beq{$num_eq} = 0;
                        $num_eq ++;
                    }
                }
            }
        }

        foreach my $f ( 0 .. $nflows-1 )
        {
            foreach my $power ( sort {$a<=>$b} keys %allPowers )
            {
                foreach my $rate ( sort {$a<=>$b} keys %allRates )
                {
                    foreach my $i ( 0 .. $num_pnode-1 )
                    {
                        next if (exists $using_T_ack{$power}{$rate}{$f}{$i});
                        printf lpFile "T_ack($power,$rate,$f,$i) = 0\n" if ($gen_lp);
                        $str = "T_ack($power,$rate,$f,$i)";
                        $FIXED{$str} = 0;
                    }
                }
            }
        }
    }
        
    # Y(power,rate,f,d,k,src(f)) = 0
    foreach my $power ( keys %allPowers )
    {
        foreach my $rate ( keys %allRates )
        {
            next if ($target_power != -1 && $target_power != $power);
            next if ($target_rate != -1 && $target_rate != $rate);
            
            foreach my $f ( 0 .. $nflows-1 )
            {
                my($flow_demand, $flow_src, @flow_dest) = split " ", $flow[$f];
                
                foreach my $curr_dest ( @flow_dest )
                {
                    foreach my $k ( keys %{$reached{$power}{$rate}{$flow_src}} )
                    {
			#ejr- testbed may not have all entries!
			#next if (!(exists($neighbors{$power}{$rate}{$k}{$flow_src})));

                        print lpFile "Y($power,$rate,$f,$curr_dest,$k,$flow_src) = 0\n" if ($gen_lp);
                            
                        $str = "Y($power,$rate,$f,$curr_dest,$k,$flow_src)";
                        $FIXED{$str} = 0;
                    }
                }
            }
        }
    }

    # Y(power,rate,f,d,dest(f,d),k) = 0 for any (f,d)
    foreach my $power ( keys %allPowers )
    {
        foreach my $rate ( keys %allRates )
        {
            next if ($target_power != -1 && $target_power != $power);
            next if ($target_rate != -1 && $target_rate != $rate);

            foreach my $f ( 0 .. $nflows-1 )
            {
                my($flow_demand, $flow_src, @flow_dest) = split " ", $flow[$f];
                
                foreach my $curr_dest ( @flow_dest )
                {
                    foreach my $k ( keys %{$reaching{$power}{$rate}{$curr_dest}} )
                    {
                        print lpFile "Y($power,$rate,$f,$curr_dest,$curr_dest,$k) = 0\n" if ($gen_lp);
                        
                        $str = "Y($power,$rate,$f,$curr_dest,$curr_dest,$k)";
                        $FIXED{$str} = 0;
                    }
                }
            }
        }
    }

    # sum_{power,rate,k} Y_{power,rate,f,d,k,i} >= sum_{power,rate,k} Y_{power,rate,f,d,i,k}
    foreach my $f ( 0 .. $nflows-1 )
    {
        my($flow_demand, $flow_src, @flow_dest) = split " ", $flow[$f];
        
        foreach my $curr_dest ( @flow_dest )
        {
            foreach my $i ( 0 .. $num_pnode-1 )
            {
                next if ($flow_src == $i);
                next if ($curr_dest == $i);

                foreach my $power ( keys %allPowers )
                {
                    foreach my $rate ( keys %allRates )
                    {
                        next if ($target_power != -1 && $target_power != $power);
                        next if ($target_rate != -1 && $target_rate != $rate);

                        # incoming traffic
                        foreach my $k ( keys %{$reached{$power}{$rate}{$i}} )
                        {
                            if ($gen_lp)
                            {
                                print lpFile "+ Y($power,$rate,$f,$curr_dest,$k,$i) ";
                            }

                            $str = "Y($power,$rate,$f,$curr_dest,$k,$i)";
                            $A{$num_ineq}{$var2id{$str}} = -1;
                        }

                        # outgoing traffic
                        foreach my $k ( keys %{$reaching{$power}{$rate}{$i}} )
                        {
                            if ($gen_lp)
                            {
                                print lpFile "- Y($power,$rate,$f,$curr_dest,$i,$k) ";
                            }
                            
                            $str = "Y($power,$rate,$f,$curr_dest,$i,$k)";
                            $A{$num_ineq}{$var2id{$str}} = 1;
                        }
                    }
                }
                print lpFile ">= 0\n" if ($gen_lp);
                $b{$num_ineq} = 0;
                $num_ineq++;
            }
        }
    }

    # for each subset of i's neighbors (or forwarding list) NS(i)
    # T_{power,rate,f,i} S_{power,rate,i,NS(i)} - sum_{k \in NS(i)} Y_{power,rate,f,d,i,k} >= 0
    foreach my $f ( 0 .. $nflows-1 )
    {
        my($flow_demand, $flow_src, @flow_dest) = split " ", $flow[$f];
        
        foreach my $curr_dest ( @flow_dest )
        {
            foreach my $power ( keys %allPowers )
            {
                foreach my $rate ( keys %allRates )
                {
                    next if ($target_power != -1 && $target_power != $power);
                    next if ($target_rate != -1 && $target_rate != $rate);
            
                    foreach my $i ( 0 .. $num_pnode-1 )
                    {
                        my(@curr_neighbors)  = (keys %{$reaching{$power}{$rate}{$i}});
                        if ($pruningMode == 1)
                        {
                            @curr_neighbors = &pruning1($power,$rate,$f,$curr_dest,$i,@curr_neighbors);
                        }
                        elsif ($pruningMode == 2 && @curr_neighbors > $pruneThresh)
                        {
                                @curr_neighbors = &pruning2($power,$rate,$f,$curr_dest,$i,@curr_neighbors);
                        }
                        elsif ($pruningMode == 3 && @curr_neighbors > $pruneThresh)
                        {
                                @curr_neighbors = &pruning3($power,$rate,$f,$curr_dest,$i,@curr_neighbors);
                        }

                        #print "reaching: ";
                        #print (join " ", keys %{$reaching{$power}{$rate}{$i}});
                        #print "\n";
                        
                        #print "curr_neighbors: ";
                        #print (join " ", @curr_neighbors);
                        #print "\n";
                        
                        my($numFwdLists) = 2**(@curr_neighbors+0)-1;
                
                        # print "numFwdLists = $numFwdLists\n";
                        
                        next if (@curr_neighbors == 0);
                
                        foreach my $j ( &enumerate_subset(@curr_neighbors+0) )
                        {
                            my $vloss = 1;
                            foreach my $k ( 0 .. $#curr_neighbors )
                            {
                                if (($j & (1<<$k)) > 0)
                                {
                                    $vloss *= $loss{$power}{$rate}{$i}{$curr_neighbors[$k]};
                                }
                            }

                            printf lpFile "+%.9f T(%d,%d,%d,%d) ",(1-$vloss),$power,$rate,$f,$i if ($gen_lp);
                            $str = "T($power,$rate,$f,$i)";
                            $A{$num_ineq}{$var2id{$str}} = -(1-$vloss);
                            
                            foreach my $k ( 0 .. $#curr_neighbors )
                            {
                                if (($j & (1<<$k)) > 0)
                                {
                                    my($curr_neigh) = $curr_neighbors[$k];
                                    
                                    print lpFile "- Y($power,$rate,$f,$curr_dest,$i,$curr_neigh) " if ($gen_lp);
                                    
                                    $str = "Y($power,$rate,$f,$curr_dest,$i,$curr_neigh)";
                                    $A{$num_ineq}{$var2id{$str}} = 1;
                                }
                            }
                            
                            print lpFile ">= 0\n" if ($gen_lp);
                            $b{$num_ineq} = 0;
                            $num_ineq++;
                        }
                    }
                }
            }
        }
    }
}

sub pruning1
{
    my($power,$rate,$f,$flow_dest,$i,@curr_neighbors) = @_;
    my(@pruned_lst) = ();

    #print "Before pruning $i: ";
    #print (join " ", @curr_neighbors);
    #print "\n";
    
    foreach my $neighbor ( @curr_neighbors )
    {
        if ($cost{$neighbor}{$flow_dest} < $cost{$i}{$flow_dest})
        {
            push @pruned_lst, $neighbor;
        }
        else
        {
            print lpFile "Y($power,$rate,$f,$flow_dest,$i,$neighbor) = 0\n" if ($gen_lp);
            my($str) = "Y($power,$rate,$f,$flow_dest,$i,$neighbor)";
            $FIXED{$str} = 0;
        }
    }

    #print "After pruning $i: ";
    #print (join " ", @pruned_lst);
    #print "\n";
    
    return(@pruned_lst);
}

sub pruning2
{
    my($power,$rate,$f,$flow_dest,$i,@curr_neighbors) = @_;
    my(@sorted_curr_neighbors) = sort {$cost{$a}{$flow_dest} <=> $cost{$b}{$flow_dest}} ( @curr_neighbors);
    
    foreach my $neighbor ( @sorted_curr_neighbors[$pruneThresh..$#sorted_curr_neighbors] )
    {
        print lpFile "Y($power,$rate,$f,$flow_dest,$i,$neighbor) = 0\n" if ($gen_lp);
        my($str) = "Y($power,$rate,$f,$flow_dest,$i,$neighbor)";
        $FIXED{$str} = 0;
    }
    
    return(@sorted_curr_neighbors[0..$pruneThresh-1]);
}

sub pruning3
{
    my($power,$rate,$f,$flow_dest,$i,@curr_neighbors) = @_;
    my(@sorted_curr_neighbors) = sort {$cost{$a}{$flow_dest} <=> $cost{$b}{$flow_dest}} ( @curr_neighbors);

    if ($cost{$sorted_curr_neighbors[$pruneThresh]}{$flow_dest} <= $cost{$i}{$flow_dest})
    {
        return(&pruning1($power,$rate,$f,$flow_dest,$i,@sorted_curr_neighbors));
    }
    else
    {
        return(&pruning2($power,$rate,$f,$flow_dest,$i,@sorted_curr_neighbors));
    }
}

sub enumerate_subset
{
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
    return(@res);
}

sub enumerate_subset_old
{
    my(%subsets, $ij);
    my($n) = @_;
    my $fullset = (2**$n-1);
    my @res = ();
    if ($n <= $StartPruneThresh)
    {
        @res = (1 .. $fullset);
    }
    else
    {
        my $NumSubsetPerNode = (1<<$StartPruneThresh);
        my %subsets = ();
        $subsets{$fullset} = 1;
        my $i = 0;
        while ($i < $NumSubsetPerNode)
        {
            my $ss = 1 + int(rand()*$fullset);
            next if exists $subsets{$ss};
            $subsets{$ss} = 1;
            $i++;
        }
        @res = keys(%subsets);
    }

    return(@res);
}

sub generate_interference_constraints
{
    my($str);
    
    # \sum_{f} T_{f,i} - \sum_{i \in I_k} \lambda_k cap_i <= 0
    foreach my $i ( 0 .. $num_pnode-1 )
    {
        foreach my $power ( keys %allPowers )
        {
            foreach my $rate ( keys %allRates )
            {
                next if ($target_power != -1 && $target_power != $power);
                next if ($target_rate != -1 && $target_rate != $rate);

                foreach my $f ( 0 .. $nflows-1 )
                {
                    printf lpFile "+%.9f T(%d,%d,%d,%d) ", 1/($rate*$efficiency), $power, $rate, $f, $i if ($gen_lp);
                    $str = "T($power,$rate,$f,$i)";
                    $A{$num_ineq}{$var2id{$str}} = 1/($rate*$efficiency);
                }
            
                foreach my $k ( 0 .. $num_indeptSets-1 )
                {
                    next if (!exists $indept2nodeMulti{$k}{$i}{$power}{$rate});
                    printf lpFile "- lambda(%d) ", $k if ($gen_lp);
                    $str = "lambda($k)";
                    $A{$num_ineq}{$var2id{$str}} = -1;
                }

                printf lpFile "<=0\n" if ($gen_lp);
                $b{$num_ineq} = 0;
                $num_ineq++;
            }
        }
    }
    
    # sum_{k} \lambda_k <= 1
    foreach my $k ( 0 .. $num_indeptSets-1 )
    {
        print lpFile "+ lambda($k) " if ($gen_lp);

        $str = "lambda($k)";
        $A{$num_ineq}{$var2id{$str}} = 1;
    }
    
    printf lpFile "<=1\n" if ($gen_lp);
    $b{$num_ineq} = 1;
    $num_ineq++;
}

sub generate_flow_bound
{
    my($str);
    
    # generate upperbound: throughput <= demand
    foreach my $f ( 0 .. $nflows-1 )
    {
        my($flow_demand, $flow_src, @flow_dest) = split " ", $flow[$f];

        foreach my $curr_dest ( @flow_dest )
        {
            foreach my $i ( 0 .. $num_pnode-1 )
            {
                foreach my $power ( keys %allPowers )
                {
                    foreach my $rate ( keys %allRates )
                    {
                        next if ($target_power != -1 && $target_power != $power);
                        next if ($target_rate != -1 && $target_rate != $rate);
                        
                        foreach my $k ( keys %{$reaching{$power}{$rate}{$i}} )
                        {
                            next if ($k != $curr_dest);
                            print lpFile "+ Y($power,$rate,$f,$curr_dest,$i,$curr_dest) " if ($gen_lp);
                            $str = "Y($power,$rate,$f,$curr_dest,$i,$curr_dest)";
                            $A{$num_ineq}{$var2id{$str}} = 1;
                        }
                    }
                }
            }
            print lpFile "<= $flow_demand\n" if ($gen_lp);
            $b{$num_ineq} = $flow_demand;
            $num_ineq++;
        }
    }


    # throughput >= R(f)
    foreach my $f ( 0 .. $nflows-1 )
    {
        my($flow_demand, $flow_src, @flow_dest) = split " ", $flow[$f];

        foreach my $curr_dest ( @flow_dest )
        {
            foreach my $i ( 0 .. $num_pnode-1 )
            {
                foreach my $power ( keys %allPowers )
                {
                    foreach my $rate ( keys %allRates )
                    {
                        next if ($target_power != -1 && $target_power != $power);
                        next if ($target_rate != -1 && $target_rate != $rate);
                        
                        foreach my $k ( keys %{$reaching{$power}{$rate}{$i}} )
                        {
                            next if ($k != $curr_dest);
                            print lpFile "+ Y($power,$rate,$f,$curr_dest,$i,$curr_dest) " if ($gen_lp);
                            $str = "Y($power,$rate,$f,$curr_dest,$i,$curr_dest)";
                            $A{$num_ineq}{$var2id{$str}} = -1;
                        }
                    }
                }
            }
            print lpFile "- R($f) >= 0\n" if ($gen_lp);

            $str = "R($f)";
            $A{$num_ineq}{$var2id{$str}} = 1;
            $b{$num_ineq} = 0;
            $num_ineq++;
        }
    }

    # throughput >= demand*alpha
    if ($gamma > 0)
    {
        foreach my $f ( 0 .. $nflows-1 )
        {
            my($flow_demand, $flow_src, @flow_dest) = split " ", $flow[$f];
            
            foreach my $curr_dest ( @flow_dest )
            {
                foreach my $i ( 0 .. $num_pnode-1 )
                {
                    foreach my $power ( keys %allPowers )
                    {
                        foreach my $rate ( keys %allRates )
                        {
                            next if ($target_power != -1 && $target_power != $power);
                            next if ($target_rate != -1 && $target_rate != $rate);

                            foreach my $k ( keys %{$reaching{$power}{$rate}{$i}} )
                            {
                                next if ($k != $curr_dest);
                                print lpFile "+ Y($power,$rate,$f,$curr_dest,$i,$curr_dest) " if ($gen_lp);
                                
                                $str = "Y($power,$rate,$f,$curr_dest,$i,$curr_dest)"; 
                                
                                $A{$num_ineq}{$var2id{$str}} = -1;
                            }
                        }
                    }
                }
                printf lpFile "-%.9f alpha >= 0\n", $flow_demand if ($gen_lp);
                $str = "alpha";
                $A{$num_ineq}{$var2id{$str}} = $flow_demand;
                $b{$num_ineq} = 0;
                $num_ineq++;
            }
        }
    }
    
    # throughput >= epsilon
    if ($epsilon > 0)
    {
        foreach my $f ( 0 .. $nflows-1 )
        {
            my($flow_demand, $flow_src, @flow_dest) = split " ", $flow[$f];
            
            foreach my $curr_dest ( @flow_dest )
            {
                foreach my $i ( 0 .. $num_pnode-1)
                {
                    foreach my $power ( keys %allPowers )
                    {
                        foreach my $rate ( keys %allRates )
                        {
                            next if ($target_power != -1 && $target_power != $power);
                            next if ($target_rate != -1 && $target_rate != $rate);

                            foreach my $k ( keys %{$reaching{$power}{$rate}{$i}} )
                            {
                                next if ($k != $curr_dest);
                                print lpFile "+ Y($power,$rate,$f,$curr_dest,$i,$curr_dest) " if ($gen_lp);

                                $str = "Y($power,$rate,$f,$curr_dest,$i,$curr_dest)";
                                $A{$num_ineq}{$var2id{$str}} = -1;
                                
                            }
                        }
                    }
                }
                print lpFile ">= $epsilon\n" if ($gen_lp);
                $b{$num_ineq} = -$epsilon;
                $num_ineq++;
            }
        }
    }

    if ($OBJ == OBJ_MAX_PROP_FAIRNESS || $OBJ == OBJ_MAX_PROP_FAIRNESS2)
    {
        foreach my $f ( 0 .. $nflows-1 )
        {
            print lpFile "R($f) " if ($gen_lp);
            $str = "R($f)";
            $Aeq{$num_eq}{$var2id{$str}} = 1; 
            foreach my $i ( 0 .. $num_cut_points-1 )
            {
                print lpFile " - R($f,$i) " if ($gen_lp);
                $Aeq{$num_eq}{$var2id{"R($f,$i)"}} = -1;
            }
            print lpFile " = 0\n" if ($gen_lp);
            $beq{$num_eq} = 0;
            $num_eq++;
        }
    }
}

sub generate_bounds
{
    my($str);
    
    printf lpFile "bounds\n" if ($gen_lp);

    if ($OBJ == OBJ_MAX_PROP_FAIRNESS || $OBJ == OBJ_MAX_PROP_FAIRNESS2)
    {
        foreach my $f ( 0 .. $nflows-1 )
        {
            my($i);
            
            foreach $i ( 0 .. $num_cut_points-2 )
            {
                printf lpFile "0 <= R(%d,%d) <= %.6f\n", $f, $i, $width[$i] if ($gen_lp);
                $str = "R($f,$i)";
                $LB{$var2id{$str}} = 0;
                $UB{$var2id{$str}} = $width[$i];
            }

            $i = $num_cut_points-1;
            printf lpFile "0 <= R(%d,%d)\n", $f, $i if ($gen_lp);
            $str = "R($f,$i)";
            $LB{$var2id{$str}} = 0;
        }
    }
    
    # Y(power,rate,f,d,i,j) >= 0
    foreach my $power ( keys %allPowers )
    {
        foreach my $rate ( keys %allRates )
        {
            next if ($target_power != -1 && $target_power != $power);
            next if ($target_rate != -1 && $target_rate != $rate);
            my $Ymax = $rate*$efficiency;
    
            foreach my $f ( 0 .. $nflows-1 )
            {
                my($flow_demand,$flow_src,@flow_dest) = split " ", $flow[$f];

                foreach my $curr_dest ( @flow_dest )
                {
                    foreach my $i ( 0 .. $num_pnode-1 )
                    {
                        foreach my $j ( keys %{$reaching{$power}{$rate}{$i}} )
                        {
                            print lpFile "0 <= Y($power,$rate,$f,$curr_dest,$i,$j) <= $Ymax\n" if ($gen_lp);
                            $str = "Y($power,$rate,$f,$curr_dest,$i,$j)";
                            $LB{$var2id{$str}} = 0;
                            $UB{$var2id{$str}} = $Ymax;
                        }
                    }
                }
            }
        }
    }
    
    # T(power,rate,f,i) > =0
    foreach my $power ( keys %allPowers )
    {
        foreach my $rate ( keys %allRates )
        {
            next if ($target_power != -1 && $target_power != $power);
            next if ($target_rate != -1 && $target_rate != $rate);
            my $Tmax = $rate*$efficiency;
    
            foreach my $f ( 0 .. $nflows-1 )
            {
                foreach my $i ( 0 .. $num_pnode-1 )
                {
                    print lpFile "0 <= T($power,$rate,$f,$i) <= $Tmax\n" if ($gen_lp);
                    $str = "T($power,$rate,$f,$i)";
                    $LB{$var2id{$str}} = 0;
                    $UB{$var2id{$str}} = $Tmax;
                }
            }
        }
    }

    # T_ack(power,rate,f,i) > =0
    if ($include_ack_overhead)
    {
        foreach my $power ( keys %allPowers )
        {
            foreach my $rate ( keys %allRates )
            {
                next if ($target_power != -1 && $target_power != $power);
                next if ($target_rate != -1 && $target_rate != $rate);
                
                foreach my $f ( 0 .. $nflows-1 )
                {
                    foreach my $i ( 0 .. $num_pnode-1 )
                    {
                        print lpFile "T_ack($power,$rate,$f,$i) >= 0\n" if ($gen_lp);
                        $str = "T_ack($power,$rate,$f,$i)";
                        $LB{$var2id{$str}} = 0;
                    }
                }
            }
        }
    }

    # lambda \in [0 .. 1]
    if ($use_indeptSet)
    {
        foreach my $k ( 0 .. $num_indeptSets-1 )
        {
            print lpFile "0 <= lambda($k) <= 1\n" if ($gen_lp);
            $str = "lambda($k)";
            $LB{$var2id{$str}} = 0;
            $UB{$var2id{$str}} = 1;
        }
    }

    # alpha >= 0
    print lpFile "alpha >= 0\n" if ($gen_lp);
    $str = "alpha";
    $LB{$var2id{$str}} = 0;
    
    # reset bounds for fixed variables
    foreach $str (keys %FIXED)
    {
        $LB{$var2id{$str}} = $FIXED{$str};
        $UB{$var2id{$str}} = $FIXED{$str};
    }
}

sub process_output
{
    my(%T,%R,%Y,%max_info,%total_max_info);
    my($total_goodput, @goodput);

    %T = ();
    %R = ();
    %Y = ();
    %max_info = ();
    %total_max_info = ();

    $total_goodput = 0;
    
    # get T(power,rate,f,i) and R(f,i)
    open(lpResultFile,"<$lpResultFile");
    while (<lpResultFile>)
    {
        if (/^T_ack/)
        {
            next;
        }
        elsif (/^T/)
        {
            my($var, $value) = split " ", $_;
            $var =~ /T\((\d+),(\d+),(\d+),(\d+)\)/;
            my($power,$rate,$f,$i) = ($1,$2,$3,$4);

	    #get rate to correct output -- ejr
	    foreach my $trate ( keys %allRates ) {
		$rate = $trate if ($trate == $rate);
	    }

            #ejr
	    #open (FF, ">>myfile");
	    #print FF "power: $power rate: $rate f: $f i: $i\n";
	    #close FF;

            $T{$power}{$rate}{$f}{$i} = $value;

            foreach my $k ( keys %{$reaching{$power}{$rate}{$i}} )
            {
                $R{$f}{$k} += $value*(1-$loss{$power}{$rate}{$i}{$k});
            }
        }
        elsif (/^Y/)
        {
            my($var, $value) = split " ", $_;
            $var =~ /Y\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)/;
            my($power,$rate,$f,$d,$i,$j) = ($1,$2,$3,$4,$5,$6);
            $Y{$power}{$rate}{$f}{$d}{$i}{$j} = $value;
            # max info on each edge over all destination for the multicast flow
            $max_info{$power}{$rate}{$f}{$i}{$j} = $Y{$power}{$rate}{$f}{$d}{$i}{$j} if (!exists $max_info{$power}{$rate}{$f}{$i}{$j} || $max_info{$power}{$rate}{$f}{$i}{$j} < $Y{$power}{$rate}{$f}{$d}{$i}{$j});
#            printf "new max info: $power,$rate,$f,$i,$j => %f\n", $max_info{$power}{$rate}{$f}{$i}{$j}; 
        }
        elsif (/^R/)
        {
            next if (/,/);
            my($var, $value) = split " ", $_;
            $var =~ /R\((\d+)/;
            my($flowid) = ($1);
            $goodput[$flowid] = $value;
            $total_goodput += $value;
        }
    }
    close(lpResultFile);

    foreach my $power ( keys %allPowers )
    {
        foreach my $rate ( keys %allRates )
        {

            next if ($target_power != -1 && $target_power != $power);
            next if ($target_rate != -1 && $target_rate != $rate);

            foreach my $f ( 0 .. $nflows-1 )
            {
                foreach my $i ( 0 .. $num_pnode-1 )
                {
                    foreach my $j ( keys %{$reaching{$power}{$rate}{$i}} )
                    {

                        $total_max_info{$f}{$j} += $max_info{$power}{$rate}{$f}{$i}{$j};
                    }
                }
            }
        }
    }

    # print weightFile: <flowId> <srcId> <power> <rate> <destId> <weight>
    open(weightFile,">$weightFile");
    foreach my $f ( 0 .. $nflows-1 )
    {
        my($flow_demand,$flow_src,@flow_dest) = split " ", $flow[$f];
        
        foreach my $i ( 0 .. $num_pnode-1 )
        {
            foreach my $power ( sort {$a <=> $b} keys %allPowers )
            {
                foreach my $rate ( sort {$a <=> $b} keys %allRates )
                {
                    next if ($target_power != -1 && $target_power != $power);
                    next if ($target_rate != -1 && $target_rate != $rate);

                    foreach my $j ( keys %{$reaching{$power}{$rate}{$i}} )
                    {
                        my($recv) = $T{$power}{$rate}{$f}{$i}*(1-$loss{$power}{$rate}{$i}{$j});
                        if ($recv > 0)
                        {
                            printf weightFile "%d %d %d %d %d %.9g\n", $f, $power, $rate, $i+1, $j+1, $max_info{$power}{$rate}{$f}{$i}{$j}/$recv;
                        }
                        else
                        {
                            printf weightFile "%d %d %d %d %d %.9g\n", $f, $power, $rate, $i+1, $j+1, 0;
                        }
                    }
                }
            }
        }
    }
    close(weightFile);
    
    # output credit file
    foreach my $scale ( 1 , 1.1, 1.2, 1.5 )
    {
        open(TxCreditFile,">$TxCreditFile.s$scale");
        foreach my $i ( 0 .. $num_pnode-1 )
        {
            foreach my $power ( sort {$a <=> $b} keys %allPowers )
            {
                foreach my $rate ( sort {$a <=> $b} keys %allRates )
                {
                    next if ($target_power != -1 && $target_power != $power);
                    next if ($target_rate != -1 && $target_rate != $rate);

                    foreach my $f ( 0 .. $nflows-1 )
                    {
                        my($flow_demand,$flow_src,@flow_dest) = split " ", $flow[$f];
                        my($ival, $tval, $redundancy);
                        my($min_interval) = $payload*8/$rate*1e-6;

                        # if forwarding traffic is too low, just set it to 0
                        #$T{$power}{$rate}{$f}{$i} = 0 if ($T{$power}{$rate}{$f}{$i} < $fwdThresh);
			if ($T{$power}{$rate}{$f}{$i} < $fwdThresh && $i != $flow_src) {
			   $T{$power}{$rate}{$f}{$i} = 0; 
			}
			if ($R{$f}{$i} < $fwdThresh && $i != $flow_src) {
			    $R{$f}{$i} = 0;
			}
                        
                        $tval = $T{$power}{$rate}{$f}{$i};

                        $R{$f}{$i} = 0 if (!exists $R{$f}{$i});

                        if ($T{$power}{$rate}{$f}{$i} > 0 && $i == $flow_src)
                        {
                            if ($use_indeptSet)
                            {
                                $ival = $min_interval/($T{$power}{$rate}{$f}{$i}/$rate);
				#$ival /= $eff{$batch_size};
                            }
                            else
                            {
                                # 802.11 model already takes into account of overhead
                                $ival = $payload*8/$T{$power}{$rate}{$f}{$i}*1e-6;
                                # $ival = $min_interval/($T{$power}{$rate}{$f}{$i}/$rate);
                                
                            }
                        }
                        else
                        {
                            # set to 0 if it's not a source
                            $ival = 0;
                        }

                        # compute redundancy
                        if ($i == $flow_src)
                        {
                            $redundancy = 0;
                        }
                        elsif ($total_max_info{$f}{$i} == 0) 
                        {
                            $redundancy = 0;
                        }
                        else
                        {
                            $redundancy = $tval/$total_max_info{$f}{$i};
                        }
                        printf TxCreditFile "%d %d %d %d 1 1 %.9g %.9g %.9g %.9g\n", $i+1, $power, $rate, $f, $tval*$scale, $R{$f}{$i}*$scale, $ival/$scale,$redundancy;
                    }
                }
            }
        }
        
        close(TxCreditFile);
    }

    if($mac == 0){
	open(SUMMARY, ">>summary.lp.OUR2.p$pruningMode.r$OBJ.m$model.MR$isMultiRate.R$target_rate.11b.rl");
    }else{
	open(SUMMARY, ">>summary.lp.OUR2.p$pruningMode.r$OBJ.m$model.MR$isMultiRate.R$target_rate.11a.rl");
    }
    print SUMMARY "$num_pnode $nflows $randSeed $max_hop ",$total_goodput," ";
    print SUMMARY (join " ", @goodput);
    print SUMMARY "\n";
    close(SUMMARY);
}

