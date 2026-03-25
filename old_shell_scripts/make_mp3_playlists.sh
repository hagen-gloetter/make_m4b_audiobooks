#! /bin/bash
STARTPFAD=${1:-"/audio/Alben"}
IFS="
"   #  initial Field separator auf crlf umdefinieren"
echo "$0 in $STARTPFAD gestartet"
for album in `cd $STARTPFAD ; ls -1` ;
do
  if test -d $STARTPFAD/$album; then
    echo "bearbeite $STARTPFAD/$album/ "
    cd "$STARTPFAD/$album/"
    find  -name "*[Mm][pP]3" | sort --ignore-case --ignore-leading-blanks --ignore-nonprinting --general-numeric-sort > \!_playlist.m3u
  fi
done
  echo "bearbeite $STARTPFAD "
  cd $STARTPFAD
  find  -name "*[Mm][pP]3" | sort --ignore-case --ignore-leading-blanks --ignore-nonprinting --general-numeric-sort > \!_playlist.m3u
echo "DONE"
