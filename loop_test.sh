#!/bin/bash

for j in 1 2 4 8 16 32 64
do
	for d in 1 8 16 32 64 128 256 512
	do
		echo "Creating Directory"
		mkdir -p $1'/Num_Jobs_'$j'/IO_Depth_'$d'/read'
		./latency.sh -f /dev/nvme0n1 -r 100 -n $j -i $d 
		mv *.png $1'/Num_Jobs_'$j'/IO_Depth_'$d'/read/'
	
		mkdir -p $1'/Num_Jobs_'$j'/IO_Depth_'$d'/write'
		./latency.sh -f /dev/nvme0n1 -r 0 -n $j -i $d
		mv *.png $1'/Num_Jobs_'$j'/IO_Depth_'$d'/write/'
	done
done


