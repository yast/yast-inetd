#! /bin/bash
# $Id$
# required: pdb-commandline.rpm
#
# Find all files in /etc/xinetd.d in the autobuild
# and create a ycp file linking the declared services and the packages
# Currently the format is:
# A list of maps, having the keys "package", "service" and "port"
# and string values
SX=all-services
:> $SX.ycp
exec > $SX.ycp

# no leading slash
DIR=etc/xinetd.d
pdb query --filter "rpmdir:/$DIR" --attribs packname > $SX-pkgs

echo "// A mapping between all available services and rpm packages"
echo -n "// Generated on "
LANG=C date
echo "["
sort $SX-pkgs | while read pkg; do
    rm -f $DIR/*
    rpm2cpio /work/CDs/all/full-i386/suse/*/$pkg.rpm \
	| cpio -idvm --no-absolute-filenames "$DIR/*"
    # Use the agent to parse the config files
    # It has a hack to print "$service\t$port" to stderr
    {
	echo "Xinetd(\"./$SX.conf\")"
	# services-by-package
	echo "Execute(.sbp)"
	echo "result(nil)"
    } | ../agents/ag_netd 2>&1 >/dev/null \
	| sed "s/^/$pkg	&/" \
	| awk '{print "$[\"package\":\"" $1 "\", \"service\":\"" $2 "\", \"protocol\":\"" $3 "\"],"}'
done
echo "]"
rm -f $DIR/*
