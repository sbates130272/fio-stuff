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

  # Parameters for post-processing
BINS=100
SKIP=10000
CROP=10000

  # Parameters for running FIO
FILENAME=/dev/nvme0n1
NUM_JOBS=1
SIZE=1G
IO_DEPTH=1
BLOCK_SIZE=512
COUNT=$((100000 + ${SKIP} + ${CROP}))
RW_MIX_READ=100

  # Accept some key parameter changes from the command line.
while getopts "r:n:f:i:" opt; do
    case "$opt" in
	r)  RW_MIX_READ=${OPTARG}
            ;;
	n)  NUM_JOBS=${OPTARG}
            ;;
	f)  FILENAME=${OPTARG}
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
LAT_LOG=$(basename ${FILENAME})

function cleanup { 
    rm -f *_slat.*.log *_clat.*.log > /dev/null
    mv ${LAT_LOG}_lat.1.log ${LAT_LOG}.log
}

if [ ! -e "$FILENAME" ]; then
     echo "latency.sh: You must specify an existing file or block IO device"
     exit 1
fi

rm *.log
FILENAME=${FILENAME} SIZE=${SIZE} NUM_JOBS=${NUM_JOBS} IO_DEPTH=${IO_DEPTH} \
    BLOCK_SIZE=${BLOCK_SIZE} COUNT=${COUNT} RW_MIX_READ=${RW_MIX_READ} \
    LAT_LOG=${LAT_LOG} fio ./fio-scripts/latency.fio
cleanup
./pp-scripts/latency.py -k ${CROP} -s ${SKIP} -b ${BINS} -c ${LAT_LOG}.log
