
def add_geometry(model)
  
  @runner.registerInfo("Started adding geometry")
  
  #load geometry from the saved .osm
  model = safe_load_model("#{File.dirname(__FILE__)}/secondary_school_geometry.osm")

  @runner.registerInfo("Finished adding geometry")
  
  return model
  
end
 
def define_space_type_map

  space_type_map = {
    'Office' => ['Offices_ZN_1_FLR_1', 'Offices_ZN_1_FLR_2'],
    'Lobby' => ['Lobby_ZN_1_FLR_2', 'Lobby_ZN_1_FLR_1'],
    'Gym' => ['Gym_ZN_1_FLR_1', 'Aux_Gym_ZN_1_FLR_1'],
    'Mechanical' => ['Mech_ZN_1_FLR_2', 'Mech_ZN_1_FLR_1'],
    'Cafeteria' => ['Cafeteria_ZN_1_FLR_1'],
    'Kitchen' => ['Kitchen_ZN_1_FLR_1'],
    'Restroom' => ['Bathrooms_ZN_1_FLR_2', 'Bathrooms_ZN_1_FLR_1'],
    'Auditorium' => ['Auditorium_ZN_1_FLR_1'],
    'Corridor' => ['Corridor_Pod_1_ZN_1_FLR_1', 'Corridor_Pod_3_ZN_1_FLR_2',
                    'Main_Corridor_ZN_1_FLR_2', 'Main_Corridor_ZN_1_FLR_1',
                    'Corridor_Pod_3_ZN_1_FLR_1', 'Corridor_Pod_1_ZN_1_FLR_2',
                    'Corridor_Pod_2_ZN_1_FLR_1', 'Corridor_Pod_2_ZN_1_FLR_2'],
    'Classroom' => [
      'Mult_Class_2_Pod_2_ZN_1_FLR_2',
      'Mult_Class_2_Pod_3_ZN_1_FLR_1',
      'Corner_Class_2_Pod_1_ZN_1_FLR_1',
      'Mult_Class_2_Pod_1_ZN_1_FLR_2',
      'Corner_Class_1_Pod_1_ZN_1_FLR_1',
      'Corner_Class_2_Pod_1_ZN_1_FLR_2',
      'Corner_Class_1_Pod_2_ZN_1_FLR_2',
      'Mult_Class_1_Pod_1_ZN_1_FLR_2',
      'Corner_Class_2_Pod_2_ZN_1_FLR_2',
      'Mult_Class_2_Pod_2_ZN_1_FLR_1',
      'Mult_Class_2_Pod_3_ZN_1_FLR_2',
      'LIBRARY_MEDIA_CENTER_ZN_1_FLR_2',
      'Corner_Class_1_Pod_3_ZN_1_FLR_1',
      'Mult_Class_1_Pod_1_ZN_1_FLR_1',
      'Mult_Class_1_Pod_2_ZN_1_FLR_2',
      'Mult_Class_1_Pod_2_ZN_1_FLR_1',
      'Mult_Class_2_Pod_1_ZN_1_FLR_1',
      'Mult_Class_1_Pod_3_ZN_1_FLR_1',
      'Corner_Class_1_Pod_1_ZN_1_FLR_2',
      'Corner_Class_1_Pod_2_ZN_1_FLR_1',
      'Corner_Class_2_Pod_2_ZN_1_FLR_1',
      'Corner_Class_1_Pod_3_ZN_1_FLR_2',
      'Mult_Class_1_Pod_3_ZN_1_FLR_2',
      'Corner_Class_2_Pod_3_ZN_1_FLR_1',
      'Corner_Class_2_Pod_3_ZN_1_FLR_2'
    ]
  }

  return space_type_map

end

