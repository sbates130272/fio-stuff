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
##     A simple shell script to call the rdma-client.fio and
##     rdma-server.fio scripts with enviroment variables setup.
##
########################################################################

  # Parameters for running FIO
MODE=server
FILENAME=
NUM_JOBS=1
SIZE=1G
IO_DEPTH=1
BLOCK_SIZE=512
FIOEXE=fio
RUNTIME=10
PORT=12345
HOSTNAME=donard-rdma
VERB=read

  # Accept some key parameter changes from the command line.
  # Note -z is a hack to save me typing the mmap file all the time ;-).
while getopts "x:t:b:n:f:i:s:p:h:r:mz" opt; do
    case "$opt" in
	x)  FIOEXE=${OPTARG}
            ;;
	t)  RUNTIME=${OPTARG}
            ;;
	b)  BLOCK_SIZE=${OPTARG}
            ;;
	n)  NUM_JOBS=${OPTARG}
            ;;
	f)  FILENAME=${OPTARG}
            ;;
	i)  IO_DEPTH=${OPTARG}
            ;;
	s)  SIZE=${OPTARG}
            ;;
	p)  PORT=${OPTARG}
            ;;
	h)  HOSTNAME=${OPTARG}
            ;;
	v)  VERB=${OPTARG}
            ;;
    m)  MODE=client
            ;;
    z)  FILENAME=/sys/bus/pci/devices/0000:06:00.0/resource4
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

if [ "${MODE}" == "server" ]; then
    if [ -e "$FILENAME" ]; then
        if [ ! -b "$FILENAME" ]; then
            if [ ! -f "$FILENAME" ]; then
	            echo "rdma.sh: Only block devices or regular files are permitted"
	            exit 1
            fi
            if [ ! -r "$FILENAME" ] && [ ! -w "$FILENAME" ]; then
	            echo "rdma.sh: Do not have read and write access to the target file"
	            exit 1
            fi
        fi
        MAP="--iomem mmap:${FILENAME}"
    else
        MAP=
    fi
    echo ${MEMSTR}
    SIZE=${SIZE} NUM_JOBS=${NUM_JOBS} \
        BLOCK_SIZE=${BLOCK_SIZE} PORT=${PORT} IO_DEPTH=${IO_DEPTH} \
        ${FIOEXE} ${MAP} ./fio-scripts/rdma-${MODE}.fio
else
    SIZE=${SIZE} NUM_JOBS=${NUM_JOBS} IO_DEPTH=${IO_DEPTH} \
        BLOCK_SIZE=${BLOCK_SIZE} RUNTIME=${RUNTIME} PORT=${PORT} \
        HOSTNAME=${HOSTNAME} VERB=${VERB} \
        ${FIOEXE} ./fio-scripts/rdma-${MODE}.fio
fi
