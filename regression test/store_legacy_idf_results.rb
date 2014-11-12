# The purpose of this script is to collect the simulation results from the
# legacy Prototype and Reference Building IDF file runs to serve as
# the "truth" standard for the OpenStudio Prototype Buildings.
# This script should be run after "run_legacy_idf_files.rb" is complete.

# Specify the building types to run.
bldg_types = ["OfficeSmall"] #["OfficeSmall", "SchoolSecondary"]

# Specify the vintages you want to run.
# valid options are: pre1980, post1980, STD2004, STD2007, STD2010, STD2013
vintages = ["Pre1980", "Post1980", "STD2010"] #["Pre1980", "Post1980", "STD2010"]

# Specify the climate zones you want to run.
# for PTool: Los Angeles, Houston, Chicago, and Baltimore
climate_zones = ["Houston"]#, "Chicago", "Baltimore"]

################################################################################

require 'json'
require 'C:/Program Files (x86)/OpenStudio 1.5.0/Ruby/openstudio'
    
# List of all fuel types
fuel_types = ["Electricity", "Natural Gas", "Additional Fuel", "District Cooling", "District Heating", "Water"]

# List of all end uses
end_uses = ["Heating", "Cooling", "Interior Lighting", "Exterior Lighting", "Interior Equipment", "Exterior Equipment", "Fans", "Pumps", "Heat Rejection","Humidification", "Heat Recovery", "Water Systems", "Refrigeration", "Generators"]

# Create a hash of hashes to store the results from each file
results_hash = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
    
# Find the IDF files for each of the given combinations
# and add a job for this file to the run manager
bldg_types.sort.each do |bldg_type|
  vintages.sort.each do |vintage|
    climate_zones.sort.each do |climate_zone|
      puts "#{bldg_type}-#{vintage}-#{climate_zone}"

      # Open the sql file, skipping if not found
      sql_path_string = "#{Dir.pwd}/regression runs/#{bldg_type}.#{vintage}.#{climate_zone}/EnergyPlus/eplusout.sql"
      sql_path = OpenStudio::Path.new(sql_path_string)
      sql = nil
      if OpenStudio.exists(sql_path)
        sql = OpenStudio::SqlFile.new(sql_path)
      else 
        puts "  eplusout.sql not found here: #{sql_path_string}"
        next
      end
             
      # Record values for all fuel type/end use pairs
      fuel_types.each do |fuel_type|
        end_uses.each do |end_use|
          
          # Correct the query for differences between EnergyPlus 7.2 and 8.0
          query_fuel_type = fuel_type
          if (vintage == "Pre1980" || vintage == "Post1980") && fuel_type == "Additional Fuel"
            query_fuel_type = "Other Fuel"
          end
          
          # Select the correct units based on fuel type
          units = "GJ"
          if fuel_type == "Water"
            units = "m3"
          end
          
          # End use breakdown query
          energy_query = "SELECT Value FROM TabularDataWithStrings WHERE (ReportName='AnnualBuildingUtilityPerformanceSummary') AND (ReportForString='Entire Facility') AND (TableName='End Uses') AND (ColumnName='#{query_fuel_type}') AND (RowName = '#{end_use}') AND (Units='#{units}')"
          
          energy_val = sql.execAndReturnFirstDouble(energy_query)
          if energy_val.is_initialized
            energy_val = energy_val.get
          else
            puts "    No value found for #{bldg_type}-#{vintage}-#{climate_zone}-#{fuel_type}-#{end_use}    #{energy_query}"
            energy_val = 0
          end
          
          # Store the result
          
          # First rename the building type, vintage, and climate zone to match the
          # conventions that will be used for the prototype buildings
          bldg_type_map = {
          "SchoolSecondary" => "SecondarySchool",
          "OfficeSmall" => "SmallOffice"
          }

          vintage_map = {
          "Pre1980" => "DOE Ref Pre-1980",
          "Post1980" => "DOE Ref 1980-2004",
          "STD2010" => "90.1-2010"
          }          
          
          climate_zone_map = {
          "Houston" => "ASHRAE 169-2006-2A",
          "Baltimore" => "ASHRAE 169-2006-4A",
          "Chicago" => "ASHRAE 169-2006-5A"
          }

          new_bldg_type = bldg_type_map[bldg_type]
          new_vintage = vintage_map[vintage]
          new_climate_zone = climate_zone_map[climate_zone]
          
          #puts "#{bldg_type}-#{vintage}-#{climate_zone}-#{fuel_type}-#{end_use}"
          results_hash[new_bldg_type][new_vintage][new_climate_zone][fuel_type][end_use] = energy_val
          
        end
      end
           
    end
  end
end

# Save the results to JSON
File.open("#{Dir.pwd}/legacy_idf_results.json", 'w') do |file|
  #file << results_hash.to_json
  file << JSON::pretty_generate(results_hash)
end

puts "Finished saving results"
