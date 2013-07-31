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
# File:	clients/inetd_auto.ycp
# Package:	Configuration of inetd
# Summary:	Client for autoinstallation
# Authors:	Petr Hadraba <phadraba@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# This is a client for autoinstallation. It takes its arguments,
# goes through the configuration and return the setting.
# Does not do any changes to the configuration.

# @param first a map of inetd settings
# @return [Hash] edited settings or an empty map if canceled
# @example map mm = $[ "FAIL_DELAY" : "77" ];
# @example map ret = WFM::CallModule ("inetd_auto", [ mm ]);
module Yast
  class InetdAutoClient < Client
    def main
      Yast.import "UI"

      textdomain "inetd"

      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Xinetd auto started")

      Yast.import "Inetd"
      Yast.import "Service"

      Yast.include self, "inetd/wizards.rb"
      Yast.include self, "inetd/dialogs.rb"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      # kind of constructor
      if !Inetd.autoyast_initialized
        Inetd.Import({})
        Inetd.autoyast_initialized = true
      end

      # Create a summary
      # return string
      if @func == "Summary"
        @ret = Inetd.Summary 
        #ret = select(Inetd::Summary(), 0 , "");
      # Reset configuration
      # return map or list
      elsif @func == "Reset"
        # We can load default during first "Change" call :o)
        Inetd.Import({})
        Inetd.modified = false
        @ret = {}
      # Change configuration
      # return symbol (i.e. `finish || `accept || `next || `cancel || `abort)
      elsif @func == "Change"
        # we do not want to install RPMs in autoinstallation mode...
        Inetd.auto_mode = true
        #    Inetd::Import(param);
        @ret = InetdAutoSequence()
      # Return list of needed packages
      # return map or list
      elsif @func == "Read"
        @po = Progress.set(false)
        @ret = Inetd.Read
        Progress.set(@po)
        Inetd.netd_status = Service.Status("xinetd")
        Inetd.netd_conf = Builtins.maplist(Inetd.netd_conf) do |s|
          Builtins.add(s, "changed", true)
        end
      # Return list of needed packages
      # return map or list
      elsif @func == "Packages"
        @ret = Inetd.AutoPackages
      # Return configuration data
      # return map or list
      elsif @func == "Export"
        @ret = Inetd.Export
      # Return if configuration  was changed
      # return boolean
      elsif @func == "GetModified"
        @ret = Inetd.modified
      # Set modified flag
      # return boolean
      elsif @func == "SetModified"
        Inetd.modified = true
        @ret = true
      # Write configuration data
      # return boolean
      elsif @func == "Write"
        Yast.import "Progress"
        @po = Progress.set(false)
        Inetd.write_only = true
        @ret = Inetd.Write
        Progress.set(@po)
      # Import settings
      # return boolean
      elsif @func == "Import"
        @ret = Inetd.Import(@param)
      else
        Builtins.y2error("unknown function: %1", @func)
        @ret = false
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("Xinetd auto finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::InetdAutoClient.new.main
