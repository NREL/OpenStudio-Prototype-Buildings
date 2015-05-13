# The purpose of this script is to run the
# legacy Prototype and Reference Building IDF files.
# Simulation results wil be used as the "truth" standard for
# the OpenStudio Prototype Buildings.
# The available Reference Building vintages are pre-1980, 1980-2004, and 2004.
# The available Prototype Building vintages are 2004, 2007, 2010, and 2013.
# Both sets of buildings contain 2004.  The Prototype Buildings will be used.

# Specify the building types to run.
bldg_types = ["HotelLarge"]#["OfficeSmall", "SchoolSecondary", "HotelLarge"]

# Specify the vintages you want to run.
# valid options are: Pre1980, Post1980, STD2004, STD2007, STD2010, STD2013
vintages = ["Pre1980", "Post1980", "STD2004", "STD2007", "STD2010", "STD2013",]

# Specify the climate zones you want to run.
# for PTool: El Paso, Houston, Chicago, and Baltimore
# 1A Miami, 2A Houston, 2B Phoenix, 3A Memphis (Atlanta), 3B El Paso (Las Vegas), 3C San Francisco
# 4A Baltimore, 4B Albuquerque, 4C Salem (Seattle), 5A Chicago, 5B Boise (Boulder), 6A Burlington (Minneapolis)
# 6B Helena, 7A Duluth, 8A Fairbanks
climate_zones = ["Miami", "Houston", "Phoenix", "Memphis","El Paso","San Francisco",
"Baltimore", "Albuquerque", "Salem", "Chicago", "Boise", "Burlington",
"Helena", "Duluth", "Fairbanks"]

################################################################################

require 'find'
require 'fileutils'
require 'C:/Program Files (x86)/OpenStudio 1.5.0/Ruby/openstudio'
require 'openstudio/energyplus/find_energyplus'

# Make the folder to store results, if it doesn't exist yet
regression_dir = "#{Dir.pwd}/regression runs"
if !Dir.exists?(regression_dir)
  Dir.mkdir regression_dir
end

# Setup a run manager
run_manager_db_path = OpenStudio::Path.new("#{regression_dir}/regression_test.db")
run_manager = OpenStudio::Runmanager::RunManager.new(run_manager_db_path, true)

# Find EnergyPlus 
# 7.2 for the Reference Buildings
ep_72_hash = OpenStudio::EnergyPlus::find_energyplus(7,2)
ep_72_path = OpenStudio::Path.new(ep_72_hash[:energyplus_exe].to_s)
idd_72_path = OpenStudio::Path.new(ep_72_hash[:energyplus_idd].to_s)
ep_72_tool = OpenStudio::Runmanager::ToolInfo.new(ep_72_path)
# 8.0 for the Prototype Buildings
ep_80_hash = OpenStudio::EnergyPlus::find_energyplus(8,0)
ep_80_path = OpenStudio::Path.new(ep_80_hash[:energyplus_exe].to_s)
idd_80_path = OpenStudio::Path.new(ep_80_hash[:energyplus_idd].to_s)
ep_80_tool = OpenStudio::Runmanager::ToolInfo.new(ep_80_path)

# Find the IDF files for each of the given combinations
# and add a job for this file to the run manager
bldg_types.each do |bldg_type|
  vintages.each do |vintage|
    climate_zones.each do |climate_zone|
      puts "#{bldg_type}-#{vintage}-#{climate_zone}"
      # Change the bldg_type based on the vintage since the naming
      # conventions are different between Prototype and Reference buildings.
      bldg_type_search = nil
      if vintage == "Pre1980" || vintage == "Post1980"
        case bldg_type
        when "OfficeSmall"
          bldg_type_search = "SmallOffice"
        when "SchoolSecondary"
          bldg_type_search = "SecondarySchool"
        when "HotelLarge"
          bldg_type_search=  "LargeHotel"
        else
          bldg_type_search = bldg_type
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

      # Find the IDF file
      # Prototype file naming convention = ASHRAE90.1_SchoolSecondary_STD2004_Fairbanks.idf
      # Reference file naming convention = RefBldgSecondarySchoolPre1980_v1.4_7.2_8A_USA_AK_FAIRBANKS.idf
      idf_file = nil
      Find.find(Dir.pwd) do |path|
        if path =~ /#{bldg_type_search}/i && path =~ /#{vintage}/i && path =~ /#{climate_zone}/i
          idf_file = path
          puts "  IDF File = #{path}"
          break
        end
      end
      if idf_file.nil?
        puts "  IDF File = IDF FILE NOT FOUND"
        next
      end
      
      # Find the EPW file for this climate zone
      epw_file = nil
      Find.find(Dir.pwd) do |path|
        if path =~ /#{climate_zone}/i && path =~ /epw/
          epw_file = path
          puts "  EPW File = #{path}"
          break
        end
      end
      if epw_file.nil?
        puts "  EPW File = EPW FILE NOT FOUND"
        next
      end
      
      # Choose the correct version of EnergyPlus
      ep_tool = nil
      idd_path = nil
      if vintage == "Pre1980" || vintage == "Post1980"
        ep_tool = ep_72_tool
        idd_path = idd_72_path
      else
        ep_tool = ep_80_tool
        idd_path = idd_80_path
      end
     
      # Create the output path to store the results of the run
      output_path_string = "#{Dir.pwd}/Regression Runs/#{bldg_type}.#{vintage}.#{climate_zone}"
      output_path = OpenStudio::Path.new(output_path_string)
  
      # Delete any existing results for this combination
      FileUtils.rm_rf output_path_string
  
      # Make a job for this IDF file
      job = OpenStudio::Runmanager::JobFactory::createEnergyPlusJob(ep_tool,
                                                                   idd_path,
                                                                   idf_file,
                                                                   epw_file,
                                                                   output_path)
      
      # Add the job to the run manager queue
      run_manager.enqueue(job, true)
      
    end
  end
end

# Wait for jobs to complete
while run_manager.workPending()
  sleep 1
  OpenStudio::Application::instance().processEvents()
end

puts "finished running models"
