#!/user/local/bin/perl -w
# run.pl -- (c) UT Austin, Lili Qiu, Fri Jul 11 2008
#   <lili@cs.utexas.edu>
#
########################################################

# convert everything from 0.0.0.* to 0.0.1.*
# topo.nodes, topo.app, topo.fault

$AppFile = "./topo.app";
$recvFile = "./recv.txt";
$faultFile = "../topo.fault";
$statFile = "./topo.stat";
$S2 = "./S2.txt";
$R2 = "./R2.txt";
$pktsize = 1112; # 1024 + 88
$payload = 1024;

$sender1 = $ARGV[0];
$sender2 = $ARGV[1];
$totalNodes = $ARGV[2];
$simTime = $ARGV[3];

# step 1: prepare all input files
system("sed 's/thru 6/thru $totalNodes/;s/SIMULATION-TIME 20S/SIMULATION-TIME 5S/' lp-s1.OUR2.config > topo.config");
system("set_static_routes.sh $totalNodes");
print "sed 's/ 0\\.0\\.0\\./ 0.0.1./g' ../topo.fault > topo.fault\n";
system("sed 's/ 0\\.0\\.0\\./ 0.0.1./g' ../topo.fault > topo.fault");


# prepare app file: 2 sender broadcast experiments
open(AppFile,">$AppFile");
print AppFile "MCBR 0.0.1.$sender1 0.0.1.255 0 $pktsize 0.0002 0.001 0\n";
print AppFile "MCBR 0.0.1.$sender2 0.0.1.255 0 $pktsize 0.0002 0.002 0\n";
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

open S2, ">>$S2" || die "can't open S2 for writing!\n";
print S2 "$sender1 $sender2 ",$sent{$sender1},"\n";
print S2 "$sender2 $sender1 ",$sent{$sender2},"\n";
close(S2);

open R2, ">>$R2" || die "can't open R2 for writing!\n";
foreach my $receiver ( 1 .. $totalNodes )
{
    $recv{$sender1}{$receiver} = 0 if (!exists $recv{$sender1}{$receiver});
    print R2 "$sender1 $sender2 $receiver ", $recv{$sender1}{$receiver},"\n";
}

foreach my $receiver ( 1 .. $totalNodes )
{
    $recv{$sender2}{$receiver} = 0 if (!exists $recv{$sender2}{$receiver});
    print R2 "$sender2 $sender1 $receiver ", $recv{$sender2}{$receiver},"\n";
}
close(R2);

