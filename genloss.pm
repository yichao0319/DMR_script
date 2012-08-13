#! /usr/bin/perl -w
eval 'exec /usr/bin/perl -S $0 "$*"'
    if undef;

package genloss;

### export

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(generate_fish generate_cross generate_tree generate_5node_ratecontrol generate_6node_iaware generate_spear generate_tophat generate_diamond generate_diamond2 generate_diamond_2rate generate_3hop_linear generate_4hop_linear generate_3hop_linear_rate_6 generate_triangle generate_ballcap generate_2hop_linear generate_2hop_linear_2rate generate_1hop_linear generate_9node_tree generate_6node generate_8node generate_8node_3parallel);
@EXPORT_OK = qw(1);
### sub routine prototype

sub generate_6node($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;
    
    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0; #0.2; #0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0; #0.2; #0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 0; #0.6; #0;
            $lossMulti->{2}{0}{$pid}{$rate} = 0; #0.6; #0;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{0}{4}{$pid}{$rate} = 1;
            $lossMulti->{4}{0}{$pid}{$rate} = 1;

            $lossMulti->{0}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{0}{$pid}{$rate} = 1;

            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{1}{$pid}{$rate} = 1;

            $lossMulti->{2}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{2}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{2}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{2}{$pid}{$rate} = 1;

            $lossMulti->{3}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{3}{$pid}{$rate} = 0;
            
            $lossMulti->{3}{5}{$pid}{$rate} = 0;
            $lossMulti->{5}{3}{$pid}{$rate} = 0;
            
            $lossMulti->{4}{5}{$pid}{$rate} = 0;
            $lossMulti->{5}{4}{$pid}{$rate} = 0;
        }
    }
}

sub generate_8node($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;
    
    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{0}{4}{$pid}{$rate} = 1;
            $lossMulti->{4}{0}{$pid}{$rate} = 1;

            $lossMulti->{0}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{0}{$pid}{$rate} = 1;

            $lossMulti->{0}{6}{$pid}{$rate} = 1;
            $lossMulti->{6}{0}{$pid}{$rate} = 1;

            $lossMulti->{0}{7}{$pid}{$rate} = 1;
            $lossMulti->{7}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{1}{$pid}{$rate} = 1;

            $lossMulti->{1}{6}{$pid}{$rate} = 1;
            $lossMulti->{6}{1}{$pid}{$rate} = 1;

            $lossMulti->{1}{7}{$pid}{$rate} = 1;
            $lossMulti->{7}{1}{$pid}{$rate} = 1;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{2}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{2}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{2}{$pid}{$rate} = 1;

            $lossMulti->{2}{6}{$pid}{$rate} = 1;
            $lossMulti->{6}{2}{$pid}{$rate} = 1;

            $lossMulti->{2}{7}{$pid}{$rate} = 1;
            $lossMulti->{7}{2}{$pid}{$rate} = 1;
            
            $lossMulti->{3}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{3}{$pid}{$rate} = 0;
            
            $lossMulti->{3}{5}{$pid}{$rate} = 0;
            $lossMulti->{5}{3}{$pid}{$rate} = 0;

            $lossMulti->{3}{6}{$pid}{$rate} = 0;
            $lossMulti->{6}{3}{$pid}{$rate} = 0;

            $lossMulti->{3}{7}{$pid}{$rate} = 1;
            $lossMulti->{7}{3}{$pid}{$rate} = 1;
            
            $lossMulti->{4}{5}{$pid}{$rate} = 0;
            $lossMulti->{5}{4}{$pid}{$rate} = 0;

            $lossMulti->{4}{6}{$pid}{$rate} = 0;
            $lossMulti->{6}{4}{$pid}{$rate} = 0;

            $lossMulti->{4}{7}{$pid}{$rate} = 1;
            $lossMulti->{7}{4}{$pid}{$rate} = 1;
            
            $lossMulti->{5}{6}{$pid}{$rate} = 0;
            $lossMulti->{6}{5}{$pid}{$rate} = 0;
            
            $lossMulti->{5}{7}{$pid}{$rate} = 0;
            $lossMulti->{7}{5}{$pid}{$rate} = 0;

            $lossMulti->{6}{7}{$pid}{$rate} = 0;
            $lossMulti->{7}{6}{$pid}{$rate} = 0;
        }
    }
}

