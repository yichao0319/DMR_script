#!/bin/sh
if [ $# -eq 1 ]
then
    staticRouteFileName="topo.routes-static"
    rm -f $staticRouteFileName
    echo "writing $staticRouteFileName"
else
    echo "$0 numNodes"
    exit -1;
fi
numNode=$1;
numNode_wOb=$numNode
#numNode_wOb=`expr $numNode + 1`
#nodeId destAddr nextHop outgoingInterf cost
for i in `seq 1 $numNode_wOb`
  do
  for j in `seq 1 $numNode_wOb`
    do
    if [ $i -ne $j ]
	then
	echo "$i  0.0.1.$j  0.0.1.$j  0.0.1.$i  1" >> $staticRouteFileName
    fi
  done
  echo " " >> $staticRouteFileName
done
echo "$staticRouteFileName created!"
