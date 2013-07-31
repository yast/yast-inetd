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
# File:        testsuite/tests/Inetd.ycp
# Package:     Configuration of inetd
# Summary:     Testsuite for Reading and Writing (x)inetd configuration
# Authors:     Martin Vidner <mvidner@suse.cz>
#              Petr Hadraba <phadraba@suse.cz>
#
# $Id$
#
# This is testsuite for Inetd.ycp source file.
# These tests are checking reading and writing
# of inetd or xinetd services.
module Yast
  class InetdClient < Client
    def main
      # testedfiles: Inetd.ycp Service.ycp Testsuite.ycp

      Yast.include self, "testsuite.rb"
      Yast.import "Inetd"
      Yast.import "Report"
      Yast.import "Progress"

      Report.DisplayErrors(false, 0)
      Progress.off

      @s = {
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

      @service_on = { "start" => ["3", "5"], "stop" => ["3", "5"] }

      @service_off = { "start" => [], "stop" => [] }

      @READ = {
        "target"    => { "size" => -1 },
        "init"      => {
          "scripts" => {
            "exists"   => true,
            "runlevel" => { "xinetd" => @service_on },
            "comment"  => { "xinetd" => {} }
          }
        },
        "targetpkg" => { "installed" => true },
        "etc"       => { "xinetd_conf" => { "services" => [@s] } }
      }

      @READ3 = {}
      @READ3 = Builtins.eval(@READ)
      Ops.set(@READ3, ["init", "scripts", "runlevel", "xinetd"], @service_off)

      @WRITE = {}

      @EXECUTE = {
        "target" => {
          "bash_output" => { "exit" => 0, "stdout" => "", "stderr" => "" },
          "mkdir"       => true
        }
      }

      # All services are installed (inetd and xinetd)
      # All services are running
      # User will save and use inetd
      DUMP("\nAll services are running and inetd will be used\n")
      DUMP("\nRead  --- read all services\n")

      TEST(lambda { Inetd.Read }, [@READ, @WRITE, @EXECUTE], nil)

      # filled by InetdDialog()
      Inetd.netd_status = 0

      DUMP("\nWrite --- write services")
      TEST(lambda { Inetd.Write }, [@READ, @WRITE, @EXECUTE], nil)

      DUMP("\n  ---\n")



      # All services are installed (inetd, xinetd)
      # inetd is running
      # User will save and use xinetd
      DUMP("\ninetd is running and xinetd will be used\n")
      DUMP("\nRead  --- read all services\n")

      TEST(lambda { Inetd.Read }, [@READ3, @WRITE, @EXECUTE], nil)

      # filled by InetdDialog()
      Inetd.netd_status = 3

      DUMP("\nWrite --- write xinetd")
      DUMP("  inetd and xinetd are installed and only inetd is running\n")
      TEST(lambda { Inetd.Write }, [@READ3, @WRITE, @EXECUTE], nil)

      DUMP("\n  ---\n")

      nil
    end
  end
end

Yast::InetdClient.new.main