sub generate_8node_3parallel($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;
    
    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{4}{$pid}{$rate} = 1;
            $lossMulti->{4}{0}{$pid}{$rate} = 1;

            $lossMulti->{0}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{0}{$pid}{$rate} = 1;

            $lossMulti->{0}{6}{$pid}{$rate} = 1;
            $lossMulti->{6}{0}{$pid}{$rate} = 1;

            $lossMulti->{0}{7}{$pid}{$rate} = 1;
            $lossMulti->{7}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{5}{$pid}{$rate} = 0;
            $lossMulti->{5}{1}{$pid}{$rate} = 0;

            $lossMulti->{1}{6}{$pid}{$rate} = 0;
            $lossMulti->{6}{1}{$pid}{$rate} = 0;

            $lossMulti->{1}{7}{$pid}{$rate} = 1;
            $lossMulti->{7}{1}{$pid}{$rate} = 1;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{2}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{2}{5}{$pid}{$rate} = 0;
            $lossMulti->{5}{2}{$pid}{$rate} = 0;

            $lossMulti->{2}{6}{$pid}{$rate} = 0;
            $lossMulti->{6}{2}{$pid}{$rate} = 0;

            $lossMulti->{2}{7}{$pid}{$rate} = 1;
            $lossMulti->{7}{2}{$pid}{$rate} = 1;
            
            $lossMulti->{3}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{3}{$pid}{$rate} = 0;
            
            $lossMulti->{3}{5}{$pid}{$rate} = 0;
            $lossMulti->{5}{3}{$pid}{$rate} = 0;

            $lossMulti->{3}{6}{$pid}{$rate} = 0;
            $lossMulti->{6}{3}{$pid}{$rate} = 0;

            $lossMulti->{3}{7}{$pid}{$rate} = 1;
            $lossMulti->{7}{3}{$pid}{$rate} = 1;
            
            $lossMulti->{4}{5}{$pid}{$rate} = 0;
            $lossMulti->{5}{4}{$pid}{$rate} = 0;

            $lossMulti->{4}{6}{$pid}{$rate} = 0;
            $lossMulti->{6}{4}{$pid}{$rate} = 0;

            $lossMulti->{4}{7}{$pid}{$rate} = 0;
            $lossMulti->{7}{4}{$pid}{$rate} = 0;
            
            $lossMulti->{5}{6}{$pid}{$rate} = 0;
            $lossMulti->{6}{5}{$pid}{$rate} = 0;
            
            $lossMulti->{5}{7}{$pid}{$rate} = 0;
            $lossMulti->{7}{5}{$pid}{$rate} = 0;

            $lossMulti->{6}{7}{$pid}{$rate} = 0;
            $lossMulti->{7}{6}{$pid}{$rate} = 0;
        }
    }
}

sub generate_5node_ratecontrol($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;
    
    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0.9;
            $lossMulti->{2}{1}{$pid}{$rate} = 1;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 0.9;
            $lossMulti->{3}{1}{$pid}{$rate} = 1;
            
            $lossMulti->{3}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{3}{$pid}{$rate} = 0;

            $lossMulti->{2}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{2}{$pid}{$rate} = 0;
        }
    }
}

sub generate_6node_iaware($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;
    
    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{5}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{5}{$pid}{$rate} = 0;
            
            $lossMulti->{5}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{5}{$pid}{$rate} = 0;
            
            $lossMulti->{5}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{5}{$pid}{$rate} = 0;
            
            $lossMulti->{5}{0}{$pid}{$rate} = 0;
            $lossMulti->{0}{5}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{2}{$pid}{$rate} = 0;
            
            
            $lossMulti->{1}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{2}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{3}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{3}{$pid}{$rate} = 0;
        }
    }
}

