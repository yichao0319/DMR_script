#!/bin/bash

#cat topo.credit.s1 | awk -F" " '{if($9 > 0) {print $0;}}'

cat topo.credit.s1 | awk -F" " '{if($9 > 0) {print $0;}}' | awk -F" " '{if($9 > 0) {print $0; system("./cat.link.sh "$5); system("./cat.link.sh "$6);}}'

