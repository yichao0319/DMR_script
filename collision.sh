#!/bin/bash

echo "collision"
#cat tmp.out.txt | grep "node 1: all receiving: collision" | wc -l
#cat tmp.out.txt | grep "node 2: all receiving: collision" | wc -l
#cat tmp.out.txt | grep "node 3: all receiving: collision" | wc -l
#cat tmp.out.txt | grep "node 4: all receiving: collision" | wc -l
#cat tmp.out.txt | grep "node 5: all receiving: collision" | wc -l
cat tmp.out.txt | grep "node 6: all receiving: collision" | wc -l

echo "trigger - trigger"
#cat tmp.out.txt | grep "node 1: all receiving: collision" | grep "type40" | grep -v "type32" | wc -l
#cat tmp.out.txt | grep "node 2: all receiving: collision" | grep "type40" | grep -v "type32" | wc -l
#cat tmp.out.txt | grep "node 3: all receiving: collision" | grep "type40" | grep -v "type32" | wc -l
#cat tmp.out.txt | grep "node 4: all receiving: collision" | grep "type40" | grep -v "type32" | wc -l
#cat tmp.out.txt | grep "node 5: all receiving: collision" | grep "type40" | grep -v "type32" | wc -l
cat tmp.out.txt | grep "node 6: all receiving: collision" | grep "type40" | grep -v "type32" | wc -l

echo "node2,3: trigger - trigger"
#cat tmp.out.txt | grep "node 1: all receiving: collision" | grep "src2 type40" | grep "src3 type40" | wc -l
#cat tmp.out.txt | grep "node 4: all receiving: collision" | grep "src2 type40" | grep "src3 type40" | wc -l
#cat tmp.out.txt | grep "node 5: all receiving: collision" | grep "src2 type40" | grep "src3 type40" | wc -l
cat tmp.out.txt | grep "node 6: all receiving: collision" | grep "src2 type40" | grep "src3 type40" | wc -l

echo "trigger - data"
#cat tmp.out.txt | grep "node 1: all receiving: collision" | grep "type32" | grep "type40" | wc -l
#cat tmp.out.txt | grep "node 2: all receiving: collision" | grep "type32" | grep "type40" | wc -l
#cat tmp.out.txt | grep "node 3: all receiving: collision" | grep "type32" | grep "type40" | wc -l
#cat tmp.out.txt | grep "node 4: all receiving: collision" | grep "type32" | grep "type40" | wc -l
#cat tmp.out.txt | grep "node 5: all receiving: collision" | grep "type32" | grep "type40" | wc -l
cat tmp.out.txt | grep "node 6: all receiving: collision" | grep "type32" | grep "type40" | wc -l

echo "node2,3: trigger - data"
#cat tmp.out.txt | grep "node 1: all receiving: collision" | grep "type32" | grep "type40" | grep "src2" | grep "src3" | wc -l
#cat tmp.out.txt | grep "node 2: all receiving: collision" | grep "type32" | grep "type40" | grep "src2" | grep "src3" | wc -l
#cat tmp.out.txt | grep "node 3: all receiving: collision" | grep "type32" | grep "type40" | grep "src2" | grep "src3" | wc -l
#cat tmp.out.txt | grep "node 4: all receiving: collision" | grep "type32" | grep "type40" | grep "src2" | grep "src3" | wc -l
#cat tmp.out.txt | grep "node 5: all receiving: collision" | grep "type32" | grep "type40" | grep "src2" | grep "src3" | wc -l
cat tmp.out.txt | grep "node 6: all receiving: collision" | grep "type32" | grep "type40" | grep "src2" | grep "src3" | wc -l

echo "data - data"
#cat tmp.out.txt | grep "node 1: all receiving: collision" | grep "type32" | grep -v "type40" | wc -l
#cat tmp.out.txt | grep "node 2: all receiving: collision" | grep "type32" | grep -v "type40" | wc -l
#cat tmp.out.txt | grep "node 3: all receiving: collision" | grep "type32" | grep -v "type40" | wc -l
#cat tmp.out.txt | grep "node 4: all receiving: collision" | grep "type32" | grep -v "type40" | wc -l
#cat tmp.out.txt | grep "node 5: all receiving: collision" | grep "type32" | grep -v "type40" | wc -l
cat tmp.out.txt | grep "node 6: all receiving: collision" | grep "type32" | grep -v "type40" | wc -l

echo "node2, 3: data - data"
#cat tmp.out.txt | grep "node 1: all receiving: collision" | grep "type32" | grep -v "type40" | grep "src2" | grep "src3" | wc -l
#cat tmp.out.txt | grep "node 2: all receiving: collision" | grep "type32" | grep -v "type40" | grep "src2" | grep "src3" | wc -l
#cat tmp.out.txt | grep "node 3: all receiving: collision" | grep "type32" | grep -v "type40" | grep "src2" | grep "src3" | wc -l
#cat tmp.out.txt | grep "node 4: all receiving: collision" | grep "type32" | grep -v "type40" | grep "src2" | grep "src3" | wc -l
#cat tmp.out.txt | grep "node 5: all receiving: collision" | grep "type32" | grep -v "type40" | grep "src2" | grep "src3" | wc -l
cat tmp.out.txt | grep "node 6: all receiving: collision" | grep "type32" | grep -v "type40" | grep "src2" | grep "src3" | wc -l

echo "node4, 5: data - data"
#cat tmp.out.txt | grep "node 1: all receiving: collision" | grep "type32" | grep -v "type40" | grep "src4" | grep "src5" | wc -l
#cat tmp.out.txt | grep "node 2: all receiving: collision" | grep "type32" | grep -v "type40" | grep "src4" | grep "src5" | wc -l
#cat tmp.out.txt | grep "node 3: all receiving: collision" | grep "type32" | grep -v "type40" | grep "src4" | grep "src5" | wc -l
#cat tmp.out.txt | grep "node 4: all receiving: collision" | grep "type32" | grep -v "type40" | grep "src4" | grep "src5" | wc -l
#cat tmp.out.txt | grep "node 5: all receiving: collision" | grep "type32" | grep -v "type40" | grep "src4" | grep "src5" | wc -l
cat tmp.out.txt | grep "node 6: all receiving: collision" | grep "type32" | grep -v "type40" | grep "src4" | grep "src5" | wc -l