sub generate_9node_tree($$$)
{
    my($lossMulti, $numPowerLevel, $allRates) = @_;
    
    foreach my $pid ( 0 .. $numPowerLevel - 1 )
    {
	foreach my $rate ( keys %{$allRates} )
	{
	    $lossMulti->{0}{1}{$pid}{$rate} = 0;
	    $lossMulti->{0}{2}{$pid}{$rate} = 1;
	    $lossMulti->{0}{3}{$pid}{$rate} = 1;
	    $lossMulti->{0}{4}{$pid}{$rate} = 1;
	    $lossMulti->{0}{5}{$pid}{$rate} = 0;
	    $lossMulti->{0}{6}{$pid}{$rate} = 1;
	    $lossMulti->{0}{7}{$pid}{$rate} = 1;
	    $lossMulti->{0}{8}{$pid}{$rate} = 1;

	    $lossMulti->{1}{2}{$pid}{$rate} = 0;
	    $lossMulti->{1}{3}{$pid}{$rate} = 1;
	    $lossMulti->{1}{4}{$pid}{$rate} = 1;
	    $lossMulti->{1}{5}{$pid}{$rate} = 1;
	    $lossMulti->{1}{6}{$pid}{$rate} = 1;
	    $lossMulti->{1}{7}{$pid}{$rate} = 1;
	    $lossMulti->{1}{8}{$pid}{$rate} = 1;
	    $lossMulti->{1}{0}{$pid}{$rate} = 0;

	    $lossMulti->{2}{0}{$pid}{$rate} = 1;
	    $lossMulti->{2}{1}{$pid}{$rate} = 0;
	    $lossMulti->{2}{3}{$pid}{$rate} = 0;
	    $lossMulti->{2}{4}{$pid}{$rate} = 0;
	    $lossMulti->{2}{5}{$pid}{$rate} = 1;
	    $lossMulti->{2}{6}{$pid}{$rate} = 1;
	    $lossMulti->{2}{7}{$pid}{$rate} = 1;
	    $lossMulti->{2}{8}{$pid}{$rate} = 1;

	    $lossMulti->{3}{0}{$pid}{$rate} = 1;
	    $lossMulti->{3}{1}{$pid}{$rate} = 1;
	    $lossMulti->{3}{2}{$pid}{$rate} = 0;
	    $lossMulti->{3}{4}{$pid}{$rate} = 1;
	    $lossMulti->{3}{5}{$pid}{$rate} = 1;
	    $lossMulti->{3}{6}{$pid}{$rate} = 1;
	    $lossMulti->{3}{7}{$pid}{$rate} = 1;
	    $lossMulti->{3}{8}{$pid}{$rate} = 1;

	    $lossMulti->{4}{0}{$pid}{$rate} = 1;
	    $lossMulti->{4}{1}{$pid}{$rate} = 1;
	    $lossMulti->{4}{2}{$pid}{$rate} = 0;
	    $lossMulti->{4}{3}{$pid}{$rate} = 1;
	    $lossMulti->{4}{5}{$pid}{$rate} = 1;
	    $lossMulti->{4}{6}{$pid}{$rate} = 1;
	    $lossMulti->{4}{7}{$pid}{$rate} = 1;
	    $lossMulti->{4}{8}{$pid}{$rate} = 1;

	    $lossMulti->{5}{0}{$pid}{$rate} = 0;
	    $lossMulti->{5}{1}{$pid}{$rate} = 1;
	    $lossMulti->{5}{2}{$pid}{$rate} = 1;
	    $lossMulti->{5}{3}{$pid}{$rate} = 1;
	    $lossMulti->{5}{4}{$pid}{$rate} = 1;
	    $lossMulti->{5}{6}{$pid}{$rate} = 0;
	    $lossMulti->{5}{7}{$pid}{$rate} = 1;
	    $lossMulti->{5}{8}{$pid}{$rate} = 1;

	    $lossMulti->{6}{0}{$pid}{$rate} = 1;
	    $lossMulti->{6}{1}{$pid}{$rate} = 1;
	    $lossMulti->{6}{2}{$pid}{$rate} = 1;
	    $lossMulti->{6}{3}{$pid}{$rate} = 1;
	    $lossMulti->{6}{4}{$pid}{$rate} = 1;
	    $lossMulti->{6}{5}{$pid}{$rate} = 0;
	    $lossMulti->{6}{7}{$pid}{$rate} = 0;
	    $lossMulti->{6}{8}{$pid}{$rate} = 0;

	    $lossMulti->{7}{0}{$pid}{$rate} = 1;
	    $lossMulti->{7}{1}{$pid}{$rate} = 1;
	    $lossMulti->{7}{2}{$pid}{$rate} = 1;
	    $lossMulti->{7}{3}{$pid}{$rate} = 1;
	    $lossMulti->{7}{4}{$pid}{$rate} = 1;
	    $lossMulti->{7}{5}{$pid}{$rate} = 1;
	    $lossMulti->{7}{6}{$pid}{$rate} = 0;
	    $lossMulti->{7}{8}{$pid}{$rate} = 1;

	    $lossMulti->{8}{0}{$pid}{$rate} = 1;
	    $lossMulti->{8}{1}{$pid}{$rate} = 1;
	    $lossMulti->{8}{2}{$pid}{$rate} = 1;
	    $lossMulti->{8}{3}{$pid}{$rate} = 1;
	    $lossMulti->{8}{4}{$pid}{$rate} = 1;
	    $lossMulti->{8}{5}{$pid}{$rate} = 1;
	    $lossMulti->{8}{6}{$pid}{$rate} = 0;
	    $lossMulti->{8}{7}{$pid}{$rate} = 1;

	}
    }
}

