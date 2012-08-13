#!/usr/bin/perl -w
use ConflictGraphUtil;

my $DEBUG = 1;
my $conflictMultiFile = "conflict-multi.txt";
my $conflictFile = "conflict.txt";

my $isReversePath = $ARGV[0];
my $filename = $ARGV[1];
my $scaleFactor_fwd = $ARGV[2];
my $scaleFactor_rev = $ARGV[3];
my $isMORE = $ARGV[4];
my $default_power = $ARGV[5];
my $default_rate = $ARGV[6];
my $route_metric = $ARGV[7]; # 0 for ETX and 1 for ETT
my $lossFile = $ARGV[8];
my $bidirectional = $ARGV[9]; 
my %mgroupContains;
my %recvIns;
my $mgC;
my $rIns;

my $etxFile = "etx-r$route_metric-b$bidirectional.txt";

$route_metric = 0 if (!defined($route_metric));

## STEP 1: read conflict graph file ##
print "scaleFactor is $scaleFactor_fwd $scaleFactor_rev\n";
my ($graph, $flows);
if ( $isMORE )
{
    $isReversePath = 1;
    ($graph, $flows,$mgC, $rIns)=read_conflict_graph_scale($conflictFile,$scaleFactor_fwd,$route_metric,$bidirectional);
    %mgroupContains=%$mgC;
    %recvIns=%$rIns;
}
else
{
    if ($isReversePath )
    {
	($graph, $flows, $mgC, $rIns)=read_conflict_graph_multi($conflictMultiFile,$scaleFactor_fwd,$scaleFactor_rev,$route_metric,$bidirectional,$lossFile); ## for ack pkt
    }
    else
    {
	($graph,$flows, $mgC, $rIns)=read_conflict_graph_multi($conflictMultiFile,$scaleFactor_fwd,$scaleFactor_rev,$route_metric,$bidirectional,$lossFile); ## for data pkt
    }
    %mgroupContains=%$mgC;
    %recvIns=%$rIns;
}

if ($DEBUG) 
{
    print "mikie mikie\n";
    print "<print graph>\n";
    printGraph($graph);
    print "\n";
    print "<print flows>\n";
    printFlows($flows);
    print "\n";
}

#exit(0);

## STEP 2: compute all flow shortest path
@src_array=();
@dst_array=();

@dst_array =();

foreach $fid (0 .. $flows->{num_flow}-1)
{
    my $t_flow=$flows->{flow}{$fid};
    my $f_src=$t_flow->{src};
    my $f_dst=$t_flow->{dst};
    push @src_array, $f_src;
}

#@root=(0);

@root=(0 .. $graph->{num_node}-1);

($ddist,$ppath)=shortest_path(\@root,$graph);

%path = %$ppath;
%dist = %$ddist;

#exit(0);

&generate_etx_file();

## now,
## path and dist have entries for (from each f_src to all nodes)

remove_files();

my $ucast_fid = 0;
foreach $fid (0 .. $flows->{num_flow}-1)
{
    my $f_src=$src_array[$fid] +0;
    foreach my $f_dst (sort {$a <=> $b} keys %{$mgroupContains{$fid}})
    {
        if ($DEBUG){
            print "FlowID ",$fid,":" ;
            print "[src$f_src "; 
            print "dst$f_dst]\n";	    
        }
        
        if ($isReversePath)
        {
            my @shortest_path=@{$path{$f_dst}{$f_src}};
            print_shortest_path($fid,\@shortest_path);
        }
        else
        {
            my @shortest_path=@{$path{$f_src}{$f_dst}};
            print_shortest_path($ucast_fid,\@shortest_path);    	
        }
        $ucast_fid++;
    }
}

sub generate_etx_file
{
    open(etxFile,">$etxFile");
    foreach my $src ( @root )
    {
        foreach my $fid ( 0 .. $flows->{num_flow}-1 )
        {
            foreach my $f_dst (keys %{$mgroupContains{$fid}})
            {
                print etxFile $src," ",$f_dst," ",$dist{$src}{$f_dst},"\n";
            }
        }
    }       
    close(etxFile);
}

sub remove_files
{
    print "remove $filename\n";
    system("rm -f $filename");   
}

sub print_shortest_path
{
    my ($fid,$shortest_path)=@_;
    system ("echo $filename!!");
    my @shortest_path=@$shortest_path;
    open(SPATH_OUT,">>$filename");
    printf SPATH_OUT "#flowId src dst hopCount nxtHopId power rate nxtHopId power rate ... dst_nodeId\n";
    printf SPATH_OUT "%d 0.0.0.%d 0.0.0.%d %d ",$fid,$shortest_path[0]+1,$shortest_path[$#shortest_path]+1,$#shortest_path;
    foreach $i (0 .. $#shortest_path)
    {
	if ( $i == $#shortest_path)
	{
	    printf SPATH_OUT "0.0.0.%d ",$shortest_path[$i]+1;
	}
	else
	{
	    my $from = $shortest_path[$i];
	    my $to = $shortest_path[$i+1];
	    if(my $edge=$graph->{edges}{"$from $to"})
	    {
		print "from$from $to is $edge->{oetx}\n";
		my ($powerIndex, $macRate);
		if ($isMORE)
		{
		    $powerIndex = $default_power;
		    $macRate = $default_rate;
		}
		else
		{
		    $powerIndex = $edge->{power};
		    $macRate = $edge->{rate};
		}
		printf SPATH_OUT "0.0.0.%d %d %f ",$shortest_path[$i]+1, $powerIndex, $macRate;
	    }
	    else
	    {
		print "WRONG!!!!!!!!!!\n";
		exit(0);
	    }
	}
    }
    printf SPATH_OUT "\n";
    close(SPATH_OUT);
}
