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
require "#{File.dirname(__FILE__)}/../lib/btap"
require 'uri'

#this is where the doe idf files reside. It will process all the idf files in this folder.  
idf_folder = '../resources/models/DOEArchetypes/Original/'
#this is the weather file location that is to be used. 
weather_files = BTAP::FileIO::get_find_files_from_folder_by_extension('../weather/', '.epw')
#weather_files = ["../weather/CAN_AB_Calgary.718770_CWEC.epw"]
#This is the osm library where the default contruction set is used. 
construction_library_file = "../resources/constructions/BTAP_Construction_Library.osm"
#this is the name of the default construction set. 
construction_set_name = "DND-Concrete"
#this is the output folder where the models will be generated. 
output_folder = 'C:/archetypes/'

#system assignment. 
boiler_fueltypes = ["NaturalGas","Electricity","PropaneGas","FuelOil#1","FuelOil#2","Coal","Diesel","Gasoline","OtherFuel1"]
mau_types = [true, false]
mau_heating_coil_types = ["Hot Water", "Electric"]
baseboard_types = ["Hot Water" , "Electric"]
chiller_types = ["Scroll","Centrifugal","Rotary Screw","Reciprocating"]
mua_cooling_types = ["DX","Hydronic"]
heating_coil_types_sys3 = ["Electric", "Gas", "DX"]
heating_coil_types_sys4and6 = ["Electric", "Gas"]
fan_types = ["AF_or_BI_rdg_fancurve","AF_or_BI_inletvanes","fc_inletvanes","var_speed_drive"]


puts "Delete all .osm files in output to ensure all files are fresh."

BTAP::FileIO::delete_files_in_folder_by_extention(output_folder,'.osm')

weather_files.each do |weather_file|
  #This method should create the DOE archetypes and change the insulation values of the model to what is required by the HDD in the weather file. 
  puts BTAP::Compliance::NECB2011::convert_all_doe_to_necb_reference_building( idf_folder, output_folder, construction_library_file , construction_set_name , weather_file )
end

BTAP::SimManager::simulate_all_files_in_folder( output_folder ) 
BTAP::Reporting::get_all_annual_results_from_runmanger( output_folder ) 

BTAP::FileIO::convert_all_eso_to_csv(output_folder, output_folder).each {|csvfile| BTAP::FileIO::terminus_hourly_output(csvfile)} 
