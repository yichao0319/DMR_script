#!/user/local/bin/perl -w
# process-summary.pl -- (c) UT Austin, Lili Qiu, Tue Mar 11 2008
#   <lili@cs.utexas.edu>
#
########################################################

#use Stat;

$F1 = $ARGV[0];
$shift = $ARGV[1];
$metric = $ARGV[2]; # 0 for total throughput, 1 for prop. fairness, 2 for appx. prop. fairness
$obj = $ARGV[3]; # used only when metric == 2 

open(F1,"<$F1");
while (<F1>)
{
    @f1 = split " ", $_;
    $numConn = $f1[1];
    if ($metric == 0)
    {
        if ($shift == 2)
        {
            $total = $f1[4+$numConn+1]/1000000;
        }
        elsif ($shift == 1)
        {
            $total = $f1[4+1]/1000000;
        }
        else
        {
            $total = $f1[4]/1000000;
        }
    }
    elsif ($metric == 1)
    {
        if ($shift == 2)
        {
            $total = &compute_prop_fairness(@f1[6+$numConn .. $#f1]);
        }
        elsif ($shift == 1)
        {
            $total = &compute_prop_fairness(@f1[6 .. 6+$numConn-1]);
        }
        else
        {
            $total = &compute_prop_fairness(@f1[5 .. 5+$numConn-1]);
        }
    }
    elsif ($metric == 2)
    {
        if ($shift == 2)
        {
            $total = &compute_approx_prop_fairness($numConn,@f1[6+$numConn .. $#f1]);
        }
        elsif ($shift == 1)
        {
            $total = &compute_approx_prop_fairness($numConn,@f1[6 .. 6+$numConn-1]);
        }
        else
        {
            $total = &compute_approx_prop_fairness($numConn,@f1[5 .. 5+$numConn-1]);
        }
    }
    push @{$total_rl1{$numConn}}, $total;
}
close(F1);

my $index = 1;
foreach $numConn ( sort {$a <=> $b} (keys %total_rl1) )
{
    my($curr_mean) = mean(\@{$total_rl1{$numConn}});
    my($curr_std) = std(\@{$total_rl1{$numConn}});
    printf "%d %.6g %.6g %.6g\n", $index, $numConn, $curr_mean, $curr_std;
    $index++;
}

sub compute_prop_fairness
{
    my(@lst) = @_;
    my($value) = 0;

    foreach my $v ( @lst )
    {
        $value += log($v/1000000+0.001);
    }

    return($value);
}

sub compute_approx_prop_fairness
{
    my($numConn,@lst) = @_;
    my($total) = 0;
    my(@cut_points, @slope, @width);

    if ($obj == 3)
    {
        @cut_points = (0, 0.01, 0.1, sqrt(0.1), 1, sqrt(10), 10);
        @slope = (239.7895, 24.6358, 5.2930, 1.6806, 0.5321, 0.1683, 0.1000);
        @width = (0.01, 0.09, 0.2162, 0.6838, 2.1623, 6.8377);
    }
    else
    {
        @cut_points = (0, 0.005, 0.0550, 0.2081, 0.6581, 2.0811, 6.5811);
        @slope = (358.3519, 44.6718, 8.6052, 2.5513, 0.8083, 0.2558, 0.1520);
        @width = (0.005, 0.05, 0.1531, 0.45, 1.4230, 4.5);
    }

    foreach my $v ( @lst )
    {
        my($remaining) = $v/1000000;
        
        foreach my $i ( 0 .. $#width )
        {
            last if ($remaining <= 0);
            # print "remaining = $remaining ",$cut_points[$i], "\n";
            my($segment) = min($remaining,$width[$i]);
            $total += $segment*$slope[$i];
            $remaining -= $segment;
            # print "segment = $segment y = ", $segment*$slope[$i-1],"\n";
        }
    }
    
    # print "total = $total\n";
    return($total+log(0.001)*$numConn);
}

sub min
{
    my(@lst) = @_;
    my($min);
    
    $min = $lst[0];
    foreach my $v (@lst )
    {
        $min = $v if ($min > $v);
    }
    return($min);
}

sub mean
         {
    my($lst) = @_;
    my($length) = @$lst+0;
    my($result) = 0;
    
    foreach $i ( 0 .. $length-1 )
    {
        $result += $$lst[$i];
    }
    
    $result /= $length;
    return ($result);
}

sub std
        {
            my($lst) = @_;
            my($length) = @$lst+0;
            my($result) = 0;
            my($curr_mean) = mean($lst);
            
            foreach $i ( 0 .. $length-1 )
            {
                $result += ($$lst[$i]-$curr_mean) ** 2;
            }
            
            $result = sqrt($result/($length-1))/sqrt($length);
            return ($result);
        }


