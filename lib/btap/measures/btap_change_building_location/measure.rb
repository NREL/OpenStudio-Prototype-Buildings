
# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide
require 'fileutils'
require "date"
#copy most recent btap code into measures folder if available.
folder = "#{File.dirname(__FILE__)}/../../../../lib/btap/lib/"
ext = "rb"
btap_ruby_files = Dir.glob("#{folder}/**/*#{ext}")
btap_ruby_files.each do |file|
  FileUtils.cp(file, File.dirname(__FILE__))
end
btaplibpath = "#{File.dirname(__FILE__)}/btap.rb"
#Check if btap.rb does not exist.
raise ("could not load btap environment from #{btaplibpath}") unless File.exists?("#{btaplibpath}")
require "#{btaplibpath}"




#see the URL below for information on how to write OpenStudio measures
# TODO: Remove this link and replace with the wiki
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html



class ChangeBuildingLocation < OpenStudio::Ruleset::ModelUserScript

  attr_reader :weather_directory

  def initialize
    super

    # Hard code the weather directory for now. This assumes that you are running
    # the analysis on the OpenStudio distributed analysis server
    @weather_directory = File.expand_path(File.join(File.dirname(__FILE__), "../../weather"))
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    'ChangeBuildingLocation'
  end

  #define the arguments that the user will input
  def arguments(model)
    #list of arguments as they will appear in the interface. They are available in the run command as
    @argument_array_of_arrays = [
      [    "variable_name",          "type",          "required",  "model_dependant", "display_name",                 "default_value",  "min_value",  "max_value",  "string_choice_array",  	"os_object_type"	],
      [    "weather_file_name",      "STRING",        true,        false,             "Weather File Name",                nil,               nil,          nil,           nil,  	         nil					],
      #Default set for server weather folder.
      [    "weather_directory",      "STRING",        true,        false,             "Weather Directory",               "../../weather",               nil,          nil,          nil,	                       nil					]
            
    ]
    #set up arguments. 
    args = OpenStudio::Ruleset::OSArgumentVector.new
    self.argument_setter(args)
    return args
  end

  # Define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    #Set argument to instance variables. 
    self.argument_getter(model, runner,user_arguments)
    
    ################ Start Measure code here ################################
    # Argument will be passed as instance variable. So if your argument was height, your can access it using @height. 

    # report initial condition
    site = model.getSite
    initial_design_days = model.getDesignDays
    if site.weatherFile.is_initialized
      weather = site.weatherFile.get
      runner.registerInitialCondition("The initial weather file path was '#{weather.path.get}' and the model had #{initial_design_days.size} design days.")
    else
      runner.registerInitialCondition("The initial weather file has not been set and the model had #{initial_design_days.size} design days.")
    end


    #Check form weather directory Weather File
    unless (Pathname.new @weather_directory).absolute?
      @weather_directory = File.expand_path(File.join(File.dirname(__FILE__), @weather_directory))
    end
    weather_file = File.join(@weather_directory, @weather_file_name)
    if File.exists?(weather_file) and @weather_file_name.downcase.include? ".epw"
      runner.registerInfo("' The epw weather file #{weather_file}' was found!.")
    else
      runner.registerError("'#{weather_file}' does not exist or is not an .epw file.")
      return false
    end

    begin
      weather = BTAP::Environment::WeatherFile.new(weather_file)
      #Set Weather file to model.
      weather.set_weather_file(model)
      #Store information about this run in the runner for output. This will be in the csv and R dumps.
      #runner.registerValue( 'latitude',weather.lat.to_f )
      #runner.registerValue( 'longitude',weather.lon.to_f )
      runner.registerValue( 'city',weather.city )
      runner.registerValue( 'state_province_region ',weather.state_province_region )
      runner.registerValue( 'country',weather.country )
      runner.registerValue( 'hdd18',weather.hdd18 )
      runner.registerValue( 'cdd18',weather.cdd18 )
      runner.registerValue( 'necb_climate_zone',BTAP::Compliance::NECB2011::get_climate_zone_name(weather.hdd18).to_s)
      runner.registerFinalCondition( "Model ended with weatherfile of #{model.getSite.weatherFile.get.path.get}" )
    rescue
      runner.registerError("Could not load weather file. #{weather_file}") 
      puts "Could not load weather file. #{weather_file}"
      return false
    end
    return true
  end
  
  def argument_setter(args)
    #***boilerplate code starts. Do not edit...
    # this converts the 2D array to a array hash for better readability and makes
    # column data accessible by name.
    @argument_array_of_hashes = []
    @argument_array_of_arrays[1..-1].each do |row|   # [1..-1] skips the first row
      hsh = {}; @argument_array_of_arrays[0].each_with_index{ |header, idx|   hsh[header] = row[idx] }
      @argument_array_of_hashes << hsh
    end

    #iterate through array of hashes and make arguments based on type and set
    # max and min values where applicable.
    @argument_array_of_hashes.each do |row|
      arg = nil
      case row["type"]
      when "BOOL"
        arg = OpenStudio::Ruleset::OSArgument::makeBoolArgument(row["variable_name"],row["required"],row["model_dependant"])
      when "STRING"
        arg = OpenStudio::Ruleset::OSArgument::makeStringArgument(row["variable_name"],row["required"],row["model_dependant"])
      when "INTEGER"
        arg = OpenStudio::Ruleset::OSArgument::makeIntegerArgument(row["variable_name"],row["required"],row["model_dependant"])
        arg.setMaxValue( row["max_value"].to_i ) unless row["min_value"].nil?
        arg.setMaxValue( row["max_value"].to_i ) unless  row["max_value"].nil?
      when "FLOAT"
        arg = OpenStudio::Ruleset::OSArgument::makeDoubleArgument(row["variable_name"],row["required"],row["model_dependant"])
        arg.setMaxValue( row["max_value"].to_f ) unless row["min_value"].nil?
        arg.setMaxValue( row["max_value"].to_f ) unless  row["max_value"].nil?
      when "STRINGCHOICE"
        # #add string choices one by one.
        chs = OpenStudio::StringVector.new
        row["string_choice_array"].each {|choice| chs << choice}
        arg = OpenStudio::Ruleset::OSArgument::makeChoiceArgument(row["variable_name"], chs,row["required"],row["model_dependant"])
      when "PATH"
        arg = OpenStudio::Ruleset::OSArgument::makePathArgument("alternativeModelPath",true,"osm")
      when "WSCHOICE"
        arg = OpenStudio::Ruleset::makeChoiceArgumentOfWorkspaceObjects( row["variable_name"], row["os_object_type"].to_IddObjectType , model, row["required"])
      end
      # #common argument aspects.
      unless arg.nil?
        arg.setDisplayName(row["display_name"])
        arg.setDefaultValue(row["default_value"]) unless row["default_value"].nil?
        args << arg
      end
    end
    return args
  end

  def argument_getter(model, runner,user_arguments)
    @argument_array_of_hashes.each do |row|
      name = row["variable_name"]
      case row["type"]
      when "BOOL"
        instance_variable_set("@#{name}", runner.getBoolArgumentValue(name, user_arguments) )
      when "STRING"
        instance_variable_set("@#{name}", runner.getStringArgumentValue(name, user_arguments) )
      when "INTEGER"
        instance_variable_set("@#{name}", runner.getIntegerArgumentValue(name, user_arguments) )
        if ( not row["min_value"].nil?  and instance_variable_get("@#{name}") < row["min_value"] ) or ( not row["max_value"].nil? and instance_variable_get("@#{name}") > row["max_value"] )
          runner.registerError("#{row["display_name"]} must be greater than or equal to #{row["min_value"]} and less than or equal to #{row["max_value"]}.  You entered #{instance_variable_get("@#{name}")}.")
          return false
        end
      when "FLOAT"
        instance_variable_set("@#{name}", runner.getDoubleArgumentValue(name, user_arguments) )
        if ( not row["min_value"].nil?  and instance_variable_get("@#{name}") < row["min_value"] ) or ( not row["max_value"].nil? and instance_variable_get("@#{name}") > row["max_value"] )
          runner.registerError("#{row["display_name"]} must be greater than or equal to #{row["min_value"]} and less than or equal to #{row["max_value"]}.  You entered #{instance_variable_get("@#{name}")}.")
          return false
        end
      when "STRINGCHOICE"
        instance_variable_set("@#{name}", runner.getStringArgumentValue(name, user_arguments) )
      when "WSCHOICE"
        instance_variable_set("@#{name}", runner.getOptionalWorkspaceObjectChoiceValue(name, user_arguments,model) )

      when "PATH"
        instance_variable_set("@#{name}", runner.getPathArgument(name, user_arguments) )
      end #end case
    end #end do
  end
  
  
end

# This allows the measure to be use by the application
ChangeBuildingLocation.new.registerWithApplication