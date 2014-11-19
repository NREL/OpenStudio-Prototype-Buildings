
#load a model into OS & version translates, exiting and erroring if a problem is found
def safe_load_model(model_path_string)  
  model_path = OpenStudio::Path.new(model_path_string)
  if OpenStudio::exists(model_path)
    versionTranslator = OpenStudio::OSVersion::VersionTranslator.new 
    model = versionTranslator.loadModel(model_path)
    if model.empty?
      OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Model", "Version translation failed for #{model_path_string}")
      return false
    else
      model = model.get
    end
  else
    OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Model", "#{model_path_string} couldn't be found")
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
    OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Model", "#{sql_path} couldn't be found")
    return false
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

# A helper method to search through a hash for the objects that meets the
# desired search criteria, as passed via a hash.  If capacity is supplied,
# the objects will only be returned if the specified capacity is between
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
    OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Model", "Find objects search criteria returned no results. Search criteria: #{search_criteria}, capacity = #{capacity}.  Called from #{caller(0)[1]}.")
  end
  
  return matching_objects
 
end

# A helper method to search through a hash for an object that meets the
# desired search criteria, as passed via a hash.  If capacity is supplied,
# the object will only be returned if the specified capacity is between
# the minimum_capacity and maximum_capacity values.
def find_object(hash_of_objects, search_criteria, capacity = nil)
  
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
    OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Model", "Find object search criteria returned no results. Search criteria: #{search_criteria}, capacity = #{capacity}.  Called from #{caller(0)[1]}")
  elsif matching_objects.size == 1
    desired_object = matching_objects[0]
  else 
    desired_object = matching_objects[0]
    OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Model", "Find object search criteria returned #{matching_objects.size} results, the first one will be returned. Search criteria: #{search_criteria} Called from #{caller(0)[1]}.  All results: \n #{matching_objects.join("\n")}")
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
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started simulation in '#{run_dir}'")
    
    # Change the simulation to only run the weather file
    # and not run the sizing day simulations
    sim_control = self.getSimulationControl
    sim_control.setRunSimulationforSizingPeriods(false)
    sim_control.setRunSimulationforWeatherFileRunPeriods(true)
    
    # Save the model to energyplus idf
    idf_name = "in.idf"
    osm_name = "in.osm"
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
          OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Model", "Model has not been assigned a weather file.")
          return false
        end
      else
        OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Model", "Model has a weather file assigned, but the file is not in the specified location.")
        return false
      end
    else
      OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Model", "Model has not been assigned a weather file.")
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
    run_manager = OpenStudio::Runmanager::RunManager.new(run_manager_db_path, true, false, false, false)
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
    
    # Load the sql file created by the sizing run
    sql_path = OpenStudio::Path.new("#{run_dir}/Energyplus/eplusout.sql")
    if OpenStudio::exists(sql_path)
      sql = OpenStudio::SqlFile.new(sql_path)
      # Attach the sql file from the run to the sizing model
      self.setSqlFile(sql)
    else 
      OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Model", "Results for the sizing run couldn't be found here: #{sql_path}.")
      return false
    end
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished simulation in '#{run_dir}'")
    
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
  
  # A helper method to make a schedule from the standards json data
  def make_schedule(schedules, schedule_name)

    require 'date'

    # First, find all the schedules that match the name
    rules = find_objects(schedules, {"name"=>schedule_name})
    
    # Make a schedule ruleset
    sch_ruleset = OpenStudio::Model::ScheduleRuleset.new(self)
    sch_ruleset.setName("#{schedule_name}")  

    # Loop through the rules, making one for each row in the spreadsheet
    rules.each do |rule|
      day_types = rule["day_types"]
      start_date = DateTime.parse(rule["start_date"])
      end_date = DateTime.parse(rule["end_date"])
      
      #Day Type choices: Wkdy, Wknd, Mon, Tue, Wed, Thu, Fri, Sat, Sun, WntrDsn, SmrDsn, Hol
      
      # Default
      if day_types.include?("Default")
        day_sch = sch_ruleset.defaultDaySchedule
        day_sch.setName("#{schedule_name} Default")
        for i in 1..24
          next if rule["hr_#{i}"] == rule["hr_#{i+1}"]
          day_sch.addValue(OpenStudio::Time.new(0, i, 0, 0), rule["hr_#{i}"])     
        end  
      end
      
      # Winter Design Day
      if day_types.include?("WntrDsn")
        day_sch = OpenStudio::Model::ScheduleDay.new(self)  
        sch_ruleset.setWinterDesignDaySchedule(day_sch)
        day_sch = sch_ruleset.winterDesignDaySchedule
        day_sch.setName("#{schedule_name} Winter Design Day")
        for i in 1..24
          next if rule["hr_#{i}"] == rule["hr_#{i+1}"]
          day_sch.addValue(OpenStudio::Time.new(0, i, 0, 0), rule["hr_#{i}"])     
        end  
      end    
      
      # Summer Design Day
      if day_types.include?("SmrDsn")
        day_sch = OpenStudio::Model::ScheduleDay.new(self)  
        sch_ruleset.setSummerDesignDaySchedule(day_sch)
        day_sch = sch_ruleset.summerDesignDaySchedule
        day_sch.setName("#{schedule_name} Summer Design Day")
        for i in 1..24
          next if rule["hr_#{i}"] == rule["hr_#{i+1}"]
          day_sch.addValue(OpenStudio::Time.new(0, i, 0, 0), rule["hr_#{i}"])     
        end  
      end
      
      # Other days (weekdays, weekends, etc)
      if day_types.include?("Wknd") ||
        day_types.include?("Wkdy") ||
        day_types.include?("Sat") ||
        day_types.include?("Sun") ||
        day_types.include?("Mon") ||
        day_types.include?("Tue") ||
        day_types.include?("Wed") ||
        day_types.include?("Thu") ||
        day_types.include?("Fri")
      
        # Make the Rule
        sch_rule = OpenStudio::Model::ScheduleRule.new(sch_ruleset)
        day_sch = sch_rule.daySchedule
        day_sch.setName("#{schedule_name} Summer Design Day")
        for i in 1..24
          next if rule["hr_#{i}"] == rule["hr_#{i+1}"]
          day_sch.addValue(OpenStudio::Time.new(0, i, 0, 0), rule["hr_#{i}"])     
        end 
        
        # Set the dates when the rule applies
        sch_rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_date.month.to_i), start_date.day.to_i))
        sch_rule.setEndDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_date.month.to_i), end_date.day.to_i))
        
        # Set the days when the rule applies
        # Weekends
        if day_types.include?("Wknd")
          sch_rule.setApplySaturday(true)
          sch_rule.setApplySunday(true)
        end
        # Weekdays
        if day_types.include?("Wkdy")
          sch_rule.setApplyMonday(true)
          sch_rule.setApplyTuesday(true)
          sch_rule.setApplyWednesday(true)
          sch_rule.setApplyThursday(true)
          sch_rule.setApplyFriday(true)
        end
        # Individual Days
        sch_rule.setApplyMonday(true) if day_types.include?("Mon")     
        sch_rule.setApplyTuesday(true) if day_types.include?("Tue")
        sch_rule.setApplyWednesday(true) if day_types.include?("Wed")
        sch_rule.setApplyThursday(true) if day_types.include?("Thu")
        sch_rule.setApplyFriday(true) if day_types.include?("Fri")
        sch_rule.setApplySaturday(true) if day_types.include?("Sat")        
        sch_rule.setApplySunday(true) if day_types.include?("Sun")

      end
      
    end # Next rule  
    
    return sch_ruleset
    
  end
   
end
