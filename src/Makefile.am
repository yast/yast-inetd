#
# Makefile.am for devtools/devtools/skeletons/config/src
#

# copied from runlevel
#crude:
TAGS_DEPENDENCIES = *.ycp
ETAGS_ARGS = $(TAGS_DEPENDENCIES)

yncludedir = @yncludedir@/inetd

client_DATA =			\
	inetd.ycp		\
	inetd_auto.ycp	        \
	inetd_proposal.ycp

# all-services to be removed
ydata_DATA =                    \
	default_conf_inetd.ycp  \
	default_conf_xinetd.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp		\
	routines.ycp

desktop_DATA =			\
	inetd.desktop

module_DATA =			\
	Inetd.ycp

include $(top_srcdir)/Makefile.am.common

inetd:
	ln -sf . inetd

ycpchook = inetd

YCPCFLAGS=-I.


EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(ydata_DATA) $(desktop_DATA)
