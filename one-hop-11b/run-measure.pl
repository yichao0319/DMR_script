#!/user/local/bin/perl -w
# run-measure.pl -- (c) UT Austin, Lili Qiu, Mon Sep  1 2008
#   <lili@cs.utexas.edu>
#
########################################################

$totalNode = $ARGV[0];
$simTime = $ARGV[1];
$rate = $ARGV[2];
$mac = $ARGV[3];
$cs_thresh = $ARGV[4];

if(1){
foreach $sender ( 1 .. $totalNode )
{
    if(defined($cs_thresh)){
	system("perl measure-one-node.pl $sender $totalNode $simTime $rate $mac $cs_thresh");
    }else{
	system("perl measure-one-node.pl $sender $totalNode $simTime $rate $mac");
    }
}
}
if(0){
foreach $sender1 ( 1 .. $totalNode)
{
    foreach $sender2 ( $sender1+1 .. $totalNode)
    {
	if(defined($cs_thresh)){
	    system("perl measure-pairwise.pl $sender1 $sender2 $totalNode $simTime $rate $mac $cs_thresh");
	}else{
	    system("perl measure-pairwise.pl $sender1 $sender2 $totalNode $simTime $rate $mac");
	}
    }
}
}

