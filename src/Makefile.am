#
# Makefile.am for y2c_inet/src
#
# $Id$
#

yncludedir = @yncludedir@/inetd

client_DATA =			\
	inetd.ycp		\
	inetd_auto.ycp		\
	inetd_summary.ycp	\
	inetd_write.ycp

ynclude_DATA =			\
	helps.ycp		\
	ui.ycp

config_DATA = inetd.y2cc

module_DATA =			\
	Inetd.ycp

ybin_SCRIPTS = 			\
	build_inetd_conf_ycp.pl

EXTRA_DIST = $(ybin_SCRIPTS) $(client_DATA) $(ynclude_DATA) $(config_DATA) $(module_DATA)
