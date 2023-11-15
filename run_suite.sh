#!/bin/bash

GITHUB_CI=${GITHUB_CI:-"false"}
PNG_EXPECT=${PNG_EXPECT:-14}
DIR=$(realpath $(dirname "$0"))

set -e

if [ "${GITHUB_CI}" == "true" ]; then
    pjobs=(1)
    pbs=(512)
else
    pjobs=(1 2 4 8 16 32 64)
    pbs=(512 4k 8k 16k 64k 128k 1M)
fi

OUTDIR=bs_job
mkdir -p $OUTDIR
$DIR/bs.sh "$@" -o $OUTDIR

OUTDIR=latency_job
mkdir -p $OUTDIR
$DIR/latency.sh "$@" -o $OUTDIR

OUTDIR=threads_job
mkdir -p $OUTDIR
$DIR/threads.sh "$@" -o $OUTDIR

for jobs in $pjobs; do
    for bs in $pbs; do
	OUTDIR=iodepth_job_${jobs}_bs_${bs}
	mkdir -p $OUTDIR
	$DIR/iodepth.sh "$@" -b $bs -n $jobs -o $OUTDIR
    done
done

  # During CI testing ensure the appropriate number of non-zero sized
  # PNG files have been created.

if [ "${GITHUB_CI}" == "true" ]; then
    PNG_COUNT=$(find . -name *.png -size +0 | wc -l)
    if [ ${PNG_COUNT} -ne ${PNG_EXPECT} ]; then
	echo "Error in expected number of PNG files (${PNG_COUNT}!=${PNG_EXPECT})"
	exit 1
    fi
fi
