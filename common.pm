#! /usr/bin/perl -w
eval 'exec /usr/bin/perl -S $0 "$*"'
    if undef;

package common;

### export

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(compute_tx_time compute_tx_time_with_CW compute_tx_size compute_tx_size2 permute min findIndepSets findIndepSetsMulti findIndepSets_composite findIndepSetsMulti_composite set_ranges);
@EXPORT_OK = qw(1);
### sub routine prototype

sub min($);
sub compute_tx_time($$$$$$);
sub compute_tx_time_with_CW($$$$$$);
sub compute_tx_size($$$$);
sub compute_tx_size2($$$$$$);
sub permute($);
sub findIndepSets($$$$);
sub findIndepSets_composite($$$$$);
sub findIndepSetsMulti($$$$$$);
sub findIndepSetsMulti_composite($$$$$$);
sub set_ranges($);
# $sub distance($$);


#sub distance($$)
#{
#    my($i, $j) = @_;
#    return(sqrt(($x[$i]-$x[$j])**2+($y[$i]-$y[$j])**2));
#}

sub set_ranges($)
{

}

sub min($)
{
    my(@lst) = @_;
    my($min);

    $min = $lst[0];
    foreach my $i ( @lst )
    {
        $min = $i if ($min > $i);
    }
    return($min);
}

sub compute_tx_size($$$$)
{
    my($transport, $mac, $payload, $rate) = @_;
    my($pktsize, $preamble, $EP, $H);

    if ($transport == 0) {
                # TCP 20 byte header
        $pktsize = ($payload+20+28+22/8)+20;
    }
    else {
                # UDP  8 byte header
        $pktsize = ($payload+20+28+22/8)+8;
    }

    if ($mac == 0) {
        $preamble = 192;
    }
    else {
        $preamble = 20;
    }

    $EP   = ($payload*8)/$rate;                      # expected payload tx time
    $H    = $preamble + ($pktsize-$payload)*8/$rate; # packet preamble + header

    return(($EP+$H)*$rate);
}

sub compute_tx_size2($$$$$$)
{
    my($transport, $mac, $payload, $rate, $isopr , $isack) = @_;
    my($pktsize, $preamble, $EP, $H, $tp_hdr, $ip_hdr);
    if ( $isopr )
    {
	$ip_hdr = 88;
	
    }
    else
    {
	$isack = 0;
	$ip_hdr = 20;
    }
    if ($transport == 0) {
	$tp_hdr = 20;
    }
    else{
	$tp_hdr = 8;
    }
    if ($isack){
	$tp_hdr = 0;
	$payload = 0;
    }

    $pktsize = ($payload+$ip_hdr+28)+$tp_hdr;

    if ($mac == 0) {
        $preamble = 192;
    }
    else {
        $preamble = 20;
    }

    $EP   = ($payload*8)/$rate;                      # expected payload tx time
    $H    = $preamble + ($pktsize-$payload)*8/$rate; # packet preamble + header

    return(($EP+$H)*$rate);
}

sub compute_tx_time($$$$$$)
{
    my($transport, $mac, $payload, $rate, $isBcast, $wRTS) = @_;
    my($pktsize, $acksize, $SIFS, $preamble, $slot, $CW, $DIFS, $ACK, $EP, $H, $PROP, $Ts);

    if ($transport == 0) {
        # TCP 20 byte header
        $pktsize = ($payload+20+28+22/8)+20;
    }
    else {
        # UDP  8 byte header
        $pktsize = ($payload+20+28+22/8)+8;
    }

    # 14-byte MAC level ack
    $acksize = 14;

    # mac=0 for 11b and else for 11a
    if ($mac == 0) {
        # 11b
        $SIFS      = 10;
        $preamble  = 192;
        $slot      = 20;
        $CW        = 31;
    }
    else {
        # 11a
        $SIFS      = 16;
        $preamble  = 20;
        $slot      = 9;
        $CW        = 15;
    }

    $DIFS = 2*$slot + $SIFS;
    $ACK  = ($acksize*8/$rate + $preamble);
    $EP   = ($payload*8)/$rate;                      # expected payload tx time
    $H    = $preamble + ($pktsize-$payload)*8/$rate; # packet preamble + header
    $PROP = 0;
    $RTS  = $preamble + 20*8/$rate;                  # RTS xmission time
    $CTS  = $preamble + 14*8/$rate;                  # CTS xmission time

    if ($isBcast) {
        # broadcast
        $Ts = $H + $EP + $DIFS + $PROP;
    }
    elsif ($wRTS) {
        # unicast wo/ RTS/CTS
        $Ts = $H + $EP + $SIFS + $PROP + $ACK + $DIFS + $PROP;
    }
    else {
        # unicast w/ RTS/CTS
        $Ts = $RTS + $SIFS + $CTS + $SIFS + $H + $EP + $SIFS + $PROP + $ACK + $DIFS + $PROP;
    }

    
    $Ts = $Ts/1000000;
    return($Ts);
}

