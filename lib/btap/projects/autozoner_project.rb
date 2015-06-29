# *********************************************************************
# *  Copyright (c) 2008-2015, Natural Resources Canada
# *  All rights reserved.
# *
# *  This library is free software; you can redistribute it and/or
# *  modify it under the terms of the GNU Lesser General Public
# *  License as published by the Free Software Foundation; either
# *  version 2.1 of the License, or (at your option) any later version.
# *
# *  This library is distributed in the hope that it will be useful,
# *  but WITHOUT ANY WARRANTY; without even the implied warranty of
# *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# *  Lesser General Public License for more details.
# *
# *  You should have received a copy of the GNU Lesser General Public
# *  License along with this library; if not, write to the Free Software
# *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
# **********************************************************************/

require "#{File.dirname(__FILE__)}/../lib/btap"
require "#{File.dirname(__FILE__)}/../lib/compliance"
# To change this template, choose Tools | Templates
# and open the template in the editor.

#Load doe inp file change path as necessary.

#try loading the file. 
BTAP::FileIO::get_find_files_from_folder_by_extension( "C:/projects/OpenStudio-analysis-spreadsheet/lib/btap/resources/models/DOEArchetypes/OSM_NECB_Space_Types", '.osm' ).each do |file|
  model = BTAP::FileIO::load_osm( file )
  system_zone_array = BTAP::Compliance::NECB2011::necb_autozoner( model )
  system_zone_array.each_with_index do |thermal_zone_array,system_index|
    #skip if no thermal zones for this system.
    next if thermal_zone_array.size == 0
    puts "Zone Names for System #{system_index}"
    thermal_zone_array.each do |thermal_zone|
      puts thermal_zone.getAttribute("name").get.valueAsString
    end  
  end
  BTAP::FileIO::save_osm( model, file + "autozone.osm" )
end

