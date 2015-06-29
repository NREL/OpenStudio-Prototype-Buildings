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
require "#{File.dirname(__FILE__)}/btap/btap"
require "SecureRandom"

#TG-BE Modeling Needs
#Individual Measure	Archetypes to model	Climate zones to model	Impacts to model
#

#

#
#U-value of fenestration and doors	Large office
#MURB
#Big box	5 and 7A	1 level:
#85% of current U-values
#Reference: NECB 2011 U-values
#




output_folder = "C:/heather"
#Iterate through osm files.
building_files = BTAP::FileIO::get_find_files_from_folder_by_extension( 'C:/osruby/Resources/DOEArchetypes/OSM_NECB_Space_Types','.osm' )

building_files.each  do |filepath|
  model = BTAP::FileIO::load_osm(filepath)
  #Remove all existing constructions from model.
  BTAP::Resources::Envelope::remove_all_envelope_information( model )

  #Load Contruction osm library.
  construction_lib = BTAP::FileIO::load_osm("#{@script_root_folder_path}/#{@library_file}")

  #Get construction set.. I/O expensive so doing it here.
  vintage_construction_set = construction_lib.getDefaultConstructionSetByName(@default_construction_set_name)
  if vintage_construction_set.empty?
    raise("#{@default_construction_set} does not exist in #{@script_root_folder_path}/#{@library_file} library ")
  else
    vintage_construction_set = construction_lib.getDefaultConstructionSetByName(@default_construction_set_name).get
  end




  #Set NECB FDWR Ratio (not perfect) 
  #Set U-Values
  #Iterate through weather files
  [
    #    'C:/OSRuby/weather_files/CAN_BC_Vancouver.718920_CWEC/CAN_BC_Vancouver.718920_CWEC.epw',
    #    'C:/OSRuby/weather_files/CAN_ON_Toronto.716240_CWEC/CAN_ON_Toronto.716240_CWEC.epw',
    #    'C:/OSRuby/weather_files/CAN_BC_Prince.George.718960_CWEC/CAN_BC_Prince.George.718960_CWEC.epw',
    #    'C:/OSRuby/weather_files/CAN_PQ_Sept-Iles.718110_CWEC/CAN_PQ_Sept-Iles.718110_CWEC.epw',
    #    'C:/OSRuby/weather_files/CAN_PQ_Lake.Eon.714210_CWEC/CAN_PQ_Lake.Eon.714210_CWEC.epw',
    'C:/OSRuby/weather_files/CAN_NU_Resolute.719240_CWEC.epw'
  ].each do |weather_file_path|

    #Get basic climate and code data.
    weather_file = BTAP::Environment::WeatherFile.new(weather_file_path)
    @hdd = weather_file.hdd18
    @weather_name = weather_file.location_name
    @building_type = File.basename(filepath,'.osm')


    #    #Whole building air leakage	Large office
    #    #MURB
    #    #Big box	5 and 7A	6 whole building air leakage rates at 75 Pa:
    #    #8 L/(s•m2), 3.75 L/(s•m2), 2 L/(s•m2), 1.25 L/(s•m2), 0.75 L/(s•m2), 0.25 L/(s•m2)
    #    #Reference: 0.25 L/(s•m2) at 5 Pa
    #    [8.00, 3.75, 2.00, 1.25, 0.75, 0.25].each do |infiltration_rate|
    #      @measure_id = "infil #{infiltration_rate}"
    #      infil_model = BTAP::FileIO::deep_copy(model, true)
    #      BTAP::Resources::SpaceLoads::ScaleLoads::set_inflitration_magnitude( infil_model, 0.0,0.0,infiltration_rate,0.0 )
    #      BTAP::FileIO::set_name(model,"#{@building_type}~#{@weather_name}~#{@measure_id}")
    #      BTAP::FileIO::save_osm( model, "#{output_folder}/#{BTAP::FileIO::get_name(model)}.osm") unless output_folder.nil?
    #      puts "Changed name to #{BTAP::FileIO::get_name(model)}"
    #    end



    #U-value of opaque (above and below ground)	Large office
    #MURB
    #Big box	5 and 7A	2 levels:
    #80 and 85% of NECB 2011 U-values
    #Reference: NECB 2011 U-values
    [0.80, 0.85].each do |necb_opaque_u_value_reduction_rate|
      @script_root_folder_path
      @library_file
      @default_construction_set_name
      opaque_model = BTAP::FileIO::deep_copy(model, true)



      vintage_construction_set.clone(opaque_model).to_DefaultConstructionSet.get
      #Get Climate zone conductance for walls, roofs and underground
      BTAP::Compliance::NECB2011::set_all_construction_sets_to_necb!(opaque_model, @hdd,
        necb_opaque_u_value_reduction_rate,  #scale wall uvalue
        necb_opaque_u_value_reduction_rate , #scale wall uvalue scale_floor
        necb_opaque_u_value_reduction_rate   #scale wall uvalue scale_roof
      )
    end
    #
    #    #U-value of fenestration and doors	Large office
    #    #MURB
    #    #Big box	5 and 7A	1 level:
    #    #85% of current U-values
    #    #Reference: NECB 2011 U-values
    #    [0.80, 0.85].each do |necb_fenestration_u_value_reduction_rate|
    #      fenestration_model = BTAP::FileIO::deep_copy(model, true)
    #
    #    end
    #
    #    #Skylight to roof ratio	Large office
    #    #MURB
    #    #Big box	5 and 7A	2 levels:
    #    #0%, 2%
    #    #Reference: NECB 2011 maximum allowable 5%
    #    [0.05, 0.0, 0.01].each do |necb_fenestration_u_value_reduction_rate|
    #      skylight_model = BTAP::FileIO::deep_copy(model, true)
    #    end


  end
end 

time = Time.now