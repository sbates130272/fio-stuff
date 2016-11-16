#!/bin/bash
# Test script for the io-poll additions to the block layer. This
# script takes up to three command line arguments:
# 1. io_poll value (0 or 1), default 1.
# 2. io_poll_delay (integer), default -1.
# 3. numjobs (positive), default 1.

DEVICE=nvme0n1
DEST=/mnt/iopoll-test

IOPOLLEN=${1:-1}
IOPOLLMODE=${2:--1}
IOPOLLFILE=/sys/block/${DEVICE}/queue/io_poll
IOPOLLMODEFILE=/sys/block/${DEVICE}/queue/io_poll_delay
BLKMQDIR=/sys/block/${DEVICE}/mq

  # Setup the filesystem on the test device

umount /dev/${DEVICE}
#mkfs.ext4 -F /dev/${DEVICE}
mount -t ext4 /dev/${DEVICE} ${DEST}
#dd if=/dev/urandom of=${DEST}/iopoll.test bs=1k count=1M
ls -lrth ${DEST}

  # Ensure the CPU scaling is turned off to avoid p-states.

for DIR in /sys/devices/system/cpu/cpu[0-9]*
do
    echo performance > ${DIR}/cpufreq/scaling_governor
done

  # Turn on/off io-polling and run a short fio test. Note that on
  # newer kernels there is a new file called io_poll_delay which also
  # needs to be set.

echo ${IOPOLLEN} > ${IOPOLLFILE}

if [ -e "$IOPOLLMODEFILE" ]
then
    echo ${IOPOLLMODE} > ${IOPOLLMODEFILE}
fi

  # Newer kernels allow us to reset the iopoll counters in each
  # run. We test to see if the stats files are writeable then we can
  # zero the stats.

for DIR in ${BLKMQDIR}/*
do
    if [ -w "${DIR}/io_poll" ]
    then
	echo 0 > ${DIR}/io_poll
    fi
done

touch temp.fio
fio --filename=${DEST}/iopoll.test --size=100% --numjobs=${3:-1} --iodepth=1 \
    --bs=4k --number_ios=100M --runtime=60 --ioengine=pvsync2 --hipri=1 \
    --rw=randrw --random_generator=lfsr --direct=1 --group_reporting=1 \
    --rwmixread=100 --loops=1 --name temp.fio
rm -f temp.fio

  # Report on each of the queues in blk-my

echo "Results:"
echo ${IOPOLLFILE}
cat ${IOPOLLFILE}
if [ -e "$IOPOLLMODEFILE" ]
then
    echo ${IOPOLLMODEFILE}
    cat ${IOPOLLMODEFILE}
fi
for DIR in ${BLKMQDIR}/*
do
    cat ${DIR}/io_poll
done
