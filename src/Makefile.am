#
# Makefile.am for y2c_inet/src
#

modulesdir = $(YAST2DIR)/clients
menudir = $(YAST2DIR)/menuentries

modules_SCRIPTS = lan_inetd_start.ycp	\
		  lan_inetd_custom.ycp	\
		  lan_inetd.ycp

bindir = $(YAST2DIR)/bin
bin_SCRIPTS = build_inetd_conf_ycp.pl 


menu_SCRIPTS = menuentry_lan_inetd.y2cc

EXTRA_DIST = $(modules_SCRIPTS) $(menu_SCRIPTS) $(bin_SCRIPTS)
