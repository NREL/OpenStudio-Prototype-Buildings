
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

class ReplaceModel < OpenStudio::Ruleset::ModelUserScript

  # override name to return the name of your script
  def name
    return "Replaces OpenStudio Model "
  end

  # return a vector of arguments
  def arguments(model)
        #list of arguments as they will appear in the interface. They are available in the run command as
    @argument_array_of_arrays = [
      [    "variable_name",         "type",          "required",  "model_dependant", "display_name",                "default_value",                                     "min_value",  "max_value",  "string_choice_array",   "os_object_type"	    ],
      [    "alternativeModel",      "STRING",        true,        false,             "Alternative Model",           'FullServiceRestaurant.osm',                          nil,          nil,           nil,  	               nil					],
      [    "osm_directory",         "STRING",        true,        false,             "OSM Directory",               "../../lib/btap/resources/models/smart_archetypes",   nil,          nil,           nil,	                   nil					]     
    ]
    #set up arguments. 
    args = OpenStudio::Ruleset::OSArgumentVector.new
    self.argument_setter(args)
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    #Set argument to instance variables. 
    self.argument_getter(model, runner,user_arguments)
    
    ################ Start Measure code here ################################
    # Argument will be passed as instance variables. So if your argument was alternativeModel, your can access it using @alternativeModel. 

    # report initial condition
    runner.registerInitialCondition("Initial model.")

    #set path to new model. 

    alternativeModelPath = OpenStudio::Path.new(File.dirname(__FILE__) + '/' + @osm_directory.strip + '/' + @alternativeModel.strip)
    unless File.exist?(alternativeModelPath.to_s) 
      runner.registerError("File does not exist: #{alternativeModelPath.to_s}") 
      return false
    end
    

    #try loading the file. 
    translator = OpenStudio::OSVersion::VersionTranslator.new
    oModel = translator.loadModel(alternativeModelPath)
    if oModel.empty?
      runner.registerError("Could not load alternative model from '" + alternativeModelPath.to_s + "'.")
      return false
    end

    #Get the new model. 
    newModel = oModel.get

    # pull original weather file object over
    weatherFile = newModel.getOptionalWeatherFile
    if not weatherFile.empty?
      weatherFile.get.remove
      runner.registerInfo("Removed alternate model's weather file object.")
    end
    originalWeatherFile = model.getOptionalWeatherFile
    if not originalWeatherFile.empty?
      originalWeatherFile.get.clone(newModel)
    end

    # pull original design days over
    newModel.getDesignDays.each { |designDay|
      designDay.remove
    }
    model.getDesignDays.each { |designDay|
      designDay.clone(newModel)
    }

    # swap underlying data in model with underlying data in newModel
   
    # remove existing objects from model
    handles = OpenStudio::UUIDVector.new
    model.objects.each do |obj|
      handles << obj.handle
    end
    model.removeObjects(handles)
    # add new file to empty model
    model.addObjects( newModel.toIdfFile.objects )
    runner.registerFinalCondition("Model replaced with alternative #{alternativeModelPath}. Weather file and design days retained from original.")

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

#this allows the measure to be used by the application
ReplaceModel.new.registerWithApplication
