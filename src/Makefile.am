#
# Makefile.am for y2c_inet/src
#
# $Id$
#

clientsdir = $(YAST2DIR)/clients
includedir = $(YAST2DIR)/include/lan_inetd
modulesdir = $(YAST2DIR)/modules

clients_DATA =			\
	lan_inetd.ycp		\
	inetd_auto.ycp		\
	inetd_summary.ycp	\
	inetd_write.ycp

include_DATA =			\
	helps.ycp		\
	ui.ycp

config_DATA = lan_inetd.y2cc

modules_DATA =			\
	Inetd.ycp

bindir = $(YAST2DIR)/bin
bin_SCRIPTS = 			\
	build_inetd_conf_ycp.pl

EXTRA_DIST = $(bin_SCRIPTS) $(clients_DATA) $(include_DATA) $(config_DATA) $(modules_DATA)
