ls *.mp3 |     sed -e "s/\(.*\)/file '\1'/" >  filenames.txt
ffmpeg -f concat -safe 0 -i filenames.txt -c copy output.mp3	
ffmpeg -i output.mp3	 -c:a aac "output-converted.m4a"
mkdir -p m4b
mv "output-converted.m4a" "m4b/output-converted.m4b"
rm output.mp3
rm filenames.txt
