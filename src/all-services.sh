#! /bin/bash
# $Id$
# required: pdb-commandline.rpm
#
# Find all files in /etc/xinetd.d in the autobuild
# and create a ycp file linking the declared services and the packages
# Currently the format is:
# A list of maps, having the keys "package", "service", "port", "program"
# and string values
# Program is the base name. It is the real program, not tcpd.

SX=all-services
:> $SX.ycp
exec > $SX.ycp

# no leading slash
DIR=etc/xinetd.d
pdb query --filter "rpmdir:/$DIR" --attribs packname > $SX-pkgs

echo "// A mapping between all available services and rpm packages"
echo "// Author: Martin Vidner <mvidner@suse.cz>"
echo "// \$Id\$"
echo -n "// Generated on "
LANG=C date
echo "["
sort $SX-pkgs | while read pkg; do
    mv -f $DIR/* $DIR.bak
    rpm2cpio /work/CDs/all/full-i386/suse/*/$pkg.rpm \
	| cpio -idvm --no-absolute-filenames "$DIR/*"
    # Use the agent to parse the config files
    # It has a hack to print "$service,$port,$program" to fd3
    {
	echo "Xinetd(\"./$SX.conf\")"
	# services-by-package
	echo "Execute(.sbp)"
	echo "result(nil)"
    } | ../agents/ag_netd 3>&1 >/dev/null \
	| sed "s/^/$pkg,&/" \
	| awk -F, '{print "$[\"package\":\"" $1 "\", \"service\":\"" $2 "\", \"protocol\":\"" $3 "\", \"program\":\"" $4 "\"],"}'
done
echo "]"
mv -f $DIR/* $DIR.bak
