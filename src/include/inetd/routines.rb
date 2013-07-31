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
# File:	include/inetd/routines.ycp
# Package:	Configuration of inetd
# Summary:	Miscelanous functions for configuration of inetd.
# Authors:	Petr Hadraba <phadraba@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
module Yast
  module InetdRoutinesInclude
    def initialize_inetd_routines(include_target)
      Yast.import "UI"

      textdomain "inetd"

      Yast.import "Inetd"
      Yast.import "Progress"
      Yast.import "Service"
      Yast.import "Popup"
      Yast.import "Package"
      Yast.import "UsersCache"
      Yast.import "String"

      # Cache for {#IsInstalled.}
      @is_installed_cache = {}
    end

    # Check for pending Abort press
    # @return true if pending abort
    def PollAbort
      UI.PollInput == :abort
    end

    # If modified, ask for confirmation
    # @return true if abort is confirmed
    def ReallyAbort
      !Inetd.Modified || Popup.ReallyAbort(true)
    end

    # Progress::NextStage and Progress::Title combined into one function
    # @param [String] title progressbar title
    def ProgressNextStage(title)
      Progress.NextStage
      Progress.Title(title)

      nil
    end

    # Used for cpmparisons whether the servers match:
    # If server is /usr/sbin/tcpd, consider server_args instead.
    # Then take the firse word (strips arguments or the parenthesized pkg name).
    # Then take the last slash-delimited component.
    # For sparse matching: nil is returned if server is nil
    # (or if server args is nil AND is needed)
    # @param [String] server "server" field of a service
    # @param [String] server_args "server_args" field of a service
    # @return basename of the real server
    def GetServerBasename(server, server_args)
      result = server
      # discard tcpd
      result = server_args if result == "/usr/sbin/tcpd"
      # check nil
      if result != nil
        # program only
        result = String.FirstChunk(result, " \t")
        # basename
        comp = Builtins.splitstring(result, "/")
        result = Ops.get(comp, Ops.subtract(Builtins.size(comp), 1), "")
      end
      result
    end

    # Considers the maps as structs and tests
    # some of their fields for equality (conjunctively, short circuit).
    # @param [Hash] a one struct
    # @param [Hash] b other struct
    # @param [Array] fields list of keys
    # @return Do the maps have all the named fields equal?
    def struct_match(a, b, fields)
      a = deep_copy(a)
      b = deep_copy(b)
      fields = deep_copy(fields)
      # short circuit: use the _find_ builtin to get the mismatching key
      mismatch = Builtins.find(fields) do |key|
        Ops.get(a, key) != Ops.get(b, key)
      end
      # mismatch is nil => they match
      mismatch == nil
    end

    # Considers the maps as structs and tests
    # some of their fields for equality (conjunctively, short circuit).
    # If a key is missing in either of the maps, it is considered as matching.
    # <p> Used when merging autoyast items, to match only those fields that
    # are specified in the profile. There, only one map is sparse.
    # (the profile map)
    # @param [Hash] a one struct
    # @param [Hash] b other struct
    # @param [Array] fields list of keys
    # @return Do the maps have all named fields that are in both of them equal?
    # @example match: $["a": 1, "b": 2, "c": 3], $["b": 2, "d": 4]
    def struct_match_sparse(a, b, fields)
      a = deep_copy(a)
      b = deep_copy(b)
      fields = deep_copy(fields)
      # short circuit: use the _find_ builtin to get the mismatching key
      mismatch = Builtins.find(fields) do |key|
        !(Ops.get(a, key) == Ops.get(b, key) || !Builtins.haskey(a, key) ||
          !Builtins.haskey(b, key))
      end
      # mismatch is nil => they match
      mismatch == nil
    end

    # Determine, if service package is installed.
    # This function requires full configuration
    # (like Inetd::netd_conf) and standalone map with service.
    # Linear complexity (in the working config)
    # @param [Array<Hash{String => Object>}] netd_conf Full configuration
    # @param [Hash{String => Object}] s a {#service}
    # @return match found
    def isServiceMatchPresent(netd_conf, s)
      netd_conf = deep_copy(netd_conf)
      s = deep_copy(s)
      match = Builtins.find(netd_conf) { |i| ServicesMatch(i, s) }
      match != nil
    end

    #  * This function merges real xinetd configuration (read by agent) and
    #  * available services packages generated for SuSE distribution
    #  * This function is automaticaly calld by CreateTableData() if Inetd::configured_service
    #  * is `xinetd.
    #
    #  * Adds those from default_conf that do not have a matching
    #  * service in the working config.
    #
    #  * @param netd_conf not used in this function, but used for
    #  * isServiceMatchPresent call.
    #  * @param table_data Table data structure used as source data
    #  * @return list New table data
    def AddNotInstalled(netd_conf, table_data)
      netd_conf = deep_copy(netd_conf)
      table_data = deep_copy(table_data)
      #y2milestone("in function mergeXinetdConfs()");

      defaults = deep_copy(Inetd.default_conf)

      index = 0
      Builtins.foreach(defaults) do |line|
        if !isServiceMatchPresent(netd_conf, line)
          index = Ops.add(index, 1)
          entry = ServiceToTableItem(line, index)
          table_data = Builtins.add(table_data, entry)
        end
      end
      deep_copy(table_data)
    end
    def ServiceToTableItem(service, ni_index)
      service = deep_copy(service)
      Builtins.y2debug("* %1", Ops.get_string(service, "service", ""))
      status_text = ""
      wait_text = ""

      # determine service is enabled (enabled text)
      changed_text = Ops.get_boolean(service, "changed", false) ? "X" : ""
      if Ops.get_boolean(service, "enabled", true)
        # Translators: Service status: On = running, --- = stopped
        status_text = _("On")
      else
        # Translators: This string you can leave unchanged
        status_text = _("---")
      end

      # HACK:
      # our data structures kinda suck, so we have no quick way of determining
      # what package a service belongs to.
      # But IsInstalled returns true for "" so we don't get to install an
      # unknown package.
      if !IsInstalled(Ops.get_string(service, "package", ""))
        # Translators: This is used for status "Not Installed".
        #    Please, make the
        #    translation as short as possible.
        status_text = _("NI")
      end

      # determine wait mode (convert to string)
      if Ops.get_boolean(service, "wait", true)
        wait_text = _("Yes")
      else
        wait_text = _("No")
      end
      sname = Ops.get_string(service, "service", "")
      rpc_ver = Ops.get_string(service, "rpc_version", "")
      sname = Ops.add(Ops.add(sname, "/"), rpc_ver) if rpc_ver != ""
      user_group = Ops.get_string(service, "group", "")
      if user_group == ""
        user_group = Ops.get_string(service, "user", "")
      else
        # TODO switch to ":" as separator
        user_group = Ops.add(
          Ops.add(Ops.get_string(service, "user", ""), "."),
          user_group
        )
      end
      # create line for table structure
      entry = Item(
        Id(
          ni_index == nil ?
            Ops.get_string(service, "iid", "0") :
            Ops.add("NI", ni_index)
        ),
        changed_text,
        status_text,
        sname,
        Ops.get_string(service, "socket_type", ""),
        Ops.get_string(service, "protocol", ""),
        wait_text,
        user_group,
        Ops.get_string(service, "server", ""),
        Ops.get_string(service, "server_args", "")
      )
      deep_copy(entry)
    end

    # Sorts items for table of xinetd services
    #
    # @param [Array<Yast::Term>] unsorted_terms
    # @return [Array<Yast::Term>] sorted_terms
    def SortTableData(unsorted_terms, sort_by)
      unsorted_terms = deep_copy(unsorted_terms)
      sorted_terms = []

      # string as the service name
      # list of integers of position in unsorted list (the same service name can exist twice or more)
      helper_sorting_map = {}
      position = 0
      service_name = ""
      Builtins.foreach(unsorted_terms) do |item|
        service_name = Ops.get_string(item, sort_by, "")
        Ops.set(
          helper_sorting_map,
          service_name,
          Builtins.add(Ops.get(helper_sorting_map, service_name, []), position)
        )
        position = Ops.add(position, 1)
      end

      # map is sorted by the string service name by defualt
      Builtins.foreach(helper_sorting_map) do |service_name2, term_ids|
        Builtins.foreach(term_ids) do |term_id|
          sorted_terms = Builtins.add(
            sorted_terms,
            Ops.get(unsorted_terms, term_id) { Item("") }
          )
        end
      end

      deep_copy(sorted_terms)
    end

    # Converts configuration format from agent to table data structures
    # @param [Array<Hash{String => Object>}] netd_conf netd_conf handles whole configuration of configured service
    # @return returnes table data
    def CreateTableData(netd_conf)
      netd_conf = deep_copy(netd_conf)
      table_input = []

      Builtins.foreach(netd_conf) do |service|
        # service must be marked as nondeleted ("deleted" == false or "deleted" not exists)
        if !Ops.get_boolean(service, "deleted", false)
          entry = ServiceToTableItem(service, nil)
          # add line to table structure
          table_input = Builtins.add(table_input, entry)
        end
      end

      # now can do it for both superservers
      # ... not yet
      # because in the system data, we do not have the "package" field

      table_input = AddNotInstalled(netd_conf, table_input)

      # table_input = find out which are installed
      # but that would require a better data model.
      # let's try doing with the current one.

      # OK, let's start with sorting the data by the service name
      # term field '2' is the service name
      table_input = SortTableData(table_input, 3)

      deep_copy(table_input)
    end

    # Read user names from passwd.
    # It does not get the NIS entries.
    # "+" is filtered out.
    # @return [Array] users
    def CreateLocalUsersList
      users = Convert.convert(
        Builtins.merge(
          UsersCache.GetUsernames("local"),
          UsersCache.GetUsernames("system")
        ),
        :from => "list",
        :to   => "list <string>"
      )
      users = Builtins.sort(users)
      Builtins.y2debug("users: %1", users)

      users = Builtins.add(users, _("--default--"))
      deep_copy(users)
    end

    # Read group names from  group
    # It does not get the NIS entries.
    # "+" is filtered out.
    # @return [Array] groups
    def CreateLocalGroupsList
      groups = Convert.convert(
        Builtins.merge(
          UsersCache.GetGroupnames("local"),
          UsersCache.GetGroupnames("system")
        ),
        :from => "list",
        :to   => "list <string>"
      )
      groups = Builtins.sort(groups)
      Builtins.y2debug("groups: %1", groups)

      groups = Builtins.add(groups, _("--default--"))

      deep_copy(groups)
    end

    # Find any service to be enabled
    # If no found, return `no
    # @param [Array<Hash{String => Object>}] ready_conf ready_conf handles whole service configuration (Inetd::netd_conf)
    # @return returnes if found `yes, otherwise `no
    def IsAnyServiceEnabled(ready_conf)
      ready_conf = deep_copy(ready_conf)
      ret = :no

      Builtins.foreach(ready_conf) do |line|
        if Ops.get_boolean(line, "deleted", false) == false
          ret = :yes if Ops.get_boolean(line, "enabled", false) != false
        end
      end
      ret
    end
    def ServicesMatch(a, b)
      a = deep_copy(a)
      b = deep_copy(b)
      if struct_match_sparse(a, b, ["script", "service", "protocol"])
        # Compare whether the server matches
        # Watch out for tcpd, use basenames
        # because the 8.2 UI produced server="in.ftpd (ftpd)"
        a_serverbn = GetServerBasename(
          Ops.get_string(a, "server"),
          Ops.get_string(a, "server_args")
        )
        b_serverbn = GetServerBasename(
          Ops.get_string(b, "server"),
          Ops.get_string(b, "server_args")
        )
        if a_serverbn == nil || b_serverbn == nil || a_serverbn == b_serverbn
          return true
        end
      end
      false
    end

    # Clears cache for {#IsInstalled} .
    # This is too wasteful. Later, when it works, optimize for single packages.
    def IsInstalledClearCache
      @is_installed_cache = {}

      nil
    end
    def IsInstalled(rpm)
      result = rpm == "" ? true : Ops.get(@is_installed_cache, rpm)
      if result == nil
        result = Package.Installed(rpm)
        @is_installed_cache = Builtins.add(@is_installed_cache, rpm, result)
      end
      Builtins.y2debug("%1: %2", rpm, result)
      result
    end
  end
end
