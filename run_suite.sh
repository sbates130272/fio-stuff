#!/bin/sh

DIR=$(realpath $(dirname "$0"))

set -e

$DIR/bs.sh "$@" -o .
$DIR/latency.sh "$@" -o .
$DIR/threads.sh "$@" -o .

for jobs in 1 2 4 8 16 32 64; do
    for bs in 512 4k 8k 16k 64k 128k 1M; do
	OUTDIR=iodepth_jobs_${jobs}_bs_${bs}
	mkdir -p $OUTDIR
	echo $DIR/iodepth.sh "$@" -b $bs -n $jobs -o $OUTDIR
    done
done
