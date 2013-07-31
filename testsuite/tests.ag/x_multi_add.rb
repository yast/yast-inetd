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
# adding a service to a multi-file config, #26999
module Yast
  class XMultiAddClient < Client
    def main
      SCR.RegisterAgent(
        path(".test.inetd"),
        term(:ag_netd, term(:Xinetd, WFM.Args(0)))
      )

      @r = Convert.to_list(SCR.Read(path(".test.inetd.services")))
      @service = {
        "changed"     => true,
        "enabled"     => true,
        "service"     => "myservice",
        "socket_type" => "stream",
        "protocol"    => "tcp",
        "wait"        => false,
        "user"        => "root",
        "server"      => "/usr/sbin/myserviced",
        "server_args" => "--foo"
      }
      @r = Builtins.add(@r, @service)
      @result = SCR.Write(path(".test.inetd.services"), @r)

      @result
    end
  end
end

Yast::XMultiAddClient.new.main
