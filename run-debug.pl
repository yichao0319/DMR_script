#!/user/local/bin/perl -w
# run-test.pl -- (c) UT Austin, Lili Qiu, Thu Nov  1 2007
#   <lili@cs.utexas.edu>
#
########################################################

use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

use constant SPP => 1;
use constant PRO => 2;
use constant MORE => 3;
use constant MIMO => 4;

$default_power = 0;
$isBER = 0;
$batch_size = 12;
$runType = 0;       # 0 for random generated loss rate      ## yichao: 0 -> 1
$measureOneHop = 0;

$isSim = 1;
$mac = 1;            # 1 for 11a 0 for 11b
$d_rate = 1;        # DATA Rate 1,2, 5,5, 11 Mbps for 11b

# if($model == 1)      # if using WiFi model, then isSim should be 2
# {
#    $isSim = 2;
# }

if($mac == 1)
{
    $d_rate = 6; 
    $mac_str="PHY802.11a";
    $dist = 100; ## yichao: node distance
    $one_hop_name ="one-hop";
    $power = 10;
    $tx_range = 230.09555965;   ## yichao: 230.09555965 -> 150
    $if_range = 253.641819459;
    $cs_range = $if_range;
    $freq = 5.2e9;
}else{
    $mac_str="PHY802.11b";
    $one_hop_name ="one-hop-11b";
    $power = 15;
    $freq = 2.4e9;
    if($d_rate == 1)
    {
        $dist = 550;
        # $tx_range = 1027.799111221291;
        $tx_range = 1012.3;
    }elsif($d_rate == 2) {
        $dist = 400;
        $tx_range = 741.31540545662;
    }elsif($d_rate == 5.5) {
        $dist = 350;
        $tx_range = 631.53106522855;
    }elsif($d_rate == 11){
        $dist = 210;
        # $tx_range = 452.91472221866;
        $tx_range = 415.3;
    }else{
        print "unsupported rate for $mac_str\n";
        exit(0);
    }
    $if_range = 1090.5117766974669;
    $cs_range = $if_range;
}

system("echo $d_rate > rate.txt");
system("echo $power $tx_range $if_range $cs_range > power.txt");

