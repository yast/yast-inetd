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
# File:	clients/inetd_proposal.ycp
# Package:	Configuration of inetd
# Summary:	Proposal function dispatcher.
# Authors:	Petr Hadraba <phadraba@suse.cz>
#
# $Id$
#
# Proposal function dispatcher for inetd configuration.
module Yast
  class InetdProposalClient < Client
    def main

      textdomain "inetd"

      Yast.import "Inetd"
      Yast.import "Progress"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Xinetd proposal started")

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      # create a textual proposal
      if @func == "MakeProposal"
        @proposal = ""
        @warning = nil
        @warning_level = nil
        @force_reset = Ops.get_boolean(@param, "force_reset", false)

        if @force_reset || !Inetd.proposal_valid
          Inetd.proposal_valid = true
          @po = Progress.set(false)
          Inetd.Read
          Progress.set(@po)
        end
        @proposal = Inetd.Summary


        @ret = {
          "preformatted_proposal" => @proposal,
          "warning_level"         => @warning_level,
          "warning"               => @warning
        }
      # run the module
      elsif @func == "AskUser"
        @stored = Inetd.Export
        @seq = Convert.to_symbol(WFM.CallFunction("inetd", [path(".propose")]))
        Inetd.Import(@stored) if @seq != :next
        Builtins.y2debug("stored=%1", @stored)
        Builtins.y2debug("seq=%1", @seq)
        @ret = { "workflow_sequence" => @seq }
      # create titles
      elsif @func == "Description"
        @ret = {
          "rich_text_title" => _("Xinetd"),
          "menu_title"      => _("&Xinetd"),
          "id"              => "inetd"
        }
      # write the proposal
      elsif @func == "Write"
        Inetd.Write
      else
        Builtins.y2error("unknown function: %1", @func)
      end

      # Finish
      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("Xinetd proposal finished")
      Builtins.y2milestone("----------------------------------------")
      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::InetdProposalClient.new.main
