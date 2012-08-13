#!/usr/local/bin/perl -w
# post-process-mimo.pl -- (c) UT-Austin, U-lili-G68YH1\lili, Tue Feb  7 2012
#   <yzhang@cs.utexas.edu>
#
########################################################

use strict;

use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

my $AntennaFile = "antenna.txt";
my $topoFile = "topology.txt";
my $qualnetTopoFile = "topo.nodes";
my $qualnetTopoMIMOFile = "topo-mimo.nodes";
my $qualnetMIMOAppFile = "topo-mimo.app";
my $qualnetFaultFile = "topo.fault";
my $qualnetFaultMIMOFile = "topo-mimo.fault";
my $SrcAppFile = "src.s1";
my $SrcAppMIMOFile = "src-mimo.s1";
my $compositeLinkFile = "composite.txt";
my $compositeLinkMIMOFile = "composite_mimo.txt";
my $TxCreditFile = "topo.credit.s1";
my $TxCreditMIMOFile = "topo-mimo.credit.s1";

my %num_antennas = ();
my %node2antenna = ();
my %interval_table = ();
my %min_interval_table = ();
my @composite_link = ();
my $total_composite_links = 0;
    
# my $qualnetFaultMultiFile = "topo-multi.fault"; 
my $totalNodes = 0;

open(topoFile,"<$topoFile");
read_antenna();
generate_topo();
generate_fault();
generate_composite_link();
generate_src_app();
generate_app();
generate_txcredit();
close(topoFile);

sub read_antenna
{
    open(AntennaFile,"<$AntennaFile");
    my $total_num_antenna = 0;	# add by yichao
    while (<AntennaFile>)
    {
        my($i_, $num_antenna_) = split " ", $_;
        $num_antennas{$i_} = $num_antenna_;
        $total_num_antenna += $num_antenna_;	# add by yichao
    }
    close(AntennaFile);

    # add by yichao: update config files for MIMO
    system("sed 's/thru 9/thru $total_num_antenna/' lp-nrl.MIMO.tmp.config > lp-nrl.MIMO.config");
}

sub generate_topo
{
    my($line);
    my($nc, $mr, $default_rate, $TR, $IR);

    system("cp $qualnetTopoFile $qualnetTopoMIMOFile");
    open(qualnetTopoMIMOFile, ">>$qualnetTopoMIMOFile");
    $line = <topoFile>;
    ($totalNodes, $nc, $mr, $default_rate, $TR, $IR) = split " ", $line;
    my($totalNodes_before) = $totalNodes;

    foreach my $i ( 0 .. $totalNodes_before-1 )
    {
	$line = <topoFile>;
        my($i, $x, $y) = split ",", $line;
        $node2antenna{$i}{0} = $i;
        next if ($num_antennas{$i} == 1);

        foreach my $j ( 1 .. $num_antennas{$i}-1 )
        {
            printf qualnetTopoMIMOFile "%d 0 (%.2f, %.2f, 10)\n", $totalNodes+1, $x+0.1*$j, $y+0.1*$j;my $payload = 1024;
            $node2antenna{$i}{$j}=$totalNodes;
            $totalNodes++;
        }
    }

    close(qualnetTopoMIMOFile);

    # foreach my $i ( 0 .. $totalNodes_before-1 )
    # {
    #	foreach my $j ( 0 .. $num_antennas{$i}-1 )
    #    {
    #	    print "hhh: $i ", $node2antenna{$i}{$j},"\n";
    #	}
    # }
}

sub lcm 
{
    use integer;
    my ($x, $y) = @_;
    my ($a, $b) = @_;
    while ($a != $b) {
	($a, $b, $x, $y) = ($b, $a, $y, $x) if $a > $b; 
	$a = $b / $x * $x;
	$a += $x if $a < $b;
    }
    return($a);
}

sub generate_app
{
    my $startTimeRange = 0.1;
    my $payload = 1024;
    my $line;

    open(qualnetMIMOAppFile,">$qualnetMIMOAppFile");
    $line = <topoFile>;
    my($nflows,$np) = split " ", $line;
    my($flowId) = 0;

    while (<topoFile>)
    {
        my($demand, $src, $dest) = split " ", $_;
	my($startTime) = $startTimeRange*$src/$totalNodes;
	my($curr_lcm) = &lcm($num_antennas{$src},$num_antennas{$dest});

	foreach my $virtual_flow_id ( 0 .. $curr_lcm-1 )
	{
	    my($j1) = $virtual_flow_id % $num_antennas{$src};
	    my($j2) = $virtual_flow_id / $num_antennas{$src} % $num_antennas{$dest};

	    # printf "CBR 0.0.0.%d 0.0.0.%d 0 $payload $interval $startTime 0\n",$node2antenna{$src}{$j1}+1,$node2antenna{$dest}{$j2}+1;

	    printf qualnetMIMOAppFile "CBR 0.0.0.%d 0.0.0.%d 0 $payload $min_interval_table{$flowId} $startTime 0\n",$node2antenna{$src}{$j1}+1,$node2antenna{$dest}{$j2}+1;
        }
	$flowId++;
    }
    close(qualnetMIMOAppFile);
}

