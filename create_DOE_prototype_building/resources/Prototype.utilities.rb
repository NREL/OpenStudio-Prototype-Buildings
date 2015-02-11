
#load a model into OS & version translates, exiting and erroring if a problem is found
def safe_load_model(model_path_string)  
  model_path = OpenStudio::Path.new(model_path_string)
  if OpenStudio::exists(model_path)
    versionTranslator = OpenStudio::OSVersion::VersionTranslator.new 
    model = versionTranslator.loadModel(model_path)
    if model.empty?
      OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "Version translation failed for #{model_path_string}")
      return false
    else
      model = model.get
    end
  else
    OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "#{model_path_string} couldn't be found")
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
    OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "#{sql_path} couldn't be found")
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

  # Remove all internal mass
  model.getInternalMasss.each do |tm|
    tm.remove
  end

  # Remove all internal mass defs
  model.getInternalMassDefinitions.each do |tmd|
    tmd.remove
  end
  
  # Remove all thermal zones
  model.getThermalZones.each do |zone|
    zone.remove
  end
  
  # Remove all schedules
  model.getSchedules.each do |sch|
    sch.remove
  end
  
  # Remove all schedule type limits
  model.getScheduleTypeLimitss.each do |typ_lim|
    typ_lim.remove
  end
  
  # Remove the sizing parameters
  model.getSizingParameters.remove
  
  # Remove the design days
  model.getDesignDays.each do |dd|
    dd.remove
  end

  # Remove the rendering colors
  model.getRenderingColors.each do |rc|
    rc.remove
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
    OpenStudio::logFree(OpenStudio::Warn, 'openstudio.model.Model', "Find objects search criteria returned no results. Search criteria: #{search_criteria}, capacity = #{capacity}.  Called from #{caller(0)[1]}.")
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
    next if !meets_all_search_criteria
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
    #OpenStudio::logFree(OpenStudio::Warn, 'openstudio.model.Model', "Find object search criteria returned no results. Search criteria: #{search_criteria}, capacity = #{capacity}.  Called from #{caller(0)[1]}")
  elsif matching_objects.size == 1
    desired_object = matching_objects[0]
  else 
    desired_object = matching_objects[0]
    OpenStudio::logFree(OpenStudio::Warn, 'openstudio.model.Model', "Find object search criteria returned #{matching_objects.size} results, the first one will be returned. Search criteria: #{search_criteria} Called from #{caller(0)[1]}.  All results: \n #{matching_objects.join("\n")}")
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
  
  return 3.517/cop
 
end

# A helper method to convert from kW/ton to COP
def kw_per_ton_to_cop(kw_per_ton)
  
  return 3.517/kw_per_ton
 
end