def define_hvac_system_map

  system_to_space_map = [
    {
        'type' => 'VAV',
        'space_names' =>
        [
            'Corner_Class_1_Pod_1_ZN_1_FLR_1',
            'Corner_Class_1_Pod_1_ZN_1_FLR_2',
            'Mult_Class_1_Pod_1_ZN_1_FLR_1',
            'Mult_Class_1_Pod_1_ZN_1_FLR_2',
            'Corridor_Pod_1_ZN_1_FLR_1',
            'Corridor_Pod_1_ZN_1_FLR_2',
            'Corner_Class_2_Pod_1_ZN_1_FLR_1',
            'Corner_Class_2_Pod_1_ZN_1_FLR_2',
            'Mult_Class_2_Pod_1_ZN_1_FLR_1',
            'Mult_Class_2_Pod_1_ZN_1_FLR_2'
        ]
    },
    {
        'type' => 'VAV',
        'space_names' =>
        [
            'Corner_Class_1_Pod_2_ZN_1_FLR_1',
            'Corner_Class_1_Pod_2_ZN_1_FLR_2',
            'Mult_Class_1_Pod_2_ZN_1_FLR_1',
            'Mult_Class_1_Pod_2_ZN_1_FLR_2',
            'Corridor_Pod_2_ZN_1_FLR_1',
            'Corridor_Pod_2_ZN_1_FLR_2',
            'Corner_Class_2_Pod_2_ZN_1_FLR_1',
            'Corner_Class_2_Pod_2_ZN_1_FLR_2',
            'Mult_Class_2_Pod_2_ZN_1_FLR_1',
            'Mult_Class_2_Pod_2_ZN_1_FLR_2'
        ]
    },
    {
        'type' => 'VAV',
        'space_names' =>
        [
            'Corner_Class_1_Pod_3_ZN_1_FLR_1',
            'Corner_Class_1_Pod_3_ZN_1_FLR_2',
            'Mult_Class_1_Pod_3_ZN_1_FLR_1',
            'Mult_Class_1_Pod_3_ZN_1_FLR_2',
            'Corridor_Pod_3_ZN_1_FLR_1',
            'Corridor_Pod_3_ZN_1_FLR_2',
            'Corner_Class_2_Pod_3_ZN_1_FLR_1',
            'Corner_Class_2_Pod_3_ZN_1_FLR_2',
            'Mult_Class_2_Pod_3_ZN_1_FLR_1',
            'Mult_Class_2_Pod_3_ZN_1_FLR_2'
        ]
    },
    {
        'type' => 'VAV',
        'space_names' =>
        [
            'Main_Corridor_ZN_1_FLR_1',
            'Main_Corridor_ZN_1_FLR_2',
            'Lobby_ZN_1_FLR_1',
            'Lobby_ZN_1_FLR_2',
            'Bathrooms_ZN_1_FLR_1',
            'Bathrooms_ZN_1_FLR_2',
            'Offices_ZN_1_FLR_1',
            'Offices_ZN_1_FLR_2',
            'LIBRARY_MEDIA_CENTER_ZN_1_FLR_2',
            'Mech_ZN_1_FLR_1',
            'Mech_ZN_1_FLR_2'
        ]
    },
    {
        'type' => 'PSZ-AC',
        'space_names' =>
        [
            'Gym_ZN_1_FLR_1'
        ]
    },
    {
        'type' => 'PSZ-AC',
        'space_names' =>
        [
            'Aux_Gym_ZN_1_FLR_1'
        ]
    },
    {
        'type' => 'PSZ-AC',
        'space_names' =>
        [
            'Auditorium_ZN_1_FLR_1'
        ]
    },
    {
        'type' => 'PSZ-AC',
        'space_names' =>
        [
            'Kitchen_ZN_1_FLR_1'
        ]
    },
    {
        'type' => 'PSZ-AC',
        'space_names' =>
        [
            'Cafeteria_ZN_1_FLR_1'
        ]
    }
]

  return system_to_space_map

end

def assign_space_type_stubs(model, building_type, space_type_map)

  space_type_map.each do |space_type_name, space_names|
    # Create a new space type
    stub_space_type = OpenStudio::Model::SpaceType.new(model)
    stub_space_type.setStandardsBuildingType(building_type)
    stub_space_type.setStandardsSpaceType(space_type_name)
      
    space_names.each do |space_name|
      space = model.getSpaceByName(space_name)
      next if space.empty?
      space = space.get
      space.setSpaceType(stub_space_type)

      #@runner.registerInfo("Setting #{space.name} to #{building_type}.#{space_type_name}")
    end
  end

  return model
end

