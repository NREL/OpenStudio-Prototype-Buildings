
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
        'Retail'=> ['Retail_1_Flr_1','Retail_2_Flr_1'],
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
    chilled_water_loop = self.add_chw_loop(prototype_input, hvac_standards)
    hot_water_loop = self.add_hw_loop(prototype_input, hvac_standards)

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
            self.add_vav(prototype_input, hvac_standards, hot_water_loop, chilled_water_loop, thermal_zones)
          else
            OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', 'No hot water and chilled water plant loops in model')
            return false
          end
        when 'DOAS'
          self.add_doas(prototype_input, hvac_standards, hot_water_loop, chilled_water_loop, thermal_zones)
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
      space_type_data.each_pair do |key, value|
        puts "#{key}, #{value}"
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

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished adding HVAC')
    return true
  end #add hvac
  
  def add_swh(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
   
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started Adding SWH")

    swh_loop = self.add_swh_loop(prototype_input, hvac_standards, 'main')
    self.add_swh_end_uses(prototype_input, hvac_standards, swh_loop, 'main')
    self.add_swh_end_uses(prototype_input, hvac_standards, swh_loop, 'laundry')
    
    #swh_booster_loop = self.add_swh_booster(prototype_input, hvac_standards, main_swh_loop)
    #self.add_booster_swh_end_uses(prototype_input, hvac_standards, swh_booster_loop)
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished adding SWH")
    
    return true
    
  end #add swh    
  
  def add_refrigeration(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
       
    return false
    
  end #add refrigeration

end
