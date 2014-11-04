
# open the class to add methods to size all HVAC equipment
class OpenStudio::Model::Model

  # Load the helper libraries for getting the autosized
  # values for each type of model object.
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

  # A helper method to run a sizing run and pull any values calculated during
  # autosizing back into the self.
  def runSizingRun(sizing_run_dir = "#{Dir.pwd}/SizingRun")
    
    # If the sizing run directory is not specified
    # run the sizing run in the current working directory
    
    # Make the directory if it doesn't exist
    if !Dir.exists?(sizing_run_dir)
      Dir.mkdir(sizing_run_dir)
    end

    # Report the sizing factors being used
    siz_params = self.getSimulationControl.sizingParameters
    if siz_params.is_initialized
      siz_params = siz_params.get
    else
      siz_params_idf = OpenStudio::IdfObject.new OpenStudio::Model::SizingParameters::iddObjectType
      self.addObject siz_params_idf
      siz_params = self.getSimulationControl.sizingParameters.get
    end
    #self.runner.registerInfo("The heating sizing factor for the model is #{siz_params.heatingSizingFactor}.")
    #self.runner.registerInfo("The cooling sizing factor for the model is #{siz_params.coolingSizingFactor}.")
    
    # Change the simulation to only run the sizing days
    sim_control = self.getSimulationControl
    sim_control.setRunSimulationforSizingPeriods(true)
    sim_control.setRunSimulationforWeatherFileRunPeriods(false)
    
    # Save the model to energyplus idf
    idf_name = "sizing.idf"
    osm_name = "sizing.osm"
    #runner.registerInfo("Saving sizing idf to #{sizing_run_dir} as '#{idf_name}'")
    forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new()
    idf = forward_translator.translateModel(self)
    idf_path = OpenStudio::Path.new("#{sizing_run_dir}/#{idf_name}")  
    osm_path = OpenStudio::Path.new("#{sizing_run_dir}/#{osm_name}")
    idf.save(idf_path,true)
    self.save(osm_path,true)
    
    # Set up the sizing simulation
    # Find the weather file
    epw_path = nil
    if self.weatherFile.is_initialized
      epw_path = self.weatherFile.get.path
      if epw_path.is_initialized
        if File.exist?(epw_path.get.to_s)
          epw_path = epw_path.get
        else
          #self.runner.registerError("Model has not been assigned a weather file.")
          return false
        end
      else
        #self.runner.registerError("Model has a weather file assigned, but the file is not in the specified location.")
        return false
      end
    else
      #self.runner.registerError("Model has not been assigned a weather file.")
      return false
    end
    
    # Find EnergyPlus
    require 'openstudio/energyplus/find_energyplus'
    ep_hash = OpenStudio::EnergyPlus::find_energyplus(8,1)
    ep_path = OpenStudio::Path.new(ep_hash[:energyplus_exe].to_s)
    ep_tool = OpenStudio::Runmanager::ToolInfo.new(ep_path)
    idd_path = OpenStudio::Path.new(ep_hash[:energyplus_idd].to_s)
    output_path = OpenStudio::Path.new("#{sizing_run_dir}/")
    
    # Make a run manager and queue up the sizing run
    run_manager_db_path = OpenStudio::Path.new("#{sizing_run_dir}/sizing_run.db")
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
    #self.runner.registerInfo("Finished sizing run.")
    
    # Load the sql file created by the sizing run
    sql_path = OpenStudio::Path.new("#{sizing_run_dir}/Energyplus/eplusout.sql")
    if OpenStudio::exists(sql_path)
      sql = OpenStudio::SqlFile.new(sql_path)
      # Attach the sql file from the run to the sizing model
      self.setSqlFile(sql)
    else 
      #self.runner.registerError("Results for the sizing run couldn't be found here: #{sql_path}.")
      return false
    end
    
    # Change the model back to running the weather file
    sim_control.setRunSimulationforSizingPeriods(false)
    sim_control.setRunSimulationforWeatherFileRunPeriods(true)
    
    return true

  end

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into all objects model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    # Ensure that the model has a sql file associated with it
    if self.sqlFile.empty?
      puts "failed to apply sizing values because sql file missing"
      return false
    end
  
    # Zone equipment
    # TODO unit heater
    # TODO low temp radiant electric
    # TODO var flow radiant
    # TODO const flow radiant
    # TODO PTAC
    # TODO Water to Air HP
    # TODO PTHP
    # TODO Zone Exhaust Fan
    # TODO four pipe fan coil
    # TODO water baseboard heating
    # TODO electric baseboard
    
    # Air terminals
    self.getAirTerminalSingleDuctParallelPIUReheats.sort.each {|obj| obj.applySizingValues}
    self.getAirTerminalSingleDuctVAVReheats.sort.each {|obj| obj.applySizingValues}
    self.getAirTerminalSingleDuctUncontrolleds.sort.each {|obj| obj.applySizingValues}
    # TODO VAV no reheat
    # TODO CAV reheat
    # TODO Series PIU
    # TODO HeatCool Reheat
    # TODO HeatCool No Reheat
    # TODO Cooled beam
     
    # AirLoopHVAC components
    self.getAirLoopHVACs.sort.each {|obj| obj.applySizingValues}
    self.getSizingSystems.sort.each {|obj| obj.applySizingValues}
    # TODO AirloopHVAC Unitary System
    # TODO AirloopHVAC Unitary Changeover Bypass
    
    # Fans
    self.getFanConstantVolumes.sort.each {|obj| obj.applySizingValues}
    self.getFanVariableVolumes.sort.each {|obj| obj.applySizingValues}
    
    # Heating coils
    self.getCoilHeatingElectrics.sort.each {|obj| obj.applySizingValues}
    self.getCoilHeatingGass.sort.each {|obj| obj.applySizingValues}
    self.getCoilHeatingWaters.sort.each {|obj| obj.applySizingValues}
    # TODO dx heat pump coils
    # TODO water to air HP heating coils
    # TODO multi stage gas heating coils
    
    # Cooling coils
    self.getCoilCoolingDXSingleSpeeds.sort.each {|obj| obj.applySizingValues}
    self.getCoilCoolingDXTwoSpeeds.sort.each {|obj| obj.applySizingValues}
    self.getCoilCoolingWaters.sort.each {|obj| obj.applySizingValues}
    # TODO dx heat pump coils
    # TODO water to air HP cooling coils
    # TODO multi stage DX cooling coils
    
    # Outdoor air
    self.getControllerOutdoorAirs.sort.each {|obj| obj.applySizingValues}
    self.getHeatExchangerAirToAirSensibleAndLatents.sort.each {|obj| obj.applySizingValues}
    # TODO direct evap cooler
    # TODO indirect evap cooler
    # TODO heat exchanger sensbile and latent
    
    # PlantLoop components
    self.getPlantLoops.sort.each {|obj| obj.applySizingValues}
    # TODO fluid to fluid HX
    
    # Pumps
    self.getPumpConstantSpeeds.sort.each {|obj| obj.applySizingValues}
    self.getPumpVariableSpeeds.sort.each {|obj| obj.applySizingValues}
    
    # Heating equipment
    self.getBoilerHotWaters.sort.each {|obj| obj.applySizingValues}
    
    # Cooling equipment
    self.getChillerElectricEIRs.sort.each {|obj| obj.applySizingValues}
    
    # Condenser equipment
    self.getCoolingTowerSingleSpeeds.sort.each {|obj| obj.applySizingValues}
    # TODO evap fluid cooler
    # TODO two speed cooling tower
    # TODO var speed cooling tower
    
    # Controls
    self.getControllerWaterCoils.sort.each {|obj| obj.applySizingValues}
    
    # VRF components
    # TODO VRF system
    # TODO VRF terminal
    
    # Refrigeration components
    
    return true
    
  end

  # A helper method to get component sizes from the model
  # returns the autosized value as an optional double
  def getAutosizedValue(object, value_name, units)

    result = OpenStudio::OptionalDouble.new()

    name = object.name.get.upcase
    
    object_type = object.iddObject.type.valueDescription.gsub('OS:','')
      
    sql = self.sqlFile
    
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
   
end