sub generate_cross($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{2}{4}{$pid}{$rate} = 0;
            $lossMulti->{4}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{3}{5}{$pid}{$rate} = 0;
            $lossMulti->{5}{3}{$pid}{$rate} = 0;
            
            $lossMulti->{4}{5}{$pid}{$rate} = 0;
            $lossMulti->{5}{4}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 1;
            $lossMulti->{2}{1}{$pid}{$rate} = 1;
            
            $lossMulti->{3}{4}{$pid}{$rate} = 1;
            $lossMulti->{4}{3}{$pid}{$rate} = 1;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 1;
            $lossMulti->{0}{4}{$pid}{$rate} = 1;
            $lossMulti->{0}{5}{$pid}{$rate} = 1;
            $lossMulti->{3}{0}{$pid}{$rate} = 1;
            $lossMulti->{4}{0}{$pid}{$rate} = 1;
            $lossMulti->{5}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{1}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{1}{$pid}{$rate} = 1;
            
            $lossMulti->{2}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{2}{$pid}{$rate} = 1;
        }
    }
}

sub generate_tree($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0; # 0.5;
            $lossMulti->{1}{0}{$pid}{$rate} = 0; # 0.5;

            $lossMulti->{0}{2}{$pid}{$rate} = 0; # 0.5;
            $lossMulti->{2}{0}{$pid}{$rate} = 0; # 0.5;

            $lossMulti->{0}{3}{$pid}{$rate} = 0; # 0.5;
            $lossMulti->{3}{0}{$pid}{$rate} = 0; # 0.5;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{2}{$pid}{$rate} = 0;
            
        }
    }
}

sub generate_diamond_2rate($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        $rate = 12;
        $lossMulti->{0}{1}{$pid}{$rate} = 0; # 0.5;
        $lossMulti->{1}{0}{$pid}{$rate} = 0; # 0.5;
        
        $lossMulti->{1}{2}{$pid}{$rate} = 1;
        $lossMulti->{2}{1}{$pid}{$rate} = 1;
        
        $lossMulti->{0}{3}{$pid}{$rate} = 1;
        $lossMulti->{3}{0}{$pid}{$rate} = 1;
        
        $lossMulti->{2}{3}{$pid}{$rate} = 0; # 0.95; # 0.75;
        $lossMulti->{3}{2}{$pid}{$rate} = 0; # 0.95; # 0.75;
        
        $lossMulti->{0}{2}{$pid}{$rate} = 0; # 0.5;
        $lossMulti->{2}{0}{$pid}{$rate} = 0; # 0.5;
        
        $lossMulti->{1}{3}{$pid}{$rate} = 0; # 0.95; # 0.75;
        $lossMulti->{3}{1}{$pid}{$rate} = 0; # 0.95; # 0.75;

        $rate = 6;
        $lossMulti->{0}{1}{$pid}{$rate} = 0; # 0.25;
        $lossMulti->{1}{0}{$pid}{$rate} = 0; # 0.25;

        $lossMulti->{1}{2}{$pid}{$rate} = 1;
        $lossMulti->{2}{1}{$pid}{$rate} = 1;

        $lossMulti->{0}{3}{$pid}{$rate} = 1;
        $lossMulti->{3}{0}{$pid}{$rate} = 1;

        $lossMulti->{2}{3}{$pid}{$rate} = 0;
        $lossMulti->{3}{2}{$pid}{$rate} = 0;

        $lossMulti->{0}{2}{$pid}{$rate} = 0; # 0.25;
        $lossMulti->{2}{0}{$pid}{$rate} = 0; # 0.25;

        $lossMulti->{1}{3}{$pid}{$rate} = 0;
        $lossMulti->{3}{1}{$pid}{$rate} = 0;
        
    }
}

sub generate_diamond($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0; #0.5;
            $lossMulti->{1}{0}{$pid}{$rate} = 0; #0.5;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 0; #0.5;
            $lossMulti->{2}{0}{$pid}{$rate} = 0; #0.5;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{1}{$pid}{$rate} = 0;
        }
    }
}

