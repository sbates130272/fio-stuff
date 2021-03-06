#!/bin/bash
# Test script for the io-poll additions to the block layer.

# This script takes up to three command line arguments:
# 1. Polling block device to target.
# 2. numjobs (positive), default 1.
# 3. Use FILE on FS (1) or use raw block device (0).
# 4. io_poll value (0 or 1), default 1.
# 5. io_poll_delay (integer (-1=>always, 0=>hybrid,>0=>delay before
#    polling), default -1. Note some early kernels do not use this
#    value. 
#
# Note that there have been a few changes to the sysfs/debugfs
# locations of some of the polling entires are this work as
# matured. This script detects which locations are operational and
# adapts accordigly.
#
# WARNING: By default this script reformats the target block
# device. You will lose data if you are not careful!!

set -e

DEVICE=${1:-nvme1n1}
NUMJOBS=${2:-1}
FILE_EN=${3:-0}
IOPOLL_EN=${4:-1}
IOPOLL_MODE=${5:--1}
HIPRI=${6:-100}

IOPOLL_FILE=/sys/block/${DEVICE}/queue/io_poll
IOPOLL_MODE_FILE=/sys/block/${DEVICE}/queue/io_poll_delay
SCHED_FILE=/sys/block/${DEVICE}/queue/scheduler

MOUNT=/mnt/iopoll-test
TEST_FILE=test.data

print_queue()
{
    if [ -f $2 ]; then
	result=`grep -i "=0" $2 | wc -l`
    fi
    if [[ "$result" -ne 3 ]]; then
	echo "Results for queue $1..."
	cat $2
    else
	echo "Skipped results for queue $1..."
    fi
}

if [ -e /sys/block/${DEVICE}/mq/0/io_poll ]; then
    BLKMQ_STATS_DIR=/sys/block/${DEVICE}/mq
    BLKMQ_PSTATS_DIR=/sys/block/${DEVICE}/mq
elif [ -e /sys/kernel/debug/block/${DEVICE}/mq/0/io_poll ]; then
    BLKMQ_STATS_DIR=/sys/kernel/debug/block/${DEVICE}/mq
    BLKMQ_PSTATS_DIR=/sys/kernel/debug/block/${DEVICE}/mq
elif [ -e /sys/kernel/debug/block/${DEVICE}/hctx0/io_poll ]; then
    BLKMQ_STATS_DIR=/sys/kernel/debug/block/${DEVICE}/hctx
    BLKMQ_PSTATS_DIR=/sys/kernel/debug/block/${DEVICE}
else
    echo "Could not determine IO polling stats location!"
    exit 1
fi

  # Setup the filesystem on the test device if FILE_EN is not
  # zero. Note we use EXT4 and a fixed file size for testing. We
  # check to see if the drive is mounted and if so we unmount.

if grep -qs ${MOUNT} /proc/mounts; then
    umount /dev/${DEVICE}
fi
if [ "$FILE_EN" -ne "0" ]; then
    DEST=${MOUNT}/${TEST_FILE}
    mkfs.ext4 -F /dev/${DEVICE}
    mkdir -p ${MOUNT}
    mount -t ext4 /dev/${DEVICE} ${MOUNT}
    dd if=/dev/urandom of=${DEST} bs=1k count=1k
    ls -lrth ${DEST}
else
    DEST=/dev/$DEVICE
fi

echo "Running iopoll=test on $DEST..."

  # Ensure the CPU scaling is turned off to avoid p-states when
  # applicable.

for DIR in /sys/devices/system/cpu/cpu[0-9]*
do
    if [ -e ${DIR}/cpufreq/scaling_governor ]; then
	echo performance > ${DIR}/cpufreq/scaling_governor
    fi
done

  # Ensure the scheduler is set to none for these tests. This seems to
  # be especially important in QEMU testing where the scheduler
  # services all the IO. Need to understand exactly why that is.

echo none > ${SCHED_FILE}

  # Turn on/off io-polling and run a short fio test. Note that on
  # newer kernels there is a new file called io_poll_delay which also
  # needs to be set.

echo ${IOPOLL_EN} > ${IOPOLL_FILE}

if [ -e "$IOPOLL_MODE_FILE" ]
then
    echo ${IOPOLL_MODE} > ${IOPOLL_MODE_FILE}
else
    echo "Error, could not locate $IOPOLL_MODE_FILE"
    exit -1
fi

  # Newer kernels allow us to reset the iopoll counters in each
  # run. We test to see if the stats files are writeable then we can
  # zero the stats.

bfirst=1;
for DIR in ${BLKMQ_STATS_DIR}*
do
    if [ -e "${DIR}/io_poll" ]
    then
	if [ -w "${DIR}/io_poll" ]
	then
	    if (($bfirst == 1)); then
		echo "zeroing io_poll counters..."
		bfirst=0;
	    fi
	    echo 0 > ${DIR}/io_poll
	else
	    if (($bfirst ==1)); then
		echo "Cannot zero io_poll counters..."
		bfirst = 0;
	    fi
	fi
    else
	echo "Error, could not locate ${DIR}/io_poll"
	exit -1
    fi
done

touch temp.fio
set +e
fio --filename=${DEST} --size=100% --numjobs=${NUMJOBS} --iodepth=1 \
    --bs=512 --number_ios=100M --runtime=6 --ioengine=pvsync2 --hipri=$HIPRI \
    --rw=randrw --random_generator=lfsr --direct=1 --group_reporting=1 \
    --rwmixread=100 --loops=1 --name temp.fio
set -e
rm -f temp.fio

  # Report on each of the queues...

echo "Results (--highpri=${HIPRI}):"
echo ${IOPOLL_FILE}
cat ${IOPOLL_FILE}
if [ -e "$IOPOLL_MODE_FILE" ]
then
    echo ${IOPOLL_MODE_FILE}
    cat ${IOPOLL_MODE_FILE}
fi
echo ${SCHED_FILE}
cat ${SCHED_FILE}
if [ -e ${BLKMQ_PSTATS_DIR}/poll_stat ]; then
    echo ${BLKMQ_PSTATS_DIR}/poll_stat
    cat ${BLKMQ_PSTATS_DIR}/poll_stat
fi
queue=0
set +e
for DIR in ${BLKMQ_STATS_DIR}*
do
    print_queue $queue ${DIR}/io_poll
    queue=$((queue+ 1))
done
if [ -e /sys/kernel/debug/block/${DEVICE}/state ]; then
    echo /sys/kernel/debug/block/${DEVICE}/state
    cat /sys/kernel/debug/block/${DEVICE}/state
fi
