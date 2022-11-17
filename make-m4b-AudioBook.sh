#! /bin/bash

# written by hagen glötter in 2020
# contact hagen@gloetter.de

#for i in *.mp3 ; do ffmpeg -i  "$i" -c:a aac -strict experimental -b:a 128k -vsync 2 -f mp4 "$i.m4b" ; done
#for i in *.mp3 ; do ffmpeg -i  "$i" -c:a aac -strict experimental  -vsync 2 -f mp4 "$i.m4b" ; done
#for i in *mp3 ; do ffmpeg -i $i -c:a aac -b:a 64k $i.m4b ; done
#ffmpeg -i "concat:*.mp3|input1.mp3|input2.mp3" -c:a libfdk_aac -b:a 128k -f mp4 output.m4b

# variables
i=0
green='\033[0;32m'
reset='\033[0m'
output_file="output/output.mp3"

mkdir -p input
mkdir -p output

echo "Combining the following audiobook parts: "
for audiobook in *.mp3; do
	# get audiobook name without the input prefix
	name="${audiobook#"input/"}"

	# get the filename without the extension
	filename="${name%.*}"

	# concat parts file into a single string for
	if [[ $i -lt 1 ]]; then
		parts="${audiobook}"
	else
		parts="$parts|${audiobook}"
	fi
	echo "${name}"
	(( i++ ))
done
echo "Ready to combine and convert to m4b (y/n)? "
read -r response
if echo "$response" | grep -iq "^y" ;
then
	echo "Combining audiobook parts... "
	ffmpeg -i concat:"${parts}" -acodec copy $output_file

	if [ -f "$output_file" ]
	then
		echo "Converting mp3 to m4a... "
#		ffmpeg -i "${output_file}" -c:a aac "output/${filename}-converted.m4a" # does no more work ??
#		ffmpeg -i "${output_file}" "output/${filename}-converted.aac"
		ffmpeg -i "${output_file}" -map a:0 -c:a aac -strict experimental -b:a 128k -f mp4 "output/${filename}-converted.m4b"
		if [[ -f "output/${filename}-converted.aac" ]]; then
			echo "Renaming .aac to .m4b... "
#			rm -rf ${output_file}
#			mv "output/${filename}-converted.aac" "output/${filename}-converted.m4b"
#			mkdir mp3
#			mv *.mb4 mb4/
			echo " Finished"
		fi
	fi
fi

