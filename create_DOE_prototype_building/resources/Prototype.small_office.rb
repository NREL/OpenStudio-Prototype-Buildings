
# Extend the class to add Small Office specific stuff
class OpenStudio::Model::Model
 
  def define_space_type_map(building_type, building_vintage, climate_zone)

    space_type_map = {
      'WholeBuilding - Sm Office' => ['Perimeter_ZN_1', 'Perimeter_ZN_2', 'Perimeter_ZN_3', 'Perimeter_ZN_4', 'Core_ZN'],
      'Attic' => ['Attic']
    }

    return space_type_map

  end

  def define_hvac_system_map(building_type, building_vintage, climate_zone)

    system_to_space_map = [
      {
          'type' => 'PSZ-AC',
          'space_names' =>
          [
              'Perimeter_ZN_1'
          ]
      },
      {
          'type' => 'PSZ-AC',
          'space_names' =>
          [
              'Perimeter_ZN_2'
          ]
      },
      {
          'type' => 'PSZ-AC',
          'space_names' =>
          [
              'Perimeter_ZN_3'
          ]
      },
      {
          'type' => 'PSZ-AC',
          'space_names' =>
          [
              'Perimeter_ZN_4'
          ]
      },
      {
          'type' => 'PSZ-AC',
          'space_names' =>
          [
              'Core_ZN'
          ]
      }
  ]

    return system_to_space_map

  end
     
  def add_hvac(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
   
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started Adding HVAC')
    
    system_to_space_map = define_hvac_system_map(building_type, building_vintage, climate_zone)
    
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
      when 'PSZ-AC'
        self.add_psz_ac(prototype_input, hvac_standards, thermal_zones)
      end

    end
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished adding HVAC')
    
    return true
    
  end #add hvac

end
