
# Extend the class to add Large Hotel specific stuff
class OpenStudio::Model::Model

  def define_space_type_map(building_type, building_vintage, climate_zone)
    space_type_map = {
        'Banquet' => ['Banquet_Flr_6','Dining_Flr_6'],
        'Basement'=>['Basement'],
        'Cafe' => ['Cafe_Flr_1'],
        'Corridor'=> ['Corridor_Flr_6'],
        'Corridor2'=> ['Corridor_Flr_3'],
        'GuestRoom'=> ['Room_1_Flr_3','Room_2_Flr_3','Room_5_Flr_3','Room_6_Flr_3'],
        'GuestRoom3'=> ['Room_1_Flr_6','Room_2_Flr_6'],
        'GuestRoom2'=> ['Room_3_Mult19_Flr_3','Room_4_Mult19_Flr_3'],
        'GuestRoom4'=> ['Room_3_Mult9_Flr_6'],
        'Kitchen'=> ['Kitchen_Flr_6'],
        'Laundry'=> ['Laundry_Flr_1'],
        'Lobby'=> ['Lobby_Flr_1'],
        'Mechanical'=> ['Mech_Flr_1'],
        'Retail'=> ['Retail_1_Flr_1'],
        'Retail2'=> ['Retail_2_Flr_1'],
        'Storage'=> ['Storage_Flr_1']
    }

    return space_type_map
  end

  def define_hvac_system_map(building_type, building_vintage, climate_zone)
    system_to_space_map = [
        {
            'type' => 'VAV',
            'space_names' =>
                [
                    'Basement',
                    'Retail_1_Flr_1',
                    'Retail_2_Flr_1',
                    'Mech_Flr_1',
                    'Storage_Flr_1',
                    'Laundry_Flr_1',
                    'Cafe_Flr_1',
                    'Lobby_Flr_1',
                    'Corridor_Flr_3',
                    'Banquet_Flr_6',
                    'Dining_Flr_6',
                    'Corridor_Flr_6',
                    'Kitchen_Flr_6'
                ]
        },
        {
            'type' => 'DOAS',
            'space_names' =>
                [
                    'Room_1_Flr_3','Room_2_Flr_3','Room_3_Mult19_Flr_3','Room_4_Mult19_Flr_3','Room_5_Flr_3','Room_6_Flr_3','Room_1_Flr_6','Room_2_Flr_6','Room_3_Mult9_Flr_6'
                ]
        }
    ]
    return system_to_space_map
  end

  def define_space_multiplier
    # This map define the multipliers for spaces with multipliers not equals to 1
    space_multiplier_map = {
        'Room_1_Flr_3' => 4,
        'Room_2_Flr_3' => 4,
        'Room_3_Mult19_Flr_3' => 76,
        'Room_4_Mult19_Flr_3' => 76,
        'Room_5_Flr_3' => 4,
        'Room_6_Flr_3' => 4,
        'Corridor_Flr_3' => 4,
        'Room_3_Mult9_Flr_6' => 9
    }
    return space_multiplier_map
  end

  def add_hvac(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
    #simulation_control =  self.getSimulationControl
    #simulation_control.setLoadsConvergenceToleranceValue(0.4)
    #simulation_control.setTemperatureConvergenceToleranceValue(0.5)

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started Adding HVAC')
    system_to_space_map = define_hvac_system_map(building_type, building_vintage, climate_zone)

    #VAV system; hot water reheat, water-cooled chiller
    chilled_water_loop = self.add_chw_loop(prototype_input, hvac_standards, nil, building_type)
    hot_water_loop = self.add_hw_loop(prototype_input, hvac_standards, building_type)

    system_to_space_map.each do |system|
      #find all zones associated with these spaces
      thermal_zones = []
      system['space_names'].each do |space_name|
        space = self.getSpaceByName(space_name)
        if space.empty?
          OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "No space called #{space_name} was found in the model")
          return false
        end
        space = space.get
        zone = space.thermalZone
        if zone.empty?
          OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "No thermal zone was created for the space called #{space_name}")
          return false
        end
        thermal_zones << zone.get
      end

      case system['type']
        when 'VAV'
          if hot_water_loop && chilled_water_loop
            self.add_vav(prototype_input, hvac_standards, hot_water_loop, chilled_water_loop, thermal_zones, building_type)
          else
            OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', 'No hot water and chilled water plant loops in model')
            return false
          end
        when 'DOAS'
          self.add_doas(prototype_input, hvac_standards, hot_water_loop, chilled_water_loop, thermal_zones, building_type)
        else
          OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "Undefined HVAC system type called #{system['type']}")
          return false
      end
    end

    # Add Exhaust Fan
    space_type_map = define_space_type_map(building_type, building_vintage, climate_zone)
    ['Banquet', 'Kitchen','Laundry'].each do |space_type|
      space_type_data = self.find_object(self.standards['space_types'], {'template'=>building_vintage, 'building_type'=>building_type, 'space_type'=>space_type})
      if space_type_data == nil
        OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "Unable to find space type #{building_vintage}-#{building_type}-#{space_type}")
        return false
      end

      exhaust_schedule = add_schedule(space_type_data['exhaust_schedule'])
      if exhaust_schedule.class.to_s == "NilClass"
        OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "Unable to find Exhaust Schedule for space type #{building_vintage}-#{building_type}-#{space_type}")
        return false
      end
      balanced_exhaust_schedule = add_schedule(space_type_data['balanced_exhaust_fraction_schedule'])

      space_names = space_type_map[space_type]
      space_names.each do |space_name|
        space = self.getSpaceByName(space_name).get
        thermal_zone = space.thermalZone.get

        zone_exhaust_fan = OpenStudio::Model::FanZoneExhaust.new(self)
        zone_exhaust_fan.setName(space.name.to_s + " Exhaust Fan")
        zone_exhaust_fan.setAvailabilitySchedule(exhaust_schedule)
        zone_exhaust_fan.setFanEfficiency(space_type_data['exhaust_fan_efficiency'])
        zone_exhaust_fan.setPressureRise (space_type_data['exhaust_fan_pressure_rise'])
        maximum_flow_rate = OpenStudio.convert(space_type_data['exhaust_fan_maximum_flow_rate'], 'cfm', 'm^3/s').get

        zone_exhaust_fan.setMaximumFlowRate(maximum_flow_rate)
        if balanced_exhaust_schedule.class.to_s != "NilClass"
          zone_exhaust_fan.setBalancedExhaustFractionSchedule (balanced_exhaust_schedule)
        end
        zone_exhaust_fan.setEndUseSubcategory("Zone Exhaust Fans")
        zone_exhaust_fan.addToThermalZone(thermal_zone)
      end
    end

    # Update Sizing Zone
    zone_sizing = self.getSpaceByName('Kitchen_Flr_6').get.thermalZone.get.sizingZone
    zone_sizing.setCoolingMinimumAirFlowFraction(0.7)

    zone_sizing = self.getSpaceByName('Laundry_Flr_1').get.thermalZone.get.sizingZone
    zone_sizing.setCoolingMinimumAirFlow(0.23567919336)

    # Add the daylighting controls for lobby, cafe, dinning and banquet
    #self.add_daylighting_controls(building_vintage)

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished adding HVAC')
    return true
  end #add hvac

  def add_daylighting_controls(building_vintage)
      space_names = ['Banquet_Flr_6','Dining_Flr_6','Cafe_Flr_1','Lobby_Flr_1']
      space_names.each do |space_name|
        space = self.getSpaceByName(space_name).get
        space.addDaylightingControls(building_vintage, false, false)
      end
  end

  def add_swh(building_type, building_vintage, climate_zone, prototype_input, hvac_standards, space_type_map)

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started Adding SWH")

    # Add the main service hot water loop
    swh_space_name = "Basement"
    swh_thermal_zone = self.getSpaceByName(swh_space_name).get.thermalZone.get
    swh_loop = self.add_swh_loop(prototype_input, hvac_standards, 'main',swh_thermal_zone)

    # Add the water use equipment
    guess_room_space_types =['GuestRoom','GuestRoom2','GuestRoom3','GuestRoom4']
    kitchen_space_types = ['Kitchen']
    guess_room_water_use_rate = 0.020833333 # gal/min, Reference: NREL Reference building report 5.1.6
    kitchen_space_use_rate = 2.22 # gal/min, from PNNL prototype building
    guess_room_water_use_schedule = "HotelLarge GuestRoom_SWH_Sch"
    kitchen_water_use_schedule = "HotelLarge BLDG_SWH_SCH"

    water_end_uses = []
    space_type_map = define_space_type_map(building_type, building_vintage, climate_zone)
    space_multipliers = define_space_multiplier

    guess_room_space_types.each do |space_type|
      space_names = space_type_map[space_type]
      space_names.each do |space_name|
        space_multiplier = 1
        space_multiplier= space_multipliers[space_name].to_i if space_multipliers[space_name] != nil
        water_end_uses.push([space_name, guess_room_water_use_rate * space_multiplier,guess_room_water_use_schedule])
      end
    end

    kitchen_space_types.each do |space_type|
        space_names = space_type_map[space_type]
        space_names.each do |space_name|
          space_multiplier = 1
          space_multiplier= space_multipliers[space_name].to_i if space_multipliers[space_name] != nil
          water_end_uses.push([space_name, kitchen_space_use_rate * space_multiplier,kitchen_water_use_schedule])
        end
    end

    self.add_large_hotel_swh_end_uses(prototype_input, hvac_standards, swh_loop, 'main', water_end_uses)

    # Add the laundry water heater
    laundry_water_heater_space_name = "Basement"
    laundry_water_heater_thermal_zone = self.getSpaceByName(laundry_water_heater_space_name).get.thermalZone.get
    laundry_water_heater_loop = self.add_swh_loop(prototype_input, hvac_standards, 'laundry', laundry_water_heater_thermal_zone)
    self.add_swh_end_uses(prototype_input, hvac_standards, laundry_water_heater_loop,'laundry')

    booster_water_heater_space_name = "KITCHEN_FLR_6"
    booster_water_heater_thermal_zone = self.getSpaceByName(booster_water_heater_space_name).get.thermalZone.get
    swh_booster_loop = self.add_swh_booster(prototype_input, hvac_standards, swh_loop, booster_water_heater_thermal_zone)
    self.add_booster_swh_end_uses(prototype_input, hvac_standards, swh_booster_loop)

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished adding SWH")
    return true
  end #add swh

  def add_large_hotel_swh_end_uses(prototype_input, standards, swh_loop, type, water_end_uses)
    puts "Adding water uses type = '#{type}'"
    water_end_uses.each do |water_end_use|
      space_name = water_end_use[0]
      use_rate = water_end_use[1] # in gal/min

      # Water use connection
      swh_connection = OpenStudio::Model::WaterUseConnections.new(self)
      swh_connection.setName(space_name + "Water Use Connections")
      # Water fixture definition
      water_fixture_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(self)
      rated_flow_rate_m3_per_s = OpenStudio.convert(use_rate,'gal/min','m^3/s').get
      water_fixture_def.setPeakFlowRate(rated_flow_rate_m3_per_s)
      water_fixture_def.setName("#{space_name} Service Water Use Def #{use_rate.round(2)}gal/min")

      sensible_fraction = 0.2
      latent_fraction = 0.05

      # Target mixed water temperature
      mixed_water_temp_f = prototype_input["#{type}_water_use_temperature"]
      mixed_water_temp_sch = OpenStudio::Model::ScheduleRuleset.new(self)
      mixed_water_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),OpenStudio.convert(mixed_water_temp_f,'F','C').get)
      water_fixture_def.setTargetTemperatureSchedule(mixed_water_temp_sch)

      sensible_fraction_sch = OpenStudio::Model::ScheduleRuleset.new(self)
      sensible_fraction_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),sensible_fraction)
      water_fixture_def.setSensibleFractionSchedule(sensible_fraction_sch)

      latent_fraction_sch = OpenStudio::Model::ScheduleRuleset.new(self)
      latent_fraction_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),latent_fraction)
      water_fixture_def.setSensibleFractionSchedule(latent_fraction_sch)

      # Water use equipment
      water_fixture = OpenStudio::Model::WaterUseEquipment.new(water_fixture_def)
      schedule = self.add_schedule(water_end_use[2])
      water_fixture.setFlowRateFractionSchedule(schedule)
      water_fixture.setName("#{space_name} Service Water Use #{use_rate.round(2)}gal/min")
      swh_connection.addWaterUseEquipment(water_fixture)

      # Connect the water use connection to the SWH loop
      swh_loop.addDemandBranchForComponent(swh_connection)
    end
  end

  def add_refrigeration(building_type, building_vintage, climate_zone, prototype_input, standards)
    # TODO: Check different vintage to see what parameters are required.
    # refrigeration_standards = standards['refrigeration']
    # climate_zone_sets = self.find_all_climate_zone_sets(climate_zone)
    # refrigeration_objs = []
    # climate_zone_sets.each do |climate_zone_set|
    #   # Find the initial Chiller properties based on initial inputs
    #   search_criteria = {
    #       'template' => building_vintage,
    #       'climate_zone_set' => climate_zone_set,
    #       'building_type' => building_type
    #   }
    #   refrigeration_objs = self.find_objects(refrigeration_standards, search_criteria)
    #   break if refrigeration_objs.size > 0
    # end
    #
    # refrigeration_objs.each do |obj|
    #   self.add_refrigeration_case(obj)
    # end

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started Adding Refrigeration System")

    #Schedule Ruleset
    defrost_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    defrost_sch.setName("Refrigeration Defrost Schedule")
    #All other days
    defrost_sch.defaultDaySchedule.setName("Refrigeration Defrost Schedule Default")
    defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,11,0,0), 0)
    defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,11,20,0), 1)
    defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,23,0,0), 0)
    defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,23,20,0), 1)
    defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0)

    #Schedule Ruleset
    defrost_dripdown_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    defrost_dripdown_sch.setName("Refrigeration Defrost DripDown Schedule")
    #All other days
    defrost_dripdown_sch.defaultDaySchedule.setName("Refrigeration Defrost DripDown Schedule Default")
    defrost_dripdown_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,11,0,0), 0)
    defrost_dripdown_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,11,30,0), 1)
    defrost_dripdown_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,23,0,0), 0)
    defrost_dripdown_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,23,30,0), 1)
    defrost_dripdown_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0)

    #Schedule Ruleset
    case_credit_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    case_credit_sch.setName("Refrigeration Case Credit Schedule")
    #All other days
    case_credit_sch.defaultDaySchedule.setName("Refrigeration Case Credit Schedule Default")
    case_credit_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,7,0,0), 0.2)
    case_credit_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,21,0,0), 0.4)
    case_credit_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0.2)

    space = self.getSpaceByName('Kitchen_Flr_6')
    if space.empty?
      OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "No space called Kitchen was found in the model")
      return false
    end
    space = space.get
    thermal_zone = space.thermalZone
    if thermal_zone.empty?
      OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "No thermal zone was created for the space called #{space_name}")
      return false
    end
    thermal_zone = thermal_zone.get

    ref_sys1 = OpenStudio::Model::RefrigerationSystem.new(self)
    ref_sys1.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(self))
    condenser1 = OpenStudio::Model::RefrigerationCondenserAirCooled.new(self)
    condenser1.setRatedFanPower(350)

    ref_case1 = OpenStudio::Model::RefrigerationCase.new(self, defrost_sch)
    ref_case1.setAvailabilitySchedule(self.alwaysOnDiscreteSchedule)
    ref_case1.setThermalZone(thermal_zone)
    ref_case1.setRatedTotalCoolingCapacityperUnitLength(367.0)
    ref_case1.setCaseLength(7.32)
    ref_case1.setCaseOperatingTemperature(-23.0)
    ref_case1.setStandardCaseFanPowerperUnitLength(34)
    ref_case1.setOperatingCaseFanPowerperUnitLength(34)
    ref_case1.setStandardCaseLightingPowerperUnitLength(16.4)
    ref_case1.resetInstalledCaseLightingPowerperUnitLength

    ref_case1.setCaseLightingSchedule(self.add_schedule('HotelLarge BLDG_LIGHT_SCH'))
    ref_case1.setHumidityatZeroAntiSweatHeaterEnergy(0)
    ref_case1.setCaseDefrostPowerperUnitLength(273.0)
    ref_case1.setCaseDefrostType('Electric')
    ref_case1.resetDesignEvaporatorTemperatureorBrineInletTemperature

    ref_case1.setRatedAmbientTemperature(23.88)
    ref_case1.setRatedLatentHeatRatio(0.1)
    ref_case1.setRatedRuntimeFraction(0.4)
    ref_case1.setLatentCaseCreditCurve(self.add_curve('HotelLarge Kitchen_Flr_6_Case:1_WALKINFREEZERSingleShelfHorizontal_LatentEnergyMult',standards))
    ref_case1.setCaseLightingSchedule(self.add_schedule('HotelLarge BLDG_LIGHT_SCH'))
    ref_case1.setFractionofAntiSweatHeaterEnergytoCase(0)

    ref_case1.setCaseHeight(0)
    ref_case1.setCaseDefrostDripDownSchedule(defrost_dripdown_sch)
    ref_case1.setUnderCaseHVACReturnAirFraction(0)
    # TODO: setRefrigeratedCaseRestockingSchedule is not working
    ref_case1.setRefrigeratedCaseRestockingSchedule(self.add_schedule('HotelLarge Kitchen_Flr_6_Case:1_WALKINFREEZER_WalkInStockingSched'))
    ref_case1.setCaseCreditFractionSchedule(case_credit_sch)

    ref_sys1.addCase(ref_case1)
    ref_sys1.setRefrigerationCondenser(condenser1)
    ref_sys1.setSuctionPipingZone(thermal_zone)

    #Schedule Ruleset
    defrost_sch2 = OpenStudio::Model::ScheduleRuleset.new(self)
    defrost_sch2.setName('Refrigeration Defrost Schedule 2')
    #All other days
    defrost_sch2.defaultDaySchedule.setName('Refrigeration Defrost Schedule Default 2')
    defrost_sch2.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0)

    ref_sys2 = OpenStudio::Model::RefrigerationSystem.new(self)
    ref_sys2.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(self))
    condenser2 = OpenStudio::Model::RefrigerationCondenserAirCooled.new(self)
    condenser2.setRatedFanPower(350)

    ref_case2 = OpenStudio::Model::RefrigerationCase.new(self, defrost_sch2)
    ref_case2.setThermalZone(thermal_zone)
    ref_case2.setAvailabilitySchedule(self.alwaysOnDiscreteSchedule)
    ref_case2.setRatedTotalCoolingCapacityperUnitLength(734.0)
    ref_case2.setCaseLength(3.66)
    ref_case2.setCaseOperatingTemperature(2.0)
    ref_case2.setStandardCaseFanPowerperUnitLength(55)
    ref_case2.setOperatingCaseFanPowerperUnitLength(55)
    ref_case2.setStandardCaseLightingPowerperUnitLength(33)
    ref_case2.resetInstalledCaseLightingPowerperUnitLength

    ref_case2.setCaseLightingSchedule(self.add_schedule('HotelLarge BLDG_LIGHT_SCH'))
    ref_case2.setHumidityatZeroAntiSweatHeaterEnergy(0)
    ref_case2.setCaseDefrostType('None')
    ref_case2.resetDesignEvaporatorTemperatureorBrineInletTemperature

    ref_case2.setRatedAmbientTemperature(23.88)
    ref_case2.setRatedLatentHeatRatio(0.08)
    ref_case2.setRatedRuntimeFraction(0.85)
    ref_case2.setLatentCaseCreditCurve(self.add_curve('HotelLarge Kitchen_Flr_6_Case:2_SELFCONTAINEDDISPLAYCASEMultiShelfVertical_LatentEnergyMult',standards))
    ref_case2.setFractionofAntiSweatHeaterEnergytoCase(0.2)

    ref_case2.setCaseHeight(0)
    ref_case2.setCaseDefrostPowerperUnitLength(0)
    ref_case2.setUnderCaseHVACReturnAirFraction(0.05)
    ref_case2.setRefrigeratedCaseRestockingSchedule(self.add_schedule('HotelLarge Kitchen_Flr_6_Case:2_SELFCONTAINEDDISPLAYCASE_CaseStockingSched'))

    ref_sys2.addCase(ref_case2)
    ref_sys2.setRefrigerationCondenser(condenser2)
    ref_sys2.setSuctionPipingZone(thermal_zone)

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished adding Refrigeration System")

    return true
  end #add refrigeration
end