# run SPP, MORE, OUR2 w/RL, OUR2 wo/RL
foreach $group_size ( 1 ) # multicast group size, 1 means unicast
{
    foreach $isMultiRate ( 1 ) 
    {
        foreach $default_rate ( $d_rate ) 
        {
        foreach $nAntenna ( 3 ) ## yichao: number of antennas in src and dst
        {
            foreach $nColumns ( 5 ) ## yichao: 5 -> 3
            {
                $nRows = $nColumns;   ## yichao: --
                # $nRows = 1;     ## yichao: ++
                $totalNodes = $nColumns * $nRows;
                $rate_bps = $default_rate * 1000000;
                
                # generate config files for shortest path
                system("sed 's/thru 9/thru $totalNodes/;s/PHY802.11-DATA-RATE .*/PHY802.11-DATA-RATE $rate_bps/;s/PHY802.11-DATA-RATE-FOR-BROADCAST .*/PHY802.11-DATA-RATE-FOR-BROADCAST $rate_bps/;s/PHY-MODEL .*/PHY-MODEL $mac_str/;s/PHY-RX-MODEL .*/PHY-RX-MODEL $mac_str/;s/PROPAGATION-CHANNEL-FREQUENCY 5.2e9/PROPAGATION-CHANNEL-FREQUENCY $freq/' lp.SPP.mother.config > lp.SPP.config");

                system("sed 's/thru 9/thru $totalNodes/;s/PHY802.11-DATA-RATE .*/PHY802.11-DATA-RATE $rate_bps/;s/PHY802.11-DATA-RATE-FOR-BROADCAST .*/PHY802.11-DATA-RATE-FOR-BROADCAST $rate_bps/;s/PHY-MODEL .*/PHY-MODEL $mac_str/;s/PHY-RX-MODEL .*/PHY-RX-MODEL $mac_str/;s/PROPAGATION-CHANNEL-FREQUENCY 5.2e9/PROPAGATION-CHANNEL-FREQUENCY $freq/' lp.SPP.Compress.mother.config > lp.SPP.Compress.config");
                
                system("sed 's/thru 9/thru $totalNodes/;s/PHY802.11-DATA-RATE .*/PHY802.11-DATA-RATE $rate_bps/;s/PHY802.11-DATA-RATE-FOR-BROADCAST .*/PHY802.11-DATA-RATE-FOR-BROADCAST $rate_bps/;s/PHY-MODEL .*/PHY-MODEL $mac_str/;s/PHY-RX-MODEL .*/PHY-RX-MODEL $mac_str/;s/PROPAGATION-CHANNEL-FREQUENCY 5.2e9/PROPAGATION-CHANNEL-FREQUENCY $freq/' lp-nrl.SPP.mother.config > lp-nrl.SPP.config");

                system("sed 's/thru 9/thru $totalNodes/;s/PHY802.11-DATA-RATE .*/PHY802.11-DATA-RATE $rate_bps/;s/PHY802.11-DATA-RATE-FOR-BROADCAST .*/PHY802.11-DATA-RATE-FOR-BROADCAST $rate_bps/;s/PHY-MODEL .*/PHY-MODEL $mac_str/;s/PHY-RX-MODEL .*/PHY-RX-MODEL $mac_str/;s/PROPAGATION-CHANNEL-FREQUENCY 5.2e9/PROPAGATION-CHANNEL-FREQUENCY $freq/' lp-nrl.SPP.Compress.mother.config > lp-nrl.SPP.Compress.config");

                # generate config files for MORE
                system("sed 's/thru 9/thru $totalNodes/;s/PHY802.11-DATA-RATE .*/PHY802.11-DATA-RATE $rate_bps/;s/PHY802.11-DATA-RATE-FOR-BROADCAST .*/PHY802.11-DATA-RATE-FOR-BROADCAST $rate_bps/;s/BATCH-SIZE .*/BATCH-SIZE $batch_size/;s/PHY-MODEL .*/PHY-MODEL $mac_str/;s/PHY-RX-MODEL .*/PHY-RX-MODEL $mac_str/;s/PROPAGATION-CHANNEL-FREQUENCY 5.2e9/PROPAGATION-CHANNEL-FREQUENCY $freq/' lp.MORE.mother.config > lp.MORE.config");
                
                system("sed 's/thru 9/thru $totalNodes/;s/PHY802.11-DATA-RATE .*/PHY802.11-DATA-RATE $rate_bps/;s/PHY802.11-DATA-RATE-FOR-BROADCAST .*/PHY802.11-DATA-RATE-FOR-BROADCAST $rate_bps/;s/BATCH-SIZE .*/BATCH-SIZE $batch_size/;s/PHY-MODEL .*/PHY-MODEL $mac_str/;s/PHY-RX-MODEL .*/PHY-RX-MODEL $mac_str/;s/PROPAGATION-CHANNEL-FREQUENCY 5.2e9/PROPAGATION-CHANNEL-FREQUENCY $freq/' lp-nrl.MORE.mother.config > lp-nrl.MORE.config");
                # generate config files for MORE2
                # system("sed 's/thru 9/thru $totalNodes/' lp.MORE2.mother.config > lp.MORE2.config");
                # system("sed 's/thru 9/thru $totalNodes/' lp-nrl.MORE2.mother.config > lp-nrl.MORE2.config");
                
                # generate config files for OUR2
                system("sed 's/thru 9/thru $totalNodes/;s/BATCH-SIZE .*/BATCH-SIZE $batch_size/;s/PHY802.11-DATA-RATE .*/PHY802.11-DATA-RATE $rate_bps/;s/PHY802.11-DATA-RATE-FOR-BROADCAST .*/PHY802.11-DATA-RATE-FOR-BROADCAST $rate_bps/;s/PHY-MODEL .*/PHY-MODEL $mac_str/;s/PHY-RX-MODEL .*/PHY-RX-MODEL $mac_str/;s/PROPAGATION-CHANNEL-FREQUENCY 5.2e9/PROPAGATION-CHANNEL-FREQUENCY $freq/' lp.OUR2.mother.config > lp.OUR2.config");

                system("sed 's/thru 9/thru $totalNodes/;s/BATCH-SIZE .*/BATCH-SIZE $batch_size/;s/PHY802.11-DATA-RATE .*/PHY802.11-DATA-RATE $rate_bps/;s/PHY802.11-DATA-RATE-FOR-BROADCAST .*/PHY802.11-DATA-RATE-FOR-BROADCAST $rate_bps/;s/PHY-MODEL .*/PHY-MODEL $mac_str/;s/PHY-RX-MODEL .*/PHY-RX-MODEL $mac_str/;s/PROPAGATION-CHANNEL-FREQUENCY 5.2e9/PROPAGATION-CHANNEL-FREQUENCY $freq/' lp-nrl.OUR2.mother.config > lp-nrl.OUR2.config");

        
                # add by yichao: generate config files for MIMO
                system("sed 's/PHY802.11-DATA-RATE .*/PHY802.11-DATA-RATE $rate_bps/;s/PHY802.11-DATA-RATE-FOR-BROADCAST .*/PHY802.11-DATA-RATE-FOR-BROADCAST $rate_bps/;s/BATCH-SIZE .*/BATCH-SIZE $batch_size/;s/PHY-MODEL .*/PHY-MODEL $mac_str/;s/PHY-RX-MODEL .*/PHY-RX-MODEL $mac_str/;s/PROPAGATION-CHANNEL-FREQUENCY 5.2e9/PROPAGATION-CHANNEL-FREQUENCY $freq/' lp-nrl.MIMO.mother.config > lp-nrl.MIMO.tmp.config");
        
                foreach $topologyType ( 1 ) # (0, 1 ) 1 for grid 0 for random   ## yichao: 0 -> 1
                {
                    foreach $pruning ( 1 )
                    {
                    foreach $nf ( 1 ) # 1, 2, 4, 8, 16 ) 
                    {
                        foreach $s ( 1 ... 3 )
                        {
                        $seed = $s + $nColumns*$nRows*$nf;
                        print "seed is $seed\n";

                        foreach $ratelimit ( 1 )
                        {
                            foreach $demandType ( 1 )
                            {
                                foreach $obj ( 1 )  # 1: total throughput; 3,4: proportional fairness
                                {
                                foreach $protocol ( MIMO ) # SPP, MORE, PRO, MIMO ) 
                                {
                                
                                ## add by yichao, make sure using correct model
                                if($protocol == MIMO) {
                                    $models = ( 2 );
                                }
                                elsif($protocol == MORE) {
                                    $models = ( 0 );
                                }
                                elsif($protocol == PRO) {
                                    $models = ( 2 );
                                }
                                elsif($protocol == SPP) {
                                    $models = ( 2 );    ## 0 or 2
                                }
                                
                                foreach $model ( $models ) # by yichao
                                # foreach $model ( 2 ) # 1 for wifi model 2 for CG model
                                {
                                    next if ($protocol == MORE && $model != 0);
                                    next if ($protocol == PRO && $model == 0);
                                    $max_hop = 1000;
                                    
                                    
                                    my @t0 = gettimeofday();
                                    
                                    $cmd = "perl multirate-multicast3.pl $nf $nColumns $nRows $seed $ratelimit $topologyType $demandType $dist $max_hop power.txt rate.txt $default_power $default_rate $isBER $runType $group_size $isSim $isMultiRate $obj $pruning $model $mac $measureOneHop $protocol $nAntenna";
                                    print "$cmd\n";
                                    system($cmd);

                                    my @t1 = gettimeofday();
                                    my $elapsed = tv_interval (\@t0, \@t1);
                                    print STDERR "$nAntenna antenna, $nf flow: all elapsed time: $elapsed\n\n";

                                    if ($measureOneHop)
                                    {
                                        $cmd = "cd $one_hop_name; rm S1.txt R1.txt S2.txt R2.txt; perl run-measure.pl $totalNodes 5 $default_rate $mac";
                                        print "$cmd\n";
                                        system($cmd);

                                        # $dir_name ="$one_hop_name-rate$default_rate-topo$topologyType-dist$dist";
                                        # $cmd = "mkdir $dir_name; cp -R $one_hop_name/* $dir_name";
                                        # print "$cmd\n";
                                        # system($cmd);

                                        # $measureOneHop = 0;
                                        # system("perl multirate-multicast.pl $nf $nColumns $nRows $seed $ratelimit $topologyType $demandType $dist $max_hop power.txt rate.txt $default_power $default_rate $isBER $runType $group_size $isSim $isMultiRate $obj $pruning $model $mac $measureOneHop $protocol");
                                    }

                                    if ( 0 )
                                    {
                                        foreach $scaling ( 1 ) # (1, 1.1, 1.2, 1.5 )
                                        {
                                            my($comment) = "$totalNodes $nf $seed 1000";     
                                            system("cd one-hop; perl run.pl $totalNodes $scaling \"$comment\"");
                                        }
                                    }
                                }
                                }
                                }
                                }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
}
