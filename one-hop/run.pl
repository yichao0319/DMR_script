#!/user/local/bin/perl -w
# run.pl -- (c) UT Austin, Lili Qiu, Fri Jul 11 2008
#   <lili@cs.utexas.edu>
#
########################################################

# convert everything from 0.0.0.* to 0.0.1.*
# topo.nodes, topo.app, topo.fault

$TxCreditFile = "../topo.credit.s1";
$AppFile = "./topo.app";
$statFile = "./topo.stat";
$recvFile = "./recv.txt";
$lossFile = "../loss.txt";
$faultFile = "../topo.fault";
$pktsize = 1112; # 1024 + 88
$payload = 1024;
$simTime = 20;

$totalNodes = $ARGV[0];
$scaling = $ARGV[1];
$comment = $ARGV[2];

$summaryFile = "../validate-summary-s$scaling.txt";

system("sed 's/thru 6/thru $totalNodes/' lp-s1.OUR2.config > topo.config");
system("set_static_routes.sh $totalNodes");
print "sed 's/ 0\\.0\\.0\\./ 0.0.1./g' ../topo.fault > topo.fault\n";
system("sed 's/ 0\\.0\\.0\\./ 0.0.1./g' ../topo.fault > topo.fault");

# generate topo.app based on credit file
open(TxCreditFile,"<$TxCreditFile");
while (<TxCreditFile>)
{
    @lst = split " ", $_;
    $nodeId = $lst[0];
    $traffic = $lst[6];
    next if ($traffic == 0);
    $totalTraffic{$nodeId} += $traffic*$scaling;
}
close(TxCreditFile);

open(AppFile,">$AppFile");
foreach $nodeId ( sort {$a <=> $b} keys %totalTraffic)
{
    my($interArrival) = $payload*8/$totalTraffic{$nodeId}*0.000001;
    my($startTime) = rand(1)*0.1;
    print AppFile "MCBR 0.0.1.$nodeId 0.0.1.255 0 $pktsize $interArrival $startTime 0\n";
}
close(AppFile);

system("rm out");
system("./qualnet topo.config > out");

# compare numPackets sent
print "Compare sending rates\n";
open(statFile,"<$statFile");
while (<statFile>)
{
    if (/Signals transmitted/)
    {
        @lst = split ",", $_;
        $src = $lst[0]+0;
        @lst2 = split "=", $lst[$#lst];
        $numPkts = $lst2[$#lst2]+0;
        next if (!exists $totalTraffic{$src});
        print "$src ",$totalTraffic{$src}," ",$numPkts*$payload*8/$simTime/1000000,"\n";
    }
}
close(statFile);

# compare numPackets received
print "Compare receiving rates\n";
open(lossFile,"<$lossFile");
while(<lossFile>)
{
    my(@lst) = split " ", $_;
    next if (@lst != 8);
    my($curr_linkId, $lnode, $src, $curr_power, $curr_rate, $dest, $curr_channel, $curr_loss) = @lst;
    $src++;
    $dest++;
    next if (!exists $totalTraffic{$src} || $totalTraffic{$src} == 0);
    # curr_loss includes both collision and inherent losses
    $estRecv{$src}{$dest} = $totalTraffic{$src} * (1-$curr_loss);
    # print "ppp: $src $dest ", $totalTraffic{$src}," ",1-$curr_loss," ",$totalTraffic{$src} * (1-$curr_loss),"\n";
}
close(lossFile);

open(faultFile,"<$faultFile");
while(<faultFile>)
{
    my($skip1,$dest_addr,$skip2,$skip3,$src_addr,$curr_loss) = split " ", $_;
    my(@lst) = split /\./, $dest_addr;
    my($dest) = $lst[3];
    @lst = split /\./, $src_addr;
    my($src) = $lst[3];
    next if (!exists $totalTraffic{$src} || $totalTraffic{$src} == 0);
    # curr_loss includes only inherent loss
    # $estRecv{$src}{$dest} = $totalTraffic{$src} * (1-$curr_loss);
}
close(faultFile);

system("grep EEEE: out | sort |uniq -c > $recvFile");
open(recvFile,"<$recvFile");
while (<recvFile>)
{
    ($numPkts, $skip, $src, $dest)   = split " ", $_;
    $estRecv{$src}{$dest} = 0 if (!exists $estRecv{$src}{$dest});
    print "$src $dest ", $estRecv{$src}{$dest}," ", $numPkts*$payload*8/$simTime/1000000,"\n";
    $total_est_recv  += $estRecv{$src}{$dest};
    $total_actual_recv += $numPkts*$payload*8/$simTime/1000000;
}
close(recvFile);

open(summaryFile,">>$summaryFile");
print summaryFile $comment," ",$total_est_recv," ",$total_actual_recv," ",$total_actual_recv/$total_est_recv,"\n";
close(summaryFile);
