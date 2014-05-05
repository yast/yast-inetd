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
# File:	include/inetd/dialogs.ycp
# Package:	Configuration of inetd
# Summary:	Dialogs definitions
# Authors:	Petr Hadraba <phadraba@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
module Yast
  module InetdDialogsInclude
    def initialize_inetd_dialogs(include_target)
      Yast.import "UI"

      textdomain "inetd"

      Yast.import "Inetd"

      Yast.import "Package"
      Yast.import "Wizard"
      Yast.import "Popup"
      Yast.import "Label"

      Yast.include include_target, "inetd/helps.rb"
      Yast.include include_target, "inetd/routines.rb"

      # local users and groups are stored here
      # We create both lists only once - during first EditOrCreateServiceDlg() call.
      @local_users = nil

      # see local_users.
      @local_groups = nil

      # This map is used for (re)selecting table items. This is new inetd GUI improvement! :o)
      # Indexes table items, ie. not counting deleted services.
      @iid_to_index = {}

      # See iid_to_index.
      # This is reverse to iid_to_index.
      # Indexes table items, ie. not counting deleted services.
      @index_to_iid = {}

      # used for conversion netd_conf to table's format
      @table_data = []

      # Map of the just installed service, this service changes it's name from
      # NI{int} to {int}:/etc/{service_conf}
      # This map is used to find the currently selected service using the names
      # and options of the service.
      # Related to bug 172449.
      # BTW: This module should have been rewritten ages ago! No more hacking, please.
      @just_installed = {}
    end

    # This function regenerates index_to_iid and iid_to_index maps
    def indexTable
      index = 0 # (re)set index
      @iid_to_index = {} # clear data
      @index_to_iid = {} #   maps are not empty!
      Builtins.foreach(Inetd.netd_conf) do |line|
        # Skip deleted entries
        if Ops.get_boolean(line, "deleted", false) == false
          index = Ops.add(index, 1)
          iid = Ops.get_string(line, "iid", "")
          @iid_to_index = Builtins.add(@iid_to_index, iid, index)
          @index_to_iid = Builtins.add(@index_to_iid, index, iid)
        end
      end

      nil
    end

    # This function extracts provided packages (from Inetd::default_conf_*)
    # for selected service.
    # Matches by (service, protocol,"program (package)")
    # @param [Yast::Term] service_info Contains informations about selected service
    # @return [Array] Provided packages
    def GetProvidedPackage(service_info)
      service_info = deep_copy(service_info)
      packages = []

      # yuck, using numbers instead of names, this should be cleaned up
      table_s =
        # can't compare "script" here, it is not in the table.
        # is it a problem?
        {
          "service"     => Ops.get_string(service_info, 3, ""),
          "protocol"    => Ops.get_string(service_info, 5, ""),
          "server"      => Ops.get_string(service_info, 8, ""),
          "server_args" => Ops.get_string(service_info, 9, "")
        }

      Builtins.foreach(Inetd.default_conf) do |default_s|
        if ServicesMatch(default_s, table_s)
          packages = Builtins.add(
            packages,
            Ops.get_string(default_s, "package", "")
          )
        end
      end
      deep_copy(packages)
    end

    # Ensure that a package is installed.
    # Show dialog with packages names provided non-installed service.
    # @param [String] selected_item iid from table
    # @return [Symbol] Status of operation:<pre>
    # `next: nothing to do, it is installed already
    # `auto: will be installed at autoinstall time
    # `installed: successfully installed
    # `none: cancelled or install error
    # </pre>
    def InstallProvidedPackage(selected_item)
      @just_installed = {}
      ret = :next
      # possibly nil it out
      selected_item = CheckInstallable(selected_item)
      service_info = IidToTerm(selected_item)

      # service (package) is installed and its configuration is known,
      # so simply skip dialog
      if service_info == nil
        Builtins.y2milestone("%1", ret)
        return ret
      end

      # Now, the package doesn't exists. We must tell user, the package is required...
      # But, the fisrt, we must extract requested package name
      # (singleton list)
      package_name = GetProvidedPackage(service_info)
      Builtins.y2milestone("* pkg: %1", package_name)

      # if Autoinstallation mode --- we do not want to install packages yet...
      if Inetd.auto_mode
        # Translators: In autoinstallation mode:
        #    The package name is stored in %1. This is Popup::ContinueCancel.
        if Popup.ContinueCancel(
            Builtins.sformat(
              _("Package %1 will be installed during the write process."),
              Ops.get(package_name, 0, "")
            )
          )
          # Add requested package into list...
          Package.DoInstallAndRemove(package_name, [])
          IsInstalledClearCache()
          ret = :auto
        else
          ret = :none
        end
      else
        # if installation failes
        # Translators: The package name is stored in %1.
        if !Package.InstallAll(package_name)
          #if (true) { // for debugging
          # Translators: The package name is stored in %1. This is Popup::Message.
          Popup.Message(
            Builtins.sformat(
              _("Package %1 was not installed. The service cannot be edited."),
              Ops.get(package_name, 0, "")
            )
          )
          ret = :none
        else
          IsInstalledClearCache()
          Builtins.y2milestone("Rereading xinetd configuration")
          old_conf = deep_copy(Inetd.netd_conf)
          # Reread configuration!
          Inetd.netd_conf = Convert.convert(
            SCR.Read(path(".etc.xinetd_conf.services")),
            :from => "any",
            :to   => "list <map <string, any>>"
          )
          Inetd.netd_conf = Inetd.MergeEditedWithSystem(
            Inetd.netd_conf,
            old_conf
          )
          # Translators: The package name is stored in %1
          Popup.Message(
            Builtins.sformat(
              _("Package %1 was successfully installed."),
              Ops.get(package_name, 0, "")
            )
          )
          ret = :installed

          @just_installed = {
            "script"      => Ops.get(service_info, 3),
            "socket_type" => Ops.get(service_info, 4),
            "protocol"    => Ops.get(service_info, 5),
            "user"        => Ops.get(service_info, 7),
            "server"      => Ops.get(service_info, 8),
            "server_args" => Ops.get(service_info, 9)
          }
          Builtins.y2milestone("Just installed %1", @just_installed)
        end
      end
      Builtins.y2milestone("%1", ret)
      ret
    end
    def IidToTerm(selected_item)
      return nil if selected_item == nil
      Builtins.find(@table_data) do |line|
        Ops.get_string(line, [0, 0], "NI") == selected_item
      end
    end
    def CheckInstallable(id)
      if Inetd.auto_mode
        # must get to the "package" field
        service = Builtins.find(Inetd.netd_conf) do |s|
          Ops.get_string(s, "iid", "") == id
        end
        return nil if IsInstalled(Ops.get_string(service, "package", ""))
      else
        # ids of NotInstalled table items start with NI
        return nil if !Builtins.regexpmatch(id, "^NI")
      end
      id
    end

    # Function finds a new ID of the service
    #
    # service_info[3]:"" - service
    # service_info[8]:"" - server
    # service_info[9]:"" - server_args
    # ...
    #
    # Inetd::netd_conf
    #	-line["service"]:""
    #	-line["server"]:""
    #	-line["server_args"]:""
    # ...
    #
    # This function is needed for services which get installed during the configuration
    # of yast2-inetd. They change their name from NI[number1] to [number2]:/path/to/server.
    #
    def FindNewLineWithNewID(selected_item_old, service_info)
      service_info = deep_copy(service_info)
      service_info_service = Ops.get_string(service_info, 3)
      service_info_socket_type = Ops.get_string(service_info, 4)
      service_info_protocol = Ops.get_string(service_info, 5)
      service_info_wait = Ops.get_string(service_info, 6, "yes") == "yes" ? true : false
      service_info_user = Ops.get_string(service_info, 7)
      service_info_server = Ops.get_string(service_info, 8)
      service_info_server_args = Ops.get_string(service_info, 9)

      ret = selected_item_old

      Builtins.foreach(Inetd.netd_conf) do |inetd_line|
        if service_info_service == Ops.get_string(inetd_line, "service", "") &&
            service_info_socket_type ==
              Ops.get_string(inetd_line, "socket_type", "") &&
            service_info_protocol == Ops.get_string(inetd_line, "protocol", "") &&
            service_info_wait == Ops.get_boolean(inetd_line, "wait") &&
            service_info_user == Ops.get_string(inetd_line, "user", "") &&
            service_info_server == Ops.get_string(inetd_line, "server", "") &&
            service_info_server_args ==
              Ops.get_string(inetd_line, "server_args", "")
          ret = Ops.get_string(inetd_line, "iid", "")
          # reporting only really changed one
          if selected_item_old != ret
            Builtins.y2milestone(
              "Service has changed its ID from %1 to %2",
              selected_item_old,
              ret
            )
          end
          raise Break
        end
      end

      ret
    end

    # This is main inetd module dialog.
    # @return dialog result
    def InetdDialog
      expert_contents = [
        Item(Id(:all_on), _("&Activate All Services")),
        Item(Id(:all_off), _("&Deactivate All Services"))
      ]

      # These special options are available if `expert_inetd' parameter is given into command-line
      # if(WFM::Args()[0]:"" == "expert_inetd")
      # 	expert_contents = add(expert_contents, `menu("E&xpert tools",
      # 	    [
      # 		`item(`id(`all_rev), "&Invert Status"),
      # 		`item(`id(`clear_changed), "&Clear \"CHANGED\" flag")
      # 	    ]));
      # These special options are available, if YAST2_INETD environment variable contains `EXPERT'
      # The `expert_inetd' command-line parameter is implemented too.
      if Builtins.getenv("YAST2_INETD") == "EXPERT" ||
          Ops.get_string(WFM.Args, 0, "") == "expert_inetd"
        expert_contents = Builtins.add(
          expert_contents,
          term(
            :menu,
            "E&xpert tools",
            [
              Item(Id(:all_rev), "&Invert Status"),
              Item(Id(:clear_changed), "&Clear \"CHANGED\" flag")
            ]
          )
        )
      end

      # Main dialog contents
      contents = VBox(
        VSpacing(0.5),
        Left(
          RadioButtonGroup(
            VBox(
              # Translators: Initial and target state of xinetd (or inetd)
              Left(RadioButton(Id(:stop), Opt(:notify), _("D&isable"), true)),
              Left(
                RadioButton(Id(:editable), Opt(:notify), _("Enab&le"), false)
              )
            )
          )
        ),
        VSpacing(0.5),
        # Main dialog edit inetd.conf
        # Translators: Name of table with services (echo, chargen, ...)
        Left(Label(_("Currently Available Services"))),
        HBox(
          # Translators: Table Header: The "Ch" label is short of "Changed". Please, make the
          # 		translation as short as possible.
          Table(
            Id(:table), # `opt(`notify),
            #`opt(`keepSorting),
            Header(
              Center(_("Ch")),
              Center(_("Status")),
              _("Service"),
              _("Type "),
              Center(_("Protocol")),
              _("Wait"),
              _("User"),
              _("Server"),
              _("Server / Args")
            ),
            @table_data
          )
        ),
        HBox(
          Left(
            HBox(
              HSpacing(1),
              # Translators: Add service
              PushButton(Id(:create), Opt(:key_F3), _("&Add")),
              HSpacing(1),
              # Translators: Edit service
              PushButton(Id(:edit), Opt(:key_F4), _("&Edit")),
              HSpacing(1),
              # Translators: Delete service
              PushButton(Id(:delete), Opt(:key_F5), _("&Delete"))
            )
          ),
          #		`VSpacing(),
          Right(
            HBox(
              # Translators: Change service status
              HSquash(
                PushButton(Id(:switch_active), _("&Toggle Status (On or Off)"))
              ),
              HSpacing(1)
            )
          )
        ),
        HBox(
          Right(
            HBox(
              HSquash(
                MenuButton(
                  Id(:toggle_menu),
                  _("Status for All &Services"),
                  expert_contents
                )
              ),
              HSpacing(1)
            )
          )
        ),
        VSpacing(0.5)
      )

      ret = nil

      # Inetd configure dialog caption
      caption = _("Network Service Configuration (xinetd)")

      # initialize GUI
      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "c1", ""),
        Label.BackButton,
        Label.FinishButton
      )

      Wizard.HideBackButton
      Wizard.SetAbortButton(:cancel, Label.CancelButton)

      Wizard.SetScreenShotName("inetd-5-maindialog")

      new_state = false

      # if service active, enable editting
      new_state = Inetd.netd_status
      UI.ChangeWidget(Id(:editable), :Value, new_state)
      UI.ChangeWidget(Id(:table), :Enabled, new_state)
      UI.ChangeWidget(Id(:create), :Enabled, new_state)
      UI.ChangeWidget(Id(:delete), :Enabled, new_state)
      UI.ChangeWidget(Id(:edit), :Enabled, new_state)
      UI.ChangeWidget(Id(:toggle_menu), :Enabled, new_state)
      UI.ChangeWidget(Id(:switch_active), :Enabled, new_state)

      @table_data = CreateTableData(Inetd.netd_conf)
      indexTable
      UI.ChangeWidget(Id(:table), :Items, @table_data)

      # main loop
      while true
        # item ID for `table stored here will be selected
        to_select = ""
        # skip time critical calculations if need_reindex == false (don't call indexTable())
        need_reindex = false
        # skip time critical calculations if need_rebuild == false (don't call CreateTableData())
        # AARGH unused.
        need_rebuild = true

        if Convert.to_boolean(UI.QueryWidget(Id(:editable), :Value))
          UI.SetFocus(Id(:table))
        else
          UI.SetFocus(Id(:stop))
        end

        ret = UI.UserInput
        Builtins.y2milestone("ret %1", ret)
        ret = :abort if ret == :cancel # window-close button

        if ret == :editable || ret == :stop
          new_state2 = Convert.to_boolean(UI.QueryWidget(Id(:editable), :Value))
          UI.ChangeWidget(Id(:table), :Enabled, new_state2)
          UI.ChangeWidget(Id(:create), :Enabled, new_state2)
          UI.ChangeWidget(Id(:delete), :Enabled, new_state2)
          UI.ChangeWidget(Id(:edit), :Enabled, new_state2)
          UI.ChangeWidget(Id(:toggle_menu), :Enabled, new_state2)
          UI.ChangeWidget(Id(:switch_active), :Enabled, new_state2)

          Inetd.netd_status = new_state2
        # create new entry
        elsif ret == :create
          selected_item = Convert.to_string(
            UI.QueryWidget(Id(:table), :CurrentItem)
          )
          return_val = {}
          Inetd.last_created = Ops.add(Inetd.last_created, 1) # need uniq
          # default parameters for new service
          # TODO is "script: mandatory?
          new_line = {
            "enabled"     => true,
            "service"     => "",
            "max"         => "",
            "socket_type" => "stream",
            "protocol"    => "tcp",
            "wait"        => false,
            "server_args" => "",
            "user"        => "root",
            "group"       => "",
            "comment"     => "",
            "iid"         => Ops.add("new", Inetd.last_created),
            "created"     => true
          }
          # execute dialog
          # Translators: Caption for EditOrCreateServiceDlg()
          return_val = EditOrCreateServiceDlg(
            _("Add a New Service Entry"),
            new_line
          )
          # check Cancel
          if return_val != nil
            # new service was created --- add to global configuration
            Inetd.addLine(return_val)
            Inetd.modified = true
            need_reindex = true # iid_to_index and index_to_iid and
            need_rebuild = true #   table_data must be rebuild
            to_select = Ops.add("new", Inetd.last_created) # select new entry
          else
            need_reindex = false # nothing changed
            need_rebuild = false #   so skip time-critical calculations
            if selected_item != nil
              to_select = selected_item
            else
              to_select = Ops.get_string(@index_to_iid, 1, "")
            end
          end
        # delete new entry
        elsif ret == :delete
          selected_item = Convert.to_string(
            UI.QueryWidget(Id(:table), :CurrentItem)
          )

          # one line must be selected
          if selected_item != nil
            if CheckInstallable(selected_item) != nil
              # Translators: Popup::Error
              Popup.Error(_("Cannot delete the service. It is not installed."))
            else
              Inetd.modified = true
              need_reindex = true # see `create (above) for more details
              need_rebuild = true
              old_index = Ops.get_integer(@iid_to_index, selected_item, 0)
              Inetd.deleteLine(selected_item)
              if old_index == Builtins.size(@iid_to_index)
                to_select = Ops.get_string(
                  @index_to_iid,
                  Ops.subtract(old_index, 1),
                  ""
                )
              else
                to_select = Ops.get_string(
                  @index_to_iid,
                  Ops.add(old_index, 1),
                  ""
                )
              end
            end
          else
            # Translators: Popup::Message
            Popup.Message(
              _("To delete a service, select one in the main dialog")
            )
            need_reindex = false
            need_rebuild = false
            to_select = ""
          end
        # switch service status
        elsif ret == :switch_active
          # get selected line iid
          selected_item = Convert.to_string(
            UI.QueryWidget(Id(:table), :CurrentItem)
          )
          # notify a line is selected
          if selected_item != nil
            # For newly installed packages, new service which changes its ID
            service_info = IidToTerm(selected_item)

            result = InstallProvidedPackage(selected_item)

            if result == :none
              need_reindex = false
              need_rebuild = false
            else
              # New service has been installed and has changed its ID, find it
              selected_item = FindNewLineWithNewID(selected_item, service_info)

              # look for the selected line
              current_line = Builtins.find(Inetd.netd_conf) do |line|
                Ops.get_string(line, "iid", "0") == selected_item
              end
              # change status of line
              if Ops.get_boolean(current_line, "enabled", true) == true
                current_line = Builtins.add(current_line, "enabled", false)
              else
                current_line = Builtins.add(current_line, "enabled", true)
              end
              # change line in database
              Inetd.changeLine(current_line, selected_item)
              Inetd.modified = true
              need_reindex = true
              need_rebuild = true
            end

            to_select = selected_item
          else
            # Translators: Popup::Message
            Popup.Message(
              _(
                "To activate or deactivate a service, select one in the main dialog."
              )
            )
            need_reindex = false
            need_rebuild = false
            to_select = ""
          end
        # activate all services
        elsif ret == :all_on
          Inetd.netd_conf = Builtins.maplist(Inetd.netd_conf) do |line|
            if Ops.get_boolean(line, "deleted", false) != true
              line = Builtins.add(line, "changed", true)
              line = Builtins.add(line, "enabled", true)
            end
            deep_copy(line)
          end
          Inetd.modified = true
          need_reindex = true
          need_rebuild = true
          to_select = Convert.to_string(
            UI.QueryWidget(Id(:table), :CurrentItem)
          )
        # deactivate all services
        elsif ret == :all_off
          Inetd.netd_conf = Builtins.maplist(Inetd.netd_conf) do |line|
            if Ops.get_boolean(line, "deleted", false) != true
              line = Builtins.add(line, "changed", true)
              line = Builtins.add(line, "enabled", false)
            end
            deep_copy(line)
          end
          Inetd.modified = true
          need_reindex = true
          need_rebuild = true
          to_select = Convert.to_string(
            UI.QueryWidget(Id(:table), :CurrentItem)
          )
        # invert status for all services
        elsif ret == :all_rev
          Inetd.netd_conf = Builtins.maplist(Inetd.netd_conf) do |line|
            if Ops.get_boolean(line, "deleted", false) != true
              line = Builtins.add(line, "changed", true)
              line = Builtins.add(
                line,
                "enabled",
                !Ops.get_boolean(line, "enabled", false)
              )
            end
            deep_copy(line)
          end
          Inetd.modified = true
          need_reindex = true
          need_rebuild = true
          to_select = Convert.to_string(
            UI.QueryWidget(Id(:table), :CurrentItem)
          )
        # clear changed flag
        elsif ret == :clear_changed
          Inetd.netd_conf = Builtins.maplist(Inetd.netd_conf) do |line|
            if Ops.get_boolean(line, "deleted", false) != true
              line = Builtins.add(line, "changed", false)
            end
            deep_copy(line)
          end
          Inetd.modified = true
          need_reindex = true
          need_rebuild = true
          to_select = Convert.to_string(
            UI.QueryWidget(Id(:table), :CurrentItem)
          )
        # edit service
        elsif ret == :edit
          # get selected line in table
          need_reindex = false
          selected_item = Convert.to_string(
            UI.QueryWidget(Id(:table), :CurrentItem)
          )
          # line must be selected
          if selected_item != nil
            Builtins.y2milestone("Selected item %1", selected_item)
            result = InstallProvidedPackage(selected_item)

            to_select = selected_item
            if result == :none
              need_reindex = false
              need_rebuild = false
            else
              # y2milestone("All %1", Inetd::netd_conf);
              current_line = Builtins.find(Inetd.netd_conf) do |line|
                Ops.get_string(line, "iid", "0") == selected_item
              end
              current_line = {} if current_line == nil
              # Service might have changed it's IID, bug #172449
              if current_line == {} && @just_installed != {} &&
                  @just_installed != nil
                Builtins.foreach(Inetd.netd_conf) do |one_service|
                  if Ops.get(one_service, "protocol") ==
                      Ops.get_string(@just_installed, "protocol", "") &&
                      Ops.get(
                        # this one might change, matching "server" is enough
                        # one_service["script"]:nil	== just_installed["script"]:"" &&
                        one_service,
                        "server"
                      ) ==
                        Ops.get_string(@just_installed, "server", "") &&
                      Ops.get(one_service, "server_args") ==
                        Ops.get_string(@just_installed, "server_args", "") &&
                      Ops.get(one_service, "socket_type") ==
                        Ops.get_string(@just_installed, "socket_type", "") &&
                      Ops.get(one_service, "user") ==
                        Ops.get_string(@just_installed, "user", "")
                    Builtins.y2milestone(
                      "Service has changed it's ID, found matching %1",
                      one_service
                    )
                    current_line = deep_copy(one_service)
                    # selected_item contains the current (changed) iid
                    selected_item = Ops.get_string(
                      one_service,
                      "iid",
                      selected_item
                    )
                    to_select = selected_item
                    raise Break
                  else
                    Builtins.y2debug(
                      "Does not match the current one %1",
                      one_service
                    )
                  end
                end
              end

              # y2milestone("Current line %1", current_line);
              # Translators: Caption of EditOrCreateServiceDlg()
              return_val = EditOrCreateServiceDlg(
                _("Edit a service entry"),
                current_line
              )
              # y2milestone("Edit returned %1", return_val);

              # check for changes
              if return_val != nil
                Inetd.changeLine(return_val, selected_item)
                Inetd.modified = true
              end
              need_reindex = true
              need_rebuild = true
            end
          else
            # Translators: Popup::Message
            Popup.Message(_("To edit a service, select one in the main dialog"))
            need_reindex = false
            need_rebuild = false
            to_select = ""
          end
        elsif ret == :abort || ret == :back
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :next || ret == :back
          break
        else
          Builtins.y2error("unexpected retcode: %1", ret)
          next
        end
        # if(!((ret == `next) || (ret == `back) || (ret == `abort))) {
        #     Inetd::modified = true;
        # }
        @table_data = CreateTableData(Inetd.netd_conf)
        indexTable if need_reindex == true
        UI.ChangeWidget(Id(:table), :Items, @table_data)
        UI.ChangeWidget(Id(:table), :CurrentItem, to_select) if to_select != ""
      end

      if ret == :next
        if Inetd.netd_status && IsAnyServiceEnabled(Inetd.netd_conf) == :no
          Inetd.netd_status = false
          # Translators: Popup::Warning
          Popup.Warning(
            _(
              "All services are marked as disabled (locked).\nInternet super-server will be disabled."
            )
          )
        end
      end

      # Wizard::RestoreScreenShotName();
      Convert.to_symbol(ret)
    end
    def EditOrCreateServiceDlg(title, line)
      line = deep_copy(line)
      # Translators: Special widget for inetd
      input_failed = false # for all required widgets filled check
      user_choice = :back # for UserInput() loop

      # Check for local user list is created...
      @local_users = CreateLocalUsersList() if @local_users == nil
      # Check for local group list is created...
      @local_groups = CreateLocalGroupsList() if @local_groups == nil

      contents = VBox(
        VSquash(
          HBox(
            # service name
            HWeight(3, TextEntry(Id(:service), _("&Service"))),
            HSpacing(1),
            HWeight(1, TextEntry(Id(:rpc_version), _("RPC Versio&n"))),
            HSpacing(1),
            # service status (running or stopped)
            Bottom(
              CheckBox(
                Id(:status),
                _("Service is acti&ve."),
                Ops.get_boolean(line, "enabled", false)
              )
            )
          )
        ),
        HBox(
          # service socket type
          HWeight(
            3,
            ComboBox(
              Id(:type),
              Opt(:hstretch),
              _("Socket T&ype"),
              ["stream", "dgram", "raw", "seqpacket"]
            )
          ),
          HSpacing(1),
          # for protocol option - ediatble ComboBox
          HWeight(
            3,
            ComboBox(
              Id(:protocol),
              Opt(:hstretch),
              _("&Protocol"),
              ["tcp", "udp", "rpc/tcp", "rpc/udp"]
            )
          ),
          HSpacing(1),
          # for flags (wait/nowait) - noneditable ComboBox
          HWeight(
            3,
            ComboBox(
              Id(:wait),
              Opt(:hstretch),
              _("&Wait"),
              [Item(Id("yes"), _("Yes")), Item(Id("no"), _("No"))]
            )
          ),
          # check for used service - if inetd, add max TextEntry
          HWeight(0, Empty())
        ),
        VBox(
          # user and group ComboBoxes
          HBox(
            HWeight(1, ComboBox(Id(:user), _("&User"), @local_users)),
            HSpacing(1),
            HWeight(1, ComboBox(Id(:group), _("&Group"), @local_groups))
          ),
          # Server arguments
          TextEntry(Id(:server), _("S&erver")),
          TextEntry(Id(:servargs), _("Server Argumen&ts")),
          # Comment above the service line in inetd.conf
          MultiLineEdit(Id(:comment), _("Co&mment"))
        )
      )

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("inetd")
      Wizard.SetContentsButtons(
        title,
        contents,
        EditCreateHelp(),
        Label.CancelButton,
        Label.AcceptButton
      )

      Wizard.SetScreenShotName("inetd-6-servicedetails")

      UI.SetFocus(Id(:service))

      # NOW!! fill widgets
      #
      # inetd has special widget max - we must check it
      UI.ChangeWidget(Id(:service), :Value, Ops.get_string(line, "service", ""))
      UI.ChangeWidget(
        Id(:rpc_version),
        :Value,
        Ops.get_string(line, "rpc_version", "")
      )
      UI.ChangeWidget(
        Id(:type),
        :Value,
        Ops.get_string(line, "socket_type", "")
      )
      UI.ChangeWidget(
        Id(:protocol),
        :Value,
        Ops.get_string(line, "protocol", "")
      )
      if Ops.get_boolean(line, "wait", true) == true
        UI.ChangeWidget(Id(:wait), :Value, "yes")
      else
        UI.ChangeWidget(Id(:wait), :Value, "no")
      end
      UI.ChangeWidget(Id(:user), :Value, Ops.get_string(line, "user", ""))
      group = Ops.get_string(line, "group", "")
      if group == ""
        # Translators: Please BE CAREFUL! This text is often used in code! This Translation must be the same.
        UI.ChangeWidget(Id(:group), :Value, _("--default--"))
      else
        UI.ChangeWidget(Id(:group), :Value, group)
      end
      UI.ChangeWidget(Id(:server), :Value, Ops.get_string(line, "server", ""))
      UI.ChangeWidget(
        Id(:servargs),
        :Value,
        Ops.get_string(line, "server_args", "")
      )
      UI.ChangeWidget(Id(:comment), :Value, Ops.get_string(line, "comment", ""))

      Wizard.HideAbortButton
      begin
        user_choice = UI.UserInput
        user_choice = :back if user_choice == :cancel # window-close button

        if user_choice != :back
          service_name = Convert.to_string(UI.QueryWidget(Id(:service), :Value))

          # Are required values filled?
          # Inetd specific:
          #   Service and Server must be filled
          # Xinetd specific:
          #   Service must be filled.
          if service_name == ""
            Popup.Message(
              # Translators: Popup::Message
              _("Service is empty.\nEnter valid values.\n")
            )
            input_failed = true
          elsif service_name != nil && Builtins.search(service_name, "/") != nil
            # Error message
            Popup.Message(
              _("Service name contains disallowed character \"/\".")
            )
            input_failed = true
          elsif UI.QueryWidget(Id(:server), :Value) != "" &&
              UI.QueryWidget(Id(:user), :Value) == _("--default--")
            # Translators: sformat-ed() 3 strings
            Popup.Message(
              Builtins.sformat(
                _("The user %1 is reserved for internal server processes only."),
                _("--default--")
              )
            )
            input_failed = true
          else
            input_failed = false
            if Convert.to_boolean(UI.QueryWidget(Id(:status), :Value))
              line = Builtins.add(line, "enabled", true)
            else
              line = Builtins.add(line, "enabled", false)
            end
            # do not add a "flags" field, it's currently in "unparsed"
            if UI.QueryWidget(Id(:wait), :Value) == "yes"
              line = Builtins.add(line, "wait", true)
            else
              line = Builtins.add(line, "wait", false)
            end
            line = Builtins.add(
              line,
              "service",
              UI.QueryWidget(Id(:service), :Value)
            )
            line = Builtins.add(
              line,
              "rpc_version",
              UI.QueryWidget(Id(:rpc_version), :Value)
            )
            line = Builtins.add(
              line,
              "socket_type",
              UI.QueryWidget(Id(:type), :Value)
            )
            line = Builtins.add(
              line,
              "protocol",
              UI.QueryWidget(Id(:protocol), :Value)
            )
            line = Builtins.add(line, "user", UI.QueryWidget(Id(:user), :Value))
            group = Convert.to_string(UI.QueryWidget(Id(:group), :Value))
            group = "" if group == _("--default--")
            line = Builtins.add(line, "group", group)
            line = Builtins.add(
              line,
              "server",
              UI.QueryWidget(Id(:server), :Value)
            )
            line = Builtins.add(
              line,
              "server_args",
              UI.QueryWidget(Id(:servargs), :Value)
            )
            line = Builtins.add(
              line,
              "comment",
              UI.QueryWidget(Id(:comment), :Value)
            )
          end
        end
      end until user_choice == :next && input_failed == false || user_choice == :back
      Wizard.CloseDialog
      Wizard.RestoreScreenShotName
      # tell the calling function what user done
      if user_choice == :back
        return nil # operation canceled
      else
        return deep_copy(line) # line changed
      end
    end
  end
end
