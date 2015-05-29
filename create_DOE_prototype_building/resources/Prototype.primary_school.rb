
# Extend the class to add Secondary School specific stuff
class OpenStudio::Model::Model
 
  def define_space_type_map(building_type, building_vintage, climate_zone)

    space_type_map = {
      'Office' => ['Offices_ZN_1_FLR_1'],
      'Lobby' => ['Lobby_ZN_1_FLR_1'],
      'Gym' => ['Gym_ZN_1_FLR_1'],
      'Mechanical' => ['Mech_ZN_1_FLR_1'],
      'Cafeteria' => ['Cafeteria_ZN_1_FLR_1'],
      'Kitchen' => ['Kitchen_ZN_1_FLR_1'],
      'Restroom' => ['Bath_ZN_1_FLR_1', 'Bathrooms_ZN_1_FLR_1'],
      'Corridor' => [
        'Corridor_Pod_1_ZN_1_FLR_1',
        'Corridor_Pod_2_ZN_1_FLR_1',
        'Corridor_Pod_3_ZN_1_FLR_1',
        'Main_Corridor_ZN_1_FLR_1'
      ],
      'Classroom' => [
        'Computer_Class_ZN_1_FLR_1',
        'Corner_Class_1_Pod_1_ZN_1_FLR_1',
        'Corner_Class_1_Pod_2_ZN_1_FLR_1',
        'Corner_Class_1_Pod_3_ZN_1_FLR_1',
        'Corner_Class_2_Pod_1_ZN_1_FLR_1',
        'Corner_Class_2_Pod_2_ZN_1_FLR_1',
        'Corner_Class_2_Pod_3_ZN_1_FLR_1',
        'Library_Media_Center_ZN_1_FLR_1',
        'Mult_Class_1_Pod_1_ZN_1_FLR_1',
        'Mult_Class_1_Pod_2_ZN_1_FLR_1',
        'Mult_Class_1_Pod_3_ZN_1_FLR_1',
        'Mult_Class_2_Pod_1_ZN_1_FLR_1',
        'Mult_Class_2_Pod_2_ZN_1_FLR_1',
        'Mult_Class_2_Pod_3_ZN_1_FLR_1'
      ]
    }

    return space_type_map

  end

  def define_hvac_system_map(building_type, building_vintage, climate_zone)

    system_to_space_map = nil
    
    case building_vintage
    when 'DOE Ref Pre-1980', 'DOE Ref 1980-2004'
      system_to_space_map = [
      {
          'type' => 'PVAV',
          'space_names' =>
          [
              'Corner_Class_1_Pod_1_ZN_1_FLR_1',
              'Mult_Class_1_Pod_1_ZN_1_FLR_1',
              'Corridor_Pod_1_ZN_1_FLR_1',
              'Corner_Class_2_Pod_1_ZN_1_FLR_1',
              'Mult_Class_2_Pod_1_ZN_1_FLR_1',
              'Corner_Class_1_Pod_2_ZN_1_FLR_1'
          ]
      },
      {
          'type' => 'PVAV',
          'space_names' =>
          [
              'Mult_Class_1_Pod_2_ZN_1_FLR_1',
              'Corridor_Pod_2_ZN_1_FLR_1',
              'Corner_Class_2_Pod_2_ZN_1_FLR_1',
              'Mult_Class_2_Pod_2_ZN_1_FLR_1'
          ]
      },
      {
          'type' => 'PVAV',
          'space_names' =>
          [
              'Corner_Class_1_Pod_3_ZN_1_FLR_1',
              'Mult_Class_1_Pod_3_ZN_1_FLR_1',
              'Corridor_Pod_3_ZN_1_FLR_1',
              'Corner_Class_2_Pod_3_ZN_1_FLR_1',
              'Mult_Class_2_Pod_3_ZN_1_FLR_1'
          ]
      },
      {
          'type' => 'PVAV',
          'space_names' =>
          [
              'Computer_Class_ZN_1_FLR_1',
              'Main_Corridor_ZN_1_FLR_1',
              'Lobby_ZN_1_FLR_1',
              'Mech_ZN_1_FLR_1',
              'Bath_ZN_1_FLR_1',
              'Offices_ZN_1_FLR_1',
              'Library_Media_Center_ZN_1_FLR_1'
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
              'Gym_ZN_1_FLR_1'
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
      
    when '90.1-2004', '90.1-2007', '90.1-2010', '90.1-2013'
      system_to_space_map = [
      {
          'type' => 'PVAV',
          'space_names' =>
          [
              'Corner_Class_1_Pod_1_ZN_1_FLR_1',
              'Mult_Class_1_Pod_1_ZN_1_FLR_1',
              'Corridor_Pod_1_ZN_1_FLR_1',
              'Corner_Class_2_Pod_1_ZN_1_FLR_1',
              'Mult_Class_2_Pod_1_ZN_1_FLR_1'
          ]
      },
      {
          'type' => 'PVAV',
          'space_names' =>
          [
              'Mult_Class_1_Pod_2_ZN_1_FLR_1',
              'Corridor_Pod_2_ZN_1_FLR_1',
              'Corner_Class_2_Pod_2_ZN_1_FLR_1',
              'Mult_Class_2_Pod_2_ZN_1_FLR_1',
              'Corner_Class_1_Pod_2_ZN_1_FLR_1'
          ]
      },
      {
          'type' => 'PVAV',
          'space_names' =>
          [
              'Corner_Class_1_Pod_3_ZN_1_FLR_1',
              'Mult_Class_1_Pod_3_ZN_1_FLR_1',
              'Corridor_Pod_3_ZN_1_FLR_1',
              'Corner_Class_2_Pod_3_ZN_1_FLR_1',
              'Mult_Class_2_Pod_3_ZN_1_FLR_1'
          ]
      },
      {
          'type' => 'PVAV',
          'space_names' =>
          [
              'Computer_Class_ZN_1_FLR_1',
              'Main_Corridor_ZN_1_FLR_1',
              'Lobby_ZN_1_FLR_1',
              'Mech_ZN_1_FLR_1',
              'Bath_ZN_1_FLR_1',
              'Offices_ZN_1_FLR_1',
              'Library_Media_Center_ZN_1_FLR_1'
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
              'Gym_ZN_1_FLR_1'
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

    end

    return system_to_space_map

  end
    
  def add_hvac(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
   
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started Adding HVAC')
    
    system_to_space_map = define_hvac_system_map(building_type, building_vintage, climate_zone)

    hot_water_loop = self.add_hw_loop(prototype_input, hvac_standards)
     
    #VAVR system; hot water reheat, water-cooled chiller
    
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
          OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "No thermal zone created for space called #{space_name} was found in the model")
          return false
        end
        thermal_zones << zone.get
      end

      case system['type']
      when 'PVAV'
        if hot_water_loop
          self.add_pvav(prototype_input, hvac_standards, hot_water_loop, thermal_zones)
        else
          OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', 'No hot water plant loop in model')
          return false
        end
      when 'PSZ-AC'
        self.add_psz_ac(prototype_input, hvac_standards, thermal_zones)
      end

    end

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished adding HVAC')
    
    return true
    
  end #add hvac

  def add_swh(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
   
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started Adding SWH")

    main_swh_loop = self.add_swh_loop(prototype_input, hvac_standards, 'main')
    self.add_swh_end_uses(prototype_input, hvac_standards, main_swh_loop, 'main')
    
    case building_vintage
    when 'DOE Ref Pre-1980', 'DOE Ref 1980-2004' 
      # No dishwasher booster water heaters
    when '90.1-2004', '90.1-2007', '90.1-2010', '90.1-2013'
      swh_booster_loop = self.add_swh_booster(prototype_input, hvac_standards, main_swh_loop)
      self.add_booster_swh_end_uses(prototype_input, hvac_standards, swh_booster_loop)
    end
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished adding SWH")
    
    return true
    
  end #add swh  
  
end
