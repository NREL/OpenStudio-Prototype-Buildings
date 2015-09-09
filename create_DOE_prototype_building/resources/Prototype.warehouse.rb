
# Extend the class to add Medium Office specific stuff
class OpenStudio::Model::Model
 
  def define_space_type_map(building_type, building_vintage, climate_zone)
    space_type_map = {
      'Bulk' => ['Zone3 Bulk Storage'],
      'Fine' => ['Zone2 Fine Storage'],
      'Office' => ['Zone1 Office']
    }
    return space_type_map
  end

  def define_hvac_system_map(building_type, building_vintage, climate_zone)
    system_to_space_map = [
      {
          'type' => 'CAV',
          'name' => 'PSZ-Office',
          'space_names' => ['Zone1 Office']
      },
      {
          'type' => 'CAV',
          'name' => 'PSZ-Fine Storage',
          'space_names' => ['Zone2 Fine Storage']
      },
      {
          'type' => 'Unit_Heater',
          'space_names' => ['Zone3 Bulk Storage']
      }
    ]
    return system_to_space_map
  end
     
  def add_hvac(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
   
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started Adding HVAC')
    
    system_to_space_map = define_hvac_system_map(building_type, building_vintage, climate_zone)

    # hot_water_loop = self.add_hw_loop(prototype_input, hvac_standards)
    
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
      when 'CAV'
        self.add_psz_ac(prototype_input, hvac_standards, system['name'], thermal_zones)
      when 'Unit_Heater'
        self.add_unitheater(prototype_input, hvac_standards, thermal_zones)
      end

    end
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished adding HVAC')
    
    return true
    
  end #add hvac

  def add_swh(building_type, building_vintage, climate_zone, prototype_input, hvac_standards, space_type_map)
   
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Warehouse has no SWH")

    return true
    
  end #add swh    

  def add_refrigeration(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
       
    return false
    
  end #add refrigeration
  
end
