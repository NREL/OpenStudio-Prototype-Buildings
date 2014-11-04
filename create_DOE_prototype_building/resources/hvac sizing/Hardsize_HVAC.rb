
# A helper method to run a sizing run and pull any values calculated during
# autosizing back into the model.
def hardsize_hvac(model)
 
  # Report the sizing factors being used
  siz_params = model.getSimulationControl.sizingParameters
  if siz_params.is_initialized
    siz_params = siz_params.get
  else
    siz_params_idf = OpenStudio::IdfObject.new OpenStudio::Model::SizingParameters::iddObjectType
    model.addObject siz_params_idf
    siz_params = model.getSimulationControl.sizingParameters.get
  end
  @runner.registerInfo("The heating sizing factor for the model is #{siz_params.heatingSizingFactor}.")
  @runner.registerInfo("The cooling sizing factor for the model is #{siz_params.coolingSizingFactor}.")
  
  # Change the simulation to only run the sizing days
  sim_control = model.getSimulationControl
  sim_control.setRunSimulationforSizingPeriods(true)
  sim_control.setRunSimulationforWeatherFileRunPeriods(false)
  
  # Save the model to energyplus idf
  idf_directory = Dir.pwd + "/#{model.getBuilding.handle}-sizing_run"
  if !Dir.exists?(idf_directory)
    Dir.mkdir(idf_directory)
  end
  idf_name = "sizing.idf"
  osm_name = "sizing.osm"
  @runner.registerInfo("Saving sizing idf to #{idf_directory} as '#{idf_name}'")
  forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new()
  idf = forward_translator.translateModel(model)
  idf_path = OpenStudio::Path.new("#{idf_directory}/#{idf_name}")  
  osm_path = OpenStudio::Path.new("#{idf_directory}/#{osm_name}")
  idf.save(idf_path,true)
  
  puts "DEBUG SAVING model to #{osm_path}"
  model.save(osm_path,true)
  
  # Set up the sizing simulation
  # Find the weather file
  epw_path = nil
  if model.weatherFile.is_initialized
    epw_path = model.weatherFile.get.path
    if epw_path.is_initialized
      if File.exist?(epw_path.get.to_s)
        epw_path = epw_path.get
      else
        @runner.registerError("Model has not been assigned a weather file.")
        return false
      end
    else
      @runner.registerError("Model has a weather file assigned, but the file is not in the specified location.")
      return false
    end
  else
    @runner.registerError("Model has not been assigned a weather file.")
    return false
  end
  
  # Find EnergyPlus
  require 'openstudio/energyplus/find_energyplus'
  ep_hash = OpenStudio::EnergyPlus::find_energyplus(8,1)
  ep_path = OpenStudio::Path.new(ep_hash[:energyplus_exe].to_s)
  ep_tool = OpenStudio::Runmanager::ToolInfo.new(ep_path)
  idd_path = OpenStudio::Path.new(ep_hash[:energyplus_idd].to_s)
  output_path = OpenStudio::Path.new("#{idf_directory}/")
  
  # Make a run manager and queue up the sizing run
  run_manager_db_path = OpenStudio::Path.new("#{idf_directory}/sizing_run.db")
  run_manager = OpenStudio::Runmanager::RunManager.new(run_manager_db_path, true)
  job = OpenStudio::Runmanager::JobFactory::createEnergyPlusJob(ep_tool,
                                                               idd_path,
                                                               idf_path,
                                                               epw_path,
                                                               output_path)
  
  run_manager.enqueue(job, true)

  # Start the sizing run and wait for it to finish.
  while run_manager.workPending
    sleep 1
    OpenStudio::Application::instance.processEvents
  end
  @runner.registerInfo("Finished sizing run.")
  
  # Load the sql file created by the sizing run
  sql_path = OpenStudio::Path.new("#{idf_directory}/Energyplus/eplusout.sql")
  if OpenStudio::exists(sql_path)
    sql = OpenStudio::SqlFile.new(sql_path)
    # Attach the sql file from the run to the sizing model
    model.setSqlFile(sql)
  else 
    @runner.registerError("Results for the sizing run couldn't be found here: #{sql_path}.")
    return false
  end
  
  # Load the helper libraries for getting the autosized
  # values for each type of model object.
  require_relative 'Model'
  require_relative 'AirTerminalSingleDuctParallelPIUReheat'
  require_relative 'AirTerminalSingleDuctVAVReheat'
  require_relative 'AirTerminalSingleDuctUncontrolled'
  require_relative 'AirLoopHVAC'
  require_relative 'FanConstantVolume'
  require_relative 'FanVariableVolume'
  require_relative 'CoilHeatingElectric'
  require_relative 'CoilHeatingGas'
  require_relative 'CoilHeatingWater'
  require_relative 'CoilCoolingDXSingleSpeed'
  require_relative 'CoilCoolingDXTwoSpeed'
  require_relative 'CoilCoolingWater'
  require_relative 'ControllerOutdoorAir'
  require_relative 'HeatExchangerAirToAirSensibleAndLatent'
  require_relative 'PlantLoop'
  require_relative 'PumpConstantSpeed'
  require_relative 'PumpVariableSpeed'
  require_relative 'BoilerHotWater'
  require_relative 'ChillerElectricEIR'
  require_relative 'CoolingTowerSingleSpeed'
  require_relative 'ControllerWaterCoil'
  require_relative 'SizingSystem'
  
  # Get the autosized values and 
  # put them back into the model.
  apply_sizes_success = model.applySizingValues
  if apply_sizes_success
    @runner.registerInfo("Successfully applied component sizing values.")
  else
    @runner.registerInfo("Failed to apply component sizing values.")
  end
  
  # Change the model back to running the weather file
  sim_control.setRunSimulationforSizingPeriods(false)
  sim_control.setRunSimulationforWeatherFileRunPeriods(true)
  
  return true

end

# A helper method to get component sizes from the model
# returns the autosized value as an optional double
def get_autosized_value(object, value_name, units)

  result = OpenStudio::OptionalDouble.new()

  name = object.name.get.upcase
  
  object_type = object.iddObject.type.valueDescription.gsub('OS:','')
  
  model = object.model
  
  sql = model.sqlFile
  
  if sql.is_initialized
    sql = sql.get
  
    #SELECT * FROM ComponentSizes WHERE CompType = 'Coil:Heating:Gas' AND CompName = "COIL HEATING GAS 3" AND Description = "Design Size Nominal Capacity"
    query = "SELECT Value 
            FROM ComponentSizes 
            WHERE CompType='#{object_type}' 
            AND CompName='#{name}' 
            AND Description='#{value_name}' 
            AND Units='#{units}'"
            
    val = sql.execAndReturnFirstDouble(query)
    
    if val.is_initialized
      result = OpenStudio::OptionalDouble.new(val.get)
    else
      puts "****Data not found for #{query}****"
    end

  else
    puts "****Model has no SQL file****"
  end

  return result
    
end 
