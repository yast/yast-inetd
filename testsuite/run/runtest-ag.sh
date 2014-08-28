#! /bin/bash
# $Id$

YCP=$1
IN=$2
OUT_TMP=$3
ERR_TMP=$4
AG=$5

unset Y2DEBUG
unset Y2DEBUGGER
export Y2ALLGLOBAL=1

shopt -s expand_aliases
alias kick-nonerror-lines="grep -v -e ' <[0-2]> '"
alias kick-empty-lines="grep -v '^$'"
alias strip-constant-part="sed 's/^....-..-.. ..:..:.. [^)]*) //g'"
alias mask-line-numbers="sed 's/^\([^ ]* [^)]*):\)[[:digit:]]*/\1XXX/'"

# make a working copy of the file that the agent works with
rm -f "$IN.test"
cp "$IN" "$IN.test" 2> /dev/null
# let liby2 find the agent
AGDIR="`dirname $AG`"
ln -snf . "$AGDIR/servers_non_y2"

#multi
# make working copies of the included files
shopt -s nullglob
mkdir -p tmp/idir
rm -f tmp/idir/*
for INC in ${IN%.in}.*.d.in; do
    INC2=${INC##*/}
    INC2=${INC2#*.}
    cp $INC tmp/idir/${INC2%%.*}
done

# ugly hack to direct logging to stderr even from the agent
# while ycp.pm is unchanged
export HOME=/tmp
ln -snf /dev/stderr $HOME/.y2log

# run it, to $OUT_TMP
Y=/usr/lib/YaST2/bin/y2base
Y2DIR="$AGDIR" $Y -l - 2>&1 >"$OUT_TMP" "$YCP" '("'"$IN.test"'")' testsuite \
    | kick-nonerror-lines \
    | kick-empty-lines \
    | strip-constant-part \
    | mask-line-numbers \
    > "$ERR_TMP"

# add the modified file to $OUT_TMP
cat "$IN.test" >> "$OUT_TMP" 2> /dev/null

#multi
# copy expected output
mkdir -p tmp/idir.exp
rm -f tmp/idir.exp/*
for INC in ${IN%.in}.*.d.out; do
    INC2=${INC##*/}
    INC2=${INC2#*.}
    cp $INC tmp/idir.exp/${INC2%%.*}
done
# diff expected and actual output
diff -urN tmp/idir.exp tmp/idir
