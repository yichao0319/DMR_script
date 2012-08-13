#!/bin/bash

#echo $1

head_line=$(($1+1))
#echo $head_line

cat composite.txt | head -$head_line | tail -1

