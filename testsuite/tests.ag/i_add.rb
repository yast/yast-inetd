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
#
module Yast
  class IAddClient < Client
    def main
      SCR.RegisterAgent(
        path(".test.inetd"),
        term(:ag_netd, term(:Inetd, WFM.Args(0)))
      )

      @s = Convert.to_list(SCR.Read(path(".test.inetd.services")))
      @ns = {
        # no iid
        "changed"     => true,
        "comment"     => " Dys is mai servis",
        "enabled"     => true,
        "service"     => "finger",
        "socket_type" => "stream",
        "protocol"    => "tcp",
        "wait"        => false,
        "user"        => "nobody",
        "server"      => "/usr/sbin/tcpd",
        "server_args" => "in.fingerd -w"
      }
      @s = Builtins.add(@s, @ns)
      @r = SCR.Write(path(".test.inetd.services"), @s)

      @r
    end
  end
end

Yast::IAddClient.new.main
