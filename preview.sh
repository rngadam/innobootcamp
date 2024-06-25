#!/usr/bin/env bash 
set -v

function process() {
	FILENAME=$1
	ffmpeg -hide_banner -loglevel error -i $FILENAME \
		-vf "select=bitor(gte(t-prev_selected_t\,10)\,isnan(prev_selected_t))" \
		-vsync 0 $FILENAME.%d.jpg
	montage -mode concatenate $FILENAME.*.jpg $FILENAME.jpg
	rm $FILENAME.*.jpg
}

DIRNAME=`pwd`
FILES=`find $DIRNAME -name \*.mp4`
for f in $FILES
do 
	echo "Processing $f"
	if [ ! -f "$f.jpg" ]; then
		process $f
	else
		echo "$f.jpg already exists"
	fi
done