def add_loads(model, building_vintage, climate_zone)

  @runner.registerInfo("Started applying space types (loads)")

  path_to_standards_json = "#{@standards_data_dir}/OpenStudio_Standards.json"
  path_to_master_schedules_library = "#{@standards_data_dir}/Master_Schedules.osm"

  require_relative '../standards data/SpaceTypeGenerator'

  #create generators
  space_type_generator = SpaceTypeGenerator.new(path_to_standards_json, path_to_master_schedules_library)

  #loop through all the space types currently in the model
  #which are placeholders, and replace with actual space types
  #that have loads
  model.getSpaceTypes.each do |old_space_type|

    #get the building type
    stds_building_type = nil
    if old_space_type.standardsBuildingType.is_initialized
      stds_building_type = old_space_type.standardsBuildingType.get
    else
      @runner.registerError("Space type called '#{old_space_type.name}' has no standards building type.")
      return false
    end
    
    #get the space type
    stds_spc_type = nil
    if old_space_type.standardsSpaceType.is_initialized
      stds_spc_type = old_space_type.standardsSpaceType.get
    else
      @runner.registerError("Space type called '#{old_space_type.name}' has no standards space type.")
      return false
    end

    # climate_const = space_type_generator.find_climate_zone_set(building_vintage, climate_zone, stds_building_type, stds_spc_type)

    new_space_type = space_type_generator.generate_space_type(building_vintage, "ClimateZone 1-8", stds_building_type, stds_spc_type, model)[0]

    #apply the new space type to the building      
    old_space_type.spaces.each do |space|
      space.setSpaceType(new_space_type)
      #@runner.registerInfo("Setting #{space.name} to #{new_space_type.name.get}")
    end
      
  end
  
  @runner.registerInfo("Finished applying space types (loads)")
  
  return model

end

def add_constructions(model, building_type, building_vintage, climate_zone)

  @runner.registerInfo("Started applying constructions")
  
  path_to_standards_json = "#{@standards_data_dir}/OpenStudio_Standards.json"
  
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
            result = construction_set_generator.generate_construction_set(building_vintage, climateConst, building_type, space_type, model)

            # set default construction set
            model.getBuilding.setDefaultConstructionSet(result[0])

          end #next space type
        end #next building type
      end #next climate_zone
    end #next building_vintage

  sub_surface = model.getBuilding.defaultConstructionSet.get.defaultExteriorSubSurfaceConstructions.get
  window_construction = sub_surface.fixedWindowConstruction.get
  sub_surface.setSkylightConstruction(window_construction)

  material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
  material.setName("Std Wood 6inch")
  material.setRoughness("MediumSmooth")
  material.setThickness(0.15)
  material.setConductivity(0.12)
  material.setDensity(540)
  material.setSpecificHeat(1210)
  material.setThermalAbsorptance(0.9)
  material.setSolarAbsorptance(0.7)
  material.setVisibleAbsorptance(0.7)

  construction = OpenStudio::Model::Construction.new(model)
  construction.setName("InteriorFurnishings")
  
  layers = OpenStudio::Model::MaterialVector.new
  layers << material
  construction.setLayers(layers)

  model.getInternalMassDefinitions.each do |int_mass_def|
    int_mass_def.setConstruction(construction)
  end

  @runner.registerInfo("Finished applying constructions")
  
  return model

end  

def create_thermal_zones(model)

  @runner.registerInfo("Started creating thermal zones")

  # Create a thermal zone for each space in the model
  model.getSpaces.each do |space|
    zone = OpenStudio::Model::ThermalZone.new(model)
    zone.setName("#{space.name} ZN")
    space.setThermalZone(zone)

    space_type_name = space.spaceType.get.name.get
    thermostat_name = space_type_name + " Thermostat"
    thermostat = model.getThermostatSetpointDualSetpointByName(thermostat_name)
    if thermostat.empty?
      @runner.registerError("Thermostat #{thermostat_name} not found for space name: #{space.name}")
      return model
    end
    zone.setThermostatSetpointDualSetpoint(thermostat.get)
  end

  @runner.registerInfo("Finished creating thermal zones")
  
  return model

end
   
