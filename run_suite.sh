#!/bin/sh

DIR=$(realpath $(dirname "$0"))

set -e

OUTDIR=bs_job
mkdir -p $OUTDIR
$DIR/bs.sh "$@" -o $OUTDIR

OUTDIR=latency_job
mkdir -p $OUTDIR
$DIR/latency.sh "$@" -o $OUTDIR

OUTDIR=threads_job
mkdir -p $OUTDIR
$DIR/threads.sh "$@" -o $OUTDIR

for jobs in 1 2 4 8 16 32 64; do
    for bs in 512 4k 8k 16k 64k 128k 1M; do
	OUTDIR=iodepth_jobs_${jobs}_bs_${bs}
	mkdir -p $OUTDIR
	$DIR/iodepth.sh "$@" -b $bs -n $jobs -o $OUTDIR
    done
done
