require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'json'
require_relative '../measure.rb'
require 'fileutils'

# Add a "dig" method to Hash to check if deeply nested elements exist
# From: http://stackoverflow.com/questions/1820451/ruby-style-how-to-check-whether-a-nested-hash-element-exists
class Hash
  def dig(*path)
    path.inject(self) do |location, key|
      location.respond_to?(:keys) ? location[key] : nil
    end
  end
end

class CreateDOEPrototypeBuildingTest < Minitest::Unit::TestCase
  # Create a set of models, return a list of failures
  def create_models(bldg_types, vintages, climate_zones)

    #### Create the prototype building
    failures = []
    
    # Loop through all of the given combinations
    bldg_types.sort.each do |building_type|
      vintages.sort.each do |building_vintage|
        climate_zones.sort.each do |climate_zone|
    
          model_name = "#{building_type}-#{building_vintage}-#{climate_zone}"
          puts "****Testing #{model_name}****"
          
          # Create an instance of the measure
          measure = CreateDOEPrototypeBuilding.new
          
          # Create an instance of a runner
          runner = OpenStudio::Ruleset::OSRunner.new
          
          # Make an empty model
          model = OpenStudio::Model::Model.new
          
          # Set argument values
          arguments = measure.arguments(model)
          argument_map = OpenStudio::Ruleset::OSArgumentMap.new
          building_type_arg = arguments[0].clone
          assert(building_type_arg.setValue(building_type))
          argument_map['building_type'] = building_type_arg
          
          building_vintage_arg = arguments[1].clone
          assert(building_vintage_arg.setValue(building_vintage))
          argument_map['building_vintage'] = building_vintage_arg

          climate_zone_arg = arguments[2].clone
          assert(climate_zone_arg.setValue(climate_zone))
          argument_map['climate_zone'] = climate_zone_arg

          measure.run(model, runner, argument_map)
          result = runner.result
          show_output(result)
          if result.value.valueName != 'Success'
            failures << "Error - #{model_name} - Model was not created successfully."
          end

          model_directory = "#{Dir.pwd}/build/#{building_type}-#{building_vintage}-#{climate_zone}"

          # Convert the model to energyplus idf
          forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
          idf = forward_translator.translateModel(model)
          idf_path_string = "#{model_directory}/#{model_name}.idf"
          idf_path = OpenStudio::Path.new(idf_path_string)
          idf.save(idf_path,true)
          
        end     
      end
    end 
        
    #### Return the list of failures
    return failures
  
  end

  # Create a set of models, return a list of failures  
  def run_models(bldg_types, vintages, climate_zones)
  
    # Open a channel to log info/warning/error messages
    msg_log = OpenStudio::StringStreamLogSink.new
    msg_log.setLogLevel(OpenStudio::Info)
  
    #### Run the specified models
    failures = []
    
    # Make a run manager and queue up the sizing run
    run_manager_db_path = OpenStudio::Path.new("#{Dir.pwd}/run.db")
    run_manager = OpenStudio::Runmanager::RunManager.new(run_manager_db_path, true)

    # Configure the run manager with the correct versions of Ruby and E+
    config_opts = OpenStudio::Runmanager::ConfigOptions.new
    config_opts.findTools(false, false, false, false)
    run_manager.setConfigOptions(config_opts)

    # Loop through all of the given combinations
    bldg_types.sort.each do |building_type|
      vintages.sort.each do |building_vintage|
        climate_zones.sort.each do |climate_zone|

          # Load the .osm
          model = nil
          model_directory = "#{Dir.pwd}/build/#{building_type}-#{building_vintage}-#{climate_zone}"
          model_name = "#{building_type}-#{building_vintage}-#{climate_zone}"
          model_path_string = "#{model_directory}/final.osm"
          model_path = OpenStudio::Path.new(model_path_string)
          if OpenStudio::exists(model_path)
            version_translator = OpenStudio::OSVersion::VersionTranslator.new
            model = version_translator.loadModel(model_path)
            if model.empty?
              failures << "Error - #{model_name} - Version translation failed"
              return failures
            else
              model = model.get
            end
          else
            failures << "Error - #{model_name} - #{model_path_string} couldn't be found"
            return failures
          end
          
          # Delete the old ModelToIdf and SizingRun1 directories if they exist
          FileUtils.rm_rf("#{model_directory}/ModelToIdf")
          FileUtils.rm_rf("#{model_directory}/SizingRun1")

          # Convert the model to energyplus idf
          forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
          idf = forward_translator.translateModel(model)
          idf_path_string = "#{model_directory}/#{model_name}.idf"
          idf_path = OpenStudio::Path.new(idf_path_string)    
          idf.save(idf_path,true)
          
          # Find the weather file
          epw_path = nil
          if model.weatherFile.is_initialized
            epw_path = model.weatherFile.get.path
            if epw_path.is_initialized
              if File.exist?(epw_path.get.to_s)
                epw_path = epw_path.get
              else
                failures << "Error - #{model_name} - Model has not been assigned a weather file."
                return failures
              end
            else
              failures << "Error - #{model_name} - Model has a weather file assigned, but the file is not in the specified location."
              return failures
            end
          else
            failures << "Error - #{model_name} - Model has not been assigned a weather file."
            return failures
          end
          
          # Set the output path
          output_path = OpenStudio::Path.new("#{model_directory}/")
          
          # Create a new workflow for the model to go through
          workflow = OpenStudio::Runmanager::Workflow.new
          workflow.addJob(OpenStudio::Runmanager::JobType.new('ModelToIdf'))
          workflow.addJob(OpenStudio::Runmanager::JobType.new('ExpandObjects'))
          workflow.addJob(OpenStudio::Runmanager::JobType.new('EnergyPlusPreProcess'))
          workflow.addJob(OpenStudio::Runmanager::JobType.new('EnergyPlus'))
          workflow.add(config_opts.getTools)
          job = workflow.create(output_path, model_path, epw_path)

          run_manager.enqueue(job, true)
          
        end
      end
    end
    
    # Start the runs and wait for them to finish.
    while run_manager.workPending
      sleep 1
      OpenStudio::Application::instance.processEvents
    end
    
    #### Return the list of failures
    return failures
    
  end
  
  # Create a set of models, return a list of failures  
  def compare_results(bldg_types, vintages, climate_zones)
  
    #### Compare results against legacy idf results      
    acceptable_error_percentage = 10 # Max 5% error for any end use/fuel type combo
    failures = []
    
    # Load the legacy idf results JSON file into a ruby hash
    temp = File.read("#{Dir.pwd}/legacy_idf_results.json")
    legacy_idf_results = JSON.parse(temp)    
         
    # List of all fuel types
    fuel_types = ['Electricity', 'Natural Gas', 'Additional Fuel', 'District Cooling', 'District Heating', 'Water']

    # List of all end uses
    end_uses = ['Heating', 'Cooling', 'Interior Lighting', 'Exterior Lighting', 'Interior Equipment', 'Exterior Equipment', 'Fans', 'Pumps', 'Heat Rejection','Humidification', 'Heat Recovery', 'Water Systems', 'Refrigeration', 'Generators']
    csv_file = File.open("#{Dir.pwd}/build/comparison.csv", 'w')
    csv_file.write("building_type,building_vintage,climate_zone,fuel_type,end_use,Legacy Val,OpenStudio Val,Percent Error\n")
    # Create a CSV to store the results
    ### Junk csv_string = CSV.generate do |csv| end
     ###More Junk csv << ["row", "of", "CSV", "data"]

      # Loop through all of the given combinations
      bldg_types.sort.each do |building_type|
        vintages.sort.each do |building_vintage|
          climate_zones.sort.each do |climate_zone|
            puts "**********#{building_type}-#{building_vintage}-#{climate_zone}******************"
            # Open the sql file, skipping if not found
            model_name = "#{building_type}-#{building_vintage}-#{climate_zone}"
            sql_path_string = "#{Dir.pwd}/build/#{model_name}/ModelToIdf/ExpandObjects-0/EnergyPlusPreProcess-0/EnergyPlus-0/eplusout.sql"
            sql_path = OpenStudio::Path.new(sql_path_string)
            sql = nil
            if OpenStudio.exists(sql_path)
              puts "Found SQL file."
              sql = OpenStudio::SqlFile.new(sql_path)
            else
              failures << "****Error - #{model_name} - Could not find sql file"
              puts "**********no sql here #{sql_path}******************"
              next
            end
            
            # Create a hash of hashes to store the results from each file
            results_hash = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
            
            # Get the osm values for all fuel type/end use pairs
            # and compare to the legacy idf results
            total_legacy_energy_val = 0
            total_osm_energy_val = 0
            total_legacy_water_val = 0
            total_osm_water_val = 0
            fuel_types.each do |fuel_type|
              end_uses.each do |end_use|
                # Get the legacy results number
                legacy_val = legacy_idf_results.dig(building_type, building_vintage, climate_zone, fuel_type, end_use)
                #legacy_val = legacy_idf_results[building_type][building_vintage][climate_zone][fuel_type][end_use]
                if legacy_val.nil?
                  failures << "Error - #{model_name} - #{fuel_type} #{end_use} legacy idf value not found"
                  next
                end

                # Add the energy to the total
                if fuel_type == 'Water'
                  total_legacy_water_val += legacy_val
                else
                  total_legacy_energy_val += legacy_val
                end
      
                # Select the correct units based on fuel type
                units = 'GJ'
                if fuel_type == 'Water'
                  units = 'm3'
                end
                
                # End use breakdown query
                energy_query = "SELECT Value FROM TabularDataWithStrings WHERE (ReportName='AnnualBuildingUtilityPerformanceSummary') AND (ReportForString='Entire Facility') AND (TableName='End Uses') AND (ColumnName='#{fuel_type}') AND (RowName = '#{end_use}') AND (Units='#{units}')"
                
                # Get the end use value
                osm_val = sql.execAndReturnFirstDouble(energy_query)
                if osm_val.is_initialized
                  osm_val = osm_val.get
                else
                  failures << "Error - #{model_name} - No sql value found for #{fuel_type}-#{end_use} via #{energy_query}"
                  osm_val = 0
                end
                
                # Add the energy to the total
                if fuel_type == 'Water'
                  total_osm_water_val += osm_val
                else
                 total_osm_energy_val += osm_val
                end
                
                # Calculate the error and check if less than
                # acceptable_error_percentage
                percent_error = nil
                if osm_val > 0 && legacy_val > 0
                  # If both 
                  percent_error = ((osm_val - legacy_val)/legacy_val) * 100
                  if percent_error.abs > acceptable_error_percentage
                    failures << "#{building_type}-#{building_vintage}-#{climate_zone}-#{fuel_type}-#{end_use} Error = #{percent_error.round}% (#{osm_val}, #{legacy_val})"
                  end
                elsif osm_val > 0 && legacy_val == 0
                  # The osm has a fuel/end use that the legacy idf does not
                  percent_error = 1000
                  failures << "#{building_type}-#{building_vintage}-#{climate_zone}-#{fuel_type}-#{end_use} Error = osm has extra fuel/end use that legacy idf does not"
                elsif osm_val == 0 && legacy_val > 0
                  # The osm has a fuel/end use that the legacy idf does not
                  percent_error = 1000
                  failures << "#{building_type}-#{building_vintage}-#{climate_zone}-#{fuel_type}-#{end_use} Error = osm is missing a fuel/end use that legacy idf has"
                else
                  # Both osm and legacy are == 0 for this fuel/end use, no error
                  percent_error = 0
                end

                results_hash[building_type][building_vintage][climate_zone][fuel_type][end_use]['Legacy Val'] = legacy_val.round(2)
                results_hash[building_type][building_vintage][climate_zone][fuel_type][end_use]['OpenStudio Val'] = osm_val.round(2)
                results_hash[building_type][building_vintage][climate_zone][fuel_type][end_use]['Percent Error'] = percent_error.round(2)
                
              end # Next end use
            end # Next fuel type
        
            # Calculate the overall energy error
            total_percent_error = nil
            if total_osm_energy_val > 0 && total_legacy_energy_val > 0
              # If both 
              total_percent_error = ((total_osm_energy_val - total_legacy_energy_val)/total_legacy_energy_val) * 100
              failures << "#{building_type}-#{building_vintage}-#{climate_zone} *** Total Energy Error = #{total_percent_error.round}% ***"
            elsif total_osm_energy_val > 0 && total_legacy_energy_val == 0
              # The osm has a fuel/end use that the legacy idf does not
              total_percent_error = 1000
              failures << "#{building_type}-#{building_vintage}-#{climate_zone} *** Total Energy Error = osm has extra fuel/end use that legacy idf does not"
            elsif total_osm_energy_val == 0 && total_legacy_energy_val > 0
              # The osm has a fuel/end use that the legacy idf does not
              total_percent_error = 1000
              failures << "#{building_type}-#{building_vintage}-#{climate_zone} *** Total Energy Error = osm is missing a fuel/end use that legacy idf has"
            else
              # Both osm and legacy are == 0 for, no error
              total_percent_error = 0
              failures << "#{building_type}-#{building_vintage}-#{climate_zone} *** Total Energy Error = both idf and osm don't use any energy."
            end

            # Save the results to JSON
            File.open("#{Dir.pwd}/build/#{model_name}/comparison.json", 'w') do |file|
              file << JSON::pretty_generate(results_hash)
            end

            # Save the results to CSV

            results_hash.each_pair do |key1, value1|
              value1.each_pair do |key2, value2|
                value2.each_pair do |key3, value3|
                  value3.each_pair do |key4, value4|# fuel type
                    fuel_type_legacy_val_total = 0
                    fuel_type_openstudio_val_total = 0
                    value4.each_pair do |key5, value5| # end use
                      if value5['Percent Error'].to_i != 0
                        fuel_type_legacy_val_total += value5['Legacy Val'].to_f
                        fuel_type_openstudio_val_total += value5['OpenStudio Val'].to_f
                        csv_file.write("#{key1},#{key2},#{key3},#{key4},#{key5},#{value5['Legacy Val']},#{value5['OpenStudio Val']},#{value5['Percent Error']}\n")
                      end
                    end

                    if fuel_type_legacy_val_total != 0
                      csv_file.write("#{key1},#{key2},#{key3},#{key4},Total,#{fuel_type_legacy_val_total},#{fuel_type_openstudio_val_total},#{(fuel_type_openstudio_val_total-fuel_type_legacy_val_total)/fuel_type_legacy_val_total*100}\n")
                    end
                  end
                end
              end
            end


          end
        end
      end
    csv_file.close
    
    #### Return the list of failures
    return failures
  
  end
  
  # Test the Secondary School in the PTool vintages and climate zones
  def dont_test_secondary_school

    bldg_types = ['SecondarySchool']
    vintages = ['DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2010']
    climate_zones = ['ASHRAE 169-2006-2A']#, 'ASHRAE 169-2006-3B', 'ASHRAE 169-2006-4A', 'ASHRAE 169-2006-5A']

    all_failures = []
    
    # Create the models
    all_failures += create_models(bldg_types, vintages, climate_zones)
    
    # Run the models
    all_failures += run_models(bldg_types, vintages, climate_zones)
    
    # Compare the results to the legacy idf results
    all_failures += compare_results(bldg_types, vintages, climate_zones)

    # Assert if there are any errors
    puts "There were #{all_failures.size} failures"
    assert(all_failures.size == 0, "FAILURES: #{all_failures.join("\n")}")
    
  end  
  
  # "ASHRAE 169-2006-2A" => "USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3",
  # "ASHRAE 169-2006-3B" => "USA_TX_El.Paso.Intl.AP.722700_TMY3",
  # "ASHRAE 169-2006-4A" => "USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3",
  # "ASHRAE 169-2006-5A" => "USA_IL_Chicago-OHare.Intl.AP.725300_TMY3",    
  
  # Test the Small Office in the PTool vintages and climate zones
  def dont_test_small_office

    bldg_types = ['SmallOffice']
    vintages = ['DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2010'] 
    climate_zones = ['ASHRAE 169-2006-2A']#, 'ASHRAE 169-2006-3B', 'ASHRAE 169-2006-4A', 'ASHRAE 169-2006-5A']

    all_failures = []
    
    # Create the models
    all_failures += create_models(bldg_types, vintages, climate_zones)
    
    # Run the models
    all_failures += run_models(bldg_types, vintages, climate_zones)
    
    # Compare the results to the legacy idf results
    all_failures += compare_results(bldg_types, vintages, climate_zones)

    # Assert if there are any errors
    puts "There were #{all_failures.size} failures"
    assert(all_failures.size == 0, "FAILURES: #{all_failures.join("\n")}")
    
  end

  # Test the Small Office in the QTR vintages and climate zones
  def dont_test_small_office_qtr

    bldg_types = ['SmallOffice']
    vintages = ['90.1-2010']#, 'DOE Ref Pre-1980', ']'90.1-2010'
    climate_zones = ['ASHRAE 169-2006-2A']# 'ASHRAE 169-2006-3B', 'ASHRAE 169-2006-4A', 'ASHRAE 169-2006-5A']

    all_failures = []
    
    # Create the models
    all_failures += create_models(bldg_types, vintages, climate_zones)
    
    # Run the models
    all_failures += run_models(bldg_types, vintages, climate_zones)
    
    # Compare the results to the legacy idf results
    all_failures += compare_results(bldg_types, vintages, climate_zones)

    # Assert if there are any errors
    puts "There were #{all_failures.size} failures"
    assert(all_failures.size == 0, "FAILURES: #{all_failures.join("\n")}")
    
  end

  def test_small_hotel
    bldg_types = ['SmallHotel']
    vintages = ['90.1-2010']#, 'DOE Ref 1980-2004','DOE Ref Pre-1980']
    climate_zones = ['ASHRAE 169-2006-2A']#, 'ASHRAE 169-2006-3B', 'ASHRAE 169-2006-4A', 'ASHRAE 169-2006-5A']

    all_failures = []
    
    # Create the models
    all_failures += create_models(bldg_types, vintages, climate_zones)
    
    # Run the models
    all_failures += run_models(bldg_types, vintages, climate_zones)
    
    # Compare the results to the legacy idf results
    all_failures += compare_results(bldg_types, vintages, climate_zones)

    # Assert if there are any errors
    puts "There were #{all_failures.size} failures"
    assert(all_failures.size == 0, "FAILURES: #{all_failures.join("\n")}")
    
  end

  def dont_test_large_office

    bldg_types = ['LargeOffice']
    vintages = ['DOE Ref 1980-2004']#, 'DOE Ref Pre-1980', ']'90.1-2010'
    climate_zones = ['ASHRAE 169-2006-2A']# 'ASHRAE 169-2006-3B', 'ASHRAE 169-2006-4A', 'ASHRAE 169-2006-5A']

    all_failures = []
    
    # Create the models
    all_failures += create_models(bldg_types, vintages, climate_zones)
    
    # Run the models
    all_failures += run_models(bldg_types, vintages, climate_zones)
    
    # Compare the results to the legacy idf results
    all_failures += compare_results(bldg_types, vintages, climate_zones)

    # Assert if there are any errors
    puts "There were #{all_failures.size} failures"
    assert(all_failures.size == 0, "FAILURES: #{all_failures.join("\n")}")
    
  end

  # Test the Small Office in the QTR vintages and climate zones
  def test_medium_office

    bldg_types = ['MediumOffice']
    vintages = ['DOE Ref 1980-2004']#, 'DOE Ref Pre-1980', ']'90.1-2010'
    climate_zones = ['ASHRAE 169-2006-2A']# 'ASHRAE 169-2006-3B', 'ASHRAE 169-2006-4A', 'ASHRAE 169-2006-5A']

    all_failures = []
    
    # Create the models
    all_failures += create_models(bldg_types, vintages, climate_zones)
    
    # Run the models
    all_failures += run_models(bldg_types, vintages, climate_zones)
    
    # Compare the results to the legacy idf results
    all_failures += compare_results(bldg_types, vintages, climate_zones)

    # Assert if there are any errors
    puts "There were #{all_failures.size} failures"
    assert(all_failures.size == 0, "FAILURES: #{all_failures.join("\n")}")
    
  end

  # Test the large hotel in the PTool vintages and climate zones
  def dont_test_large_hotel
    bldg_types = ['LargeHotel']
    vintages = ['DOE Ref Pre-1980']#['90.1-2010','DOE Ref Pre-1980', 'DOE Ref 1980-2004']
    climate_zones = ['ASHRAE 169-2006-2A']#, 'ASHRAE 169-2006-3B','ASHRAE 169-2006-4A','ASHRAE 169-2006-5A']

    all_failures = []
    
    # Create the models
    all_failures += create_models(bldg_types, vintages, climate_zones)
    
    # Run the models
    all_failures += run_models(bldg_types, vintages, climate_zones)
    
    # Compare the results to the legacy idf results
    all_failures += compare_results(bldg_types, vintages, climate_zones)

    # Assert if there are any errors
    puts "There were #{all_failures.size} failures"
    assert(all_failures.size == 0, "FAILURES: #{all_failures.join("\n")}")
    
  end
  
  def dont_test_primary_school
    
    bldg_types = ['PrimarySchool']
    vintages = ['90.1-2004', '90.1-2007', '90.1-2010'] # '90.1-2013'] 'DOE Ref Pre-1980', 'DOE Ref 1980-2004',
    climate_zones = ['ASHRAE 169-2006-2A']#, 'ASHRAE 169-2006-3B', 'ASHRAE 169-2006-4A', 'ASHRAE 169-2006-5A']

    all_failures = []
    
    # Create the models
    all_failures += create_models(bldg_types, vintages, climate_zones)
    
    # Run the models
    all_failures += run_models(bldg_types, vintages, climate_zones)
    
    # Compare the results to the legacy idf results
    all_failures += compare_results(bldg_types, vintages, climate_zones)

    # Assert if there are any errors
    puts "There were #{all_failures.size} failures"
    assert(all_failures.size == 0, "FAILURES: #{all_failures.join("\n")}")
    
  end
  
  def dont_test_all
    
    bldg_types = ['SecondarySchool', 'PrimarySchool', 'SmallOffice', 'SmallHotel']
    vintages = ['DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2010']
    climate_zones = ['ASHRAE 169-2006-2A']#, 'ASHRAE 169-2006-3B', 'ASHRAE 169-2006-4A', 'ASHRAE 169-2006-5A']

    all_failures = []
    
    # Create the models
    #all_failures += create_models(bldg_types, vintages, climate_zones)
    
    # Run the models
    #all_failures += run_models(bldg_types, vintages, climate_zones)
    
    # Compare the results to the legacy idf results
    all_failures += compare_results(bldg_types, vintages, climate_zones)

    # Assert if there are any errors
    puts "There were #{all_failures.size} failures"
    assert(all_failures.size == 0, "FAILURES: #{all_failures.join("\n")}")
    
  end
end
