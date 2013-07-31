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
# re-reading used to keep the old list :-(
module Yast
  class XDoubleClient < Client
    def main
      SCR.RegisterAgent(
        path(".test.inetd"),
        term(:ag_netd, term(:Xinetd, WFM.Args(0)))
      )

      @s = []
      # read it twice
      @s = Convert.to_list(SCR.Read(path(".test.inetd.services")))
      @s = Convert.to_list(SCR.Read(path(".test.inetd.services")))

      deep_copy(@s)
    end
  end
end

Yast::XDoubleClient.new.main
