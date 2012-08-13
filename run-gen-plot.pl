#!/user/local/bin/perl -w
# run-process-summary.pl -- (c) UT Austin, Lili Qiu, Tue Mar 11 2008
#   <lili@cs.utexas.edu>
#
########################################################

print "set terminal postscript eps 28\n";

print "set pointsize 2\n";
# print "set key top left Left;\n";
print "set xlabel \"# Flows\";\n";
print "set ylabel \"Total throughput (Mbps)\";\n";

@name = ("ETX wo/ RL", "ETX w/ RL", "MORE", "Optimized OR", "DMR");

$fig_dir = "results/Figs";
system("mkdir $fig_dir");

foreach $obj ( 1 ) # 3, 4 )
{
    foreach $topo ( "grid-6Mbps-dist100" )
# ( "rand-6Mbps-dist100", "grid-6Mbps-dist100", "rand-6Mbps-dist100", "grid-6Mbps-dist100" )
    {
	foreach $mac ( 1 ) # 0, 1
	{
	    $dir = "results/$topo-mac$mac/r$obj";

	    if ($obj == 1)
	    {
		print "set key top left Left;\n";
	    }
	    else
	    {
		print "set key bottom left Left;\n";
		# print "set logscale y\n";
	    }
	    #print "set output \"$fig_dir/$topo.eps\"\n";
	    print "set output \"$fig_dir/$topo-mac$mac-r$obj.eps\"\n";
	    print "plot [:20][] ";
	    $index = 0;
	    foreach $alg ("summary.qualnet.ETX.MR1.R6.11a.nrl","summary.qualnet.ETX.r$obj.m2.MR1.R6.11a.rl","summary.qualnet.MORE.MR1.R6.11a.nrl", "summary-s1.qualnet.OUR2.p1.r$obj.m2.MR1.R6.11a.rl", "summary.qualnet.MIMO.MR1.R6.11a.nrl")
	    {
		$index++;
		$data_file = "$dir/$alg.proc";
		# next if (!(-e "$data_file"));
		$routeName = $name[$index-1];
		print "\"$data_file\" using 2:3:4 t \"$routeName\" with errorbars, \"$data_file\" using 2:3 t \"\" with lines lw 4";
		if ($index == 5)
		{
		    print "\n";
		}
		else
		{
		    print ",";
		}
	    }
	}
    }
}