sub generate_tophat($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0.6;
            $lossMulti->{2}{1}{$pid}{$rate} = 0.6;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 1;
            $lossMulti->{2}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{1}{$pid}{$rate} = 0;

            $lossMulti->{4}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{4}{$pid}{$rate} = 0;

            $lossMulti->{4}{2}{$pid}{$rate} = 0.6;
            $lossMulti->{2}{4}{$pid}{$rate} = 0.6;

            $lossMulti->{1}{4}{$pid}{$rate} = 1;
            $lossMulti->{4}{1}{$pid}{$rate} = 1;

            $lossMulti->{0}{4}{$pid}{$rate} = 1;
            $lossMulti->{4}{0}{$pid}{$rate} = 1;

            $lossMulti->{4}{5}{$pid}{$rate} = 0;
            $lossMulti->{5}{4}{$pid}{$rate} = 0;    

	    $lossMulti->{5}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{5}{$pid}{$rate} = 1;

            $lossMulti->{5}{2}{$pid}{$rate} = 1;
            $lossMulti->{2}{5}{$pid}{$rate} = 1;

            $lossMulti->{1}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{1}{$pid}{$rate} = 1;

            $lossMulti->{0}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{0}{$pid}{$rate} = 1;

	}
    }
}


sub generate_spear($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 1;
            $lossMulti->{2}{1}{$pid}{$rate} = 1;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{1}{$pid}{$rate} = 0;

            $lossMulti->{4}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{4}{$pid}{$rate} = 0;

            $lossMulti->{4}{2}{$pid}{$rate} = 1;
            $lossMulti->{2}{4}{$pid}{$rate} = 1;

            $lossMulti->{1}{4}{$pid}{$rate} = 1;
            $lossMulti->{4}{1}{$pid}{$rate} = 1;

            $lossMulti->{0}{4}{$pid}{$rate} = 1;
            $lossMulti->{4}{0}{$pid}{$rate} = 1;

            $lossMulti->{4}{5}{$pid}{$rate} = 0;
            $lossMulti->{5}{4}{$pid}{$rate} = 0;    

	    $lossMulti->{5}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{5}{$pid}{$rate} = 1;

            $lossMulti->{5}{2}{$pid}{$rate} = 1;
            $lossMulti->{2}{5}{$pid}{$rate} = 1;

            $lossMulti->{1}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{1}{$pid}{$rate} = 1;

            $lossMulti->{0}{5}{$pid}{$rate} = 1;
            $lossMulti->{5}{0}{$pid}{$rate} = 1;

	}
    }
}

sub generate_diamond2($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

        foreach my $pid ( 0 .. $numPowerLevel-1 )
        {
            foreach my $rate (keys %{$allRates} )
            {
                $lossMulti->{0}{1}{$pid}{$rate} = 0;
                $lossMulti->{1}{0}{$pid}{$rate} = 0;

                $lossMulti->{1}{2}{$pid}{$rate} = 0;
                $lossMulti->{2}{1}{$pid}{$rate} = 0;

                $lossMulti->{0}{3}{$pid}{$rate} = 1;
                $lossMulti->{3}{0}{$pid}{$rate} = 1;

                $lossMulti->{2}{3}{$pid}{$rate} = 0.25;
                $lossMulti->{3}{2}{$pid}{$rate} = 0.25;

                $lossMulti->{0}{2}{$pid}{$rate} = 0;
                $lossMulti->{2}{0}{$pid}{$rate} = 0;

                $lossMulti->{1}{3}{$pid}{$rate} = 0.5;
                $lossMulti->{3}{1}{$pid}{$rate} = 0.5;
            }
        }
}

sub generate_2hop_linear($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            
            $lossMulti->{0}{1}{$pid}{$rate} = 0; #0.5;
            $lossMulti->{1}{0}{$pid}{$rate} = 0; #0.5;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 1;
            $lossMulti->{2}{0}{$pid}{$rate} = 1;
        }
    }
}

sub generate_2hop_linear_2rate($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;
    
    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            
            $lossMulti->{0}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;

            if ($rate == 6)
            {
                $lossMulti->{0}{2}{$pid}{$rate} = 0.5;
                $lossMulti->{2}{0}{$pid}{$rate} = 0.5;
            }
            else
            {
                $lossMulti->{0}{2}{$pid}{$rate} = 0.75;
                $lossMulti->{2}{0}{$pid}{$rate} = 0.75;
            }
        }
    }
}

