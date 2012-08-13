#!/user/local/bin/perl -w
# run.pl -- (c) UT Austin, Lili Qiu, Fri Jul 11 2008
#   <lili@cs.utexas.edu>
#
########################################################

# convert everything from 0.0.0.* to 0.0.1.*
# topo.nodes, topo.app, topo.fault

$AppFile = "./topo.app";
$recvFile = "./recv.txt";
$statFile = "./topo.stat";
$S1 = "./S1.txt";
$R1 = "./R1.txt";
$payload = 1024;
$pktsize = $payload;

$sender1 = $ARGV[0];
$totalNodes = $ARGV[1];
$simTime = $ARGV[2];
$rate = $ARGV[3]*1000000;
$mac = $ARGV[4];
$cs_threshold = $ARGV[5];

if(!defined($mac)){
    print "mac should be defined!!!\n";
    exit(0);
}

if($mac == 0)
{
    $mac_str = "PHY802.11b";
    $cs_thresh = -93.0;
}else{
    $mac_str = "PHY802.11a";    
    $cs_thresh = -85.0;
}

if(defined($cs_threshold))
{
    $cs_thresh = $cs_threshold;
}

# step 1: prepare all input files
system("sed 's/thru 6/thru $totalNodes/;s/SIMULATION-TIME 20S/SIMULATION-TIME ${simTime}S/;s/PHY802.11-DATA-RATE 6000000/PHY802.11-DATA-RATE $rate/;s/PHY802.11-DATA-RATE-FOR-BROADCAST 6000000/PHY802.11-DATA-RATE-FOR-BROADCAST $rate/;s/PHY-MODEL .*/PHY-MODEL $mac_str/;s/PHY-RX-MODEL .*/PHY-RX-MODEL $mac_str/;s/CARRIER-SENSING-THRESH .*/CARRIER-SENSING-THRESH $cs_thresh/' lp-s1.OUR2.config > topo.config");
system("set_static_routes.sh $totalNodes");
system("rm topo.fault; touch topo.fault");
# print "sed 's/ 0\\.0\\.0\\./ 0.0.1./g' ../topo.fault > topo.fault\n";
# system("sed 's/ 0\\.0\\.0\\./ 0.0.1./g' ../topo.fault > topo.fault");


# prepare app file: 2 sender broadcast experiments
open(AppFile,">$AppFile");
print AppFile "MCBR 0.0.1.$sender1 0.0.1.255 0 $pktsize 0.0002 0.001 0\n";
close(AppFile);

# step 2: run qualnet
system("rm out");
system("./qualnet topo.config > out");

# step 3: process results
open(statFile,"<$statFile");
while(<statFile>)
{
    if (/Broadcasts sent/)
    {
        @lst1 = split ",", $_;
        $src = $lst1[0]+0;
        print "src = $src\n";
        @lst2 = split " ", $lst1[$#lst1];
        print $lst2[$#lst2],"\n";
        $sent{$src} = $lst2[$#lst2]*$payload*8/$simTime/1000000;
    }
}
close(statFile);

system("grep EEEE: out | sort |uniq -c > $recvFile");
open(recvFile,"<$recvFile");
while (<recvFile>)
{
    ($numPkts, $skip, $src, $dest)   = split " ", $_;
    $recv{$src}{$dest} = $numPkts*$payload*8/$simTime/1000000;
}
close(recvFile);

open S1, ">>$S1" || die "can't open S1 for writing!\n";
print S1 "$sender1 ",$sent{$sender1},"\n";
close(S1);

open R1, ">>$R1" || die "can't open R1 for writing!\n";
foreach my $receiver ( 1 .. $totalNodes )
{
    $recv{$sender1}{$receiver} = 0 if (!exists $recv{$sender1}{$receiver});
    print R1 "$sender1 $receiver ", $recv{$sender1}{$receiver},"\n";
}
close(R1);

