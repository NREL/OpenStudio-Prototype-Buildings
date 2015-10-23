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

# To create and run models for cold lake.
# 1. Go to the measures folder, right click 'xls2csv.ps1' and 'Run with Powershell'
# 2. Delete any ecm_*.csv files you do not wish to run...if any.
# 3. Right click this file and run and click 'Run File' while in NetBeans (This assumes you have configured Netbeans with OpenStudio.
# Tips
# To run only certain archetypes and / or ECMs simply place replace "NA" in the measure_id column for the



measure_folder = 'C:/osruby/lib/btap/btap_measures/ColdLakeVintageMaker/'
baseline_spreadsheet = 'C:/osruby/lib/btap/btap_measures/ColdLakeVintageMaker/baseline.csv'
#Note: place output folder locally to run faster! (e.g. your C drive)
output_folder = "D:/current_vintage_simulation_results_edmonton_nightly_combo_2015_01-05"
create_models = true
simulate_models = true
create_annual_outputs = true
create_hourly_outputs = true



time = Time.now
#This creates the measures object and collects all the csv information for the
# measure_id variant.
measures = BTAP::Measures::CSV_OS_Measures.new(
  baseline_spreadsheet,
  measure_folder#script root folder where all the csv relative paths are used.
)

measures.create_cold_lake_vintages(output_folder) unless create_models == false


BTAP::SimManager::simulate_all_files_in_folder(output_folder) unless simulate_models == false
BTAP::Reporting::get_all_annual_results_from_runmanger(output_folder) unless create_annual_outputs == false
#convert eso to csv then create terminus file.
BTAP::FileIO::convert_all_eso_to_csv(output_folder, output_folder).each {|csvfile| BTAP::FileIO::terminus_hourly_output(csvfile)} unless create_hourly_outputs == false
puts "Time elapsed #{(Time.now-time).to_f/60.0/60.0}"



