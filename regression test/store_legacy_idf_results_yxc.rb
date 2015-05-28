# The purpose of this script is to collect the simulation results from the
# legacy Prototype and Reference Building IDF file runs to serve as
# the "truth" standard for the OpenStudio Prototype Buildings.
# This script should be run after "run_legacy_idf_files.rb" is complete.

# Specify the building types to run.
bldg_types = [
"OfficeSmall",
"OfficeMedium",
"OfficeLarge",
"RetailStandalone",
"RetailStripmall",
"SchoolPrimary",
"SchoolSecondary",
"OutPatientHealthCare",
"Hospital",
"HotelSmall",
"HotelLarge",
"Warehouse",
"RestaurantFastFood",
"RestaurantSitDown",
"ApartmentMidRise"]

# Specify the vintages you want to run.
# valid options are: Pre1980, Post1980, STD2004, STD2007, STD2010, STD2013
vintages = ["Pre1980", "Post1980", "STD2004", "STD2007", "STD2010", "STD2013"]

# Specify the climate zones you want to run.
# for PTool: El Paso, Houston, Chicago, and Baltimore
climate_zones = [
"Miami",
"Houston", 
"Phoenix", 
"Memphis", 
"San Francisco", 
"Chicago", 
"Albuquerque", 
"Salem", 
"Boise", 
"Burlington", 
"Helena", 
"Duluth", 
"Baltimore", 
"El Paso", 
"Fairbanks"
]

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

		# Change the bldg_type based on the vintage since the naming
		# conventions are different between Prototype and Reference buildings.
		if vintage == "Pre1980" || vintage == "Post1980"
		  case bldg_type
			when "OfficeSmall" #1
			  bldg_type_search = "SmallOffice"
			when "OfficeMedium" #2
			  bldg_type_search = "MediumOffice"
			when "OfficeLarge" #3
			  bldg_type_search = "LargeOffice"
			when "RetailStandalone" #4
			  bldg_type_search = "Stand-aloneRetail"
			when "RetailStripmall" #5
			  bldg_type_search = "StripMall"
			when "SchoolPrimary" #6
			  bldg_type_search = "PrimarySchool"
			when "SchoolSecondary" #7
			  bldg_type_search = "SecondarySchool"
			when "OutPatientHealthCare" #8
			  bldg_type_search = "OutPatient"
			when "HotelSmall" #9
			  bldg_type_search=  "SmallHotel"
			when "HotelLarge" #10
			  bldg_type_search=  "LargeHotel"
			when "RestaurantFastFood" #11
			  bldg_type_search=  "QuickServiceRestaurant"
			when "RestaurantSitDown" #12
			  bldg_type_search=  "FullServiceRestaurant"
			when "ApartmentMidRise" #13
			  bldg_type_search=  "MidriseApartment"
			else
			  bldg_type_search = bldg_type  #14 Hospital #15 Warehouse
		  end

		  case climate_zone
			when "Memphis"
			  climate_zone = "Atlanta"
			when "El Paso"
			  climate_zone = "Las.Vegas"
			when "Salem"
			  climate_zone = "Seattle"
			when "Boise"
			  climate_zone = "Boulder"
			when "Burlington"
			  climate_zone = "Minneapolis"
			when "San Francisco"
			  climate_zone = "San.Francisco"
		  end
		else
		  case climate_zone
			when "El Paso"
			  climate_zone = "El.Paso"
			when "San Francisco"
			  climate_zone = "San.Francisco"
		  end
		  bldg_type_search = bldg_type
		end

      # Open the sql file, skipping if not found
      sql_path_string = "C:/Sites/regression runs/#{bldg_type}.#{vintage}.#{climate_zone}/eplusout.sql"
      sql_path = OpenStudio::Path.new(sql_path_string)
      sql = nil
      if OpenStudio.exists(sql_path)
        sql = OpenStudio::SqlFile.new(sql_path)
      else
        raise "  eplusout.sql not found here: #{sql_path_string}"
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
		    "OfficeSmall" =>  "SmallOffice",
			"OfficeMedium" => "MediumOffice",
			"OfficeLarge" => "LargeOffice",
			"RetailStandalone" => "Stand-aloneRetail",
			"RetailStripmall" => "StripMall",
			"SchoolPrimary" => "PrimarySchool",
			"SchoolSecondary" => "SecondarySchool",
			"OutPatientHealthCare" => "OutPatient",
			"Hospital" => "Hospital",
			"HotelSmall" => "SmallHotel",
			"HotelLarge"=>"LargeHotel",
			"RestaurantFastFood" => "QuickServiceRestaurant",
			"RestaurantSitDown" => "FullServiceRestaurant",
			"ApartmentMidRise" => "MidriseApartment"
          }
          vintage_map = {
              "Pre1980" => "DOE Ref Pre-1980",
              "Post1980" => "DOE Ref 1980-2004",
              "STD2004" => "90.1-2004",
              "STD2007" => "90.1-2007",
              "STD2010" => "90.1-2010",
              "STD2013" => "90.1-2013"
          }

          climate_zone_map = {
			"Miami" => "ASHRAE 169-2006-1A",
			"Houston" => "ASHRAE 169-2006-2A", 
			"Phoenix" => "ASHRAE 169-2006-2B", 
			"Memphis" => "ASHRAE 169-2006-3A", "Atlanta" => "ASHRAE 169-2006-3A",
			"El.Paso" => "ASHRAE 169-2006-3B",  "Las.Vegas" => "ASHRAE 169-2006-3B",
			"San.Francisco" => "ASHRAE 169-2006-3C", 
			"Baltimore" => "ASHRAE 169-2006-4A", 
			"Albuquerque" => "ASHRAE 169-2006-4B", 
			"Salem" => "ASHRAE 169-2006-4C", "Seattle" => "ASHRAE 169-2006-4C",
			"Chicago" => "ASHRAE 169-2006-5A", 
			"Boise" => "ASHRAE 169-2006-5B",   "Boulder" => "ASHRAE 169-2006-5B",
			"Burlington" => "ASHRAE 169-2006-6A", "Minneapolis" => "ASHRAE 169-2006-6A",
			"Helena" => "ASHRAE 169-2006-6B", 
			"Duluth" => "ASHRAE 169-2006-7A", 
			"Fairbanks" => "ASHRAE 169-2006-8A"
          }

          new_bldg_type = bldg_type_map[bldg_type]
          new_vintage = vintage_map[vintage]
          new_climate_zone = climate_zone_map[climate_zone]
		  
		  new_bldg_type = bldg_type if new_bldg_type == nil

          #puts "#{bldg_type}-#{vintage}-#{climate_zone}-#{fuel_type}-#{end_use}"
          results_hash[new_bldg_type][new_vintage][new_climate_zone][fuel_type][end_use] = energy_val

        end
      end

    end
  end
end

# Save the results to JSON
#puts "***********DEBUG #{Dir.pwd}../create_DOE_prototype_building/tests/legacy_idf_results.json

#File.open("#{Dir.pwd}/legacy_idf_results.json", 'w') do |file|
File.open("#{Dir.pwd}/../create_DOE_prototype_building/tests/legacy_idf_results.json", 'w') do |file|
  #file << results_hash.to_json
  file << JSON::pretty_generate(results_hash)
end

puts "Finished saving results"
