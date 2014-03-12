#
# spec file for package yast2-inetd
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-inetd
Version:        3.1.3
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:	        System/YaST
License:        GPL-2.0
# yast2-2.23.15 - Service module switched to systemd
BuildRequires:	yast2 >= 2.23.15
BuildRequires:	yast2-users perl-XML-Writer update-desktop-files yast2-testsuite
BuildRequires:  yast2-devtools >= 3.1.10
# Wizard::SetDialogTitleAndIcon
Requires:	yast2 >= 2.21.22
Requires:	yast2-packager yast2-users
Conflicts:	yast2-core < 2.17.9

Provides:	yast2-config-inet y2c_inet
Obsoletes:	yast2-config-inet y2c_inet
Provides:	yast2-trans-inet y2t_inet
Obsoletes:	yast2-trans-inet y2t_inet

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - Network Services Configuration

%description
The YaST2 component for configuring the inetd and xinetd daemons.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/inetd
%{yast_yncludedir}/inetd/*
%{yast_clientdir}/inetd*.rb
%{yast_clientdir}/xinetd*.rb
%{yast_moduledir}/Inetd.rb
%{yast_desktopdir}/inetd.desktop
%{yast_schemadir}/autoyast/rnc/inetd.rnc
%doc %dir %{yast_docdir}
%doc %{yast_docdir}/COPYING


%package doc
Group:		System/YaST

Requires:	yast2-inetd
Provides:	yast2-inetd:/usr/share/doc/packages/yast2-inetd/

Summary:	YaST2 - Network Services Configuration

%description doc
The YaST2 component for configuring the inetd and xinetd daemons
(documentation).

%files doc
%defattr(-,root,root)
%doc %{yast_docdir}
%exclude %{yast_docdir}/COPYING
