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

#Available options for reference systems. 
boiler_fueltypes = ["NaturalGas","Electricity","PropaneGas","FuelOil#1","FuelOil#2","Coal","Diesel","Gasoline","OtherFuel1"]
mau_types = [true, false]
mau_heating_coil_types = ["Hot Water", "Electric"]
baseboard_types = ["Hot Water" , "Electric"]
chiller_types = ["Scroll","Centrifugal","Screw","Reciprocating"]
mua_cooling_types = ["DX","Hydronic"]
heating_coil_types_sys3 = ["Electric", "Gas", "DX"]
heating_coil_types_sys4and6 = ["Electric", "Gas"]
fan_types = ["AF_or_BI_rdg_fancurve","AF_or_BI_inletvanes","fc_inletvanes","var_speed_drive"]


#Load doe inp file change path as necessary.

#try loading the file. 
BTAP::FileIO::get_find_files_from_folder_by_extension( "C:/projects/OpenStudio-analysis-spreadsheet/lib/btap/resources/models/DOEArchetypes/OSM_NECB_Space_Types", '.osm' ).each do |file|
  model = BTAP::FileIO::load_osm( file )
  system_zone_array = BTAP::Compliance::NECB2011::necb_autozoner( model )
  system_zone_array.each_with_index do |zones,system_index|
    #skip if no thermal zones for this system.
    next if zones.size == 0
    puts "Zone Names for System #{system_index}"
      case system_index
      when 1
        BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys1(model, zones, boiler_fueltypes[0], mau_types[0], mau_heating_coil_types[0], baseboard_types[0])
      when 2
        BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys2(model, zones, boiler_fueltypes[0], chiller_types[0], mua_cooling_types[0])
      when 3
        BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys3(model, zones, boiler_fueltypes[0], heating_coil_types_sys3[0], baseboard_types[0])
      when 4
        BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys4(model, zones, boiler_fueltypes[0], heating_coil_types_sys4and6[0], baseboard_types[0])
      when 5
        BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys5(model, zones, boiler_fueltypes[0], chiller_types[0], mua_cooling_types[0])
      when 6
        BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys6(model, zones, boiler_fueltypes[0], heating_coil_types_sys4and6[0], baseboard_types[0], chiller_types[0], fan_types[0])
      when 7
        #system 7 is undefined... using system 2 until Kamel gets back. 
        BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys2(model, zones, boiler_fueltypes[0], chiller_types[0], mua_cooling_types[0])
      end

  end
  new_file = "#{File.dirname(file)}/auto_zoned/#{File.basename(file,".osm")}.osm"

  BTAP::FileIO::save_osm( model, new_file )
end

