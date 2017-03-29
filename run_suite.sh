#!/bin/sh

DIR=$(realpath $(dirname "$0"))

$DIR/bs.sh "$@" -d .
$DIR/latency.sh "$@" -d .
$DIR/threads.sh "$@" -d .

for jobs in 1 2 4 8 16 32 64; do
        for bs in 512 4k 8k 16k 64k 128k 1M; do
	OUTDIR=iodepth_jobs_${jobs}_bs_${bs}
	mkdir -p $OUTDIR
	$DIR/iodepth.sh "$@" -b $bs -n $jobs -d $OUTDIR
	done
done
