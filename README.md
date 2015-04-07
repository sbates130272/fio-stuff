# fio-stuff
Some tools and scripts related to Jens Axboe's Flexible IO (fio) tester

## Setup

Make sure you have fio on your path somewhere. Most distros have RPMs
for it or you can grab the source and install it yourself from
https://github.com/axboe/fio. 

To run the post-processing scripts you will need python.

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

1. Ensure fio is installed and on the path.
2. cd into top-level folder.
3. Check that the defaults in ./fio-scripts/latency.sh are to you
liking and match your system.
4. sudo ./fio-scripts/latency.sh [NB you may not need sudo depending
on permissions]. 
5. This should create two file called ${DEVICE}_read_lat.1.log and
${DEVICE}_write_lat.1.log. 
6. The log file currently consist of 4 columns as explained in the fio
HOWTO. These are time, latency (us), direction (0=read), size (B).