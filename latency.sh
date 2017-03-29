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

DIR=$(realpath $(dirname "$0"))
source $DIR/common.sh

BINS=100
SKIP=10000
CROP=10000

export COUNT=100000

while getopts "${COMMON_OPTS}c:p" opt; do
	parse_common_opt $opt $OPTARG && continue

	case "$opt" in
		c)  export COUNT=${OPTARG} ;;
		p)  export FIOOPTS="--ioengine=pvsync2 --hipri"
		    export IOENGINE=pvsync2
		    ;;
	esac
done

export LAT_LOG=$(basename ${FILENAME})
export COUNT=$((${COUNT} + ${SKIP} + ${CROP}))

run

rm -f *_slat.*.log *_clat.*.log > /dev/null
mv ${LAT_LOG}_lat.1.log ${SCRIPT}.log

post -k ${CROP} -s ${SKIP} -b ${BINS}
