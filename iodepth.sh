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

DIR=$(realpath $(dirname "$0"))
source $DIR/common.sh

#IO_DEPTH option is not used in this script
COMMON_OPTS=${COMMON_OPTS/i:}

while getopts "${COMMON_OPTS}n:" opt; do
	parse_common_opt $opt $OPTARG && continue
done

run

post
