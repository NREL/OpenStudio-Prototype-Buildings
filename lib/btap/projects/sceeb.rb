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
# To change this template, choose Tools | Templates
# and open the template in the editor.
require "#{File.dirname(__FILE__)}/btap/btap"

def set_zones_and_constructions(model,default_construction_set)
  geometric_model = model

  #Set ThermalZones for each space.
  geometric_model.getSpaces.each { | space | BTAP::Geometry::Zones::create_thermal_zone(geometric_model, space) }
  #Set Ideal loads for thermal zones.
  geometric_model.getThermalZones.each {|zone| BTAP::Resources::HVAC::ZoneEquipment::add_ideal_air_loads( geometric_model, zone ) }
  #Set Default Construction
  geometric_model.building.get.setDefaultConstructionSet(default_construction_set.clone(geometric_model).to_DefaultConstructionSet.get)

  #Create Climate Zone model array
  puts "Creating Climate zone model Array"
  return BTAP::Compliance::NECB2011::create_climate_scan_necb_model_array(geometric_model)
end


model_array =Array.new
analysisFolder = "C:/ArchetypeSimulations"
#weather_files = BTAP::FileIO::get_find_files_from_folder_by_extension( 'C:/OSRuby/weather_files/','.epw' )
weather_files = [
  'C:/OSRuby/weather_files/CAN_BC_Vancouver.718920_CWEC/CAN_BC_Vancouver.718920_CWEC.epw',
  'C:/OSRuby/weather_files/CAN_ON_Toronto.716240_CWEC/CAN_ON_Toronto.716240_CWEC.epw',
  'C:/OSRuby/weather_files/CAN_BC_Prince.George.718960_CWEC/CAN_BC_Prince.George.718960_CWEC.epw',
  'C:/OSRuby/weather_files/CAN_PQ_Sept-Iles.718110_CWEC/CAN_PQ_Sept-Iles.718110_CWEC.epw',
  'C:/OSRuby/weather_files/CAN_PQ_Lake.Eon.714210_CWEC/CAN_PQ_Lake.Eon.714210_CWEC.epw',
  'C:/OSRuby/weather_files/CAN_NU_Resolute.719240_CWEC/CAN_NU_Resolute.719240_CWEC.epw'
]
#Create base model.
model = BTAP::FileIO::load_osm("C:/OSRuby/Resources/DOEArchetypes/blank.osm", "blank")
#Simulation settings 2 days in January.
BTAP::SimulationSettings::set_run_period( model, 1, 1, 12, 31 )
#Add necb default schedules.
BTAP::Compliance::NECB2011::add_necb_schedules( model )
#Need to add constructions sets
master_lib_path = "C:/osruby/Resources/common/BTAP_Construction_Library.osm"
master_library = BTAP::FileIO::load_osm(master_lib_path, "BTAP_Construction_Library")
default_construction_set = master_library.getDefaultConstructionSetByName("DND-Concrete").get

#remove existing space types from library. We dont need them.
master_library.getSpaceTypes.each { | space_type | space_type.remove }
puts "# Add building types and schedules"
BTAP::Compliance::NECB2011::add_necb_schedules( master_library )
BTAP::Compliance::NECB2011::add_necb_building_types( master_library )
#put all building space types into array for later use.
building_type_array = master_library.getSpaceTypes

puts "# Creating Geometry"
geometric_model_array = [
  #[BTAP::Geometry::Wizards::create_shape_h( BTAP::FileIO::deep_copy( BTAP::FileIO::deep_copy(model) ) ),"H_Shape"],
  #[BTAP::Geometry::Wizards::create_shape_l( BTAP::FileIO::deep_copy( BTAP::FileIO::deep_copy(model) ) ),"L_Shape"],
  #[BTAP::Geometry::Wizards::create_shape_t( BTAP::FileIO::deep_copy( BTAP::FileIO::deep_copy(model) ) ),"T_Shape"],
  #[BTAP::Geometry::Wizards::create_shape_u( BTAP::FileIO::deep_copy( BTAP::FileIO::deep_copy(model) ) ),"U_Shape"],
[BTAP::Geometry::Wizards::create_shape_courtyard( BTAP::FileIO::deep_copy( BTAP::FileIO::deep_copy(model) )), "Courtyard" ]
#  [BTAP::Geometry::Wizards::create_shape_rectangle( BTAP::FileIO::deep_copy( BTAP::FileIO::deep_copy(model)),
#      15.0,   #length =
#      15.0,   #width =
#      3,      #um_floors =
#      3.8,    #floor_to_floor_height =
#      1,      #plenum_height =
#      4.57   #perimeter_zone_depth
#    ), "Rectangular 15x15m" ],
#  [BTAP::Geometry::Wizards::create_shape_rectangle( BTAP::FileIO::deep_copy( BTAP::FileIO::deep_copy(model)),
#      50.0,   #length =
#      50.0,   #width =
#      3,      #um_floors =
#      3.8,    #floor_to_floor_height =
#      1,      #plenum_height =
#      4.57   #perimeter_zone_depth
#    ), "Rectangular 50x50m" ]
]
#Ensure all zones are created and default contructions are set.
geometric_model_array.each do |model|
  climate_model_array = set_zones_and_constructions(model[0],default_construction_set)

  counter = 1

  #iterate through all climates and set envelope.
  weather_files.each do |weather_file|
    hdd,cdd = BTAP::Environment::WeatherFile.new( weather_file ).get_design_degree_days()
    climate_index = BTAP::Compliance::NECB2011::get_climate_zone_index(hdd)
    puts "Creating climate model copy for index #{weather_file}"
    weather_model = BTAP::FileIO::deep_copy(climate_model_array[climate_index])
    puts "Setting weather file."
    BTAP::Site::set_weather_file( weather_model, weather_file )
    #Iterate by NECB Building Type
    building_type_array.each do | building_type |
      puts "Creating model copy for building type #{building_type.name}"
      building_type_model = BTAP::FileIO::deep_copy(weather_model)
      puts "Assigning Building SpaceTypes to all spaces in building model."
      building_type_model.building.get.setSpaceType(building_type.clone(building_type_model).to_SpaceType.get)
      puts "# Set heating and cooling setpoints based on building schedule."
      dual_setpoint_schedule = building_type_model.getThermostatSetpointDualSetpointByName( building_type.defaultScheduleSet.get.name.to_s ).get
      building_type_model.getThermalZones.each do |thermal_zone|
        raise("Could not set dual setpoint for name #{building_type.defaultScheduleSet.get.name}") unless thermal_zone.setThermostatSetpointDualSetpoint(dual_setpoint_schedule)
      end
      uuid = OpenStudio::createUUID.to_s
      BTAP::FileIO::set_name(building_type_model, uuid)
      puts "Saving  model weather:#{weather_file} spacetype:#{building_type.name} id:#{uuid}  "
      puts "#{counter} of #{weather_files.size * building_type_array.size }"
      BTAP::FileIO::save_osm(building_type_model, "#{analysisFolder.to_s}/#{model[1]}/#{uuid}.osm")
      counter = counter +1
    end
  end
end
##Load files into Run manager and simulate all of them
#process_manager = BTAP::SimManager::ProcessManager.new(analysisFolder)
#process_manager.simulate_all_files_in_folder(analysisFolder)
#
#
#process Results
#geometric_model_array.each do |value|
#  BTAP::Reporting::get_all_annual_results_from_runmanger( analysisFolder + "/#{value[1]}")
#end