#!/usr/bin/env bash 
set -v

function process() {
	FILENAME=$1
	SUBDIR=$2
	echo "$FILENAME output to $SUBDIR"
	whisper --model tiny --output_dir $SUBDIR $FILENAME
}

DIRNAME=`pwd`
FILES=`find $DIRNAME -name \*.mp4`
for f in $FILES
do 
	echo "Processing $f"
	subdir=${f%%.mp4}
	if [ ! -d "$subdir" ]; then
		process $f $subdir
	else
		echo "$subdir already exists"
	fi
done