def add_hvac(model, building_type, building_vintage, climate_zone)
 
  @runner.registerInfo("Started Adding HVAC")
  
  system_to_space_map = define_hvac_system_map()

  chilled_water_loop = add_chw_loop(model, @prototype_input)

  hot_water_loop = add_hw_loop(model, @prototype_input)
   
  #VAVR system; hot water reheat, water-cooled chiller
  
  system_to_space_map.each do |system|

    #find all zones associated with these spaces
    thermal_zones = []
    system['space_names'].each do |space_name|
      space = model.getSpaceByName(space_name)
      if space.empty?
        @runner.registerError("No space called #{space_name} was found in the model")
        return false
      end
      space = space.get
      zone = space.thermalZone
      if zone.empty?
        @runner.registerError("No thermal zone created for space called #{space_name} was found in the model")
        return false
      end
      thermal_zones << zone.get
    end

    case system['type']
    when 'VAV'
      if hot_water_loop && chilled_water_loop
        model = add_vav(model, @prototype_input, hot_water_loop, chilled_water_loop, thermal_zones)
      else
        @runner.registerError("No hot water and chilled water plant loops in model")
        return false
      end
    when "PSZ-AC"
      model = add_psz_ac(model, @prototype_input, thermal_zones)
    end

  end

  @runner.registerInfo("Finished adding HVAC")
  
  return model
  
end #add hvac

def add_exterior_lights(model, building_type, building_vintage, climate_zone)
 
  @runner.registerInfo("Started adding exterior lights")
  
  # Exterior lights A
  ext_lights_a_name = "Exterior Lights A"
  ext_lights_a_power = 353.47
  ext_lights_a_def = OpenStudio::Model::ExteriorLightsDefinition.new(model)
  ext_lights_a_def.setName("#{ext_lights_a_name} Def")
  ext_lights_a_def.setDesignLevel(ext_lights_a_power)
  ext_lights_a_sch = OpenStudio::Model::ScheduleRuleset.new(model)
  ext_lights_a_sch.setName("#{ext_lights_a_name} Sch")
  ext_lights_a_sch.defaultDaySchedule.setName("#{ext_lights_a_name} Default Sch")
  ext_lights_a_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,6,0,0),0)
  ext_lights_a_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),1)
  ext_lights_a = OpenStudio::Model::ExteriorLights.new(ext_lights_a_def, ext_lights_a_sch)
  ext_lights_a.setName("#{ext_lights_a_name} Def")
  ext_lights_a.setControlOption("AstronomicalClock")

  # Exterior lights A
  ext_lights_b_name = "Exterior Lights B"
  ext_lights_b_power = 8427.85
  ext_lights_b_def = OpenStudio::Model::ExteriorLightsDefinition.new(model)
  ext_lights_b_def.setName("#{ext_lights_b_name} Def")
  ext_lights_b_def.setDesignLevel(ext_lights_b_power)
  ext_lights_b_sch = OpenStudio::Model::ScheduleRuleset.new(model)
  ext_lights_b_sch.setName("#{ext_lights_b_name} Sch")
  ext_lights_b_sch.defaultDaySchedule.setName("#{ext_lights_b_name} Default Sch")
  ext_lights_b_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,6,0,0),0)
  ext_lights_b_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),1)
  ext_lights_b = OpenStudio::Model::ExteriorLights.new(ext_lights_b_def, ext_lights_b_sch)
  ext_lights_b.setName("#{ext_lights_b_name} Def")
  ext_lights_b.setControlOption("AstronomicalClock")
 
  @runner.registerInfo("Finished adding exterior lights")
  
  return model
  
end #add exterior lights

def add_occupancy_sensors(model, building_type, building_vintage, climate_zone)
 
  # Only add occupancy sensors for 90.1-2010
   return model unless building_vintage == "90.1-2010"
 
  @runner.registerInfo("Started Adding Occupancy Sensors")

  space_type_reduction_map = {
    "SecondarySchool" => {"Classroom" => 0.32}
  }
  
  # Loop through all the space types and reduce lighting operation schedule fractions as-specified
  model.getSpaceTypes.each do |space_type|
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
      new_lights_sch = lights_sch.clone(model).to_ScheduleRuleset.get
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
        @runner.registerInfo("Occupancy sensor reduction added to '#{light.name}'")
      end
    end
  
  end
  
  @runner.registerInfo("Finished Adding Occupancy Sensors")
  
  return model
  
end #add occupancy sensors
