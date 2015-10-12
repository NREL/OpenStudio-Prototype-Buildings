
# Extend the class to add Medium Office specific stuff
class OpenStudio::Model::Model
 
  def define_space_type_map(building_type, building_vintage, climate_zone)
    space_type_map = {
      'WholeBuilding' => [
        'LGstore1', 'SMstore1', 'SMstore2', 'SMstore3', 'SMstore4', 'LGstore2', 'SMstore5', 'SMstore6', 'SMstore7', 'SMstore8'
      ]
    }
    return space_type_map
  end

  def define_hvac_system_map(building_type, building_vintage, climate_zone)
    system_to_space_map = [
      {
          'type' => 'CAV',
          'name' => 'PSZ-AC_1',
          'space_names' => ['LGSTORE1']
      },
      {
          'type' => 'CAV',
          'name' => 'PSZ-AC_2',
          'space_names' => ['SMstore1']
      },
      {
        'type' => 'CAV',
        'name' => 'PSZ-AC_3',
        'space_names' => ['SMstore2']
      },
      {
        'type' => 'CAV',
        'name' => 'PSZ-AC_4',
        'space_names' => ['SMstore3']
      },
      {
        'type' => 'CAV',
        'name' => 'PSZ-AC_5',
        'space_names' => ['SMstore4']
      },{
        'type' => 'CAV',
        'name' => 'PSZ-AC_6',
        'space_names' => ['LGSTORE2']
      },
      {
        'type' => 'CAV',
        'name' => 'PSZ-AC_7',
        'space_names' => ['SMstore5']
      },
      {
        'type' => 'CAV',
        'name' => 'PSZ-AC_8',
        'space_names' => ['SMstore6']
      },
      {
        'type' => 'CAV',
        'name' => 'PSZ-AC_9',
        'space_names' => ['SMstore7']
      },
      {
        'type' => 'CAV',
        'name' => 'PSZ-AC_10',
        'space_names' => ['SMstore8']
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
        else
          OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "HVAC system type (#{system['type']}) was not defined for strip mall.")
          return false
      end
    end
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished adding HVAC')
    return true
  end #add hvac

  def add_swh(building_type, building_vintage, climate_zone, prototype_input, hvac_standards, space_type_map)
   
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started Adding SWH")

    # main_swh_loop = self.add_swh_loop(prototype_input, hvac_standards, 'main')
    # water_heaters = main_swh_loop.supplyComponents(OpenStudio::Model::WaterHeaterMixed::iddObjectType)
    
    # water_heaters.each do |water_heater|
    #   water_heater = water_heater.to_WaterHeaterMixed.get
    #   # water_heater.setAmbientTemperatureIndicator('Zone')
    #   # water_heater.setAmbientTemperatureThermalZone(default_water_heater_ambient_temp_sch)
    #   water_heater.setOffCycleParasiticFuelConsumptionRate(173)
    #   water_heater.setOnCycleParasiticFuelConsumptionRate(173)
    #   water_heater.setOffCycleLossCoefficienttoAmbientTemperature(1.205980747)
    #   water_heater.setOnCycleLossCoefficienttoAmbientTemperature(1.205980747)
    # end

    # self.add_swh_end_uses(prototype_input, hvac_standards, main_swh_loop, 'main')
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished adding SWH")
    
    return true
    
  end #add swh    
  
  def add_refrigeration(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
       
    return false
    
  end #add refrigeration
  
end
