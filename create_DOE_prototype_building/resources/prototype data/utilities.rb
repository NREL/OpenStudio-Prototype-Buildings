
#load a model into OS & version translates, exiting and erroring if a problem is found
def safe_load_model(model_path_string)  
  model_path = OpenStudio::Path.new(model_path_string)
  if OpenStudio::exists(model_path)
    versionTranslator = OpenStudio::OSVersion::VersionTranslator.new 
    model = versionTranslator.loadModel(model_path)
    if model.empty?
      puts("Version translation failed for #{model_path_string}")
      @runner.registerError("Version translation failed for #{model_path_string}")
      return false
    else
      model = model.get
    end
  else
    puts("#{model_path_string} couldn't be found")
    @runner.registerError("#{model_path_string} couldn't be found")
    return false
  end
  return model
end

#load a sql file, exiting and erroring if a problem is found
def safe_load_sql(sql_path_string)
  sql_path = OpenStudio::Path.new(sql_path_string)
  if OpenStudio::exists(sql_path)
    sql = OpenStudio::SqlFile.new(sql_path)
  else 
    puts("#{sql_path} couldn't be found")
    @runner.registerError("#{sql_path} couldn't be found")
    exit
  end
  return sql
end

def strip_model(model)


  #remove all materials
  model.getMaterials.each do |mat|
    mat.remove
  end

  #remove all constructions
  model.getConstructions.each do |constr|
    constr.remove
  end

  #remove performance curves
  model.getCurves.each do |curve|
    curve.remove
  end

  #remove all zone equipment
  model.getThermalZones.each do |zone|
    zone.equipment.each do |equip|
      equip.remove
    end
  end
    
  #remove all thermostats
  model.getThermostatSetpointDualSetpoints.each do |tstat|
    tstat.remove
  end

  #remove all people
  model.getPeoples.each do |people|
    people.remove
  end
  model.getPeopleDefinitions.each do |people_def|
    people_def.remove
  end

  #remove all lights
  model.getLightss.each do |lights|
   lights.remove
  end
  model.getLightsDefinitions.each do |lights_def|
   lights_def.remove
  end

  #remove all electric equipment
  model.getElectricEquipments.each do |equip|
    equip.remove
  end
  model.getElectricEquipmentDefinitions.each do |equip_def|
    equip_def.remove
  end

  #remove all gas equipment
  model.getGasEquipments.each do |equip|
    equip.remove
  end
  model.getGasEquipmentDefinitions.each do |equip_def|
    equip_def.remove
  end

  #remove all outdoor air
  model.getDesignSpecificationOutdoorAirs.each do |oa_spec|
    oa_spec.remove
  end

  #remove all infiltration
  model.getSpaceInfiltrationDesignFlowRates.each do |infil|
    infil.remove
  end

  # Remove all thermal zones
  model.getThermalZones.each do |zone|
    zone.remove
  end
  

  return model


end

# A helper method to search through a hash for an object that meets the
# desired search criteria, as passed via a hash.  If capacity is supplied,
# the object will only be returned if the specified capacity is between
# the minimum_capacity and maximum_capacity values.
def find_objects(hash_of_objects, search_criteria, capacity = nil)
  
  desired_object = nil
  search_criteria_matching_objects = []
  matching_objects = []
  
  # Compare each of the objects against the search criteria
  hash_of_objects.each do |object|
    meets_all_search_criteria = true
    search_criteria.each do |key, value|
      # Don't check non-existent search criteria
      next unless object.has_key?(key)
      # Stop as soon as one of the search criteria is not met
      if object[key] != value 
        meets_all_search_criteria = false
        break
      end
    end
    # Skip objects that don't meet all search criteria
    next if meets_all_search_criteria == false
    # If made it here, object matches all search criteria
    search_criteria_matching_objects << object
  end
 
  # If capacity was specified, narrow down the matching objects
  if capacity.nil?
    matching_objects = search_criteria_matching_objects
  else
    search_criteria_matching_objects.each do |object|
      # Skip objects that don't have fields for minimum_capacity and maximum_capacity
      next if !object.has_key?('minimum_capacity') || !object.has_key?('maximum_capacity') 
      # Skip objects that don't have values specified for minimum_capacity and maximum_capacity
      next if object['minimum_capacity'].nil? || object['maximum_capacity'].nil?
      # Skip objects whose the minimum capacity is below the specified capacity
      next if capacity <= object['minimum_capacity']
      # Skip objects whose max
      next if capacity > object['maximum_capacity']
      # Found a matching object      
      matching_objects << object
    end
  end
 
  # Check the number of matching objects found
  if matching_objects.size == 0
    desired_object = nil
    puts "ERROR - Search criteria returned #{matching_objects.size} results. \n Search criteria: #{search_criteria}, capacity = #{capacity}."
  elsif matching_objects.size == 1
    desired_object = matching_objects[0]
  else 
    desired_object = matching_objects[0]
    puts "ERROR - Search criteria returned #{matching_objects.size} results, the first one will be returned. \n Search criteria: #{search_criteria} \n All results: \n #{matching_objects.join("\n")}"
  end
 
  return desired_object
 
