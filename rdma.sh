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

DIR=$(realpath $(dirname "$0"))
source $DIR/common.sh

MODE=server
PORT=12345
HOSTNAME=donard-rdma
VERB=read

while getopts "${COMMON_OPTS}p:h:v:c" opt; do
	parse_common_opt $opt $OPTARG && continue

	case "$opt" in
		p)  export PORT=${OPTARG} ;;
		h)  export HOSTNAME=${OPTARG} ;;
		v)  export VERB=${OPTARG} ;;
	        c)  MODE=client ;;
            ;;
	esac
done

if [ "${MODE}" == "server" ]; then
	if [ ! -z "$FILENAME" ]; then
		check_filename
		export FIOOPTS="--iomem mmap:${FILENAME}"
       fi
fi

${FIOEXE} ${FIOOPTS} ${DIR}/fio-scripts/rdma-${MODE}.fio
