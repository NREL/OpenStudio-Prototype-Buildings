
# Extend the class to add Medium Office specific stuff
class OpenStudio::Model::Model
 
  def define_space_type_map(building_type, building_vintage, climate_zone)
    space_type_map = {
      'WholeBuilding - Md Office' => [
        'Perimeter_bot_ZN_1', 'Perimeter_bot_ZN_2', 'Perimeter_bot_ZN_3', 'Perimeter_bot_ZN_4', 'Core_bottom',
        'Perimeter_mid_ZN_1', 'Perimeter_mid_ZN_2', 'Perimeter_mid_ZN_3', 'Perimeter_mid_ZN_4', 'Core_mid',
        'Perimeter_top_ZN_1', 'Perimeter_top_ZN_2', 'Perimeter_top_ZN_3', 'Perimeter_top_ZN_4', 'Core_top'
      ]
    }
    return space_type_map
  end

  def define_hvac_system_map(building_type, building_vintage, climate_zone)
    system_to_space_map = [
      {
          'type' => 'PVAV',
          'space_names' =>
          [
              'Perimeter_bot_ZN_1',
              'Perimeter_bot_ZN_2',
              'Perimeter_bot_ZN_3',
              'Perimeter_bot_ZN_4',
              'Core_bottom'
          ]
      },
      {
          'type' => 'PVAV',
          'space_names' =>
          [
              'Perimeter_mid_ZN_1',
              'Perimeter_mid_ZN_2',
              'Perimeter_mid_ZN_3',
              'Perimeter_mid_ZN_4',
              'Core_mid'
          ]
      },
      {
          'type' => 'PVAV',
          'space_names' =>
          [
              'Perimeter_top_ZN_1',
              'Perimeter_top_ZN_2',
              'Perimeter_top_ZN_3',
              'Perimeter_top_ZN_4',
              'Core_top'
          ]
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
		if space_name == "Core_bottom"
			self.add_elevator(prototype_input, hvac_standards, space)
		end
        thermal_zones << zone.get
      end

      case system['type']
      when 'PVAV'
        self.add_pvav(prototype_input, hvac_standards, system['name'], thermal_zones)
      end

    end
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished adding HVAC')
    
    return true
    
  end #add hvac

  def add_swh(building_type, building_vintage, climate_zone, prototype_input, hvac_standards, space_type_map)
   
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started Adding SWH")

    main_swh_loop = self.add_swh_loop(prototype_input, hvac_standards, 'main')
    water_heaters = main_swh_loop.supplyComponents(OpenStudio::Model::WaterHeaterMixed::iddObjectType)
    
    water_heaters.each do |water_heater|
      water_heater = water_heater.to_WaterHeaterMixed.get
      # water_heater.setAmbientTemperatureIndicator('Zone')
      # water_heater.setAmbientTemperatureThermalZone(default_water_heater_ambient_temp_sch)
      water_heater.setOffCycleParasiticFuelConsumptionRate(1277)
      water_heater.setOnCycleParasiticFuelConsumptionRate(1277)
      water_heater.setOffCycleLossCoefficienttoAmbientTemperature(7.561562668)
      water_heater.setOnCycleLossCoefficienttoAmbientTemperature(7.561562668)
    end

    # spaces = define_space_type_map(building_type, building_vintage, climate_zone)['WholeBuilding - Md Office']

    # spaces.each do |space|
    #   self.add_swh_end_uses(prototype_input, hvac_standards, main_swh_loop, 'main')
    # end

    for i in 0..13
      self.add_swh_end_uses(prototype_input, hvac_standards, main_swh_loop, 'main')
    end
    # self.add_swh_end_uses(prototype_input, hvac_standards, main_swh_loop, 'main')
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished adding SWH")
    
    return true
    
  end #add swh

end