end

# A helper method to convert from SEER to COP
# per the method specified in "Achieving the 30% Goal: Energy 
# and cost savings analysis of ASHRAE Standard 90.1-2010
# Thornton, et al 2011
def seer_to_cop(seer)
  
  cop = nil

  # First convert from SEER to EER
  eer = (-0.0182 * seer * seer) + (1.1088 * seer)
  
  # Next convert EER to COP
  cop = eer_to_cop(eer)
  
  return cop
 
end

# A helper method to convert from EER to COP
# per the method specified in "Achieving the 30% Goal: Energy 
# and cost savings analysis of ASHRAE Standard 90.1-2010
# Thornton, et al 2011
def eer_to_cop(eer)
  
  cop = nil

  # r is the ratio of supply fan power to total equipment power at the rating condition,
  # assumed to be 0.12 for the reference buildngs per PNNL.
  r = 0.12
  
  cop = (eer/3.413 + r)/(1-r)
  
  return cop
 
end

# A helper method to convert from COP to kW/ton
def cop_to_kw_per_ton(cop)
  
  kw_per_ton = nil

  kw_per_ton = 3.517/cop
  
  return kw_per_ton
 
end

# open the class to add methods to size all HVAC equipment
class OpenStudio::Model::Model

  # A helper method to run the model
  def run(run_dir = "#{Dir.pwd}/Run")
    
    # If the run directory is not specified
    # run in the current working directory
    
    # Make the directory if it doesn't exist
    if !Dir.exists?(run_dir)
      Dir.mkdir(run_dir)
    end
    
    puts "Started simulation in '#{run_dir}'"
    
    # Change the simulation to only run the weather file
    # and not run the sizing day simulations
    sim_control = self.getSimulationControl
    sim_control.setRunSimulationforSizingPeriods(false)
    sim_control.setRunSimulationforWeatherFileRunPeriods(true)
    
    # Save the model to energyplus idf
    idf_name = "in.idf"
    osm_name = "in.osm"
    #runner.registerInfo("Saving sizing idf to #{run_dir} as '#{idf_name}'")
    forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new()
    idf = forward_translator.translateModel(self)
    idf_path = OpenStudio::Path.new("#{run_dir}/#{idf_name}")  
    osm_path = OpenStudio::Path.new("#{run_dir}/#{osm_name}")
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
    output_path = OpenStudio::Path.new("#{run_dir}/")
    
    # Make a run manager and queue up the sizing run
    run_manager_db_path = OpenStudio::Path.new("#{run_dir}/run.db")
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
    sql_path = OpenStudio::Path.new("#{run_dir}/Energyplus/eplusout.sql")
    if OpenStudio::exists(sql_path)
      sql = OpenStudio::SqlFile.new(sql_path)
      # Attach the sql file from the run to the sizing model
      self.setSqlFile(sql)
    else 
      #self.runner.registerError("Results for the sizing run couldn't be found here: #{sql_path}.")
      return false
    end
    
    puts "Finished simulation in '#{run_dir}'"
    
    return true

  end

  # Helper method to request report variables
  def request_timeseries_outputs
   
    # "detailed"
    # "timestep"
    # "hourly"
    # "daily"
    # "monthly"
   
    vars = []
    vars << ["Heating Coil Gas Rate", "detailed"]
    vars << ["Zone Thermostat Air Temperature", "detailed"]
    vars << ["Zone Thermostat Heating Setpoint Temperature", "detailed"]
    vars << ["Zone Thermostat Cooling Setpoint Temperature", "detailed"]
    vars << ["Zone Air System Sensible Heating Rate", "detailed"]
    vars << ["Zone Air System Sensible Cooling Rate", "detailed"]
    vars << ["Fan Electric Power", "detailed"]
    vars << ["Zone Mechanical Ventilation Standard Density Volume Flow Rate", "detailed"]
    vars << ["Air System Outdoor Air Mass Flow Rate", "detailed"]
    
    vars.each do |var, freq|  
      outputVariable = OpenStudio::Model::OutputVariable.new(var, self)
      outputVariable.setReportingFrequency(freq)
    end
    
  end  
  
end
