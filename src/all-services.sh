#! /bin/bash
# $Id$
# required: pdb-commandline.rpm
#

# generate default_conf_{inet,xinetd}.ycp, as required by
# http://w3.suse.de/~kkaempf/yast2/planning/descr/improvement_24.html
# by
# - querying PDB for all config files
# - extracting them all
# - running the agent (for inetd, xinetd)
# - for each program, quering the PDB which RPM it is in

SX=default_conf

# $1: package name
# $2: file (wildcard) to extract
function extract() {
    echo "$1" "$2" >&2
    # rpm3: etc/foo, rpm4: ./etc/foo
    rpm2cpio /work/CDs/all/full-i386/suse/*/$1.rpm \
	| cpio -idvm --no-absolute-filenames "./$2" "$2"
}

extract inetd  etc/inetd.conf
extract xinetd etc/xinetd.conf

# no leading slash
DIR=etc/xinetd.d
pdb query --filter "rpmdir:/$DIR" --attribs packname > $SX-pkgs

mv -f $DIR/* $DIR.bak
sort $SX-pkgs | while read pkg; do
    extract $pkg "$DIR/*"
done

#proceed in YCP:
/sbin/yast2 $SX_create.ycp

