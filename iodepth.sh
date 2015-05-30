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
##     A simple shell script to call the iodepth.fio script with
##     enviroment variables setup and also optionally measure the CPU
##     monitoring tool as an option.
##
########################################################################

  # Parameters for running FIO
FILENAME=/dev/nvme0n1
IOENGINE=libaio
SIZE=16G
NUM_JOBS=1
BLOCK_SIZE=512
RW_MIX_READ=100
RUNTIME=10
FIOEXE=fio

  # Accept some key parameter changes from the command line.
while getopts "x:t:b:r:n:f:i:s:e:" opt; do
    case "$opt" in
	x)  FIOEXE=${OPTARG}
            ;;
	t)  RUNTIME=${OPTARG}
            ;;
	b)  BLOCK_SIZE=${OPTARG}
            ;;
	r)  RW_MIX_READ=${OPTARG}
            ;;
	f)  FILENAME=${OPTARG}
            ;;
	n)  NUM_JOBS=${OPTARG}
            ;;
	s)  SIZE=${OPTARG}
            ;;
	e)  IOENGINE=${OPTARG}
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

if [ ! -e "$FILENAME" ]; then
     echo "iodepth.sh: You must specify an existing file or block IO device"
     exit 1
fi
if [ ! -b "$FILENAME" ]; then
    if [ ! -f "$FILENAME" ]; then
	echo "iodepth.sh: Only block devices or regular files are permitted"
	exit 1
    fi
    if [ ! -r "$FILENAME" ] && [ ! -w "$FILENAME" ]; then
	echo "iodepth.sh: Do not have read and write access to the target file"
	exit 1
    fi
fi

./tools/cpuperf.py -C fio -s -m > iodepth.cpu.log &
CPUPERF_PID=$! ; trap 'kill -9 $CPUPERF_PID' EXIT

FILENAME=${FILENAME} SIZE=${SIZE} NUM_JOBS=${NUM_JOBS} \
    BLOCK_SIZE=${BLOCK_SIZE} RW_MIX_READ=${RW_MIX_READ} \
    IOENGINE=${IOENGINE} RUNTIME=${RUNTIME} \
    ${FIOEXE} ./fio-scripts/iodepth.fio | tee iodepth.log
./pp-scripts/pprocess.py -m iodepth -c iodepth.log

