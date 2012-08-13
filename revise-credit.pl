#!/user/local/bin/perl -w                   

use strict;

my @composite_link = ();
my %credit_all = ();
my $totalCompositeLinks = 0;
my %compositeLink2id = ();
my @flow = ();
my $nflows = 0;

my $TxCreditFile = "topo.credit.s1";
my $compositeLinkFile = "composite.txt";
my $trafficFile = "traffic.txt";
my $TxCreditOutFile = "topo.credit-new.s1";
my $compositeLinkOutFile = "composite-new.txt";

&read_traffic();
&read_composite_link();
&read_credit();
&revise_credit();
&dump_composite_link();

sub read_composite_link
{
    open(compositeLinkFile,"<$compositeLinkFile");
    while (<compositeLinkFile>)
    {
        my($flow, $sender_str, $receiver_str) = split ":", $_;
        $composite_link[$totalCompositeLinks] = "$flow:$sender_str:$receiver_str";
	$compositeLink2id{"$flow:$sender_str:$receiver_str"} = $totalCompositeLinks++;
    }
    close(compositeLinkFile);
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

sub read_credit
{
    open(TxCreditFile,"<$TxCreditFile");
    while (<TxCreditFile>)
    {
	my($node,$power,$rate,$f,$vl1,$vl2,$redundancy,$weight,$credit) = split " ", $_;
	# total credits coming from incoming link $vl1
	$credit_all{$node}{$power}{$rate}{$f}{$vl1} += $credit;
    }
    close(TxCreditFile);
}

sub revise_credit
{
    open(TxCreditFile,"<$TxCreditFile");
    open(TxCreditOutFile,">$TxCreditOutFile");
    while (<TxCreditFile>)
    {
	my($node,$power,$rate,$f,$vl1,$vl2,$redundancy,$weight,$credit) = split " ", $_;

	next if ($credit == 0);

	my($f2, $sender_str2, $receiver_str2) = split ":", $composite_link[$vl2];
	my(@receiver_lst2) = split " ", $receiver_str2;
	my(@new_receiver_lst) = ();
	my($flow_demand, $flow_src, @flow_dest) = split " ", $flow[$f];

	foreach my $r ( @receiver_lst2)
	{
	    if ($r == $flow_dest[0] || $credit_all{$r}{$power}{$rate}{$f}{$vl2} > 0)
	    {
		push @new_receiver_lst, $r;
	    }
	}
	
	if (@new_receiver_lst == @receiver_lst2)
	{
	    print TxCreditOutFile $_;
	    next;
	}

	my($new_receiver_str2) = join " ", @new_receiver_lst;
	my($new_vl2);

	if (exists $compositeLink2id{"$f2:$sender_str2:$new_receiver_str2"})
	{
	    $new_vl2 = $compositeLink2id{"$f2:$sender_str2:$new_receiver_str2"};
	}
	else
	{
	    $new_vl2 = $totalCompositeLinks++;
	    $composite_link[$new_vl2] = "$f2:$sender_str2:$receiver_str2";
	    $compositeLink2id{"$f2:$sender_str2:$receiver_str2"} = $new_vl2;
	}

 	print TxCreditOutFile "$node $power $rate $f $vl1 $new_vl2 $redundancy $weight $credit\n";
    }
    close(TxCreditFile);
    close(TxCreditOutFile);
}

sub dump_composite_link
{
    open(compositeLinkOutFile,">$compositeLinkOutFile");
    foreach my $i ( 0 .. $totalCompositeLinks-1)
    {
	print compositeLinkOutFile $composite_link[$i];
    }
    close(compositeLinkOutFile);
}
