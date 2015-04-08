#!/bin/bash
########################################################################
##
## Copyright 2015 PMC-Sierra, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License"); you
## may not use this file except in compliance with the License. You may
## obtain a copy of the License at
## http://www.apache.org/licenses/LICENSE-2.0 Unless required by
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

  # Parameters for running FIO
DEVICE=/dev/nvme0n1
NUM_JOBS=1
SIZE=1G
IO_DEPTH=1
BLOCK_SIZE=512
COUNT=11024
LAT_LOG=$(basename ${DEVICE})
READ_WRITE="read"

  # Parameters for post-processing
BINS=100
SKIP=1024

  # Accept some key parameter changes from the command line.
while getopts "wn:d:i:" opt; do
    case "$opt" in
	w)  READ_WRITE="write"
            ;;
	n)  NUM_JOBS=${OPTARG}
            ;;
	d)  DEVICE=${OPTARG}
            ;;
	i)  IO_DEPTH=${OPTARG}
            ;;
	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    exit 1
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    exit 1
	    ;;
    esac
done

function cleanup { 
    rm *_slat.*.log *_clat.*.log > /dev/null
    mv ${LAT_LOG}_read_lat.1.log ${LAT_LOG}_read_lat.log
    mv ${LAT_LOG}_write_lat.2.log ${LAT_LOG}_write_lat.log
}

if [ ! -b "$DEVICE" ]; then
     echo "latency.sh: You must specify a block IO device"
     exit 1
fi

DEVICE=${DEVICE} SIZE=${SIZE} NUM_JOBS=${NUM_JOBS} IO_DEPTH=${IO_DEPTH} BLOCK_SIZE=${BLOCK_SIZE} COUNT=${COUNT} \
    LAT_LOG=${LAT_LOG} fio ./fio-scripts/latency.fio
cleanup
./pp-scripts/latency.py -s ${SKIP} -b ${BINS} -c ${LAT_LOG}_${READ_WRITE}_lat.log
