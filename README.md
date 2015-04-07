# fio-stuff
Some tools and scripts related to Jens Axboe's Flexible IO (fio) tester

## Copyright

Copyright 2015 PMC-Sierra, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You may
obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0 Unless required by
applicable law or agreed to in writing, software distributed under the
License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for
the specific language governing permissions and limitations under the
License.

## Setup

Make sure you have fio on your path somewhere. Most distros have
binaries for it or you can grab the source and install it yourself
from https://github.com/axboe/fio. 

To run the post-processing scripts you will need python and gnuplot. I
have tested using python 2.6.6 and gnuplot 4.2 but the code is
generic enought that other versions should work. Send pull requests if
you see issues.

## Directory Structure

### fio-scripts

Contains some useful FIO scripts that I use for different
purposes. Some of the more variable fields in these files are
environment variables which can either be set by running the
defaults.sh script or altered to suit your needs. Also for each .fio
script there is an (optional) .sh script that calls the .fio in a
certain loop.

### pp-scripts

A range of post-processing scripts that either parse fio output or
things like the latency files to generate interesting datasets for
plotting.

## Quick Start (Latency)

1. Ensure fio, python and gunplot are installed and on your path.
2. cd into top-level folder (fio-stuff by default).
3. Check that the defaults in ./latency.sh are to your liking and
match your system.
4. sudo ./latency.sh -d <device> -i <iodepth> [NB you may not need
sudo depending on permissions]. Note that device needs to be a block
device. Add a -w for write latency plots, the default is for read
latency plots.  
5. This should create two file called ${DEVICE}_read_lat.1.log and
${DEVICE}_write_lat.2.log and two file called latency.time.png and
latency.cdf.png. 
6. The .log files currently consist of 4 columns as explained in the fio
HOWTO. These are time, latency (us), direction (0=read), size (B).
7. latency.time.png is a time series plot of the measured
latency. latency.cdf.png is a plot of the CDF of the measured
latency. Both files can be viewed using any reasonable image viewer.

## Updates

This code is open-source, we welcome patches and pull requests against
this codebase. You are under no obligation to submit code back to us
but we are hoping you will ;-).
