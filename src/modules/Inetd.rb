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
# File:	modules/Inetd.ycp
# Package:	Configuration of inetd
# Summary:	Data for configuration of inetd, input and output functions.
# Authors:	Petr Hadraba <phadraba@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Representation of the configuration of inetd.
# Input and output routines.
require "yast"

module Yast
  class InetdClass < Module
    include Yast::Logger

    SERVICE_NAME = "xinetd"

    def main
      Yast.import "UI"
      textdomain "inetd"

      #
      # **Structure:**
      #
      #     service
      #      <pre>
      #      A service map looks like this:
      #      $[
      #* as seen on TV^H^H (x)inetd.conf:
      #        "service": string      // * different from equally named field above
      #        "rpc_version": string
      #        "socket_type": string
      #        "protocol": string
      #        "wait": boolean
      #        "max": integer         // inetd only
      #        "user": string         // *
      #        "group": string
      #        "server": string
      #        "server_args": string
      #        "comment": string      // possibly multiline, without #
      #        "enabled": boolean     // service is active
      #* bookkeeping fields:
      #        "iid": string          // internal id, use as table `id
      #                               //   Iid is necessary because there may be multiple variants
      #                               //   of the same service. See next for iid handling.
      #        "changed": boolean     // when writing, unchanged services are ignored
      #                               //   new services (created) must be set as changed
      #                               //   see changeLine() and see addLine() for more details
      #        "deleted": boolean     // when deleting, this is set to TRUE and changed
      #                               // must be set too (see deleteLine())
      #        "script": string	// which configuration file this comes from
      #        "package": string	// which rpm it is in
      #* other fields:
      #      When handling existing maps, take care to preserve any other fields
      #      that may be present!
      #
      #  "unparsed": string	// what the agent could not parse
      # ]
      #
      # path netd = .whatever.inetd or .whatever.xinetd;
      #
      # SCR::Read (.etc.inetd_conf.services) -> list of inetd configuration
      # SCR::Read (.etc.xinetd_conf.services) -> list of xinetd configuration
      # SCR::Write (.etc.inetd_conf.services, list) -> boolean
      # SCR::Write (.etc.xinetd_conf.services, list) -> boolean
      #
      # "iid" handling:
      # The agent (ag_netd) uses it to locate the service in the config
      # files.  Its value should be considered opaque, except that
      # ag_netd will check whether it contains a colon (:) and if not,
      # consider it a new service.
      # Thus new services get "new"+number.
      # Non-installed services:
      #   in normal ui they appear only in the table and get "NI"+number
      #   in autoyast ui they get "inst"+number
      # Where number is last_created
      # </pre>
      # @see <a href="../autoyast_proto.xhtml">autoyast docs</a>.

      Yast.import "Service"
      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Directory"
      Yast.import "String"
      Yast.import "XVersion"

      Yast.include self, "inetd/default_conf_xinetd.rb"

      # Abort function
      # return boolean return true if abort
      @AbortFunction = nil

      Yast.include self, "inetd/routines.rb"

      # Configuration was changed
      @modified = false

      # used in unused module inetd_proposal.ycp. This will be removed
      @proposal_valid = false

      # For autoinstallation Write() process.
      # Write_only means that the service will not be actually started,
      # because it is done by init later.
      # But also that the service data are only a patch to be applied to the system.
      @write_only = false

      # If autoinstallation mode (true), we do not want to install RPMs during configuration.
      # Otherwise (false) we allow all.
      @auto_mode = false

      # Autoyast now does not initially call Import $[] anymore. But our
      # design is so broken that we need it and will work hard to achieve it.
      @autoyast_initialized = false

      # <pre>
      # These variable holds inetd configuration.
      # This is list of maps. Each map has the following structure:
      #   $[
      #     "comment": String,
      #     "comment_inside": String, // this is agent internal
      #     "enabled": boolean,
      #     "group": String,
      #     "user": String,
      #     "iid": String,
      #     "protocol": String,
      #     "rpc_version": String,
      #     "server": String,
      #     "server_args": String,
      #     "service": String,
      #     "socket_type": String,
      #     "unparsed": String,       // agent internal
      #     "wait": boolean
      #  ]
      # </pre>
      @netd_conf = []

      # Is xinetd running?
      # These variables contains return values from Service::Status() calls.
      @netd_status = false

      # This variable is used for new iid "generator"
      @last_created = 0
    end

    # Abort function
    # @return If AbortFunction not defined, returnes false
    def Abort
      return Builtins.eval(@AbortFunction) == true if @AbortFunction != nil
      false
    end

    # Data was modified? This function returnes modified variable.
    # @return true if modified
    def Modified
      #y2debug("modified=%1",modified);
      @modified
    end

    # Read all inetd settings
    # @return true on success
    def Read
      # Inetd read dialog caption
      caption = _("Initializing inetd Configuration")

      steps = 1

      Progress.New(
        caption,
        " ",
        steps,
        [_("Read the Configuration")],
        [_("Reading the configuration..."), _("Finished")],
        ""
      )

      read_status = 0
      # read database
      return false if Abort()

      @netd_conf = Convert.convert(
        SCR.Read(path(".etc.xinetd_conf.services")),
        :from => "any",
        :to   => "list <map <string, any>>"
      )

      @netd_status = Service.active?(SERVICE_NAME)

      return false if Abort()
      ProgressNextStage(_("Finished"))

      return false if Abort()
      @modified = false
      Progress.Finish
      true
    end

    # This function solves differences between new
    # (after installing requested packages)
    # xinetd configuration and the configuration edited by the user.
    # <pre>
    # <b>In normal mode</b>:
    # take the system services
    #   if it matches a service in the ui (ServicesMatch)
    #     use the ui data
    # (not-installed ones are not a part of netd_conf, they
    # only enter the table in mergexinetdconfs)
    # Deleted services: OK.
    # Added services: a separate pass needed
    # </pre>
    # TODO reduce the quadratic complexity.
    # @param [Array<Hash{String => Object>}] system_conf holds new configuration (on the system)
    # @param [Array<Hash{String => Object>}] edited_conf holds old configuration (UI)
    # @return [Array] Returnes new solved xinetd configuration (ready for Write()).
    def MergeEditedWithSystem(system_conf, edited_conf)
      system_conf = deep_copy(system_conf)
      edited_conf = deep_copy(edited_conf)
      new_entry = nil

      # Take system services as the basis
      # (they include the newly installed ones)
      # and replace most of them with their edited counterparts
      # that also takes care of deleted services
      # but not of added ones
      system_conf = Builtins.maplist(system_conf) do |system_s|
        new_entry = deep_copy(system_s)
        Builtins.foreach(edited_conf) do |edited_s|
          new_entry = deep_copy(edited_s) if ServicesMatch(system_s, edited_s)
        end
        deep_copy(new_entry)
      end

      Builtins.y2milestone("CONF: %1", edited_conf)
      # now the added services
      added = Builtins.filter(edited_conf) do |edited_s|
        Builtins.search(Ops.get_string(edited_s, "iid", ""), "new") == 0
      end
      Builtins.flatten([system_conf, added])
    end

    # Write all inetd settings
    # @return true on success
    def Write
      # Inetd read dialog caption
      caption = _("Saving inetd Configuration")

      steps = 1

      Progress.New(
        caption,
        " ",
        steps,
        [_("Write the settings")],
        [_("Writing the settings..."), _("Finished")],
        ""
      )

      Builtins.y2milestone("Calling write:\n")
      # write settings
      return false if Abort()

      if @write_only
        # YUCK, looks like autoinst part, should be done in inetd_auto.ycp
        new_conf = []
        new_conf = Convert.convert(
          SCR.Read(path(".etc.xinetd_conf.services")),
          :from => "any",
          :to   => "list <map <string, any>>"
        )
        @netd_conf = mergeAfterInstall(new_conf, @netd_conf)
      end

      SCR.Write(path(".etc.xinetd_conf.services"), @netd_conf)
      adjust_xinetd_service

      Builtins.y2milestone("Writing done\n")

      # in future: catch errors
      Report.Error(_("Cannot write settings!")) if false

      return false if Abort()
      ProgressNextStage(_("Finished"))

      return false if Abort()
      Progress.Finish
      true
    end

    # Starts or stops and enables or disables the xinetd service
    # depending on the current and requested service state
    def adjust_xinetd_service
      current_status = Service.active?(SERVICE_NAME)

      if @netd_status
        if current_status
          log.info "#{SERVICE_NAME} was running -> calling reload"
          Service.reload(SERVICE_NAME) unless @write_only
        else
          log.info "#{SERVICE_NAME} was stopped -> enabling and starting service"
          Service.Start(SERVICE_NAME) unless @write_only
        end
        Service.Enable(SERVICE_NAME)
      else
        if current_status
          log.info "#{SERVICE_NAME} was running -> stoping and disabling service"
          Service.Stop(SERVICE_NAME) unless @write_only
        else
          log.info "#{SERVICE_NAME} was stopped -> leaving unchanged"
        end
        Service.Disable(SERVICE_NAME)
      end
    end

    # Only Write settings
    # @return [Boolean] True on success
    def WriteOnly
      @write_only = true
      Write()
    end

    # Merges autoinstall profile into the system configuration.
    # @param [Array<Hash{String => Object>}] system_c holds new configuration (on the system)
    # @param [Array<Hash{String => Object>}] user_c  holds old configuration (auto: profile + defaults)
    # @return [Array] Returnes new solved xinetd configuration (ready for Write()).
    # @see #MergeAyProfile
    def mergeAfterInstall(system_c, user_c)
      system_c = deep_copy(system_c)
      user_c = deep_copy(user_c)
      MergeAyProfile(system_c, user_c)
    end

    # merges imported changes with services defaults
    # @param [Array<Hash{String => Object>}] changes imported changes
    # @return complete configuration with user changes
    # @see #MergeAyProfile
    def mergeWithDefaults(changes)
      changes = deep_copy(changes)
      repaired_default_conf = []

      # replacing all './etc/xinetd.d/...' paths with '/etc/xinetd.d/...'
      # path must be absolute
      Builtins.foreach(@default_conf) do |service|
        iid = Ops.get_string(service, "iid", "")
        if Builtins.regexpmatch(iid, "^(.*):./etc/xinetd.d/(.*)$")
          Ops.set(
            service,
            "iid",
            Builtins.regexpsub(
              iid,
              "^(.*):\\./etc/xinetd.d/(.*)$",
              "\\1:/etc/xinetd.d/\\2"
            )
          )
        end
        repaired_default_conf = Builtins.add(repaired_default_conf, service)
      end

      MergeAyProfile(repaired_default_conf, changes)
    end

    # Removes keys from a map. Unlike the remove builtin, does not mind if
    # the keys are already removed.
    # @param [Hash] m a map
    # @param [Array] keys list of keys to remove
    # @return the map without the specified keys
    def SafeRemove(m, keys)
      m = deep_copy(m)
      keys = deep_copy(keys)
      Builtins.foreach(keys) do |key|
        m = Builtins.remove(m, key) if Builtins.haskey(m, key)
      end
      deep_copy(m)
    end

    # Merges AY profile items into a target list (defaults or system).
    # @param [Array<Hash{String => Object>}] target base list of services
    # @param [Array<Hash{String => Object>}] changes imported changes
    # @return merged list of services
    # @see <a href="../autoyast_proto.xhtml">autoyast docs</a>.
    def MergeAyProfile(target, changes)
      target = deep_copy(target)
      changes = deep_copy(changes)
      # for each change in the patch list:
      Builtins.foreach(changes) do |change_s|
        matches = 0
        # For compatibility and as a hook for workarounds
        # if the matching turns out to be too clever:
        # skip matching
        change_iid = Ops.get_string(change_s, "iid", "")
        if Builtins.search(change_iid, "new") != 0 # do nothing if matches is 0 and we add the service
          # || find (change_iid, "inst") == 0
          # apply the change to the target list:
          target = Builtins.maplist(target) do |target_s|
            new_entry = deep_copy(target_s)
            if ServicesMatch(change_s, target_s)
              # yippee, it matches
              matches = Ops.add(matches, 1)

              # Cannot do a simple union, because we don't
              # want to merge the "server" key field:
              # The "basename (package)" content generated by the
              # AY UI must be avoided.
              # And while merging, iid must be also preserved
              to_merge = SafeRemove(change_s, ["server", "iid"])
              new_entry = Convert.convert(
                Builtins.union(new_entry, to_merge),
                :from => "map",
                :to   => "map <string, any>"
              )
              new_entry = Builtins.add(new_entry, "changed", true)
              # "enabled" is true - if not present
              new_entry = Builtins.add(
                new_entry,
                "enabled",
                Ops.get_boolean(change_s, "enabled", true)
              )
            end
            deep_copy(new_entry)
          end
        end
        # Not found in target? Three states happened:
        #  - Service is new (user wants forEx. telnet on port #53;-)
        #  - Service is from non-SuSE package
        #  - Service name or description is invalid
        if matches == 0
          target = Builtins.add(target, change_s)
        elsif Ops.greater_than(matches, 1)
          Builtins.y2warning("Ambiguous match (%1): %2", matches, change_s)
        end
      end

      #y2milestone("%1", changes);
      #y2milestone("%1", target);

      deep_copy(target)
    end

    # Get all inetd settings from the first parameter
    # (For use by autoinstallation.)
    # @param [Hash] settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(settings)
      settings = deep_copy(settings)
      #y2milestone("settings = %1", settings);
      @netd_conf = mergeWithDefaults(Ops.get_list(settings, "netd_conf", []))
      # old profile can still use integer value (0 == true)
      @netd_status = [0, true].include?(settings["netd_status"])

      # common variables
      @last_created = Ops.get_integer(settings, "last_created", 0)
      #y2milestone("%1", netd_conf);
      true
    end

    # Get only changed entries
    # @param [Array<Hash{String => Object>}] config complete configuration
    # @return Returnse list of changes only
    def getChanged(config)
      config = deep_copy(config)
      defaults = []
      changes = []
      def_line = {}
      return deep_copy(changes) if config == nil

      defaults = deep_copy(@default_conf)

      # defaults not loaded --- get all services listed in config
      return deep_copy(config) if defaults == []

      # Deleted services: so far they are exported
      # But maybe better to allow only deleting added services (~ undo)
      # and thus not export them.
      Builtins.foreach(config) do |line|
        # only changed ones...
        if Ops.get_boolean(line, "changed", false)
          # now trim the fields that are not necessary, because
          # they are a part of the defaults

          # new or installed services (iid is `^new.*' or `^inst.*')
          # are not trimmed
          line_iid = Ops.get_string(line, "iid", "")
          if Builtins.search(line_iid, "new") == 0 ||
              Builtins.search(line_iid, "inst") == 0
            changes = Builtins.add(changes, line)
            next # skip the following code
          end

          # Find coresponding entry in `defaults'.
          # Could use iid here because we started editing
          # with the defaults list
          # but it broke the testsuite.
          def_line = Builtins.find(defaults) do |default_s|
            ServicesMatch(line, default_s)
          end

          # item not found
          # So, write this entry into `changes'
          if def_line == nil
            changes = Builtins.add(changes, line)
            next # skip the following code
          end

          # especially for inetd, server must not be tcpd, because
          # we could trow away the real server which distinguishes
          # a service among its variants
          if Ops.get_string(line, "server", "") == "/usr/sbin/tcpd"
            s = String.FirstChunk(
              Ops.get_string(line, "server_args", ""),
              " \t"
            )
            line = Builtins.add(line, "server", s)
          end

          # for each item of the map
          Builtins.foreach(line) do |name, val|
            # Remove it if its value is the default
            # and it's not a key field or "enabled" (*).
            # In particular, iid is trimmed here.
            if val == Ops.get(def_line, name) &&
                !Builtins.contains(
                  ["script", "protocol", "service", "server", "enabled"],
                  name
                )
              line = Builtins.remove(line, name)
            end
          end

          # "changed" is implicitly true for all Exported/Imported services
          line = Builtins.remove(line, "changed")
          # "enabled" defaults to true in _Import_, so it would
          # have been wrong above (*) to match it against the
          # _system_ default of false.
          if Ops.get_boolean(line, "enabled", false)
            line = Builtins.remove(line, "enabled")
          end

          changes = Builtins.add(changes, line)
        end
      end

      #y2milestone("%1", changes);
      deep_copy(changes)
    end

    # Dump the inetd settings to a single map
    # (For use by autoinstallation.)
    # @return [Hash] Dumped settings (later acceptable by Import ())
    def Export
      config = {}
      config = Builtins.add(config, "netd_conf", getChanged(@netd_conf))
      config = Builtins.add(config, "netd_status", @netd_status)
      config = Builtins.add(config, "last_created", @last_created)
      Builtins.y2milestone("%1", config)
      deep_copy(config)
    end

    # Create unsorted list of enabled services
    # @return [String] Returnes string with RichText-formated list
    def mkeServiceSummary
      _S = ""
      Builtins.foreach(@netd_conf) do |line|
        #"enabled" defaults to true
        if Ops.get_boolean(line, "enabled", true) &&
            !Ops.get_boolean(line, "deleted", false)
          _S = Builtins.sformat(
            "%1<li>%2 <i>(%3)</i>",
            _S,
            Ops.get_string(line, "service", ""),
            Ops.get_string(line, "protocol", "")
          )
        end
      end
      if _S == ""
        _S = _("<p><ul><i>All services are marked as stopped.</i></ul></p>")
      end
      _S
    end

    # Create a textual summary and a list of unconfigured cards
    # @return summary of the current configuration
    def Summary
      _S = ""
      if @netd_conf == []
        # Translators: Summary head, if nothing configured
        _S = Summary.AddHeader(_S, _("Network services"))
        _S = Summary.AddLine(_S, Summary.NotConfigured)
      else
        # Translators: Summary head, if something configured
        head = Builtins.sformat(_("Network services are managed via %1"), SERVICE_NAME)

        _S = Summary.AddHeader(_S, head)
        _S = Summary.AddHeader(_S, _("These services will be enabled"))
        _S = Builtins.sformat("%1<ul>%2</ul></p>", _S, mkeServiceSummary)
      end
      _S
    end

    # delete line in netd_conf
    # @param [Object] line_number "iid" geted from table's item ID
    def deleteLine(line_number)
      line_number = deep_copy(line_number)
      # delete
      current_line = Builtins.find(@netd_conf) do |line|
        Ops.get_string(line, "iid", "0") == line_number
      end
      if current_line == nil
        Builtins.y2internal("can't happen")
        current_line = {}
      end
      # set "deleted" flag to true
      current_line = Builtins.add(current_line, "changed", true)
      current_line = Builtins.add(current_line, "deleted", true)
      @netd_conf = Builtins.maplist(@netd_conf) do |line|
        if Ops.get_string(line, "iid", "0") == line_number
          next deep_copy(current_line)
        else
          next deep_copy(line)
        end
      end

      nil
    end

    # add a line in DB
    # @param [Hash{String => Object}] new_line new_line contains new entry for global netd_conf configuration
    # @return [void]
    def addLine(new_line)
      new_line = deep_copy(new_line)
      # add
      new_line = Builtins.add(new_line, "changed", true)
      @netd_conf = Builtins.add(@netd_conf, new_line)
      nil
    end

    # Change a line in DB
    # @param [Hash{String => Object}] new_line new_line contains changes for entry in netd_conf
    # @param [Object] line_number line_number contains iid of changed entry in netd_conf
    def changeLine(new_line, line_number)
      new_line = deep_copy(new_line)
      line_number = deep_copy(line_number)
      # entry was changed - so set "changed" flag to true
      new_line = Builtins.add(new_line, "changed", true)
      @netd_conf = Builtins.maplist(@netd_conf) do |line|
        if Ops.get_string(line, "iid", "0") == line_number
          next deep_copy(new_line)
        else
          next deep_copy(line)
        end
      end

      nil
    end
    # Return required packages for auto-installation
    # FIXME: Need to make this return the needed packages during installation
    # @return [Hash] of packages to be installed and to be removed
    def AutoPackages
      { "install" => [], "remove" => [] }
    end

    def DBG(i)
      Builtins.y2internal("%1", i)
      Builtins.y2milestone("  netd_conf: %1", @netd_conf)

      nil
    end

    # LiMaL interface

    def GetServicesId(mask)
      mask = deep_copy(mask)
      ids = []
      i = 0

      while Ops.greater_than(Builtins.size(@netd_conf), i)
        fit = true
        Builtins.foreach(mask) do |key, val|
          fit = false if fit && val != Ops.get(@netd_conf, [i, key])
        end if mask != nil
        ids = Builtins.add(ids, Builtins.tostring(i)) if fit
        i = Ops.add(i, 1)
      end
      deep_copy(ids)
    end

    def ServiceAttributes(id)
      Builtins.maplist(Ops.get(@netd_conf, Builtins.tointeger(id), {})) do |attribute, val|
        attribute
      end
    end

    def ServiceGetStr(id, attribute, dflt)
      if Builtins.haskey(
          Ops.get(@netd_conf, Builtins.tointeger(id), {}),
          attribute
        )
        return Ops.get_string(@netd_conf, [Builtins.tointeger(id), attribute])
      end
      dflt
    end

    def ServiceGetInt(id, attribute, dflt)
      if Builtins.haskey(
          Ops.get(@netd_conf, Builtins.tointeger(id), {}),
          attribute
        )
        return Ops.get_integer(@netd_conf, [Builtins.tointeger(id), attribute])
      end
      dflt
    end

    def ServiceGetTruth(id, attribute, dflt)
      if Builtins.haskey(
          Ops.get(@netd_conf, Builtins.tointeger(id), {}),
          attribute
        )
        return Ops.get_boolean(@netd_conf, [Builtins.tointeger(id), attribute])
      end
      dflt
    end

    def ServiceEnabled(id)
      ServiceGetTruth(id, "enabled", true)
    end

    def ServiceDelete(id)
      deleteLine(
        Ops.get_string(@netd_conf, [Builtins.tointeger(id), "iid"], "")
      )
      true
    end

    def ServiceAdd(service)
      service = deep_copy(service)
      addLine(service)
      true
    end

    def ServiceChange(id, service)
      service = deep_copy(service)
      changeLine(
        service,
        Ops.get_string(@netd_conf, [Builtins.tointeger(id), "iid"], "")
      )
      true
    end

    publish :function => :mergeAfterInstall, :type => "list <map <string, any>> (list <map <string, any>>, list <map <string, any>>)"
    publish :function => :MergeAyProfile, :type => "list <map <string, any>> (list <map <string, any>>, list <map <string, any>>)"
    publish :variable => :default_conf, :type => "list <map <string, any>>"
    publish :variable => :AbortFunction, :type => "block <boolean>"
    publish :function => :Modified, :type => "boolean ()"
    publish :function => :Abort, :type => "boolean ()"
    publish :variable => :modified, :type => "boolean"
    publish :variable => :proposal_valid, :type => "boolean"
    publish :variable => :write_only, :type => "boolean"
    publish :variable => :auto_mode, :type => "boolean"
    publish :variable => :autoyast_initialized, :type => "boolean"
    publish :variable => :netd_conf, :type => "list <map <string, any>>"
    publish :variable => :netd_status, :type => "boolean"
    publish :variable => :netd_status_read, :type => "boolean"
    publish :variable => :last_created, :type => "integer"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :MergeEditedWithSystem, :type => "list <map <string, any>> (list <map <string, any>>, list <map <string, any>>)"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :WriteOnly, :type => "boolean ()"
    publish :function => :mergeWithDefaults, :type => "list <map <string, any>> (list <map <string, any>>)"
    publish :function => :SafeRemove, :type => "map (map, list)"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :getChanged, :type => "list <map <string, any>> (list <map <string, any>>)"
    publish :function => :Export, :type => "map ()"
    publish :function => :mkeServiceSummary, :type => "string ()"
    publish :function => :Summary, :type => "string ()"
    publish :function => :deleteLine, :type => "void (any)"
    publish :function => :addLine, :type => "void (map <string, any>)"
    publish :function => :changeLine, :type => "void (map <string, any>, any)"
    publish :function => :AutoPackages, :type => "map ()"
    publish :function => :DBG, :type => "void (string)"
    publish :function => :GetServicesId, :type => "list <string> (map <string, any>)"
    publish :function => :ServiceAttributes, :type => "list <string> (string)"
    publish :function => :ServiceGetStr, :type => "string (string, string, string)"
    publish :function => :ServiceGetInt, :type => "integer (string, string, integer)"
    publish :function => :ServiceGetTruth, :type => "boolean (string, string, boolean)"
    publish :function => :ServiceEnabled, :type => "boolean (string)"
    publish :function => :ServiceDelete, :type => "boolean (string)"
    publish :function => :ServiceAdd, :type => "boolean (map <string, any>)"
    publish :function => :ServiceChange, :type => "boolean (string, map <string, any>)"
  end

  Inetd = InetdClass.new
  Inetd.main
end
