#
#--
#
# $Id$
#
# webgen: a template based web page generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#

require 'yaml'
require 'redcloth'
require 'webgen/plugins/filehandler/page'

module FileHandlers

  # Handles files in Textile format using RedCloth.
  class RedClothPagePlugin < PagePlugin

    NAME = "Textile Page Handler"
    SHORT_DESC = "Handles webpage description files in Textile format using RedCloth"

    EXTENSION = 'rcloth'

    def get_file_data( srcName )
      data = Hash.new
      data['content'] = RedCloth.new( File.read( srcName ) ).to_html
      data
    end

  end

  UPS::Registry.register_plugin RedClothPagePlugin

end