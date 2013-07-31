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
# File:	clients/inetd.ycp
# Package:	Configuration of inetd
# Summary:	Main file
# Authors:	Petr Hadraba <phadraba@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Main file for inetd configuration. Uses all other files.
module Yast
  class InetdClient < Client
    def main
      Yast.import "UI"

      #**
      # <h3>Configuration of the inetd</h3>

      textdomain "inetd"

      Yast.import "Inetd"
      Yast.import "CommandLine"


      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Xinetd module started")

      Yast.include self, "inetd/wizards.rb"

      # is this proposal or not?
      @propose = false
      @args = WFM.Args
      if Ops.greater_than(Builtins.size(@args), 0) && Ops.is_path?(WFM.Args(0)) &&
          WFM.Args(0) == path(".propose")
        Builtins.y2milestone("Using PROPOSE mode")
        @propose = true
      end

      @mini = {
        "help"       => _("Configuration of Network Services (xinetd)"),
        "id"         => "inetd",
        "guihandler" => fun_ref(method(:InetdSequence), "symbol ()"),
        "initialize" => fun_ref(Inetd.method(:Read), "boolean ()"),
        "finish"     => fun_ref(Inetd.method(:Write), "boolean ()"),
        "actions" =>
          # "add": $[
          # 	    // translators: command line help text for "add" action
          # 	    "help": _("Enable the service"),
          # 	    "handler": AddHandler,
          # 	],
          # 	"delete": $[
          # 	    // translators: command line help text for "delete" action
          # 	    "help": _("Disable the service"),
          # 	    "handler": DeleteHandler,
          # 	],
          # 	"set": $[
          # 	    // translators: command line help text for "set" action
          # 	    "help": _("Change the service"),
          # 	    "handler": SetHandler,
          # 	]
          {
            "summary" => {
              # translators: command line help text for "summary" action
              "help"    => _(
                "Show the status of current system services"
              ),
              "handler" => fun_ref(
                method(:SummaryHandler),
                "boolean (map <string, string>)"
              )
            }
          },
        "options"    => {
          "id"          => {
            # translators: command line help text for "id" option
            "help" => _(
              "Unique identifier"
            ),
            "type" => "string"
          },
          "service"     => {
            # translators: command line help text for "service" option
            "help" => _(
              "Service name"
            ),
            "type" => "string"
          },
          "disable"     => {
            # translators: command line help text for "disable" option
            "help"     => _(
              "Disable service"
            ),
            "type"     => "enum",
            "typespec" => ["yes", "no"]
          },
          "rpc_version" => {
            # translators: command line help text for "rpc_version" option
            "help" => _(
              "RPC version of RPC service"
            ),
            "type" => "string"
          },
          "socket_type" => {
            # translators: command line help text for "socket_type" option
            "help"     => _(
              "Socket type"
            ),
            "type"     => "enum",
            "typespec" => ["stream", "dgram", "raw", "seqpacket"]
          },
          "protocol"    => {
            # translators: command line help text for "protocol" option
            "help"     => _(
              "Internet (IP) protocols"
            ),
            "type"     => "enum",
            "typespec" => ["tcp", "udp", "rpc/tcp", "rpc/udp"]
          },
          "wait"        => {
            # translators: command line help text for "wait" option
            "help"     => _(
              "Wait attribute"
            ),
            "type"     => "enum",
            "typespec" => ["yes", "no"]
          },
          "user"        => {
            # translators: command line help text for "user" option
            "help" => _(
              "Determines the uid for the server process"
            ),
            "type" => "string"
          },
          "group"       => {
            # translators: command line help text for "group" option
            "help" => _(
              "Determines the gid for the server process"
            ),
            "type" => "string"
          },
          "server"      => {
            # translators: command line help text for "server" option
            "help" => _(
              "Path name of program to execute"
            ),
            "type" => "string"
          },
          "server_args" => {
            # translators: command line help text for "server_args" option
            "help" => _(
              "Parameters for server"
            ),
            "type" => "string"
          },
          "comment"     => {
            # translators: command line help text for "comment" option
            "help" => _(
              "User comment"
            ),
            "type" => "string"
          }
        },
        "mappings" =>
          #	"add":     ["service", "disable", "rpc_version", "socket_type", "protocol", "wait", "user", "group", "server", "server_args", "comment"],
          #	"delete":  ["id", "service", "disable", "rpc_version", "socket_type", "protocol", "wait", "user", "group", "server", "server_args", "comment"],
          #	"set":     ["id", "service", "disable", "rpc_version", "socket_type", "protocol", "wait", "user", "group", "server", "server_args", "comment"],
          {
            "summary" => [
              "service",
              "disable",
              "rpc_version",
              "socket_type",
              "protocol",
              "wait",
              "user",
              "group",
              "server",
              "server_args",
              "comment"
            ]
          }
      }


      # main ui function
      @ret = nil

      if @propose
        @ret = InetdAutoSequence()
      else
        @ret = CommandLine.Run(@mini)
      end
      Builtins.y2debug("ret == %1", @ret)

      # Finish
      Builtins.y2milestone("Xinetd module finished")
      Builtins.y2milestone("----------------------------------------")
      deep_copy(@ret) 

      # EOF
    end

    def CommandLineTableDump(table)
      table = deep_copy(table)
      columns = 0
      len = []
      totallen = 0
      c = 0
      Builtins.foreach(table) do |l|
        columns = Ops.greater_than(Builtins.size(l), columns) ?
          Builtins.size(l) :
          columns
        c = 0
        while Ops.less_than(c, Builtins.size(l))
          if Ops.get(l, c) != nil
            Ops.set(
              len,
              c,
              Ops.greater_than(
                Builtins.size(Ops.get_string(l, c, "")),
                Ops.get(len, c, 0)
              ) ?
                Builtins.size(Ops.get_string(l, c, "")) :
                Ops.get(len, c, 0)
            )
          end
          c = Ops.add(c, 1)
        end
      end
      c = 0
      while Ops.less_than(c, columns)
        totallen = Ops.add(Ops.add(totallen, Ops.get(len, c, 0)), 3)
        c = Ops.add(c, 1)
      end
      if Ops.greater_or_equal(totallen, 80)
        Ops.set(
          len,
          Ops.subtract(columns, 1),
          Ops.subtract(
            80,
            Ops.subtract(totallen, Ops.get(len, Ops.subtract(columns, 1), 0))
          )
        )
        if Ops.less_than(Ops.get(len, Ops.subtract(columns, 1), 0), 3)
          Ops.set(len, Ops.subtract(columns, 1), 3)
        end
      end
      Builtins.foreach(table) do |l|
        line = ""
        c = 0
        if Ops.greater_than(Builtins.size(l), 0)
          while Ops.less_than(c, columns)
            totallen = Builtins.size(line)
            line = Ops.add(line, Ops.get_string(l, c, ""))
            if Ops.less_than(c, Ops.subtract(columns, 1))
              while Ops.less_than(
                  Builtins.size(line),
                  Ops.add(totallen, Ops.get(len, c, 0))
                )
                line = Ops.add(line, " ")
              end
              line = Ops.add(line, " | ")
            end
            c = Ops.add(c, 1)
          end
        else
          while Ops.less_than(c, columns)
            totallen = Builtins.size(line)
            while Ops.less_than(
                Builtins.size(line),
                Ops.add(totallen, Ops.get(len, c, 0))
              )
              line = Ops.add(line, "-")
            end
            if Ops.less_than(c, Ops.subtract(columns, 1))
              line = Ops.add(line, "-+-")
            end
            c = Ops.add(c, 1)
          end
        end
        CommandLine.Print(line)
      end

      nil
    end

    def opts2mask(opts)
      opts = deep_copy(opts)
      mask = {}
      if Ops.get(opts, "disable") != nil
        Ops.set(
          mask,
          "enable",
          Ops.get(opts, "disable") == "yes" ? false : true
        )
      end
      if Ops.get(opts, "wait") != nil
        Ops.set(mask, "wait", Ops.get(opts, "wait") == "yes" ? true : false)
      end
      Builtins.foreach(
        [
          "service",
          "rpc_version",
          "socket_type",
          "protocol",
          "user",
          "group",
          "server",
          "server_args",
          "comment"
        ]
      ) do |key|
        Ops.set(mask, key, Ops.get(opts, key)) if Ops.get(opts, key) != nil
      end
      deep_copy(mask)
    end

    def SetHandler(opts)
      opts = deep_copy(opts)
      if Ops.get(opts, "id") == nil
        # translators: error message for command line
        CommandLine.Error(_("You must specify a service ID."))
        return false
      end
      Inetd.ServiceChange(Ops.get(opts, "id", ""), opts2mask(opts))
      true
    end

    def AddHandler(opts)
      opts = deep_copy(opts)
      if Builtins.size(opts) == 0
        # translators: error message for command line
        CommandLine.Error(_("Specify the service using a 'service' option."))
        return false
      end
      Inetd.ServiceAdd(opts2mask(opts))

      nil
    end

    def DeleteHandler(opts)
      opts = deep_copy(opts)
      service_ids = []
      if Ops.get(opts, "id") != nil
        if Ops.greater_than(Builtins.size(opts), 1)
          # translators: error message for command line
          CommandLine.Error(
            _("The 'id' option cannot be combined with other options.")
          )
          return false
        end
        service_ids = [Ops.get(opts, "id", "")]
      else
        service_ids = Inetd.GetServicesId(opts2mask(opts))
      end
      Builtins.foreach(service_ids) { |id| Inetd.ServiceDelete(id) }

      true
    end

    def SummaryHandler(opts)
      opts = deep_copy(opts)
      service_ids = []
      if Ops.get(opts, "id") != nil
        if Ops.greater_than(Builtins.size(opts), 1)
          # translators: error message for command line
          CommandLine.Error(
            _("The 'id' option cannot be combined with other options.")
          )
          return false
        end
        service_ids = [Ops.get(opts, "id", "")]
      else
        service_ids = Inetd.GetServicesId(opts2mask(opts))
      end
      services = [
        [
          _("Status"),
          _("Service"),
          _("Type"),
          _("Prot."),
          _("Wait"),
          _("User"),
          _("Server")
        ], #_("Id"),
        []
      ]

      Builtins.foreach(service_ids) do |id|
        user = Inetd.ServiceGetStr(id, "user", "")
        if Inetd.ServiceGetStr(id, "group", "") != ""
          user = Ops.add(
            Ops.add(user, "."),
            Inetd.ServiceGetStr(id, "group", "")
          )
        end
        server = Inetd.ServiceGetStr(id, "server", "")
        if Inetd.ServiceGetStr(id, "server_args", "") != ""
          server = Ops.add(
            Ops.add(server, " "),
            Inetd.ServiceGetStr(id, "server_args", "")
          )
        end
        service = Inetd.ServiceGetStr(id, "service", "")
        if Inetd.ServiceGetStr(id, "rpc_version", "") != ""
          service = Ops.add(
            Ops.add(service, "/"),
            Builtins.tostring(Inetd.ServiceGetStr(id, "rpc_version", ""))
          )
        end
        line = [
          # id,
          Inetd.ServiceEnabled(id) ?
            _("On") :
            _("Off"),
          service,
          Inetd.ServiceGetStr(id, "socket_type", ""),
          Inetd.ServiceGetStr(id, "protocol", ""),
          Inetd.ServiceGetTruth(id, "wait", true) ? _("Yes") : _("No"),
          user,
          server
        ]
        services = Builtins.add(services, line)
      end
      CommandLineTableDump(services)
      true
    end
  end
end

Yast::InetdClient.new.main
