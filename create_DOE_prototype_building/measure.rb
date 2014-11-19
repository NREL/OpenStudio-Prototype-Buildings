
# Start the measure
class CreateDOEPrototypeBuilding < OpenStudio::Ruleset::ModelUserScript
  
  # Define the name of the Measure.
  def name
    return "Create DOE Prototype Building"
  end

  # Human readable description
  def description
    return ""
  end

  # Human readable description of modeling approach
  def modeler_description
    return ""
  end
  
  # Define the arguments that the user will input.
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    # Make an argument for the building type
    building_type_chs = OpenStudio::StringVector.new
    building_type_chs << "SecondarySchool"
    building_type_chs << "SmallOffice"
    building_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('building_type', building_type_chs, true)
    building_type.setDisplayName("Select a Building Type.")
    building_type.setDefaultValue("SmallOffice")
    args << building_type

    # Make an argument for the building vintage
    building_vintage_chs = OpenStudio::StringVector.new
    building_vintage_chs << "DOE Ref Pre-1980"
    building_vintage_chs << "DOE Ref 1980-2004"
    #building_vintage_chs << "DOE Ref 2004"
    #building_vintage_chs << "90.1-2007"
    #building_vintage_chs << "189.1-2009"
    building_vintage_chs << "90.1-2010"
    building_vintage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('building_vintage', building_vintage_chs, true)
    building_vintage.setDisplayName("Select a Vintage.")
    building_vintage.setDefaultValue("90.1-2010")
    args << building_vintage    

    # Make an argument for the climate zone
    climate_zone_chs = OpenStudio::StringVector.new
    #climate_zone_chs << "ASHRAE 169-2006-1A"
    #climate_zone_chs << "ASHRAE 169-2006-1B"
    climate_zone_chs << "ASHRAE 169-2006-2A"
    #climate_zone_chs << "ASHRAE 169-2006-2B"
    #climate_zone_chs << "ASHRAE 169-2006-3A"
    climate_zone_chs << "ASHRAE 169-2006-3B"
    #climate_zone_chs << "ASHRAE 169-2006-3C"
    climate_zone_chs << "ASHRAE 169-2006-4A"
    #climate_zone_chs << "ASHRAE 169-2006-4B"
    #climate_zone_chs << "ASHRAE 169-2006-4C"
    climate_zone_chs << "ASHRAE 169-2006-5A"
    #climate_zone_chs << "ASHRAE 169-2006-5B"
    #climate_zone_chs << "ASHRAE 169-2006-5C"
    #climate_zone_chs << "ASHRAE 169-2006-6A"
    #climate_zone_chs << "ASHRAE 169-2006-6B"
    #climate_zone_chs << "ASHRAE 169-2006-7A"
    #climate_zone_chs << "ASHRAE 169-2006-7B"
    #climate_zone_chs << "ASHRAE 169-2006-8A"
    #climate_zone_chs << "ASHRAE 169-2006-8B"
    climate_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('climate_zone', climate_zone_chs, true)
    climate_zone.setDisplayName("Select a Climate Zone.")
    climate_zone.setDefaultValue("ASHRAE 169-2006-2A")
    args << climate_zone      
    
    return args
  end

  # Define what happens when the measure is run.
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    # Use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Assign the user inputs to variables that can be accessed across the measure
    building_type = runner.getStringArgumentValue("building_type",user_arguments)
    building_vintage = runner.getStringArgumentValue("building_vintage",user_arguments)
    climate_zone = runner.getStringArgumentValue("climate_zone",user_arguments)

    # Open a channel to log info/warning/error messages
    msg_log = OpenStudio::StringStreamLogSink.new
    msg_log.setLogLevel(OpenStudio::Info)
    
    # Load some libraries to use
    # HVAC sizing
    require_relative 'resources/prototype data/utilities'
    require_relative 'resources/prototype data/add_objects'
    require_relative 'resources/hvac sizing/Model'
    # Prototype Inputs
    require_relative 'resources/prototype data/prototype_hvac_systems'
    require_relative 'resources/prototype data/Model'
    # Weather data
    require_relative 'resources/weather data/add_design_days_and_weather_file'  
    # HVAC standards
    require_relative 'resources/standards data/HVAC Standards/Model'
    
    # Make the standards data available globally
    standards_data_dir = "#{File.dirname(__FILE__)}/resources/standards data"
    
    # Make the prototype input available globally
    hvac_standards_path = "#{File.dirname(__FILE__)}/resources/standards data/HVAC Standards/OpenStudio_HVAC_Standards.json"
    hvac_standards = {}
    temp = File.read(hvac_standards_path.to_s)
    hvac_standards = JSON.parse(temp)
    search_criteria = {
      "template" => building_vintage,
      "climate_zone" => climate_zone,
      "building_type" => building_type,
    }
    
    # Find the inputs for this prototype building, and fail if not found
    prototype_input = find_object(hvac_standards["prototype_inputs"], search_criteria)
    if prototype_input.nil?
      OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Could not find prototype inputs for #{search_criteria}.")
      return false
    end 
      
    # Map from the standard space type to the one used by the space
    # type generator and the contructions generators.
    # ["189.1-2009"]["ClimateZone 1-3"]["Hospital"]["Radiology"]["lighting_w_per_area"]
    space_type_generator_map = {
      "1A" => "ClimateZone 5b",
      "1B" => "TODO Riyadh",
      "2A" => "USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3",
      "2B" => "USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3",
      "3A" => "USA_TN_Memphis.Intl.AP.723340_TMY3",
      "3B" => "USA_TX_El.Paso.Intl.AP.722700_TMY3",
      "3C" => "USA_CA_San.Francisco.Intl.AP.724940_TMY3",
      "4A" => "USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3",
      "4B" => "USA_NM_Albuquerque.Intl.AP.723650_TMY3",
      "4C" => "USA_OR_Salem-McNary.Field.726940_TMY3",
      "5A" => "USA_IL_Chicago-OHare.Intl.AP.725300_TMY3",
      "5B" => "USA_ID_Boise.Air.Terminal.726810_TMY3",
      "5C" => "TODO Vancouver",
      "6A" => "USA_VT_Burlington.Intl.AP.726170_TMY3",
      "6B" => "USA_MT_Helena.Rgnl.AP.727720_TMY3",
      "7" => "USA_MN_Duluth.Intl.AP.727450_TMY3",
      "8" => "USA_AK_Fairbanks.Intl.AP.702610_TMY3"
    }
    
    # Make a directory to save the resulting models for debugging
    build_dir = "#{Dir.pwd}/build"
    if !Dir.exists?(build_dir)
      Dir.mkdir(build_dir)
    end    
    
    osm_directory = "#{build_dir}/#{building_type}-#{building_vintage}-#{climate_zone}"
    if !Dir.exists?(osm_directory)
      Dir.mkdir(osm_directory)
    end
    
    # Make the building
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Creating #{building_type}-#{building_vintage}-#{climate_zone}")
    case building_type
    when "SecondarySchool"
      require_relative 'resources/prototype data/secondary_school'
      model = add_geometry(model, "secondary_school_geometry.osm")
      space_type_map = model.define_space_type_map
      model.assign_space_type_stubs(building_type, space_type_map)
      model.add_loads(building_vintage, climate_zone, standards_data_dir) 
      model.add_constructions(building_type, building_vintage, climate_zone, standards_data_dir)
      model.create_thermal_zones
      model.add_hvac(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
      #swh_loop = model.add_swh_loop(prototype_input, hvac_standards)
      #model.add_swh_end_uses(prototype_input, hvac_standards, swh_loop)
      model.add_exterior_lights(building_type, building_vintage, climate_zone, prototype_input)
      model.add_occupancy_sensors(building_type, building_vintage, climate_zone)     
    when "SmallOffice"
      require_relative 'resources/prototype data/small_office'
      model = add_geometry(model, "small_office_geometry.osm")
      space_type_map = model.define_space_type_map
      model.assign_space_type_stubs("Office", space_type_map)
      model.add_loads(building_vintage, climate_zone, standards_data_dir) 
      model.add_constructions("Office", building_vintage, climate_zone, standards_data_dir)
      model.create_thermal_zones
      model.add_hvac(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
      swh_loop = model.add_swh_loop(prototype_input, hvac_standards)
      model.add_swh_end_uses(prototype_input, hvac_standards, swh_loop)
      model.add_exterior_lights(building_type, building_vintage, climate_zone, prototype_input)
      model.add_occupancy_sensors(building_type, building_vintage, climate_zone)
    else
      OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Model","Building Type = #{building_type} not recognized")
      return false
    end

    # Set the building location, weather files, ddy files, etc.
    added_ddy = add_design_days_and_weather_file(model, climate_zone)

    # Assign the standards to the model
    model.template = building_vintage
    model.hvac_standards = hvac_standards
    model_status = "1_initial_creation"
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
    
    # Perform a sizing run
    model.runSizingRun("#{osm_directory}/SizingRun1")
    model_status = "2_after_first_sz_run"
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
    
    # Retrieve only the fan flow rates and HX flow rates from the sizing run
    # and apply to the model.
    model.getFanConstantVolumes.sort.each {|obj| obj.applySizingValues}
    model.getFanVariableVolumes.sort.each {|obj| obj.applySizingValues}
    model.getHeatExchangerAirToAirSensibleAndLatents.sort.each {|obj| obj.applySizingValues}
    model_status = "3_after_apply_fan_flows"
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
    
    # Apply the prototype HVAC assumptions
    # which include sizing the fan pressure rises based
    # on the flow rate of the system.
    model.applyPrototypeHVACAssumptions
    model_status = "4_after_proto_hvac_assumptions"
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
    
    # Perform a second sizing run. The adjusted fan pressure rises
    # impact the sizes of the heating coils.
    model.runSizingRun("#{osm_directory}/SizingRun2")    
    
    # Get the equipment sizes from the sizing run
    # and hard-assign them back to the model
    model.applySizingValues
    model_status = "5_after_apply_sizes"
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
    
    # Apply the HVAC efficiency standard
    model.applyHVACEfficiencyStandard
    model_status = "6_after_apply_hvac_std"
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
    
    # Add output variables for debugging
    model.request_timeseries_outputs
    
    # Finished
    model_status = "final"
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)

    # Get all the log messages and put into output
    # for users to see.
    msg_log.logMessages.each do |msg|
      # DLM: you can filter on log channel here for now 
      if /openstudio\.model\..*/.match(msg.logChannel)
        # Skip the annoying/bogus "Skipping layer" warnings
        next if msg.logMessage.include?("Skipping layer")
        if msg.logLevel == OpenStudio::Info
          runner.registerInfo(msg.logMessage)  
        elsif msg.logLevel == OpenStudio::Warn
          runner.registerWarning(msg.logMessage)
        elsif msg.logLevel == OpenStudio::Error
          runner.registerError(msg.logMessage)
        end
      end
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
CreateDOEPrototypeBuilding.new.registerWithApplication
