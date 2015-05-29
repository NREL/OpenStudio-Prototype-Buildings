
# Extend the class to add Large Hotel specific stuff
class OpenStudio::Model::Model

  def define_space_type_map(building_type, building_vintage, climate_zone)
    space_type_map = {
        'Banquet' => ['Banquet_Flr_6','Dining_Flr_6'],
        'Cafe' => ['Cafe_Flr_1'],
        'Corridor'=> ['Corridor_Flr_3','Corridor_Flr_6'],
        'GuestRoom'=> ['Room_1_Flr_3','Room_2_Flr_3','Room_3_Mult19_Flr_3','Room_4_Mult19_Flr_3','Room_5_Flr_3','Room_6_Flr_3','Room_1_Flr_6','Room_2_Flr_6','Room_3_Mult9_Flr_6'],
        'Kitchen'=> ['Kitchen_Flr_6'],
        'Laundry'=> ['Laundry_Flr_1'],
        'Lobby'=> ['Lobby_Flr_1'],
        'Mechanical'=> ['Mech_Flr_1'],
        'Retail'=> ['Retail_1_Flr_1','Retail_2_Flr_1'],
        'Storage'=> ['Basement','Storage_Flr_1']
    }

    return space_type_map
  end

  def define_hvac_system_map
    system_to_space_map = [
        {
            'type' => 'VAV',
            'space_names' =>
                [
                    'Banquet_Flr_6',
                    'Dining_Flr_6',
                    'Cafe_Flr_1',
                    'Corridor_Flr_3',
                    'Corridor_Flr_6',
                    'Kitchen_Flr_6',
                    'Laundry_Flr_1',
                    'Lobby_Flr_1',
                    'Mech_Flr_1',
                    'Retail_1_Flr_1',
                    'Retail_2_Flr_1',
                    'Basement',
                    'Storage_Flr_1',
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
    simulation_control =  self.getSimulationControl
    simulation_control.setLoadsConvergenceToleranceValue(0.4)
    simulation_control.setTemperatureConvergenceToleranceValue(0.5)

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started Adding HVAC')
    system_to_space_map = define_hvac_system_map

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

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished adding HVAC')
    return true
  end #add hvac
  
  def add_swh(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
   
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started Adding SWH")

    main_swh_loop = self.add_swh_loop(prototype_input, hvac_standards, 'main')
    self.add_swh_end_uses(prototype_input, hvac_standards, main_swh_loop, 'main')
    
    laundry_swh_loop = self.add_swh_loop(prototype_input, hvac_standards, 'laundry')
    self.add_swh_end_uses(prototype_input, hvac_standards, laundry_swh_loop, 'laundry')
    
    swh_booster_loop = self.add_swh_booster(prototype_input, hvac_standards, main_swh_loop)
    self.add_booster_swh_end_uses(prototype_input, hvac_standards, swh_booster_loop)
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished adding SWH")
    
    return true
    
  end #add swh    
  
end
