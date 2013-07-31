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
# File:	include/inetd/wizards.ycp
# Package:	Configuration of inetd
# Summary:	Wizards definitions
# Authors:	Petr Hadraba <phadraba@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
module Yast
  module InetdWizardsInclude
    def initialize_inetd_wizards(include_target)
      Yast.import "UI"

      textdomain "inetd"

      Yast.import "Wizard"
      Yast.import "Label"
      Yast.import "Sequencer"
      Yast.import "Confirm"
      Yast.import "Package"
      Yast.import "PackageSystem"

      Yast.include include_target, "inetd/complex.rb"
      Yast.include include_target, "inetd/dialogs.rb"
    end

    # Whole configuration of inetd
    # @return sequence result
    def InetdSequence
      # agents barf if not root, #35363
      return :abort if !Confirm.MustBeRoot

      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { InetdDialog() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("inetd")

      ret = :abort

      if PackageSystem.CheckAndInstallPackagesInteractive(["xinetd"])
        ret = Sequencer.Run(aliases, sequence)
      end

      UI.CloseDialog
      Wizard.RestoreScreenShotName

      ret
    end

    # Whole configuration of inetd but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def InetdAutoSequence
      caption = _("Xinetd Configuration")
      contents = Label(_("Initializing ..."))

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("inetd")
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      Package.DoInstall(["xinetd"])

      ret = InetdDialog()

      Builtins.y2milestone("%1", ret)
      UI.CloseDialog
      ret
    end
  end
end
