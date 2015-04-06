#!/bin/bash
#
# A simple shell script to call the latency.fio script with enviroment
# variables setup.

DEVICE=/dev/nvme0n1
SIZE=1G
IO_DEPTH=1
BLOCK_SIZE=512
COUNT=10k
LAT_LOG=$(basename ${DEVICE})

function cleanup { 
    rm *_slat.*.log *_clat.*.log > /dev/null
} 

DEVICE=${DEVICE} SIZE=${SIZE} IO_DEPTH=1 BLOCK_SIZE=${BLOCK_SIZE} COUNT=${COUNT} \
    LAT_LOG=${LAT_LOG} fio ./fio-scripts/latency.fio

cleanup