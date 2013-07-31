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
# File:        testsuite/tests/Inetd3.ycp
# Package:     Configuration of inetd
# Summary:     Testsuite for Reading and Writing (x)inetd configuration
# Authors:     Petr Hadraba <phadraba@suse.cz>
#
# $Id$
#
# This is testsuite for Inetd.ycp source file.
# These tests are checking reading and writing
# of inetd or xinetd services.
module Yast
  class Inetd3Client < Client
    def main
      # testedfiles: Inetd.ycp Service.ycp Testsuite.ycp

      Yast.include self, "testsuite.rb"
      Yast.import "Inetd"
      Yast.import "Report"
      Yast.import "Progress"

      Progress.off
      Report.DisplayErrors(false, 0)

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
            "runlevel" => { "xinetd" => @service_off },
            "comment"  => { "xinetd" => {} }
          }
        },
        "targetpkg" => { "installed" => true },
        "etc"       => { "xinetd_conf" => { "services" => [@s] } }
      }

      @READXinetd = {}
      @READXinetd = Builtins.eval(@READ)
      Ops.set(
        @READXinetd,
        ["init", "scripts", "runlevel", "xinetd"],
        @service_off
      )
      Ops.set(@READXinetd, ["etc", "inetd_conf"], {})

      @READXinetd2 = {}
      @READXinetd2 = Builtins.eval(@READ)
      Ops.set(
        @READXinetd2,
        ["init", "scripts", "runlevel", "xinetd"],
        @service_on
      )
      Ops.set(@READXinetd2, ["etc", "inetd_conf"], {})

      @WRITE = {}

      @EXECUTE = {
        "target" => {
          "bash_output" => { "exit" => 0, "stdout" => "", "stderr" => "" },
          "mkdir"       => true
        }
      }

      # xinetd service is installed
      # xinetd is stopped
      # User will save and use xinetd
      DUMP("\nRead  --- read all services\n")

      TEST(lambda { Inetd.Read }, [@READXinetd, @WRITE, @EXECUTE], nil)


      DUMP("\nWrite --- write xinetd")
      TEST(lambda { Inetd.Write }, [@READXinetd, @WRITE, @EXECUTE], nil)

      DUMP("\n  ---\n")


      TEST(lambda { Inetd.Read }, [@READXinetd2, @WRITE, @EXECUTE], nil)

      DUMP("\nWrite --- write xinetd")
      TEST(lambda { Inetd.Write }, [@READXinetd2, @WRITE, @EXECUTE], nil)

      DUMP("\n  ---\n")

      nil
    end
  end
end

Yast::Inetd3Client.new.main
