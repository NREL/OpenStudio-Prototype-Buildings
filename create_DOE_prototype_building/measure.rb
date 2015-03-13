
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
    building_type_chs << 'SmallOffice'
    building_type_chs << 'SmallHotel'
    building_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('building_type', building_type_chs, true)
    building_type.setDisplayName('Select a Building Type.')
    building_type.setDefaultValue('SmallOffice')
    args << building_type

    # Make an argument for the building vintage
    building_vintage_chs = OpenStudio::StringVector.new
    building_vintage_chs << 'DOE Ref Pre-1980'
    building_vintage_chs << 'DOE Ref 1980-2004'
    #building_vintage_chs << 'DOE Ref 2004'
    #building_vintage_chs << '90.1-2007'
    #building_vintage_chs << '189.1-2009'
    building_vintage_chs << '90.1-2010'
    building_vintage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('building_vintage', building_vintage_chs, true)
    building_vintage.setDisplayName('Select a Vintage.')
    building_vintage.setDefaultValue('90.1-2010')
    args << building_vintage

    # Make an argument for the climate zone
    climate_zone_chs = OpenStudio::StringVector.new
    #climate_zone_chs << 'ASHRAE 169-2006-1A'
    #climate_zone_chs << 'ASHRAE 169-2006-1B'
    climate_zone_chs << 'ASHRAE 169-2006-2A'
    #climate_zone_chs << 'ASHRAE 169-2006-2B'
    #climate_zone_chs << 'ASHRAE 169-2006-3A'
    climate_zone_chs << 'ASHRAE 169-2006-3B'
    #climate_zone_chs << 'ASHRAE 169-2006-3C'
    climate_zone_chs << 'ASHRAE 169-2006-4A'
    #climate_zone_chs << 'ASHRAE 169-2006-4B'
    #climate_zone_chs << 'ASHRAE 169-2006-4C'
    climate_zone_chs << 'ASHRAE 169-2006-5A'
    #climate_zone_chs << 'ASHRAE 169-2006-5B'
    #climate_zone_chs << 'ASHRAE 169-2006-5C'
    #climate_zone_chs << 'ASHRAE 169-2006-6A'
    #climate_zone_chs << 'ASHRAE 169-2006-6B'
    #climate_zone_chs << 'ASHRAE 169-2006-7A'
    #climate_zone_chs << 'ASHRAE 169-2006-7B'
    #climate_zone_chs << 'ASHRAE 169-2006-8A'
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

    # Open a channel to log info/warning/error messages
    @msg_log = OpenStudio::StringStreamLogSink.new
    @msg_log.setLogLevel(OpenStudio::Info)
    @start_time = Time.new
    @runner = runner
    
    # Get all the log messages and put into output
    # for users to see.
    def log_msgs()
      @msg_log.logMessages.each do |msg|
        # DLM: you can filter on log channel here for now
        if /openstudio.*/.match(msg.logChannel) #/openstudio\.model\..*/
          # Skip certain messages that are irrelevant/misleading
          next if msg.logMessage.include?("Skipping layer") || # Annoying/bogus "Skipping layer" warnings
                  msg.logChannel.include?("runmanager") || # RunManager messages
                  msg.logChannel.include?("setFileExtension") || # .ddy extension unexpected
                  msg.logChannel.include?("Translator") # Forward translator and geometry translator
                  
          # Report the message in the correct way
          if msg.logLevel == OpenStudio::Info
            @runner.registerInfo(msg.logMessage)  
          elsif msg.logLevel == OpenStudio::Warn
            @runner.registerWarning("[#{msg.logChannel}] #{msg.logMessage}")
          elsif msg.logLevel == OpenStudio::Error
            @runner.registerError("[#{msg.logChannel}] #{msg.logMessage}")
          end
        end
      end
      @runner.registerInfo("Total Time = #{(Time.new - @start_time).round}sec.")
    end    
    
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
    require_relative 'resources/Standards.Model.2' # TODO merge these two Standards.Model files after changes calm down

    # Create a variable for the standard data directory
    # TODO Extend the OpenStudio::Model::Model class to store this
    # as an instance variable?
    standards_data_dir = "#{File.dirname(__FILE__)}/resources"

    # Load the hvac standards from JSON
    hvac_standards_path = "#{File.dirname(__FILE__)}/resources/OpenStudio_HVAC_Standards.json"
    temp = File.read(hvac_standards_path.to_s)
    hvac_standards = JSON.parse(temp)
    search_criteria = {
      'template' => building_vintage,
      'climate_zone' => climate_zone,
      'building_type' => building_type,
    }
    model.hvac_standards = hvac_standards

    # Load the Prototype Inputs from JSON
    prototype_input = find_object(hvac_standards['prototype_inputs'], search_criteria)
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
    space_building_type_search = building_type
    has_swh = true

    case building_type
    when 'SecondarySchool'
      require_relative 'resources/Prototype.secondary_school'
      geometry_file = 'Geometry.secondary_school.osm'
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
      space_building_type_search = 'Office'
    when 'SmallHotel'
      require_relative 'resources/Prototype.small_hotel'
      # Small Hotel geometry is different between
      # Reference and Prototype vintages
      if building_vintage == 'DOE Ref Pre-1980' || building_vintage == 'DOE Ref 1980-2004'
        geometry_file = 'Geometry.small_hotel_doe.osm'
      else
        geometry_file = 'Geometry.small_hotel_pnnl.osm'
      end
    else
      OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model',"Building Type = #{building_type} not recognized")
      return false
    end

    model.add_geometry(geometry_file)
    space_type_map = model.define_space_type_map(building_type, building_vintage, climate_zone)
    model.assign_space_type_stubs(space_building_type_search, space_type_map)
    model.add_loads(building_vintage, climate_zone, standards_data_dir)
    model.modify_infiltration_coefficients(building_type, building_vintage, climate_zone)
    model.add_constructions(building_type, building_vintage, climate_zone, standards_data_dir)
    model.create_thermal_zones
    model.add_hvac(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
    if has_swh
      swh_loop = model.add_swh_loop(prototype_input, hvac_standards)
      model.add_swh_end_uses(prototype_input, hvac_standards, swh_loop)
    end
    model.add_exterior_lights(building_type, building_vintage, climate_zone, prototype_input)
    model.add_occupancy_sensors(building_type, building_vintage, climate_zone)

    # Set the building location, weather files, ddy files, etc.
    model.add_design_days_and_weather_file(climate_zone)

    # Assign the standards to the model
    model.template = building_vintage
    model_status = '1_initial_creation'
    #model.run("#{osm_directory}/#{model_status}")
    #model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
    
    # Perform a sizing run
    if model.runSizingRun("#{osm_directory}/SizingRun1") == false
      log_msgs
      return false
    end
    model_status = "2_after_first_sz_run"
    #model.run("#{osm_directory}/#{model_status}")
    #model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
    
    # Apply the prototype HVAC assumptions
    # which include sizing the fan pressure rises based
    # on the flow rate of the system.
    model.applyPrototypeHVACAssumptions
    model_status = '4_after_proto_hvac_assumptions'
    #model.run("#{osm_directory}/#{model_status}")
    #model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)

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
    #model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)  
   
    # Add output variables for debugging
    model.request_timeseries_outputs

    # Finished
    model_status = 'final'
    #model.run("#{osm_directory}/#{model_status}")
    model.save(OpenStudio::Path.new("#{osm_directory}/#{model_status}.osm"), true)
    
    log_msgs
    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
CreateDOEPrototypeBuilding.new.registerWithApplication
