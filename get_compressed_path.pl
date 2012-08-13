#!/usr/bin/perl -w
use ConflictGraphUtil;
use strict;

my $conflictMultiFile = "conflict-multi.txt";
my $filename1 = $ARGV[0]; # filename for spp-multicast
my $filename2 = $ARGV[1]; # filename for topo.static-route
my $route_metric = $ARGV[2]; # 0 for ETX and 1 for ETT
my $lossFile = $ARGV[3];
my $bidirectional = $ARGV[4];
my $scaleFactor_fwd = $ARGV[5];
my $scaleFactor_rev = $ARGV[6];

my %mgroupContains=();
my %recvIns;
my %compress_tree=();

$route_metric = 0 if (!defined($route_metric));

my $etxFile = "etx-r$route_metric-b$bidirectional.txt";

my ($graph,$flows, $mgC, $rIns)=read_conflict_graph_multi($conflictMultiFile,$scaleFactor_fwd,$scaleFactor_rev,$route_metric, $bidirectional, $lossFile); ## for data pkt
%mgroupContains=%$mgC;
%recvIns=%$rIns;


my @root = (0 .. $graph->{num_node} - 1);
my ($ddist, $ppath) = shortest_path(\@root, $graph);
my %path = %$ppath;
my %dist = %$ddist;

&generate_etx_file();

foreach my $fid (0 .. $flows->{num_flow}-1)
{
    my $t_flow=$flows->{flow}{$fid};
    my $f_src=$t_flow->{src};

    foreach my $d (keys %{$mgroupContains{$fid}})
    {
	print "d is $d\n";
	my @sp = @{$path{$f_src}{$d}};
	foreach my $index ( 0 .. $#sp )
	{
	    my $current = $sp[$index];
	    my $previous;
	    my $next;
	    if ($index > 0 ){ 
		$previous = $sp[$index-1];
	    }else{
		$previous = $current;
	    }
	    if ($index < $#sp ){
		$next = $sp[$index+1];
	    }else{
		$next = $current;
	    }
	    $compress_tree{$fid}{$current}{$previous}{$next} = 1;
	}
    }   
}

open (SPPMCASTFILEOUT, ">$filename1");
printf SPPMCASTFILEOUT "##flowId senderId prevHopId nextDstSize nextDst1 nextDst2 ...\n";

open (STATICROUTE, ">$filename2");
printf STATICROUTE "##flowId src dst hopCount nextHopId power rate nextHopId2 power rate ... dstId\n";

foreach my $fid ( keys %compress_tree )
{
    foreach my $current ( keys %{$compress_tree{$fid}} )
    {
	my $currentId = $current + 1;
	foreach my $previous ( keys %{$compress_tree{$fid}{$current}})
	{
	    my $previousId = $previous + 1;
	    printf SPPMCASTFILEOUT "$fid $currentId $previousId ";
	    my $num_next = keys %{$compress_tree{$fid}{$current}{$previous}};
	    printf SPPMCASTFILEOUT "$num_next ";

	    foreach my $next ( keys %{$compress_tree{$fid}{$current}{$previous}})
	    {
		my $nextId = $next + 1;		
		printf SPPMCASTFILEOUT "$nextId ";

		if ( $current != $next )
		{
		    my $edge = $graph->{edges}{"$current $next"};
		    my $powerIndex =  $edge->{power};
		    my $macRate = $edge->{rate};
		    printf STATICROUTE "$fid 0.0.0.$currentId 0.0.0.$nextId 1 0.0.0.$currentId $powerIndex $macRate 0.0.0.$nextId\n";
		}
	    }
	    printf SPPMCASTFILEOUT "\n";
	}
    }
}

close (SPPMCASTFILEOUT);
close (STATICROUTE);


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
