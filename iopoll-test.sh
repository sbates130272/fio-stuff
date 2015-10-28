#!/bin/bash
# Test script for the io-poll additions to the block layer.

DEVICE=nvme0n1
DEST=/tmp/batesste

IOPOLLEN=1
IOPOLLFILE=/sys/block/${DEVICE}/queue/io_poll
BLKMQDIR=/sys/block/${DEVICE}/mq

  # Setup the filesystem on the test device

umount /dev/${DEVICE}
mkfs.ext4 -F /dev/${DEVICE}
mount -t ext4 /dev/${DEVICE} ${DEST}
dd if=/dev/urandom of=${DEST}/iopoll.test bs=1k count=1024
ls -lrth ${DEST}

  # Turn on/off io-polling and run a short fio test

echo ${IOPOLLEN} > ${IOPOLLFILE}


touch temp.fio
fio --filename=${DEST}/iopoll.test --size=100% --numjobs=1 --iodepth=1 \
    --bs=4k --number_ios=1000 --runtime=10 --ioengine=sync --rw=randrw \
    --random_generator=lfsr --direct=1 --group_reporting=1 \
    --rwmixread=100 --loops=1 --name temp.fio
rm -f temp.fio

  # Report on each of the queues in blk-my

echo "Results:"
echo ${IOPOLLFILE}
cat ${IOPOLLFILE}
for DIR in ${BLKMQDIR}/*
do
    cat ${DIR}/io_poll
done
