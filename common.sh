

set -e

COMMON_OPTS="b:d:e:f:i:n:r:s:t:x:"
SCRIPT=$(basename "${0%.*}")

export BLOCK_SIZE=512
export IOENGINE=libaio
export OUTDIR=.
export FILENAME=/dev/nvme0n1
export IO_DEPTH=1
export NUM_JOBS=1
export RW_MIX_READ=100
export SIZE=100%
export RUNTIME=10
export FIOEXE=fio

function parse_common_opt {
	case "$1" in
		b)  export BLOCK_SIZE=$2 ;;
		d)  export OUTDIR=$2 ;;
		e)  export IOENGINE=$2 ;;
		f)  export FILENAME=$2 ;;
		i)  export IO_DEPTH=$2 ;;
		n)  export NUM_JOBS=$2 ;;
		r)  export RW_MIX_READ=$2 ;;
		s)  export SIZE=$2 ;;
		t)  export RUNTIME=$2 ;;
		x)  export FIOEXE=$2 ;;
		\?)
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;

		*)  return 1 ;;
	esac

	return 0
}

function check_filename {
	if [ ! -e "$FILENAME" ]; then
		echo "$SCRIPT: You must specify an existing file or block IO device"
		exit 1
	fi

	if [ ! -b "$FILENAME" ]; then
		if [ ! -f "$FILENAME" ]; then
			echo "$SCRIPT: Only block devices or regular files are permitted"
			exit 1
		fi

		if [ ! -r "$FILENAME" ] && [ ! -w "$FILENAME" ]; then
			echo "$SCRIPT: Do not have read and write access to the target file"
			exit 1
		fi
	fi
}

function run {
	cd $OUTDIR

	check_filename

	${DIR}/tools/cpuperf.py -C fio -s -m > ${SCRIPT}.cpu.log &
	CPUPERF_PID=$! ; trap 'kill -9 $CPUPERF_PID' EXIT

	${FIOEXE} ${DIR}/fio-scripts/$SCRIPT.fio ${FIOOPTS} | tee ${SCRIPT}.log

	cd - > /dev/null
}

function post {
	cd $OUTDIR

	${DIR}/pp-scripts/pprocess.py "$@" -m $SCRIPT -c $SCRIPT.log

	cd - > /dev/null
}
