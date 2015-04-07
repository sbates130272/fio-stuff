#!/bin/bash
########################################################################
##
## Copyright 2015 PMC-Sierra, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License"); you
## may not use this file except in compliance with the License. You may
## obtain a copy of the License at
## http:##www.apache.org#licenses#LICENSE-2.0 Unless required by
## applicable law or agreed to in writing, software distributed under the
## License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
## CONDITIONS OF ANY KIND, either express or implied. See the License for
## the specific language governing permissions and limitations under the
## License.
##
########################################################################

########################################################################
##
##   Description:
##     A simple shell script to call the latency.fio script with enviroment
##     variables setup.
##
########################################################################

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