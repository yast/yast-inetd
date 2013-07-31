# encoding: utf-8

# ***************************************************************************
#
# Copyright (c) 2000 - 2012 Novell, Inc.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# ***************************************************************************
# Author: Martin Vidner <mvidner@suse.cz>
# $Id$
# continue from all-services.sh

# See doc/README.maintainer
module Yast
  class DefaultConfCreateClient < Client
    def main
      # cache:
      # server -> package
      @package_cache = {
        # no package specified => assume it is already installed
        ""                          => "", # internal services for xinetd
        # this program is in multiple packages
        # Assume it is already installed, smtp_daemon
        # is required at a very low level
        # (which it is, regardless of the rpm)
        "/usr/sbin/sendmail"        => "",
        # Not present in the distro.
        # So pretend that they _are_ present so that
        # their installation is not attempted
        # TODO: filter them out in the UI
        "/usr/sbin/in.comsat"       => "",
        "/usr/lib/xcept4/bin/ceptd" => "",
        "/usr/sbin/in.midinetd"     => "",
        "/opt/mimer/bin/mimtcp"     => "",
        "/usr/sbin/procstatd"       => "",
        "/usr/sbin/in.ftpd"         => ""
      } # in 9.0 but not 9.1

      # needs ycp.pm,v 1.6
      SCR.RegisterAgent(
        path(".aaa.xinetd"),
        term(:ag_netd, term(:Xinetd, "all-services.conf"))
      )
      @dc_xinetd = Convert.convert(
        SCR.Read(path(".aaa.xinetd.services")),
        :from => "any",
        :to   => "list <map <string, any>>"
      )

      Builtins.y2milestone("xinetd: %1", Builtins.size(@dc_xinetd))

      @dc_xinetd = DeterminePackages(@dc_xinetd)
      # watch out, a single value, not an include
      SCR.Write(path(".target.ycp"), "default_conf_xinetd.ycp", @dc_xinetd)

      SCR.Write(path(".target.string"), "/dev/stdout", "\n")

      nil
    end

    # Log a string and put a dot to stdout
    # @param [String] s string
    def Progress(s)
      Builtins.y2milestone("%1", s)
      SCR.Write(path(".target.string"), "/dev/stdout", ".")

      nil
    end

    # Shortcut for first element of splitstring
    # @param [String] whole a string
    # @param [String] delimiters where to split
    # @return first element
    def first_of_split(whole, delimiters)
      s = Builtins.splitstring(whole, delimiters)
      Ops.get(s, 0, "")
    end

    # @param [String] query will be substituted to --filter '%1'
    # @return a list of packages that match
    def PdbQuery(query)
      cmd = Builtins.sformat(
        "/usr/bin/pdb query --release stable-i386 --filter '%1' --attribs packname 2>/dev/null",
        query
      )
      res = Convert.to_map(SCR.Execute(path(".target.bash_output"), cmd))
      lines = Builtins.filter(
        Builtins.splitstring(Ops.get_string(res, "stdout", ""), "\n")
      ) { |l| l != "" }
      # pdb adds trailing spaces
      Builtins.maplist(lines) { |l| first_of_split(l, " ") }
    end

    # @param [Array<Hash{String => Object>}] services default services list
    # @param xinetd is this xinetd
    # @return services list with "package" determined
    def DeterminePackages(services)
      services = deep_copy(services)
      Builtins.maplist(services) do |service|
        sname = Ops.get_string(service, "service")
        server = Ops.get_string(service, "server", "")
        if server == "/usr/sbin/tcpd"
          server = first_of_split(
            Ops.get_string(service, "server_args", ""),
            " \t"
          )
        end
        # Ask which package has the server. If there are more
        # and it is xinetd, ask which package has the config
        # snippet.
        # Will caching work OK?
        # Xinetd should go first as it can provide more info

        # /usr/sbin for packages run via tcpd
        package = Ops.get(
          @package_cache,
          server,
          Ops.get(@package_cache, Ops.add("/usr/sbin/", server))
        )
        if package == nil
          packages = PdbQuery(Ops.add("rpmfile:*", server))
          if Ops.greater_than(Builtins.size(packages), 1)
            Builtins.y2milestone("Resorting to init script")
            script = Ops.add("xinetd.d/", Ops.get_string(service, "script"))
            packages = PdbQuery(Ops.add("rpmfile:*", script))
          end

          if Builtins.size(packages) != 1
            Builtins.y2error("%1# %2", server, Builtins.size(packages))
          end
          package = Ops.get(packages, 0, "")
          Ops.set(@package_cache, server, package)
        end
        Progress(Builtins.sformat("%1: %2 (%3)", server, package, sname))
        Builtins.add(service, "package", package)
      end
    end
  end
end

Yast::DefaultConfCreateClient.new.main
