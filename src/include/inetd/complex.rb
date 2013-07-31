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
# File:	include/inetd/complex.ycp
# Package:	Configuration of inetd
# Summary:	Dialogs definitions
# Authors:	Petr Hadraba <phadraba@suse.cz>
#
# $Id$
module Yast
  module InetdComplexInclude
    def initialize_inetd_complex(include_target)
      Yast.import "UI"

      textdomain "inetd"

      Yast.import "Wizard"
      Yast.import "Users"

      Yast.import "Inetd"

      Yast.include include_target, "inetd/helps.rb"
      Yast.include include_target, "inetd/routines.rb"
    end

    # Return a modification status
    # @return true if data was modified
    def Modified
      Inetd.Modified
    end

    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      Wizard.SetScreenShotName("inetd-3-read")
      Inetd.AbortFunction = lambda { PollAbort() }
      ret = Inetd.Read
      Users.SetGUI(false)
      Users.Read
      Wizard.RestoreScreenShotName
      ret ? :next : :abort
    end

    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      Wizard.SetScreenShotName("inetd-7-write")
      Inetd.AbortFunction = lambda { PollAbort() }
      ret = Inetd.Write
      Wizard.RestoreScreenShotName
      ret ? :next : :abort
    end
  end
end
