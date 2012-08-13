#!/user/local/bin/perl -w
# run-process-summary.pl -- (c) UT Austin, Lili Qiu, Tue Mar 11 2008
#   <lili@cs.utexas.edu>
#
########################################################

# total throughput
$dir = $ARGV[0];

$metric = 1;
foreach $alg ("summary.qualnet.ETX.MR1.R6.11a.nrl","summary.qualnet.ETX.r1.m2.MR1.R6.11a.rl","summary.qualnet.MORE.MR1.R6.11a.nrl","summary-s1.qualnet.OUR2.p1.r1.m2.MR1.R6.11a.rl","summary.qualnet.MIMO.MR1.R6.11a.nrl")
#foreach $alg ("summary.qualnet.ETX.MR1.R1.11b.nrl", "summary.qualnet.ETX.r1.m2.MR1.R1.11b.rl","summary.qualnet.MORE.MR1.R1.11b.nrl", "summary-s1.qualnet.OUR2.p1.r1.m2.MR1.R1.11b.rl","summary.qualnet.MIMO.MR1.R1.11b.nrl")
{
    $file = "$dir/$alg";
    print "file $file\n";
    next if (!(-e "$file"));
    if ($alg =~ /ETX.r/)
    {
        $shift = 2;
    }
    elsif ($alg =~ /ETX.MR/)
    {
        $shift = 1;
    }
    else
    {
        $shift = 0;
    }
    $cmd = "perl process-summary-unicast.pl $file $shift $metric > $dir/$alg.proc";
    print "$cmd\n";
    system("$cmd");
}

if ( 0 )
{
    # prop. fairness
    foreach $obj ( 3, 4 )
    {
	foreach $metric ( 0, 1 )
	{
	    foreach $alg ("summary.qualnet.ETX.MR1.R6.11a.nrl","summary.qualnet.ETX.r1.m2.MR1.R6.11a.rl","summary.qualnet.MORE.MR1.R6.11a.nrl","summary-s1.qualnet.OUR2.p1.r1.m2.MR1.R6.11a.rl","summary.qualnet.MIMO.MR1.R6.11a.nrl")
#foreach $alg ("summary.qualnet.ETX.MR1.R1.11b.nrl", "summary.qualnet.ETX.r1.m2.MR1.R1.11b.rl","summary.qualnet.MORE.MR1.R1.11b.nrl", "summary-s1.qualnet.OUR2.p1.r1.m2.MR1.R1.11b.rl","summary.qualnet.MIMO.MR1.R1.11b.nrl")   
	    {
		$file = "$dir/$alg";
		next if (!(-e "$file"));
		if ($alg =~ /ETX.r/)
		{
		    $shift = 2;
		}
		elsif ($alg =~ /ETX.MR/)
		{
		    $shift = 1;
		}
		else
		{
		    $shift = 0;
		}
		$cmd = "perl process-summary-unicast.pl $file $shift $metric $obj > $dir/r$obj-$metric/$alg.proc";
		print "$cmd\n";
		system("$cmd");
	    }
	}
    }
}