sub generate_1hop_linear($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0;#0.5;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;#0.5;
        }
    }
}


sub generate_triangle($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0.5;
            $lossMulti->{1}{0}{$pid}{$rate} = 0.5;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 0.75;
            $lossMulti->{2}{0}{$pid}{$rate} = 0.75;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0.75;
            $lossMulti->{3}{2}{$pid}{$rate} = 0.75;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 0.5;
            $lossMulti->{3}{1}{$pid}{$rate} = 0.5;
        }
    }
}


sub generate_ballcap($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 0.75;
            $lossMulti->{2}{0}{$pid}{$rate} = 0.75;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{1}{$pid}{$rate} = 1;
        }
    }
}


sub generate_fish($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0.5;
            $lossMulti->{1}{0}{$pid}{$rate} = 0.5;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 1;
            $lossMulti->{2}{1}{$pid}{$rate} = 1;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 0.5;
            $lossMulti->{2}{0}{$pid}{$rate} = 0.5;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0.5;
            $lossMulti->{3}{2}{$pid}{$rate} = 0.5;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 0.5;
            $lossMulti->{3}{1}{$pid}{$rate} = 0.5;

	    $lossMulti->{2}{4}{$pid}{$rate} = 0.5;
            $lossMulti->{4}{2}{$pid}{$rate} = 0.5;
            
            $lossMulti->{0}{4}{$pid}{$rate} = 1;
            $lossMulti->{4}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{1}{4}{$pid}{$rate} = 0.5;
            $lossMulti->{4}{1}{$pid}{$rate} = 0.5;

            $lossMulti->{4}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{4}{$pid}{$rate} = 1;
        }
    }
}


sub generate_4hop_linear($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 0.5;
            $lossMulti->{2}{0}{$pid}{$rate} = 0.5;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{1}{$pid}{$rate} = 1;

	    $lossMulti->{2}{4}{$pid}{$rate} = 0.5;
            $lossMulti->{4}{2}{$pid}{$rate} = 0.5;
            
            $lossMulti->{0}{4}{$pid}{$rate} = 1;
            $lossMulti->{4}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{1}{4}{$pid}{$rate} = 1;
            $lossMulti->{4}{1}{$pid}{$rate} = 1;

            $lossMulti->{4}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{4}{$pid}{$rate} = 0;
        }
    }
}


sub generate_3hop_linear($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
            $lossMulti->{0}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = 1;
            #$lossMulti->{0}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{0}{$pid}{$rate} = 1;
            #$lossMulti->{2}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{2}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{2}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 1;
            #$lossMulti->{0}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{0}{$pid}{$rate} = 1;
            #$lossMulti->{3}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 1;
            #$lossMulti->{1}{3}{$pid}{$rate} = 0;
            $lossMulti->{3}{1}{$pid}{$rate} = 1;
            #$lossMulti->{3}{1}{$pid}{$rate} = 0;
        }
    }
}

sub generate_3hop_linear_rate_6($$$)
{
    my($lossMulti,$numPowerLevel,$allRates) = @_;

    foreach my $pid ( 0 .. $numPowerLevel-1 )
    {
        foreach my $rate (keys %{$allRates} )
        {
	    my ($loss,$loss2);
	    if ($rate == 6 )
	    {
		$loss = 0.5;
		$loss2 = 0;
	    }
	    else
	    {
		$loss = 0.5;
		$loss2 = 0.5;
	    }

            $lossMulti->{0}{1}{$pid}{$rate} = 0;
            $lossMulti->{1}{0}{$pid}{$rate} = 0;
            
            $lossMulti->{1}{2}{$pid}{$rate} = 0;
            $lossMulti->{2}{1}{$pid}{$rate} = 0;
            
            $lossMulti->{0}{2}{$pid}{$rate} = $loss;
            $lossMulti->{2}{0}{$pid}{$rate} = $loss;
            
            $lossMulti->{2}{3}{$pid}{$rate} = $loss2;
            $lossMulti->{3}{2}{$pid}{$rate} = $loss2;
            
            $lossMulti->{0}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{0}{$pid}{$rate} = 1;
            
            $lossMulti->{1}{3}{$pid}{$rate} = 1;
            $lossMulti->{3}{1}{$pid}{$rate} = 1;
        }
    }
}