sub compute_tx_time_with_CW($$$$$$)
{
    my($transport, $mac, $payload, $rate, $isBcast, $wRTS) = @_;
    my($pktsize, $acksize, $SIFS, $preamble, $slot, $CW, $DIFS, $ACK, $EP, $H, $PROP, $Ts);

    if ($transport == 0) {
        # TCP 20 byte header
        $pktsize = ($payload+20+28+22/8)+20;
    }
    else {
        # UDP  8 byte header
        $pktsize = ($payload+20+28+22/8)+8;
    }

    # 14-byte MAC level ack
    $acksize = 14;

    # mac=0 for 11b and else for 11a
    if ($mac == 0) {
        # 11b
        $SIFS      = 10;
        $preamble  = 192;
        $slot      = 20;
        $CW        = 31;
    }
    else {
        # 11a
        $SIFS      = 16;
        $preamble  = 20;
        $slot      = 9;
        $CW        = 15;
    }

    $DIFS = 2*$slot + $SIFS;
    $ACK  = ($acksize*8/$rate + $preamble);
    $EP   = ($payload*8)/$rate;                      # expected payload tx time
    $H    = $preamble + ($pktsize-$payload)*8/$rate; # packet preamble + header
    $PROP = 0;
    $RTS  = $preamble + 20*8/$rate;                  # RTS xmission time
    $CTS  = $preamble + 14*8/$rate;                  # CTS xmission time

    if ($isBcast) {
        # broadcast
        $Ts = $H + $EP + $DIFS + $PROP + $CW*$slot/2;
    }
    elsif ($wRTS) {
        # unicast wo/ RTS/CTS
        $Ts = $H + $EP + $SIFS + $PROP + $ACK + $DIFS + $PROP + $CW*$slot/2;
    }
    else {
        # unicast w/ RTS/CTS
        $Ts = $RTS + $SIFS + $CTS + $SIFS + $H + $EP + $SIFS + $PROP + $ACK + $DIFS + $PROP + $CW*$slot/2;
    }

    
    $Ts = $Ts/1000000;
    return($Ts);
}

# allow duplicates
sub findIndepSetsMulti($$$$$$)
{
    my($totalNodes, $effort, $indepMultiFile, $conflictMulti,$rates,$numPower) = @_;
    my %allRates = %$rates;
    open(indeptMultiFile,">$indepMultiFile") or die "can't open $indepMultiFile for writing\n";

    print indeptMultiFile "$effort\n";
    
    foreach my $e ( 0 .. $effort-1 )
    {
        my @vertexLst = (); #(0 .. $totalNodes-1);
	foreach my $n ( 0 .. $totalNodes-1 )
	{
	    foreach my $p (0 .. $numPower-1 )
	    {
		foreach my $rater ( keys %allRates )
		{
		    push @vertexLst, "$n:$p:$rater"; 
		}
	    }
	}
	if( $e == 0 )
	{
	    printf "print vertexLst\n";
	    printf (join " ", @vertexLst);
	    printf "\n print vertexLst end \n";
	}	
	permute(\@vertexLst);
	
        @indepset = ();
        foreach $i ( @vertexLst )
        {
            $curr_conflict = 0;
            foreach $j ( @indepset )
            {
                if ($conflictMulti->{$i}{$j} || $conflictMulti->{$j}{$i})
                {
                    $curr_conflict = 1;
                    last;
                }
            }
            push @indepset, $i if (!$curr_conflict);
        }
        
        print indeptMultiFile "$e ", @indepset+0," ";
        print indeptMultiFile (join " ", @indepset);
        print indeptMultiFile "\n";
    }
    close(indeptMultiFile);
}

# return IDs of composite links that are independent of each other
sub findIndepSets_composite($$$$$)
{
    my($totalCompositeLinks, $effort, $indepFile, $composite_link_conflict, $compositeLink_single_antenna_sender) = @_;
    my(%seen_indept_set) = ();

    open(indeptFile,">$indepFile") or die "can't open $indepFile for writing\n";
    
    print indeptFile "$effort\n";

    foreach my $lst_id (  0, 1 )
    {
	if ($lst_id == 0)
	{
	    @compositeLinkLst = @$compositeLink_single_antenna_sender;
	}
	else
	{
	    @compositeLinkLst = ( 0 .. $totalCompositeLinks-1)
	}

	foreach my $e ( 0 .. $effort-1 )
	{
	    permute(\@compositeLinkLst);
        
	    @indepset = ();
	    foreach $i ( @compositeLinkLst )
	    {
		$curr_conflict = 0;
		foreach $j ( @indepset )
		{
		    # if ($$composite_link_conflict[$i][$j])
            my $a = $i;
            my $b = $j;
            if($i > $j) {
                $a = $j;
                $b = $i;
            }
            if (!defined($$composite_link_conflict{"$a,$b"}))  # yichao
		    {
			$curr_conflict = 1;
			last;
		    }
		}
		push @indepset, $i if (!$curr_conflict);
	    }
        my(@sorted_indepset) = sort {$a <=> $b} @indepset;
	my($sorted_indepset_str) = join " ", @sorted_indepset;
	if (!exists $seen_indept_set{$sorted_indepset_str})
	{
	    $seen_indept_set{$sorted_indepset_str} = 1; 
	    print indeptFile "$e ", @sorted_indepset+0," $sorted_indepset_str\n";
	}
    }
    }
    close(indeptFile);
}

sub findIndepSets($$$$)
{
    my($totalNodes, $effort, $indepFile, $conflict) = @_;

    open(indeptFile,">$indepFile") or die "can't open $indepFile for writing\n";
    
    print indeptFile "$effort\n";
    
    foreach my $e ( 0 .. $effort-1 )
    {
        my @nodeLst = (0 .. $totalNodes-1);
        permute(\@nodeLst);
        
        @indepset = ();
        foreach $i ( @nodeLst )
        {
            $curr_conflict = 0;
            foreach $j ( @indepset )
            {
                if ($conflict->[$i][$j])
                {
                    $curr_conflict = 1;
                    last;
                }
            }
            push @indepset, $i if (!$curr_conflict);
        }
        
        print indeptFile "$e ", @indepset+0," ";
        print indeptFile (join " ", @indepset);
        print indeptFile "\n";
    }
    close(indeptFile);
}

sub permute($)
{
    my $array = shift;
    my $i;

    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
	if ($i <0) { #ejr
	    return;
	}
        @$array[$i,$j] = @$array[$j,$i];
    }
}
