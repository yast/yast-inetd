# Sources for inetd

module_DATA = \
  modules/Inetd.rb

client_DATA = \
  clients/inetd.rb \
  clients/inetd_auto.rb \
  clients/xinetd.rb \
  clients/inetd_proposal.rb

yncludedir = @yncludedir@/inetd
ynclude_DATA = \
  include/inetd/default_conf_xinetd.rb \
  include/inetd/wizards.rb \
  include/inetd/dialogs.rb \
  include/inetd/complex.rb \
  include/inetd/routines.rb \
  include/inetd/helps.rb

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/inetd.rnc

desktop_DATA = \
  desktop/inetd.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(schemafiles_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common