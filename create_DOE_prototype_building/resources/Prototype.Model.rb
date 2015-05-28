
# open the class to add methods to size all HVAC equipment
class OpenStudio::Model::Model

  # Let the model store and access its own template and hvac_standards
  attr_accessor :template
  attr_accessor :hvac_standards
  attr_accessor :climate_zone
  #attr_accessor :runner
 
  def add_geometry(geometry_osm_name)
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started adding geometry')
    
    # Take the existing model and remove all the objects 
    # (this is cheesy), but need to keep the same memory block
    handles = OpenStudio::UUIDVector.new
    self.objects.each {|o| handles << o.handle}
    self.removeObjects(handles)

    # Load geometry from the saved geometry.osm
    geom_model = safe_load_model("#{File.dirname(__FILE__)}/#{geometry_osm_name}")

    # Add the objects from the geometry model to the working model
    self.addObjects(geom_model.toIdfFile.objects)

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished adding geometry')
    
    return true
    
  end

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

        #OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', "Setting #{space.name} to #{building_type}.#{space_type_name}")
      end
    end

    return true
  end

  def add_loads(building_vintage, climate_zone, standards_data_dir)

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started applying space types (loads)')

    path_to_standards_json = "#{standards_data_dir}/openstudio_standards.json"

    # Load the openstudio_standards.json file
    self.load_openstudio_standards_json(path_to_standards_json)

    # Loop through all the space types currently in the model,
    # which are placeholders, and generate actual space types for them.
    self.getSpaceTypes.each do |stub_space_type|

      # Get the standard building type
      # from the stub
      stds_building_type = nil
      if stub_space_type.standardsBuildingType.is_initialized
        stds_building_type = stub_space_type.standardsBuildingType.get
      else
        OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', "Space type called '#{stub_space_type.name}' has no standards building type.")
        return false
      end
      
      # Get the standards space type
      # from the stub
      stds_spc_type = nil
      if stub_space_type.standardsSpaceType.is_initialized
        stds_spc_type = stub_space_type.standardsSpaceType.get
      else
        OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', "Space type called '#{stub_space_type.name}' has no standards space type.")
        return false
      end

      new_space_type = self.add_space_type(building_vintage, 'ClimateZone 1-8', stds_building_type, stds_spc_type)

      # Apply the new space type to the building      
      stub_space_type.spaces.each do |space|
        space.setSpaceType(new_space_type)
        #OpenStudio::logFree(OpenStudio::Info, "openstudio.prototype.Model", "Setting #{space.name} to #{new_space_type.name.get}")
      end
        
      # Remove the stub space type
      stub_space_type.remove

    end
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished applying space types (loads)')
    
    return true

  end

  def add_constructions(building_type, building_vintage, climate_zone, standards_data_dir)

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started applying constructions')

    # Assign construction to adiabatic construction
    # Assign a material to all internal mass objects
    cp02_carpet_pad = OpenStudio::Model::MasslessOpaqueMaterial.new(self)
    cp02_carpet_pad.setName('CP02 CARPET PAD')
    cp02_carpet_pad.setRoughness("VeryRough")
    cp02_carpet_pad.setThermalResistance(0.21648)
    cp02_carpet_pad.setThermalAbsorptance(0.9)
    cp02_carpet_pad.setSolarAbsorptance(0.7)
    cp02_carpet_pad.setVisibleAbsorptance(0.8)

    normalweight_concrete_floor = OpenStudio::Model::StandardOpaqueMaterial.new(self)
    normalweight_concrete_floor.setName('100mm Normalweight concrete floor')
    normalweight_concrete_floor.setRoughness('MediumSmooth')
    normalweight_concrete_floor.setThickness(0.1016)
    normalweight_concrete_floor.setConductivity(2.31)
    normalweight_concrete_floor.setDensity(2322)
    normalweight_concrete_floor.setSpecificHeat(832)

    nonres_floor_insulation = OpenStudio::Model::MasslessOpaqueMaterial.new(self)
    nonres_floor_insulation.setName('Nonres_Floor_Insulation')
    nonres_floor_insulation.setRoughness("MediumSmooth")
    nonres_floor_insulation.setThermalResistance(4.13066404430099)
    nonres_floor_insulation.setThermalAbsorptance(0.9)
    nonres_floor_insulation.setSolarAbsorptance(0.7)
    nonres_floor_insulation.setVisibleAbsorptance(0.7)

    adiabatic_construction = OpenStudio::Model::Construction.new(self)
    adiabatic_construction.setName('nonres_floor_ceiling')
    layers = OpenStudio::Model::MaterialVector.new
    layers << cp02_carpet_pad
    layers << normalweight_concrete_floor
    layers << nonres_floor_insulation

    adiabatic_construction.setLayers(layers)
    self.getSurfaces.each do |surface|
      if surface.outsideBoundaryCondition.to_s == "Adiabatic"
        surface.setConstruction(adiabatic_construction)
      elsif  surface.outsideBoundaryCondition.to_s == "OtherSideCoefficients"
        surface.setOutsideBoundaryCondition("Adiabatic")
        surface.setConstruction(adiabatic_construction)
      end
    end

    path_to_standards_json = "#{standards_data_dir}/openstudio_standards.json"

    # Load the openstudio_standards.json file
    self.load_openstudio_standards_json(path_to_standards_json)

    # Make the default contruction set for the building
    bldg_def_const_set = self.add_construction_set(building_vintage, climate_zone, building_type, nil)
    if bldg_def_const_set.is_initialized
      self.getBuilding.setDefaultConstructionSet(bldg_def_const_set.get)
    else
      OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', 'Could not create default construction set for the building.')
      return false
    end
    
    # Make a construction set for each space type, if one is specified
    self.getSpaceTypes.each do |space_type|
    
      # Get the standards building type
      stds_building_type = nil
      if space_type.standardsBuildingType.is_initialized
        stds_building_type = space_type.standardsBuildingType.get
      else
        OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', "Space type called '#{space_type.name}' has no standards building type.")
      end
      
      # Get the standards space type
      stds_spc_type = nil
      if space_type.standardsSpaceType.is_initialized
        stds_spc_type = space_type.standardsSpaceType.get
      else
        OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', "Space type called '#{space_type.name}' has no standards space type.")
      end    
    
      # If the standards space type is Attic,
      # the building type should be blank.
      if stds_spc_type == 'Attic'
        stds_building_type = ''
      end

      # Attempt to make a construction set for this space type
      # and assign it if it can be created.
      spc_type_const_set = self.add_construction_set(building_vintage, climate_zone, stds_building_type, stds_spc_type)
      if spc_type_const_set.is_initialized
        space_type.setDefaultConstructionSet(spc_type_const_set.get)
      end
    
    end
    
    # Make skylights have the same construction as fixed windows
    # sub_surface = self.getBuilding.defaultConstructionSet.get.defaultExteriorSubSurfaceConstructions.get
    # window_construction = sub_surface.fixedWindowConstruction.get
    # sub_surface.setSkylightConstruction(window_construction)

    # Assign a material to all internal mass objects
    material = OpenStudio::Model::StandardOpaqueMaterial.new(self)
    material.setName('Std Wood 6inch')
    material.setRoughness('MediumSmooth')
    material.setThickness(0.15)
    material.setConductivity(0.12)
    material.setDensity(540)
    material.setSpecificHeat(1210)
    material.setThermalAbsorptance(0.9)
    material.setSolarAbsorptance(0.7)
    material.setVisibleAbsorptance(0.7)
    construction = OpenStudio::Model::Construction.new(self)
    construction.setName('InteriorFurnishings')
    layers = OpenStudio::Model::MaterialVector.new
    layers << material
    construction.setLayers(layers)
    
    # get all the space types that are conditioned
    conditioned_space_names = find_conditioned_space_names(building_type, building_vintage, climate_zone)
    
    # add internal mass
    unless building_type == 'SmallHotel' && 
      (building_vintage == '90.1-2004' or building_vintage == '90.1-2007' or building_vintage == '90.1-2010' or building_vintage == '90.1-2013')
      conditioned_space_names.each do |conditioned_space_name|
        internal_mass_def = OpenStudio::Model::InternalMassDefinition.new(self)
        internal_mass_def.setSurfaceAreaperSpaceFloorArea(2.0)
        internal_mass_def.setConstruction(construction)
        puts "internal_mass_def = #{internal_mass_def}"
    
        internal_mass = OpenStudio::Model::InternalMass.new(internal_mass_def)
        space = self.getSpaceByName(conditioned_space_name)
        space = space.get
        puts "space = #{space}"
        internal_mass.setSpace(space)
      end
    end
    
    # self.getInternalMassDefinitions.each do |int_mass_def|
      # int_mass_def.setConstruction(construction)
    # end

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished applying constructions')
    
    return true

  end  
  
  # get all the space types that are conditioned
  def find_conditioned_space_names(building_type, building_vintage, climate_zone)
    system_to_space_map = define_hvac_system_map(building_type, building_vintage, climate_zone)
    conditioned_space_names = OpenStudio::StringVector.new
    system_to_space_map.each do |system|
      system['space_names'].each do |space_name|
        conditioned_space_names << space_name
      end
    end
    return conditioned_space_names
  end
  
  def create_thermal_zones(building_type,building_vintage, climate_zone)

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started creating thermal zones')

    # This map define the multipliers for spaces with multipliers not equals to 1
    case building_type
      when 'LargeHotel'
        space_multiplier_map = define_space_multiplier
      else
        space_multiplier_map ={}
    end


    # Create a thermal zone for each space in the self
    self.getSpaces.each do |space|
      zone = OpenStudio::Model::ThermalZone.new(self)
      zone.setName("#{space.name} ZN")
      if space_multiplier_map[space.name.to_s] != nil
        zone.setMultiplier(space_multiplier_map[space.name.to_s])
      end
      space.setThermalZone(zone)
      
      # Skip thermostat for spaces with no space type
      next if space.spaceType.empty?
      
      # Add a thermostat
      space_type_name = space.spaceType.get.name.get
      thermostat_name = space_type_name + ' Thermostat'
      thermostat = self.getThermostatSetpointDualSetpointByName(thermostat_name)
      if thermostat.empty?
        OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', "Thermostat #{thermostat_name} not found for space name: #{space.name}")
        return true
      end
      zone.setThermostatSetpointDualSetpoint(thermostat.get)
    end

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished creating thermal zones')
    
    return true

  end

  def add_occupancy_sensors(building_type, building_vintage, climate_zone)
   
    # Only add occupancy sensors for 90.1-2010
     return true unless building_vintage == '90.1-2010'
   
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started Adding Occupancy Sensors')

    space_type_reduction_map = {
      'SecondarySchool' => {'Classroom' => 0.32}
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
          OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', "Occupancy sensor reduction added to '#{light.name}'")
        end
      end
    
    end
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished Adding Occupancy Sensors')
    
    return true
    
  end #add occupancy sensors

  def add_exterior_lights(building_type, building_vintage, climate_zone, prototype_input)
    # TODO Standards - translate w/linear foot of facade, door, parking, etc
    # into lookup table and implement that way instead of hard-coding as
    # inputs in the spreadsheet.
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started adding exterior lights')

    if building_type == "LargeHotel"
      data = self.find_object(@standards['exterior'], {'template'=>building_vintage, 'climate_zone_set'=>'ClimateZone 1-8', 'building_type'=>building_type})

      ext_lts_power = data['exterior_lights']
      ext_lts_sch_name = data['exterior_lights_schedule']
      ext_lts_name = 'Exterior Lights'
      ext_lts_def = OpenStudio::Model::ExteriorLightsDefinition.new(self)
      ext_lts_def.setName("#{ext_lts_name} Def")
      ext_lts_def.setDesignLevel(ext_lts_power)
      ext_lts_sch = self.add_schedule(ext_lts_sch_name)

      ext_lts = OpenStudio::Model::ExteriorLights.new(ext_lts_def, ext_lts_sch)
      ext_lts.setName("#{ext_lts_name}")
      ext_lts.setControlOption('AstronomicalClock')

      # TODO: The exterior fuel equipment is not available yet. Use exterior lights instead.
      ext_fuel_equip_power = data['fuel_equipment']
      ext_fuel_equip_sch_name = data['fuel_equipment_schedule']
      ext_fuel_equip_name = 'Exterior Fuel Equipment'
      ext_fuel_equip_def = OpenStudio::Model::ExteriorLightsDefinition.new(self)
      ext_fuel_equip_def.setName("#{ext_fuel_equip_name} Def")
      ext_fuel_equip_def.setDesignLevel(ext_fuel_equip_power)
      ext_fuel_equip_sch = self.add_schedule(ext_fuel_equip_sch_name)

      ext_fuel_equip = OpenStudio::Model::ExteriorLights.new(ext_fuel_equip_def, ext_fuel_equip_sch)
      ext_fuel_equip.setName("#{ext_fuel_equip_name}")
      ext_fuel_equip.setControlOption('ScheduleNameOnly')

    else
      # Occupancy Sensing Exterior Lights
      # which reduce to 70% power when no one is around.
      unless prototype_input['occ_sensing_exterior_lighting_power'].nil?
        occ_sens_ext_lts_power = prototype_input['occ_sensing_exterior_lighting_power']
        occ_sens_ext_lts_name = 'Occ Sensing Exterior Lights'
        occ_sens_ext_lts_def = OpenStudio::Model::ExteriorLightsDefinition.new(self)
        occ_sens_ext_lts_def.setName("#{occ_sens_ext_lts_name} Def")
        occ_sens_ext_lts_def.setDesignLevel(occ_sens_ext_lts_power)
        occ_sens_ext_lts_sch = OpenStudio::Model::ScheduleRuleset.new(self)
        occ_sens_ext_lts_sch.setName("#{occ_sens_ext_lts_name} Sch")
        occ_sens_ext_lts_sch.defaultDaySchedule.setName("#{occ_sens_ext_lts_name} Default Sch")
        if building_type == "SmallHotel"
          occ_sens_ext_lts_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),1)
        else
          occ_sens_ext_lts_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,6,0,0),0)
          occ_sens_ext_lts_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),1)
        end
        occ_sens_ext_lts = OpenStudio::Model::ExteriorLights.new(occ_sens_ext_lts_def, occ_sens_ext_lts_sch)
        occ_sens_ext_lts.setName("#{occ_sens_ext_lts_name} Def")
        occ_sens_ext_lts.setControlOption('AstronomicalClock')
      end

      # Building Facade and Landscape Lights
      # that don't dim at all at night.
      unless prototype_input['nondimming_exterior_lighting_power'].nil?
        nondimming_ext_lts_power = prototype_input['nondimming_exterior_lighting_power']
        nondimming_ext_lts_name = 'NonDimming Exterior Lights'
        nondimming_ext_lts_def = OpenStudio::Model::ExteriorLightsDefinition.new(self)
        nondimming_ext_lts_def.setName("#{nondimming_ext_lts_name} Def")
        nondimming_ext_lts_def.setDesignLevel(nondimming_ext_lts_power)
        #
        nondimming_ext_lts_sch = nil
        if building_vintage == '90.1-2010'
          nondimming_ext_lts_sch = OpenStudio::Model::ScheduleRuleset.new(self)
          nondimming_ext_lts_sch.setName("#{nondimming_ext_lts_name} Sch")
          nondimming_ext_lts_sch.defaultDaySchedule.setName("#{nondimming_ext_lts_name} Default Sch")
          if building_type == "SmallHotel"
            nondimming_ext_lts_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),1)
          else
            nondimming_ext_lts_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,6,0,0),0)
            nondimming_ext_lts_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),1)
          end
        elsif building_vintage == 'DOE Ref Pre-1980' || building_vintage == 'DOE Ref 1980-2004'
          nondimming_ext_lts_sch = self.alwaysOnDiscreteSchedule
        end
        nondimming_ext_lts = OpenStudio::Model::ExteriorLights.new(nondimming_ext_lts_def, nondimming_ext_lts_sch)
        nondimming_ext_lts.setName("#{nondimming_ext_lts_name} Def")
        nondimming_ext_lts.setControlOption('AstronomicalClock')
      end
   end
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished adding exterior lights')
    
    return true
  end #add exterior lights  
  
  def modify_infiltration_coefficients(building_type, building_vintage, climate_zone)
  
    # Only modify the infiltration coefficients for 90.1-2010
    return true unless building_vintage == '90.1-2010'
  
    # The pre-1980 and 1980-2004 buildings have this:
    # 1.0000,                  !- Constant Term Coefficient
    # 0.0000,                  !- Temperature Term Coefficient
    # 0.0000,                  !- Velocity Term Coefficient
    # 0.0000;                  !- Velocity Squared Term Coefficient
    # The 90.1-2010 buildings have this:
    # 0.0000,                  !- Constant Term Coefficient
    # 0.0000,                  !- Temperature Term Coefficient
    # 0.224,                   !- Velocity Term Coefficient
    # 0.0000;                  !- Velocity Squared Term Coefficient
    self.getSpaceInfiltrationDesignFlowRates.each do |infiltration|
      infiltration.setConstantTermCoefficient(0.0)
      infiltration.setTemperatureTermCoefficient (0.0)
      infiltration.setVelocityTermCoefficient(0.224)
      infiltration.setVelocitySquaredTermCoefficient(0.0)
    end
    
  end

  def set_sizing_parameters(building_type, building_vintage)
    
    # Default unless otherwise specified
    clg = 1.2
    htg = 1.2
    case building_vintage
    when 'DOE Ref Pre-1980', 'DOE Ref 1980-2004'
      case building_type
      when 'PrimarySchool', 'SecondarySchool'
        clg = 1.5
        htg = 1.5
      when 'LargeHotel'
        clg = 1.33
        htg = 1.33
      end
    when '90.1-2004', '90.1-2007', '90.1-2010', '90.1-2013'
      case building_type
      when 'Hospital', 'LargeHotel', 'MediumOffice', 'LargeOffice', 'OutPatientHealthCare', 'PrimarySchool'
        clg = 1.0
        htg = 1.0
      end
    end 
  
    sizing_params = self.getSizingParameters
    sizing_params.setHeatingSizingFactor(htg)
    sizing_params.setCoolingSizingFactor(clg) 
  
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.prototype.Model', "Set sizing factors to #{htg} for heating and #{clg} for cooling.")
  
  end
  
  def applyPrototypeHVACAssumptions(building_type, building_vintage, climate_zone)
    
    # Load the helper libraries for getting the autosized
    # values for each type of model object.
    require_relative 'Prototype.FanConstantVolume'
    require_relative 'Prototype.FanVariableVolume'
    require_relative 'Prototype.FanOnOff'
    require_relative 'Prototype.HeatExchangerAirToAirSensibleAndLatent'
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started applying prototype HVAC assumptions.')
    
    ##### Apply equipment efficiencies
    
    # Fans
    self.getFanConstantVolumes.sort.each {|obj| obj.setPrototypeFanPressureRise}
    self.getFanVariableVolumes.sort.each {|obj| obj.setPrototypeFanPressureRise(building_type, building_vintage, climate_zone)}
    self.getFanOnOffs.sort.each {|obj| obj.setPrototypeFanPressureRise}

    # Heat Exchangers
    self.getHeatExchangerAirToAirSensibleAndLatents.sort.each {|obj| obj.setPrototypeNominalElectricPower}
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished applying prototype HVAC assumptions.')
    
    ##### Add Economizers
    # Create an economizer maximum OA fraction of 70%
    # to reflect damper leakage per PNNL
    econ_max_70_pct_oa_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    econ_max_70_pct_oa_sch.setName("Economizer Max OA Fraction 70 pct")
    econ_max_70_pct_oa_sch.defaultDaySchedule.setName("Economizer Max OA Fraction 70 pct Default")
    econ_max_70_pct_oa_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0.7)   
    
    # Check each airloop
    self.getAirLoopHVACs.each do |air_loop|
      if air_loop.isEconomizerRequired(self.template, self.climate_zone) == true
        # If an economizer is required, determine the economizer type
        # in the prototype buildings, which depends on climate zone.
        economizer_type = nil
        case building_vintage
        when 'DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007'
          economizer_type = 'FixedDryBulb'
        when '90.1-2010', '90.1-2013'
          case climate_zone
          when 'ASHRAE 169-2006-1A',
            'ASHRAE 169-2006-2A',
            'ASHRAE 169-2006-3A',
            'ASHRAE 169-2006-4A'
            economizer_type = 'DifferentialDryBulb'
          else
            economizer_type = 'FixedDryBulb'
          end
        end
        # Set the economizer type
        # Get the OA system and OA controller
        oa_sys = air_loop.airLoopHVACOutdoorAirSystem
        if oa_sys.is_initialized
          oa_sys = oa_sys.get
        else
          OpenStudio::logFree(OpenStudio::Error, "openstudio.prototype.Model", "#{air_loop.name} is required to have an economizer, but it has no OA system.")
          next
        end
        oa_control = oa_sys.getControllerOutdoorAir
        oa_control.setEconomizerControlType(economizer_type)
        oa_control.setMaximumFractionofOutdoorAirSchedule(econ_max_70_pct_oa_sch)
      end
    
    
    end

    #### Add ERVs
    # Check each airloop and add an ERV if required
    self.getAirLoopHVACs.each do |air_loop|
      if air_loop.isEnergyRecoveryVentilatorRequired(self.template, self.climate_zone) == true
    
        # Get the AHU design supply air flow rate
        dsn_flow_m3_per_s = nil
        if air_loop.designSupplyAirFlowRate.is_initialized
          dsn_flow_m3_per_s = air_loop.designSupplyAirFlowRate.get
        elsif air_loop.autosizedDesignSupplyAirFlowRate.is_initialized
          dsn_flow_m3_per_s = air_loop.autosizedDesignSupplyAirFlowRate.get
        else
          OpenStudio::logFree(OpenStudio::Warn, "openstudio.prototype.AirLoopHVAC", "For #{air_loop.name} design supply air flow rate is not available, cannot apply ERV.")
          return false
        end
        dsn_flow_cfm = OpenStudio.convert(dsn_flow_m3_per_s, 'm^3/s', 'cfm').get    
    
        # Get the oa system
        oa_system = nil
        if air_loop.airLoopHVACOutdoorAirSystem.is_initialized
          oa_system = air_loop.airLoopHVACOutdoorAirSystem.get
        else
          runner.registerError("ERV not applicable to '#{air_loop.name}' because it has no OA intake.")
          next
        end

        # Calculate the motor power for the rotatry wheel per:
        # Power (W) = (Nominal Supply Air Flow Rate (CFM) * 0.3386) + 49.5
        power = (dsn_flow_cfm * 0.3386) + 49.5
      
        # Create an ERV
        erv = OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent.new(self)
        erv.setName("#{air_loop.name} ERV")
        erv.setSensibleEffectivenessat100HeatingAirFlow(0.7)
        erv.setLatentEffectivenessat100HeatingAirFlow(0.6)
        erv.setSensibleEffectivenessat75HeatingAirFlow(0.7)
        erv.setLatentEffectivenessat75HeatingAirFlow(0.6)
        erv.setSensibleEffectivenessat100CoolingAirFlow(0.75)
        erv.setLatentEffectivenessat100CoolingAirFlow(0.6)
        erv.setSensibleEffectivenessat75CoolingAirFlow(0.75)
        erv.setLatentEffectivenessat75CoolingAirFlow(0.6)
        erv.setNominalElectricPower(power)
        erv.setSupplyAirOutletTemperatureControl(true) 
        erv.setHeatExchangerType('Rotary')
        erv.setEconomizerLockout(true)
        
        # Add the ERV to the OA system
        erv.addToNode(oa_system.outboardOANode.get)    
    
      end
    
    end
       
  end 

  def add_debugging_variables(type)
  
    # 'detailed'
    # 'timestep'
    # 'hourly'
    # 'daily'
    # 'monthly'
  
    vars = []
    case type
    when 'service_water_heating'
      var_names << ['Water Heater Water Volume Flow Rate','timestep']
      var_names << ['Water Use Equipment Hot Water Volume Flow Rate','timestep']
      var_names << ['Water Use Equipment Cold Water Volume Flow Rate','timestep']
      var_names << ['Water Use Equipment Hot Water Temperature','timestep']
      var_names << ['Water Use Equipment Cold Water Temperature','timestep']
      var_names << ['Water Use Equipment Mains Water Volume','timestep']
      var_names << ['Water Use Equipment Target Water Temperature','timestep']
      var_names << ['Water Use Equipment Mixed Water Temperature','timestep']
      var_names << ['Water Heater Tank Temperature','timestep']
      var_names << ['Water Heater Use Side Mass Flow Rate','timestep']
      var_names << ['Water Heater Heating Rate','timestep']
      var_names << ['Water Heater Water Volume Flow Rate','timestep']
      var_names << ['Water Heater Water Volume','timestep']
    end
  
    var_names.each do |var_name, reporting_frequency|
      outputVariable = OpenStudio::Model::OutputVariable.new(var_name,self)
      outputVariable.setReportingFrequency(reporting_frequency)
    end
  
  
  end

  def run(run_dir = "#{Dir.pwd}/Run")
    
    # If the run directory is not specified
    # run in the current working directory
    
    # Make the directory if it doesn't exist
    if !Dir.exists?(run_dir)
      Dir.mkdir(run_dir)
    end
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', "Started simulation in '#{run_dir}'")
    
    # Change the simulation to only run the weather file
    # and not run the sizing day simulations
    sim_control = self.getSimulationControl
    sim_control.setRunSimulationforSizingPeriods(false)
    sim_control.setRunSimulationforWeatherFileRunPeriods(true)
    
    # Save the model to energyplus idf
    idf_name = 'in.idf'
    osm_name = 'in.osm'
    forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
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
          # If this is an always-run Measure, need to check a different path
          alt_weath_path = File.expand_path(File.join(File.dirname(__FILE__), "../../../resources"))
          alt_epw_path = File.expand_path(File.join(alt_weath_path, epw_path.get.to_s))
          if File.exist?(alt_epw_path)
            epw_path = OpenStudio::Path.new(alt_epw_path)
          else
            OpenStudio::logFree(OpenStudio::Error, "openstudio.prototype.Model", "Model has been assigned a weather file, but the file is not in the specified location of '#{epw_path.get}'.")
            return false
          end
        end
      else
        OpenStudio::logFree(OpenStudio::Error, "openstudio.prototype.Model", "Model has a weather file assigned, but the weather file path has been deleted.")
        return false
      end
    else
      OpenStudio::logFree(OpenStudio::Error, "openstudio.prototype.Model", "Model has not been assigned a weather file.")
      return false
    end
    
    # If running on a regular desktop, use RunManager.
    # If running on OpenStudio Server, use WorkFlowMananger
    # to avoid slowdown from the sizing run.   
    use_runmanager = true
    
    begin
      require 'openstudio-workflow'
      use_runmanager = false
    rescue LoadError
      use_runmanager = true
    end

    sql_path = nil
    if use_runmanager == true
      OpenStudio::logFree(OpenStudio::Info, "openstudio.prototype.Model", "Running sizing run with RunManager.")

      # Find EnergyPlus
      require 'openstudio/energyplus/find_energyplus'
      ep_hash = OpenStudio::EnergyPlus::find_energyplus(8,2)
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
        
      sql_path = OpenStudio::Path.new("#{run_dir}/Energyplus/eplusout.sql")
      
      OpenStudio::logFree(OpenStudio::Info, "openstudio.prototype.Model", "Finished sizing run in #{(Time.new - start_time).round}sec.")
      
    else # Use the openstudio-workflow gem
      OpenStudio::logFree(OpenStudio::Info, "openstudio.prototype.Model", "Running sizing run with openstudio-workflow gem.")
      
      # Copy the weather file to this directory
      FileUtils.copy(epw_path.to_s, run_dir)

      # Run the simulation
      sim = OpenStudio::Workflow.run_energyplus('Local', run_dir)
      final_state = sim.run

      if final_state == :finished
        OpenStudio::logFree(OpenStudio::Info, "openstudio.prototype.Model", "Finished sizing run in #{(Time.new - start_time).round}sec.")
      end
    
      sql_path = OpenStudio::Path.new("#{run_dir}/run/eplusout.sql")
    
    end
    
    # Load the sql file created by the sizing run
    sql_path = OpenStudio::Path.new("#{run_dir}/Energyplus/eplusout.sql")
    if OpenStudio::exists(sql_path)
      sql = OpenStudio::SqlFile.new(sql_path)
      # Check to make sure the sql file is readable,
      # which won't be true if EnergyPlus crashed during simulation.
      if !sql.connectionOpen
        OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "The run failed.  Look at the eplusout.err file in #{File.dirname(sql_path.to_s)} to see the cause.")
        return false
      end
      # Attach the sql file from the run to the sizing model
      self.setSqlFile(sql)
    else 
      OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "Results for the sizing run couldn't be found here: #{sql_path}.")
      return false
    end

    # Check that the run finished without severe errors
    error_query = "SELECT ErrorMessage 
        FROM Errors 
        WHERE ErrorType='1'"

    errs = self.sqlFile.get.execAndReturnVectorOfString(error_query)
    if errs.is_initialized
      errs = errs.get
      if errs.size > 0
        errs = errs.get
        OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "The run failed with the following severe errors: #{errs.join('\n')}.")
        return false
      end
    end
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', "Finished simulation in '#{run_dir}'")
    
    return true

  end

  def request_timeseries_outputs
   
    # "detailed"
    # "timestep"
    # "hourly"
    # "daily"
    # "monthly"
   
    vars = []
    vars << ['Heating Coil Gas Rate', 'detailed']
    vars << ['Zone Thermostat Air Temperature', 'detailed']
    vars << ['Zone Thermostat Heating Setpoint Temperature', 'detailed']
    vars << ['Zone Thermostat Cooling Setpoint Temperature', 'detailed']
    vars << ['Zone Air System Sensible Heating Rate', 'detailed']
    vars << ['Zone Air System Sensible Cooling Rate', 'detailed']
    vars << ['Fan Electric Power', 'detailed']
    vars << ['Zone Mechanical Ventilation Standard Density Volume Flow Rate', 'detailed']
    vars << ['Air System Outdoor Air Mass Flow Rate', 'detailed']
    vars << ['Air System Outdoor Air Flow Fraction', 'detailed']
    vars << ['Air System Outdoor Air Minimum Flow Fraction', 'detailed']
    
    vars << ['Water Use Equipment Hot Water Volume Flow Rate', 'hourly']
    vars << ['Water Use Equipment Cold Water Volume Flow Rate', 'hourly']
    vars << ['Water Use Equipment Total Volume Flow Rate', 'hourly']
    vars << ['Water Use Equipment Hot Water Temperature', 'hourly']
    vars << ['Water Use Equipment Cold Water Temperature', 'hourly']
    vars << ['Water Use Equipment Target Water Temperature', 'hourly']
    vars << ['Water Use Equipment Mixed Water Temperature', 'hourly']
    
    vars << ['Water Use Connections Hot Water Volume Flow Rate', 'hourly']
    vars << ['Water Use Connections Cold Water Volume Flow Rate', 'hourly']
    vars << ['Water Use Connections Total Volume Flow Rate', 'hourly']
    vars << ['Water Use Connections Hot Water Temperature', 'hourly']
    vars << ['Water Use Connections Cold Water Temperature', 'hourly']
    vars << ['Water Use Connections Plant Hot Water Energy', 'hourly']
    vars << ['Water Use Connections Return Water Temperature', 'hourly']
  
    vars.each do |var, freq|  
      outputVariable = OpenStudio::Model::OutputVariable.new(var, self)
      outputVariable.setReportingFrequency(freq)
    end
    
  end  

  def add_curve(curve_name, hvac_standards)
    
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.prototype.addCurve", "Adding curve '#{curve_name}' to the model.")
    
    success = false
    
    curve_biquadratics = hvac_standards["curve_biquadratics"]
    curve_quadratics = hvac_standards["curve_quadratics"]
    curve_bicubics = hvac_standards["curve_bicubics"]
    curve_cubics = hvac_standards["curve_cubics"]
    
    # Make biquadratic curves
    curve_data = find_object(curve_biquadratics, {"name"=>curve_name})
    if curve_data
      curve = OpenStudio::Model::CurveBiquadratic.new(self)
      curve.setName(curve_data["name"])
      curve.setCoefficient1Constant(curve_data["coeff_1"])
      curve.setCoefficient2x(curve_data["coeff_2"])
      curve.setCoefficient3xPOW2(curve_data["coeff_3"])
      curve.setCoefficient4y(curve_data["coeff_4"])
      curve.setCoefficient5yPOW2(curve_data["coeff_5"])
      curve.setCoefficient6xTIMESY(curve_data["coeff_6"])
      curve.setMinimumValueofx(curve_data["min_x"])
      curve.setMaximumValueofx(curve_data["max_x"])
      curve.setMinimumValueofy(curve_data["min_y"])
      curve.setMaximumValueofy(curve_data["max_y"])
      success = true
      return curve
    end
    
    # Make quadratic curves
    curve_data = find_object(curve_quadratics, {"name"=>curve_name})
    if curve_data
      curve = OpenStudio::Model::CurveQuadratic.new(self)
      curve.setName(curve_data["name"])
      curve.setCoefficient1Constant(curve_data["coeff_1"])
      curve.setCoefficient2x(curve_data["coeff_2"])
      curve.setCoefficient3xPOW2(curve_data["coeff_3"])
      curve.setMinimumValueofx(curve_data["min_x"])
      curve.setMaximumValueofx(curve_data["max_x"])
      success = true
      return curve
    end
    
    # Make cubic curves
    curve_data = find_object(curve_cubics, {"name"=>curve_name})
    if curve_data
      curve = OpenStudio::Model::CurveCubic.new(self)
      curve.setName(curve_data["name"])
      curve.setCoefficient1Constant(curve_data["coeff_1"])
      curve.setCoefficient2x(curve_data["coeff_2"])
      curve.setCoefficient3xPOW2(curve_data["coeff_3"])
      curve.setCoefficient4xPOW3(curve_data["coeff_4"])
      curve.setMinimumValueofx(curve_data["min_x"])
      curve.setMaximumValueofx(curve_data["max_x"])
      success = true
      return curve
    end
  
    # Make bicubic curves
    curve_data = find_object(curve_bicubics, {"name"=>curve_name})
    if curve_data
      curve = OpenStudio::Model::CurveBicubic.new(self)
      curve.setName(eirft_properties["name"])
      curve.setCoefficient1Constant(curve_data["coeff_1"])
      curve.setCoefficient2x(curve_data["coeff_2"])
      curve.setCoefficient3xPOW2(curve_data["coeff_3"])
      curve.setCoefficient4y(curve_data["coeff_4"])
      curve.setCoefficient5yPOW2(curve_data["coeff_5"])
      curve.setCoefficient6xTIMESY(curve_data["coeff_6"])
      curve.setCoefficient7xPOW3 (curve_data["coeff_7"])
      curve.setCoefficient8yPOW3 (curve_data["coeff_8"])
      curve.setCoefficient9xPOW2TIMESY(curve_data["coeff_9"])
      curve.setCoefficient10xTIMESYPOW2 (curve_data["coeff_10"])
      curve.setMinimumValueofx(eirft_properties["min_x"])
      curve.setMaximumValueofx(eirft_properties["max_x"])
      curve.setMinimumValueofy(eirft_properties["min_y"])
      curve.setMaximumValueofy(eirft_properties["max_y"])
      success = true
      return curve
    end
  
    # Return false if the curve was not created
    if success == false
      #OpenStudio::logFree(OpenStudio::Warn, "openstudio.prototype.addCurve", "Could not find a curve called '#{curve_name}' in the hvac_standards.")
      return nil
    end
    
  end
  
end
