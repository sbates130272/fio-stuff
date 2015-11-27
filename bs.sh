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
##     A simple shell script to call the bs.fio script with
##     enviroment variables setup and also optionally measure the CPU
##     monitoring tool as an option.
##
########################################################################

  # Parameters for running FIO
FILENAME=/dev/nvme0n1
IOENGINE=libaio
SIZE=16G
NUM_JOBS=1
IODEPTH=16
RW_MIX_READ=100
RUNTIME=10
FIOEXE=fio

  # Accept some key parameter changes from the command line.
while getopts "x:t:d:r:n:f:i:s:e:" opt; do
    case "$opt" in
	x)  FIOEXE=${OPTARG}
            ;;
	t)  RUNTIME=${OPTARG}
            ;;
	d)  IODEPTH=${OPTARG}
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
     echo "bs.sh: You must specify an existing file or block IO device"
     exit 1
fi
if [ ! -b "$FILENAME" ]; then
    if [ ! -f "$FILENAME" ]; then
	echo "bs.sh: Only block devices or regular files are permitted"
	exit 1
    fi
    if [ ! -r "$FILENAME" ] && [ ! -w "$FILENAME" ]; then
	echo "bs.sh: Do not have read and write access to the target file"
	exit 1
    fi
fi

./tools/cpuperf.py -C fio -s -m > bs.cpu.log &
CPUPERF_PID=$! ; trap 'kill -9 $CPUPERF_PID' EXIT

FILENAME=${FILENAME} SIZE=${SIZE} NUM_JOBS=${NUM_JOBS} \
    IODEPTH=${IODEPTH} RW_MIX_READ=${RW_MIX_READ} \
    IOENGINE=${IOENGINE} RUNTIME=${RUNTIME} \
    ${FIOEXE} ./fio-scripts/bs.fio | tee bs.log
./pp-scripts/pprocess.py -m bs -c bs.log
