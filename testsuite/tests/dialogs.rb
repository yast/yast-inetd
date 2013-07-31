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
# File:        testsuite/tests/dialogs.ycp
# Package:     Configuration of inetd
# Summary:     Testsuite for routines in dialogs.ycp and dialogs.ycp
# Authors:     Petr Hadraba <phadraba@suse.cz>
#
# $Id$
#
# This is testsuite for dialogs.ycp source file.
# These tests are checking routines implemented
# in dialogs.ycp.
#
# Tested functions:
#   indexTable()
module Yast
  class DialogsClient < Client
    def main
      Yast.import "UI"
      # testedfiles: dialogs.ycp Testsuite.ycp

      Yast.include self, "testsuite.rb"
      Yast.import "Inetd"
      Yast.include self, "inetd/dialogs.rb"
      Yast.import "Report"

      Report.DisplayErrors(false, 0)

      # already in dialogs.ycp
      # typedef list< map<string, any> > services_t;

      @netd_conf = [
        {
          "iid"         => "whatever",
          "comment"     => "My service",
          "enabled"     => true,
          "service"     => "finger",
          "socket_type" => "stream",
          "protocol"    => "tcp",
          "wait"        => false,
          "user"        => "nobody",
          "server"      => "/usr/sbin/tcpd",
          "server_args" => "in.fingerd -w"
        }
      ]

      @netd_conf_none = [
        {
          "iid"         => "whatever",
          "comment"     => "My service",
          "enabled"     => false,
          "service"     => "finger",
          "socket_type" => "stream",
          "protocol"    => "tcp",
          "wait"        => false,
          "user"        => "nobody",
          "server"      => "/usr/sbin/tcpd",
          "server_args" => "in.fingerd -w",
          "deleted"     => true
        }
      ]

      DUMP("\nAll services are available\n")

      Inetd.netd_conf = deep_copy(@netd_conf)

      indexTable

      DUMP(@iid_to_index)
      DUMP(@index_to_iid)

      DUMP("\nAll services are marked as deleted\n")

      Inetd.netd_conf = deep_copy(@netd_conf_none)

      indexTable

      DUMP(@iid_to_index)
      DUMP(@index_to_iid)

      nil
    end
  end
end

Yast::DialogsClient.new.main
