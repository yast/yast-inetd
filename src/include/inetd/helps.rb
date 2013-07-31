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
# File:	include/inetd/helps.ycp
# Package:	Configuration of inetd
# Summary:	Help texts of all the dialogs
# Authors:	Petr Hadraba <phadraba@suse.cz>
#
# $Id$
module Yast
  module InetdHelpsInclude
    def initialize_inetd_helps(include_target)
      textdomain "inetd"

      # All helps are here
      @HELPS = {
        # Popup::Error
        "no_install"       => _(
          "No packages selected. Configuration aborted."
        ),
        # Not used!
        "install_packages" => _(
          "Selected packages will be installed."
        ),
        # Read dialog help 1/2
        "read"             => _(
          "<p><b><big>Initializing xinetd Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ) +
          # Read dialog help 2/2
          _(
            "<p><b><big>Aborting the Initialization Process:</big></b><br>\nSafely abort the configuration utility by pressing <b>Abort</b> now.</p>\n"
          ),
        # Write dialog help 1/2
        "write"            => _(
          "<p><b><big>Saving xinetd Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ) +
          # Write dialog help 2/2
          _(
            "<p><b><big>Aborting the Save Process:</big></b><br>\n" +
              "Abort saving by pressing <b>Abort</b>.\n" +
              "An additional dialog will inform you whether it is safe to do so.\n" +
              "</p>\n"
          ),
        # Configure1 dialog help 1/2
        "c1"               => _(
          "<p><b><big>Network Service Configuration</big></b><br>\n" +
            "Click <b>Enable</b> to enable network services managed by a super-server\n" +
            "configuration. To stop the super-server, click <b>Disable</b>.</p>\n"
        ) + "<p><br></p>" +
          _(
            "<p><b><big>Configuration Service Status:</big></b><br>\n" +
              "All services marked with <b>X</b> in column <b>Ch</b> were edited\n" +
              "and will be changed in the system configuration.</p>\n"
          ) +
          _(
            "<p><b><big>Services Status:</big></b><br>\n" +
              "All services marked with <b>---</b> are inactive (locked).\n" +
              "All services marked with <b>On</b> are active (unlocked).\n" +
              "All services marked with <b>NI</b> are not installed and cannot be configured.</p>"
          ) +
          _(
            "<p><b><big>Changing Service Status:</big></b><br>\nSelect the service to enable or disable and press <b>Toggle Status (On or Off)</b>.</p>\n"
          ) +
          _(
            "<p><b><big>Editing Services:</big></b><br>\nSelect the service to edit and press <b>Edit</b>.</p>\n"
          ) +
          _(
            "<p><b><big>Deleting Services:</big></b><br>\nSelect the service to delete and press <b>Delete</b>.</p>\n"
          ) +
          _(
            "<p><b><big>Adding a New Entry:</big></b>\nClick <b>Create</b> and complete the form.</p>\n"
          ) + "<p><br></p>" +
          _(
            "<p><b><big>Canceling Configuration:</big></b>\n" +
              "Leave the configuration untouched by pressing the <b>Cancel</b> button.\n" +
              "If you do so, all your changes will be lost and the original configuration will remain.</p>\n"
          )
      }
    end

    # Help for the EditOrCreateServiceDlg () dialog.
    # @return The help text.
    def EditCreateHelp
      _(
        "\n" +
          "<p>To create a valid entry (service) for the super-server,\n" +
          "enter</p>\n"
      ) +
        _(
          "<ul>\n" +
            "<li>service name\n" +
            "<li>RPC version (optional)\n" +
            "<li>socket type\n" +
            "<li>protocol\n" +
            "<li>wait/nowait\n" +
            "<li>user\n" +
            "<li>group\n" +
            "<li>server program\n" +
            "<li>server program arguments\n" +
            "</ul>"
        ) +
        _(
          "<p>This is a short description. For details, see <b>info xinetd.conf</b>.</p>\n"
        ) +
        _(
          "<p>Enter a valid service name into the <b>service</b> field.\n</p>\n"
        ) +
        _(
          "<p>The <b>socket type</b> should be stream, dgram, raw, or seqpacket,\n" +
            "depending on whether the service is stream-based, is datagram-based,\n" +
            "requires direct access to IP, or requires reliable sequential datagram\n" +
            "transmission.</p>\n"
        ) +
        _(
          "<p>The <b>protocol</b> must be a valid protocol as specified in /etc/protocols.\n" +
            "Examples include <i>tcp</i>,<i>udp</i>,<i>rpc/tcp</i>, and <i>rpc/udp</i>.\n" +
            "</p>\n"
        ) +
        _(
          "<p>The <b>wait/nowait</b> entry determines if the service is\n" +
            "single-threaded or multithreaded and whether xinetd accepts the\n" +
            "connection or the server program accepts the connection. If its value is\n" +
            "<b>yes</b>, the service is single-threaded. This means that xinetd \n" +
            "starts the server then stops handling requests for the service\n" +
            "until the server dies and that the server software accepts the\n" +
            "connection. If the attribute value is <b>no</b>, the service is\n" +
            "multithreaded and xinetd keeps handling new service requests and\n" +
            "xinetd accepts the connection. \n" +
            "<i>udp/dgram</i> services normally expect the value to be <b>yes</b>,\n" +
            "because udp is not connection oriented. <i>tcp/stream</i> servers\n" +
            "normally expect the value to be <b>no</b>.</p>\n"
        ) +
        _(
          "<p>The server will be run with the permissions of the user selected in\n" +
            "<b>User</b>. This is useful to make services run with permissions\n" +
            "less than root.\n" +
            "</p>\n"
        ) +
        _(
          "<p>In <b>Server</b>, enter the path name of the program to\n" +
            "be executed by the super-server when a request reaches its socket.\n" +
            "Parameters for this program can be specified in <b>Server Arguments</b>.\n" +
            "\n" +
            "</p>\n"
        )
    end
  end
end
