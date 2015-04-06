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

## Quick Start (Latency plot)

1. Ensure fio and python are installed.