sub generate_fault
{
    open(qualnetFaultFile,"<$qualnetFaultFile");
    open(qualnetFaultMIMOFile,">$qualnetFaultMIMOFile");
        
    while(<qualnetFaultFile>)
    {
        my($e1,$r,$e3,$e4,$s,$loss) = split " ", $_;
        my(@rcv_ip_addr) = split /\./, $r;
	my($r_id) = $rcv_ip_addr[3]-1;
	my(@s_ip_addr) = split /\./, $s;
        my($s_id) = $s_ip_addr[3]-1;

        foreach my $j1 ( 0 .. $num_antennas{$s_id}-1 )
        {
            foreach my $j2 ( 0 .. $num_antennas{$r_id}-1 )
            {
                # assume the loss rates between all antennas are the same
		# printf "After $e1 0.0.0.%d $e3 $e4 0.0.0.%d %lf\n", $node2antenna{$r_id}{$j2}+1, $node2antenna{$s_id}{$j1}+1, $loss; 
                printf qualnetFaultMIMOFile "$e1 0.0.0.%d $e3 $e4 0.0.0.%d %lf\n", $node2antenna{$r_id}{$j2}+1, $node2antenna{$s_id}{$j1}+1, $loss;
            }
        }
    }
    close(qualnetFaultFile);
    close(qualnetFaultMIMOFile);
}

sub generate_src_app
{
    open(SrcAppFile,"<$SrcAppFile");
    open(SrcAppMIMOFile,">$SrcAppMIMOFile");
    while (<SrcAppFile>)
    {
        my($flowId,$flow_src,$vl,$traffic,$interval,$min_interval) = split " ", $_;
	my($flow, $sender_str, $receiver_str, $antenna_str) = split ":", $composite_link[$vl];
	my($curr_num_antenna) = &get_num_antennas_node($flow_src, $sender_str, $antenna_str);
	# print $composite_link[$vl], " flow_src=$flow_src, curr_num_antenna=$curr_num_antenna\n";
        foreach my $j ( 0 .. $curr_num_antenna-1 )
        {
	     # <flowId, flow_src, composite link id, sending rate, sending interval>          
            print SrcAppMIMOFile "$flowId ", $node2antenna{$flow_src}{$j}," $vl ",$traffic," ", $interval," $min_interval\n";
	    $interval_table{$flowId} = $interval;
	    $min_interval_table{$flowId} = $min_interval;
        }
    }
    close(SrcAppFile);
    close(SrcAppMIMOFile);
}

sub generate_composite_link
{
    open(compositeLinkFile,"<$compositeLinkFile");
    open(compositeLinkMIMOFile,">$compositeLinkMIMOFile");
    
    while (<compositeLinkFile>)
    {
        my($flow, $sender_str, $receiver_str, $antenna_str) = split ":", $_;
	$composite_link[$total_composite_links++] = $_;

        my(@sender_lst) = split " ", $sender_str;
        my(@receiver_lst) = split " ", $receiver_str;
	my(@antenna_lst) = split " ", $antenna_str;

        print compositeLinkMIMOFile "$flow:";
        foreach my $i ( 0 .. $#sender_lst )
        {
	    my($s) = $sender_lst[$i];
	    my($a) = $antenna_lst[$i];

            foreach my $j1 ( 0 .. $a-1 )
            {
                print compositeLinkMIMOFile $node2antenna{$s}{$j1}," ";
            }
        }

        print compositeLinkMIMOFile ":";
        
        foreach my $r ( @receiver_lst )
        {
            foreach my $j2 ( 0 .. $num_antennas{$r}-1 )
            {
                print compositeLinkMIMOFile $node2antenna{$r}{$j2}," ";
            }
        }
        
        print compositeLinkMIMOFile "\n";
    }
    close(compositeLinkFile);
    close(compositeLinkMIMOFile);
}

sub generate_txcredit
{
    open(TxCreditFile,"<$TxCreditFile");
    open(TxCreditMIMOFile,">$TxCreditMIMOFile");
    while (<TxCreditFile>)
    {
	my(@lst) = split " ", $_;
        my($node,$power,$rate,$f,$vl1,$vl2,$redundancy,$weight,$credit) = @lst;
	my($skip,$sender_str,$receiver_str,$antenna_str) = split ":",$composite_link[$vl2];
	my(@sender_lst) = split " ", $sender_str;
	my(@antenna_lst) = split " ", $antenna_str;
	my($curr_num_antennas) = &get_num_antennas_node($node, $sender_str, $antenna_str);
	
        foreach my $j ( 0 .. $curr_num_antennas-1 )
        {
            print TxCreditMIMOFile $node2antenna{$node}{$j}," ";
            print TxCreditMIMOFile (join " ", @lst[1..$#lst-2]);
            print TxCreditMIMOFile " ",$lst[$#lst-1]/$curr_num_antennas," ", $lst[$#lst]/$curr_num_antennas,"\n";
        }
    }
    close(TxCreditMIMOFile);
    close(TxCreditFile);
}

sub get_num_antennas_node
{
    my($node, $sender_str, $antenna_str) = @_;
    my(@sender_lst) = split " ", $sender_str;
    my(@antenna_lst) = split " ", $antenna_str;

    # print "get_num_antennas_node: $node:$sender_str:$antenna_str\n";

    foreach my $i ( 0 .. $#sender_lst )
    {
        my($s) = $sender_lst[$i];
        my($a) = $antenna_lst[$i];
        print "i=$i s=$s node=$node a=$a\n";
        return ($a) if ($s+0 == $node+0);
    }

    print "Error: get_num_antennas_node: $node, $sender_str, $antenna_str\n";
    exit(0);
}

