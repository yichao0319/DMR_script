#!/usr/local/bin/perl -w
# post-process-mimo.pl -- (c) UT-Austin, U-lili-G68YH1\lili, Tue Feb  7 2012
#   <yzhang@cs.utexas.edu>
#
########################################################

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
    
# my $qualnetFaultMultiFile = "topo-multi.fault"; 
my $totalNodes = 0;

open(topoFile,"<$topoFile");
read_antenna();
generate_topo();
generate_fault();
generate_src_app();
generate_app();
generate_composite_link();
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
    # system("mv lp-nrl.MIMO.tmp.config lp-nrl.MIMO.config");
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
	$startTime = $startTimeRange*$src/$totalNodes;

        foreach my $j1 ( 0 .. $num_antennas{$src}-1 )
        {
            foreach my $j2 ( 0 .. $num_antennas{$dest}-1 )
            {
		# printf "CBR 0.0.0.%d 0.0.0.%d 0 $payload $interval $startTime 0\n",$node2antenna{$src}{$j1}+1,$node2antenna{$dest}{$j2}+1;

                printf qualnetMIMOAppFile "CBR 0.0.0.%d 0.0.0.%d 0 $payload $min_interval_table{$flowId} $startTime 0\n",$node2antenna{$src}{$j1}+1,$node2antenna{$dest}{$j2}+1;
            }
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
        foreach my $j ( 0 .. $num_antennas{$flow_src}-1 )
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
        my($flow, $sender_str, $receiver_str) = split ":", $_;
        my(@sender_lst) = split " ", $sender_str;
        my(@receiver_lst) = split " ", $receiver_str;

        print compositeLinkMIMOFile "$flow:";
        foreach my $s ( @sender_lst )
        {
            foreach my $j1 ( 0 .. $num_antennas{$s}-1 )
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
	my($node) = $lst[0];
	foreach my $j ( 0 .. $num_antennas{$node}-1 )
	{
	    print TxCreditMIMOFile $node2antenna{$node}{$j}," ";
	    print TxCreditMIMOFile (join " ", @lst[1..$#lst-2]);
	    print TxCreditMIMOFile " ",$lst[$#lst-1]/$num_antennas{$node}," ", $lst[$#lst]/$num_antennas{$node},"\n";
	}
    }
    close(TxCreditMIMOFile);
    close(TxCreditFile);
}
