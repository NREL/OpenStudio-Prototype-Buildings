
# Load the initial model
def add_geometry(model, geometry_osm_name)
  
  OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started adding geometry")
  
  # Take the existing model and remove all the objects 
  # (this is cheesy), but need to keep the same memory block
  handles = OpenStudio::UUIDVector.new
  model.objects.each {|o| handles << o.handle}
  model.removeObjects(handles)

  # Load geometry from the saved geometry.osm
  geom_model = safe_load_model("#{File.dirname(__FILE__)}/#{geometry_osm_name}")

  # Add the objects from the geometry model to the working model
  model.addObjects(geom_model.toIdfFile.objects)

  OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished adding geometry")
  
  return model
  
end

# open the class to add methods to size all HVAC equipment
class OpenStudio::Model::Model

  def assign_space_type_stubs(building_type, space_type_map)

    space_type_map.each do |space_type_name, space_names|
      # Create a new space type
      stub_space_type = OpenStudio::Model::SpaceType.new(self)
      stub_space_type.setStandardsBuildingType(building_type)
      stub_space_type.setStandardsSpaceType(space_type_name)
        
      space_names.each do |space_name|
        space = self.getSpaceByName(space_name)
        next if space.empty?
        space = space.get
        space.setSpaceType(stub_space_type)

        #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Setting #{space.name} to #{building_type}.#{space_type_name}")
      end
    end

    return true
  end

  def add_loads(building_vintage, climate_zone, standards_data_dir)

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started applying space types (loads)")

    path_to_standards_json = "#{standards_data_dir}/OpenStudio_Standards.json"
    path_to_master_schedules_library = "#{standards_data_dir}/Master_Schedules.osm"

    require_relative '../standards data/SpaceTypeGenerator'

    #create generators
    space_type_generator = SpaceTypeGenerator.new(path_to_standards_json, path_to_master_schedules_library)

    #loop through all the space types currently in the self
    #which are placeholders, and replace with actual space types
    #that have loads
    self.getSpaceTypes.each do |old_space_type|

      #get the building type
      stds_building_type = nil
      if old_space_type.standardsBuildingType.is_initialized
        stds_building_type = old_space_type.standardsBuildingType.get
      else
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Space type called '#{old_space_type.name}' has no standards building type.")
        return false
      end
      
      #get the space type
      stds_spc_type = nil
      if old_space_type.standardsSpaceType.is_initialized
        stds_spc_type = old_space_type.standardsSpaceType.get
      else
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Space type called '#{old_space_type.name}' has no standards space type.")
        return false
      end

      # climate_const = space_type_generator.find_climate_zone_set(building_vintage, climate_zone, stds_building_type, stds_spc_type)

      new_space_type = space_type_generator.generate_space_type(building_vintage, "ClimateZone 1-8", stds_building_type, stds_spc_type, self)[0]

      #apply the new space type to the building      
      old_space_type.spaces.each do |space|
        space.setSpaceType(new_space_type)
        #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Setting #{space.name} to #{new_space_type.name.get}")
      end
        
    end
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished applying space types (loads)")
    
    return true

  end

  def add_constructions(building_type, building_vintage, climate_zone, standards_data_dir)

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started applying constructions")
    
    path_to_standards_json = "#{standards_data_dir}/OpenStudio_Standards.json"
    
    #load the data from the JSON file into a ruby hash
    standards = {}
    temp = File.read(path_to_standards_json)
    standards = JSON.parse(temp)
    space_types = standards["space_types"]
    construction_sets = standards["construction_sets"]
    
    require_relative '../standards data/ConstructionSetGenerator'
    construction_set_generator = ConstructionSetGenerator.new(path_to_standards_json)

      # get climate zone set from specific climate zone for construction set
      climateConst = construction_set_generator.find_climate_zone_set(building_vintage, climate_zone, building_type, "")

      # add construction set
      for t in construction_sets.keys.sort
        next if not t == building_vintage
        for c in construction_sets[building_vintage].keys.sort
          next if not c == climateConst
          for b in construction_sets[building_vintage][climateConst].keys.sort
            next if not b == building_type
            for space_type in construction_sets[building_vintage][climateConst][building_type].keys.sort
              #generate construction set
              result = construction_set_generator.generate_construction_set(building_vintage, climateConst, building_type, space_type, self)

              # set default construction set
              self.getBuilding.setDefaultConstructionSet(result[0])

            end #next space type
          end #next building type
        end #next climate_zone
      end #next building_vintage

    sub_surface = self.getBuilding.defaultConstructionSet.get.defaultExteriorSubSurfaceConstructions.get
    window_construction = sub_surface.fixedWindowConstruction.get
    sub_surface.setSkylightConstruction(window_construction)

    material = OpenStudio::Model::StandardOpaqueMaterial.new(self)
    material.setName("Std Wood 6inch")
    material.setRoughness("MediumSmooth")
    material.setThickness(0.15)
    material.setConductivity(0.12)
    material.setDensity(540)
    material.setSpecificHeat(1210)
    material.setThermalAbsorptance(0.9)
    material.setSolarAbsorptance(0.7)
    material.setVisibleAbsorptance(0.7)

    construction = OpenStudio::Model::Construction.new(self)
    construction.setName("InteriorFurnishings")
    
    layers = OpenStudio::Model::MaterialVector.new
    layers << material
    construction.setLayers(layers)

    self.getInternalMassDefinitions.each do |int_mass_def|
      int_mass_def.setConstruction(construction)
    end

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished applying constructions")
    
    return true

  end  

  def create_thermal_zones

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started creating thermal zones")

    # Create a thermal zone for each space in the self
    self.getSpaces.each do |space|
      zone = OpenStudio::Model::ThermalZone.new(self)
      zone.setName("#{space.name} ZN")
      space.setThermalZone(zone)
      
      # Skip thermostat for spaces with no space type
      next if space.spaceType.empty?
      
      # Add a thermostat
      space_type_name = space.spaceType.get.name.get
      thermostat_name = space_type_name + " Thermostat"
      thermostat = self.getThermostatSetpointDualSetpointByName(thermostat_name)
      if thermostat.empty?
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Thermostat #{thermostat_name} not found for space name: #{space.name}")
        return true
      end
      zone.setThermostatSetpointDualSetpoint(thermostat.get)
    end

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished creating thermal zones")
    
    return true

  end

  def add_occupancy_sensors(building_type, building_vintage, climate_zone)
   
    # Only add occupancy sensors for 90.1-2010
     return true unless building_vintage == "90.1-2010"
   
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started Adding Occupancy Sensors")

    space_type_reduction_map = {
      "SecondarySchool" => {"Classroom" => 0.32}
    }
    
    # Loop through all the space types and reduce lighting operation schedule fractions as-specified
    self.getSpaceTypes.each do |space_type|
      # Skip space types with no standards building type
      next if space_type.standardsBuildingType.empty?
      stds_bldg_type = space_type.standardsBuildingType.get
      
      # Skip space types with no standards space type
      next if space_type.standardsSpaceType.empty?
      stds_spc_type = space_type.standardsSpaceType.get
      
      # Skip building types and space types that aren't listed in the hash
      next unless space_type_reduction_map.has_key?(stds_bldg_type)
      next unless space_type_reduction_map[stds_bldg_type].has_key?(stds_spc_type)
      
      # Get the reduction fraction multiplier
      red_multiplier = 1 - space_type_reduction_map[stds_bldg_type][stds_spc_type]
      
      lights_sch_names = []
      lights_schs = {}
      reduced_lights_schs = {}

      # Get all of the lights in this space type
      # and determine the list of schedules they use.
      space_type.lights.each do |light|
        # Skip lights that don't have a schedule
        next if light.schedule.empty?
        lights_sch = light.schedule.get
        lights_schs[lights_sch.name.to_s] = lights_sch
        lights_sch_names << lights_sch.name.to_s    
      end

      # Loop through the unique list of lighting schedules, cloning
      # and reducing schedule fraction before and after the specified times
      lights_sch_names.uniq.each do |lights_sch_name|
        lights_sch = lights_schs[lights_sch_name]
        # Skip non-ruleset schedules
        next if lights_sch.to_ScheduleRuleset.empty?

        # Clone the schedule (so that we don't mess with lights in
        # other space types that might be using the same schedule).
        new_lights_sch = lights_sch.clone(self).to_ScheduleRuleset.get
        new_lights_sch.setName("#{lights_sch_name} OccSensor Reduction")
        reduced_lights_schs[lights_sch_name] = new_lights_sch

        # Method to multiply the values in a day schedule by a specified value
        def multiply_schedule(day_sch, multiplier)       
          # Record the original times and values
          times = day_sch.times
          values = day_sch.values
          
          # Remove the original times and values
          day_sch.clearValues
          
          # Create new values by using the multiplier on the original values
          new_values = []
          for i in 0..(values.length - 1)
              new_values << values[i] * multiplier
          end
          
          # Add the revised time/value pairs to the schedule
          for i in 0..(new_values.length - 1)
            day_sch.addValue(times[i], new_values[i])
          end
        end #end reduce schedule

        # Reduce default day schedule
        multiply_schedule(new_lights_sch.defaultDaySchedule, red_multiplier)
        
        # Reduce all other rule schedules
        new_lights_sch.scheduleRules.each do |sch_rule|
          multiply_schedule(sch_rule.daySchedule, red_multiplier)
        end
         
      end #end of lights_sch_names.uniq.each do

      # Loop through all lights instances, replacing old lights
      # schedules with the reduced schedules.
      space_type.lights.each do |light|
        # Skip lights that don't have a schedule
        next if light.schedule.empty?
        old_lights_sch_name = light.schedule.get.name.to_s
        if reduced_lights_schs[old_lights_sch_name]
          light.setSchedule(reduced_lights_schs[old_lights_sch_name])
          OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Occupancy sensor reduction added to '#{light.name}'")
        end
      end
    
    end
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished Adding Occupancy Sensors")
    
    return true
    
  end #add occupancy sensors

  def add_exterior_lights(building_type, building_vintage, climate_zone, prototype_input)
   
    # TODO Standards - translate w/linear foot of facade, door, parking, etc
    # into lookup table and implement that way instead of hard-coding as
    # inputs in the spreadsheet.
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started adding exterior lights")
 
    # Occupancy Sensing Exterior Lights
    # which reduce to 70% power when no one is around.
    unless prototype_input["occ_sensing_exterior_lighting_power"].nil?
      occ_sens_ext_lts_power = prototype_input["occ_sensing_exterior_lighting_power"]
      occ_sens_ext_lts_name = "Occ Sensing Exterior Lights"
      occ_sens_ext_lts_def = OpenStudio::Model::ExteriorLightsDefinition.new(self)
      occ_sens_ext_lts_def.setName("#{occ_sens_ext_lts_name} Def")
      occ_sens_ext_lts_def.setDesignLevel(occ_sens_ext_lts_power)
      occ_sens_ext_lts_sch = OpenStudio::Model::ScheduleRuleset.new(self)
      occ_sens_ext_lts_sch.setName("#{occ_sens_ext_lts_name} Sch")
      occ_sens_ext_lts_sch.defaultDaySchedule.setName("#{occ_sens_ext_lts_name} Default Sch")
      occ_sens_ext_lts_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,6,0,0),0)
      occ_sens_ext_lts_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),1)
      occ_sens_ext_lts = OpenStudio::Model::ExteriorLights.new(occ_sens_ext_lts_def, occ_sens_ext_lts_sch)
      occ_sens_ext_lts.setName("#{occ_sens_ext_lts_name} Def")
      occ_sens_ext_lts.setControlOption("AstronomicalClock")
    end
    
    # Building Facade and Landscape Lights
    # that don't dim at all at night.    
    unless prototype_input["nondimming_exterior_lighting_power"].nil?
      nondimming_ext_lts_power = prototype_input["nondimming_exterior_lighting_power"]
      nondimming_ext_lts_name = "NonDimming Exterior Lights"
      nondimming_ext_lts_def = OpenStudio::Model::ExteriorLightsDefinition.new(self)
      nondimming_ext_lts_def.setName("#{nondimming_ext_lts_name} Def")
      nondimming_ext_lts_def.setDesignLevel(nondimming_ext_lts_power)
      # 
      nondimming_ext_lts_sch = nil
      if building_vintage == "90.1-2010"
        nondimming_ext_lts_sch = OpenStudio::Model::ScheduleRuleset.new(self)
        nondimming_ext_lts_sch.setName("#{nondimming_ext_lts_name} Sch")
        nondimming_ext_lts_sch.defaultDaySchedule.setName("#{nondimming_ext_lts_name} Default Sch")
        nondimming_ext_lts_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,6,0,0),0)
        nondimming_ext_lts_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),1)
      elsif building_vintage == "DOE Ref Pre-1980" || building_vintage == "DOE Ref 1980-2004"
        nondimming_ext_lts_sch = self.alwaysOnDiscreteSchedule
      end
      nondimming_ext_lts = OpenStudio::Model::ExteriorLights.new(nondimming_ext_lts_def, nondimming_ext_lts_sch)
      nondimming_ext_lts.setName("#{nondimming_ext_lts_name} Def")
      nondimming_ext_lts.setControlOption("AstronomicalClock")
    end
   
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished adding exterior lights")
    
    return true
    
  end #add exterior lights  
  
end
