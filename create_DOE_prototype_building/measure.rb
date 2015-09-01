
# Start the measure
class CreateDOEPrototypeBuilding < OpenStudio::Ruleset::ModelUserScript
  
  require 'json'
  
  # Define the name of the Measure.
  def name
    return 'Create DOE Prototype Building'
  end

  # Human readable description
  def description
    return ''
  end

  # Human readable description of modeling approach
  def modeler_description
    return ''
  end

  # Define the arguments that the user will input.
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Make an argument for the building type
    building_type_chs = OpenStudio::StringVector.new
    building_type_chs << 'SecondarySchool'
    building_type_chs << 'PrimarySchool'
    building_type_chs << 'SmallOffice'
    building_type_chs << 'MediumOffice'
    building_type_chs << 'LargeOffice'
    building_type_chs << 'SmallHotel'
    building_type_chs << 'LargeHotel'
    building_type_chs << 'Warehouse'
    building_type_chs << 'RetailStandalone'
    building_type_chs << 'RetailStripmall'
    building_type_chs << 'QuickServiceRestaurant'
    building_type_chs << 'FullServiceRestaurant'
    building_type_chs << 'Hospital'
    building_type_chs << 'Outpatient'
    building_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('building_type', building_type_chs, true)
    building_type.setDisplayName('Select a Building Type.')
    building_type.setDefaultValue('SmallOffice')
    args << building_type

    # Make an argument for the building vintage
    building_vintage_chs = OpenStudio::StringVector.new
    building_vintage_chs << 'DOE Ref Pre-1980'
    building_vintage_chs << 'DOE Ref 1980-2004'
    building_vintage_chs << '90.1-2004'
    building_vintage_chs << '90.1-2007'
    #building_vintage_chs << '189.1-2009'
    building_vintage_chs << '90.1-2010'
    building_vintage_chs << '90.1-2013'
    building_vintage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('building_vintage', building_vintage_chs, true)
    building_vintage.setDisplayName('Select a Vintage.')
    building_vintage.setDefaultValue('90.1-2010')
    args << building_vintage

    # Make an argument for the climate zone
    climate_zone_chs = OpenStudio::StringVector.new
    climate_zone_chs << 'ASHRAE 169-2006-1A'
    #climate_zone_chs << 'ASHRAE 169-2006-1B'
    climate_zone_chs << 'ASHRAE 169-2006-2A'
    climate_zone_chs << 'ASHRAE 169-2006-2B'
    climate_zone_chs << 'ASHRAE 169-2006-3A'
    climate_zone_chs << 'ASHRAE 169-2006-3B'
    climate_zone_chs << 'ASHRAE 169-2006-3C'
    climate_zone_chs << 'ASHRAE 169-2006-4A'
    climate_zone_chs << 'ASHRAE 169-2006-4B'
    climate_zone_chs << 'ASHRAE 169-2006-4C'
    climate_zone_chs << 'ASHRAE 169-2006-5A'
    climate_zone_chs << 'ASHRAE 169-2006-5B'
    #climate_zone_chs << 'ASHRAE 169-2006-5C'
    climate_zone_chs << 'ASHRAE 169-2006-6A'
    climate_zone_chs << 'ASHRAE 169-2006-6B'
    climate_zone_chs << 'ASHRAE 169-2006-7A'
    #climate_zone_chs << 'ASHRAE 169-2006-7B'
    climate_zone_chs << 'ASHRAE 169-2006-8A'
    #climate_zone_chs << 'ASHRAE 169-2006-8B'
    climate_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('climate_zone', climate_zone_chs, true)
    climate_zone.setDisplayName('Select a Climate Zone.')
    climate_zone.setDefaultValue('ASHRAE 169-2006-2A')
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
    building_type = runner.getStringArgumentValue('building_type',user_arguments)
    building_vintage = runner.getStringArgumentValue('building_vintage',user_arguments)
    climate_zone = runner.getStringArgumentValue('climate_zone',user_arguments)

    # Turn debugging output on/off
    @debug = false    
    
    # Open a channel to log info/warning/error messages
    @msg_log = OpenStudio::StringStreamLogSink.new
    if @debug
      @msg_log.setLogLevel(OpenStudio::Debug)
    else
      @msg_log.setLogLevel(OpenStudio::Info)
    end
    @start_time = Time.new
    @runner = runner

    # Load the libraries
    # HVAC sizing
    require_relative 'resources/HVACSizing.Model'
    # Prototype Inputs
    require_relative 'resources/Prototype.utilities'
    require_relative 'resources/Prototype.add_objects'
    require_relative 'resources/Prototype.hvac_systems'
    require_relative 'resources/Prototype.Model'
    # Weather data
    require_relative 'resources/Weather.Model'
    # HVAC standards
    require_relative 'resources/Standards.Model'
    
    # Create a variable for the standard data directory
    # TODO Extend the OpenStudio::Model::Model class to store this
    # as an instance variable?
    standards_data_dir = "#{File.dirname(__FILE__)}/resources"

    # Load the Openstudio_Standards JSON files
    model.load_openstudio_standards_json(standards_data_dir)

    # Retrieve the Prototype Inputs from JSON
    search_criteria = {
      'template' => building_vintage,
      'building_type' => building_type
    }
    prototype_input = model.find_object(model.standards['prototype_inputs'], search_criteria)
    if prototype_input.nil?
      @runner.registerError("Could not find prototype inputs for #{search_criteria}, cannot create model.")
      log_msgs
      return false
    end
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', "Creating #{building_type}-#{building_vintage}-#{climate_zone} with these inputs:")
    prototype_input.each do |key, value|
      next if value.nil?
      OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', "  #{key} = #{value}")
    end
    
    # Make a directory to save the resulting models for debugging
    build_dir = "#{Dir.pwd}/build"
    if !Dir.exists?(build_dir)
      Dir.mkdir(build_dir)
    end

    osm_directory = "#{build_dir}/#{building_type}-#{building_vintage}-#{climate_zone}"
    if !Dir.exists?(osm_directory)
      Dir.mkdir(osm_directory)
    end

    # Make the prototype building
    alt_search_name = building_type

    case building_type
    when 'SecondarySchool'
      require_relative 'resources/Prototype.secondary_school'
      # Secondary School geometry is different between
      # Reference and Prototype vintages (Prototype has skylights)
      if building_vintage == 'DOE Ref Pre-1980' || building_vintage == 'DOE Ref 1980-2004'
        geometry_file = 'Geometry.secondary_school_pre_1980_to_2004.osm'
      else
        geometry_file = 'Geometry.secondary_school.osm'
      end      
    when 'PrimarySchool'
      require_relative 'resources/Prototype.primary_school'
      # Primary School geometry is different between
      # Reference and Prototype vintages (Prototype has skylights)
      if building_vintage == 'DOE Ref Pre-1980' || building_vintage == 'DOE Ref 1980-2004'
        geometry_file = 'Geometry.primary_school_pre_1980_to_2004.osm'
      else
        geometry_file = 'Geometry.primary_school.osm'
      end 
    when 'SmallOffice'
      require_relative 'resources/Prototype.small_office'
      # Small Office geometry is different for pre-1980
      # if has no attic, which means infiltration is way higher
      # since infiltration is specified per exposed exterior area.
      if building_vintage == 'DOE Ref Pre-1980'
        geometry_file = 'Geometry.small_office_pre_1980.osm'
      else
        geometry_file = 'Geometry.small_office.osm'
      end
      alt_search_name = 'Office'
    when 'MediumOffice'
      require_relative 'resources/Prototype.medium_office'
      geometry_file = 'Geometry.medium_office.osm'
      alt_search_name = 'Office'
    when 'LargeOffice'
      require_relative 'resources/Prototype.large_office'
      alt_search_name = 'Office'
      case building_vintage
        when 'DOE Ref Pre-1980','DOE Ref 1980-2004','DOE Ref 2004'
          geometry_file = 'Geometry.large_office.osm'
        else
          geometry_file = 'Geometry.large_office_2010.osm'
      end
    when 'SmallHotel'
      require_relative 'resources/Prototype.small_hotel'
      # Small Hotel geometry is different between
      # Reference and Prototype vintages
      case building_vintage
      when 'DOE Ref Pre-1980', 'DOE Ref 1980-2004'
        geometry_file = 'Geometry.small_hotel_doe.osm'
      when '90.1-2004'
        geometry_file = 'Geometry.small_hotel_pnnl2004.osm'
      when '90.1-2007'
        geometry_file = 'Geometry.small_hotel_pnnl2007.osm'
      when '90.1-2010'
        geometry_file = 'Geometry.small_hotel_pnnl2010.osm'
      when '90.1-2013'
        geometry_file = 'Geometry.small_hotel_pnnl2013.osm'
      end
    when 'LargeHotel'
      require_relative 'resources/Prototype.large_hotel'

      case building_vintage
        when 'DOE Ref Pre-1980','DOE Ref 1980-2004','DOE Ref 2004'
          geometry_file = 'Geometry.large_hotel.doe.osm'
        when '90.1-2007'
          geometry_file = 'Geometry.large_hotel.2004_2007.osm'
        when '90.1-2010'
          geometry_file = 'Geometry.large_hotel.2010.osm'
        else
          geometry_file = 'Geometry.large_hotel.2013.osm'
      end
    when 'Warehouse'
      require_relative 'resources/Prototype.warehouse'
      geometry_file = 'Geometry.warehouse.osm'
    when 'RetailStandalone'
      require_relative 'resources/Prototype.retail_standalone'
      geometry_file = 'Geometry.retail_standalone.osm'
      alt_search_name = 'Retail'
    when 'RetailStripmall'
      require_relative 'resources/Prototype.retail_stripmall'
      geometry_file = 'Geometry.retail_stripmall.osm'
      alt_search_name = 'StripMall'
    when 'QuickServiceRestaurant'
      require_relative 'resources/Prototype.quick_service_restaurant'
      geometry_file = 'Geometry.quick_service_restaurant.osm'
    when 'FullServiceRestaurant'
      require_relative 'resources/Prototype.full_service_restaurant'
      geometry_file = 'Geometry.full_service_restaurant.osm'
    when 'Hospital'
      require_relative 'resources/Prototype.hospital'
      geometry_file = 'Geometry.hospital.osm'
    when 'Outpatient'
      require_relative 'resources/Prototype.outpatient'
      geometry_file = 'Geometry.outpatient.osm'
    else
      OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model',"Building Type = #{building_type} not recognized")
      return false
    end

    model.add_geometry(geometry_file)
    model.getBuilding.setName("#{building_vintage}-#{building_type}-#{climate_zone} created: #{Time.new}")
    space_type_map = model.define_space_type_map(building_type, building_vintage, climate_zone)
    
    if building_type == "SmallHotel"
      building_story_map = model.define_building_story_map(building_type, building_vintage, climate_zone)
      model.assign_building_story(building_type, building_vintage, climate_zone, building_story_map)
    end
    
    # Assign the standards to the model
    model.template = building_vintage
    model.climate_zone = climate_zone      
    
    model.assign_space_type_stubs(alt_search_name, space_type_map)    
    model.add_loads(building_vintage, climate_zone)
    model.apply_infiltration_standard
    model.modify_infiltration_coefficients(building_type, building_vintage, climate_zone)
    model.modify_surface_convection_algorithm(building_vintage)
    model.add_constructions(alt_search_name, building_vintage, climate_zone)
    model.create_thermal_zones(building_type,building_vintage, climate_zone)
    model.add_hvac(building_type, building_vintage, climate_zone, prototype_input, model.standards)
    model.add_swh(building_type, building_vintage, climate_zone, prototype_input, model.standards, space_type_map)
    model.add_exterior_lights(building_type, building_vintage, climate_zone, prototype_input)
    model.add_occupancy_sensors(building_type, building_vintage, climate_zone)

    # Set the building location, weather files, ddy files, etc.
    model.add_design_days_and_weather_file(model.standards, building_type, building_vintage, climate_zone)
    
    # Set the sizing parameters
    model.set_sizing_parameters(building_type, building_vintage)

    # Set the Day of Week for Start Day
    model.yearDescription.get.setDayofWeekforStartDay('Sunday')

    
    # # raise the upper limit of surface temperature
    # heat_balance_algorithm = Openstudio::Model::getUniqueObject<HeatBalanceAlgorithm>(model)
    # heat_balance_algorithm = model.getOptionalUniqueObject<HeatBalanceAlgorithm>()
    # heat_balance_algorithm.setSurfaceTemperatureUpperLimit(250)

    # Adjust all spaces to have OA per area instead
    # of OA per zone.  Experiment to see if this
    # impacts OA flow rates in system.
    # model.getSpaces.sort.each do |space|
      # zone = space.thermalZone.get
      # oa_per_area = zone.outdoor_airflow_rate_per_area
      # ventilation = OpenStudio::Model::DesignSpecificationOutdoorAir.new(model)
      # ventilation.setName("#{space.name} OA per area")
      # ventilation.setOutdoorAirMethod("Flow/Area")
      # ventilation.setOutdoorAirFlowperFloorArea(oa_per_area)
      # space.setDesignSpecificationOutdoorAir(ventilation)
    # end

    model_status = '1_initial_creation'
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
    # Perform a sizing run
    if model.runSizingRun("#{osm_directory}/SizingRun1") == false
      log_msgs
      return false
    end
    model_status = "2_after_first_sz_run"
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
 
    model.apply_multizone_vav_outdoor_air_sizing
 
    # Perform a sizing run
    if model.runSizingRun("#{osm_directory}/SizingRun2") == false
      log_msgs
      return false
    end
    model_status = "3_after_second_sz_run"
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true) 

    # Apply the prototype HVAC assumptions
    # which include sizing the fan pressure rises based
    # on the flow rate of the system.
    model.applyPrototypeHVACAssumptions(building_type, building_vintage, climate_zone)
    model_status = '4_after_proto_hvac_assumptions'
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)

    # Get the equipment sizes from the sizing run
    # and hard-assign them back to the model
    #model.applySizingValues
    #model_status = "5_after_apply_sizes"
    #model.run("#{osm_directory}/#{model_status}")
    #model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
    
    # Apply the HVAC efficiency standard
    model.applyHVACEfficiencyStandard
    model_status = '6_after_apply_hvac_std'
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)  
    
    # Add daylighting controls per standard
    # TODO: There are some bugs in the function
    if building_type != "LargeHotel"
      model.addDaylightingControls
    end
   
   
    # Add output variables for debugging
    if @debug
      model.request_timeseries_outputs
    end
    
    # Finished
    model_status = 'final'
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
    
    log_msgs
    return true

  end #end the run method

  # Get all the log messages and put into output
  # for users to see.
  def log_msgs
    @msg_log.logMessages.each do |msg|
      # DLM: you can filter on log channel here for now
      if /openstudio.*/.match(msg.logChannel) #/openstudio\.model\..*/
        # Skip certain messages that are irrelevant/misleading
        next if msg.logMessage.include?("Skipping layer") || # Annoying/bogus "Skipping layer" warnings
            msg.logChannel.include?("runmanager") || # RunManager messages
            msg.logChannel.include?("setFileExtension") || # .ddy extension unexpected
            msg.logChannel.include?("Translator") || # Forward translator and geometry translator
            msg.logMessage.include?("UseWeatherFile") # 'UseWeatherFile' is not yet a supported option for YearDescription
            
        # Report the message in the correct way
        if msg.logLevel == OpenStudio::Info
          @runner.registerInfo(msg.logMessage)
        elsif msg.logLevel == OpenStudio::Warn
          @runner.registerWarning("[#{msg.logChannel}] #{msg.logMessage}")
        elsif msg.logLevel == OpenStudio::Error
          @runner.registerError("[#{msg.logChannel}] #{msg.logMessage}")
        elsif msg.logLevel == OpenStudio::Debug && @debug
          @runner.registerInfo("DEBUG - #{msg.logMessage}")
        end
      end
    end
    @runner.registerInfo("Total Time = #{(Time.new - @start_time).round}sec.")
  end

end #end the measure

#this allows the measure to be use by the application
CreateDOEPrototypeBuilding.new.registerWithApplication
