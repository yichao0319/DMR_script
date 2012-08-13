#!/bin/perl 


my %tmp = ();

print "defined\n" if(defined($tmp{"a"}));
print "not defined\n" if(!defined($tmp{"a"}));

$tmp{"a"} = 10;

print "defined\n" if(defined($tmp{"a"}));
print "not defined\n" if(!defined($tmp{"a"}));

delete $tmp{"a"};

print "defined\n" if(defined($tmp{"a"}));
print "not defined\n" if(!defined($tmp{"a"}));


