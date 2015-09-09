
# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide
require 'fileutils'
require "date"
release_mode = false
folder = "#{File.dirname(__FILE__)}/../../../../lib/btap/lib/"

if release_mode == true
  #Copy BTAP files to measure from lib folder. Use this to create independant measure. 
  Dir.glob("#{folder}/**/*rb").each do |file|
    FileUtils.cp(file, File.dirname(__FILE__))
  end
  require "#{File.dirname(__FILE__)}/btap.rb"
else
  #For only when using git hub development environment.
  require "#{File.dirname(__FILE__)}/../../../../lib/btap/lib/btap.rb"
end

# start the measure
class SetDefaultConstructionSet < OpenStudio::Ruleset::ModelUserScript

  attr_reader :lib_directory

  def initialize
    super

    # Hard code to the weather directory for now. This assumes that you are running
    # the analysis on the OpenStudio distributed analysis server
    @lib_directory = File.expand_path(File.join(File.dirname(__FILE__), "../../lib/btap/resources/constructions"))
  end
  
  # human readable name
  def name
    return "Set Default Construction Set"
  end

  # human readable description
  def description
    return "Loads and Set the a default construction library from an osm file. "
  end

  # human readable description of modeling approach
  def modeler_description
    return "Loads and Set the a default construction library from an osm file.  "
  end

  # define the arguments that the user will input
  def arguments(model)
    #list of arguments as they will appear in the interface. They are available in the run command as
    @argument_array_of_arrays = [
      [    "variable_name",              "type",          "required",  "model_dependant", "display_name",                 "default_value",  "min_value",  "max_value",  "string_choice_array",  	"os_object_type"	],
      [    "lib_file_name",              "STRING",        true,        false,             "Lib File Name",                nil,               nil,          nil,           nil,  	         nil					],
      [    "construction_set_name",      "STRING",        true,        false,             "Construction Set Name",        nil,               nil,          nil,           nil,  	         nil					],
      
      #Default set for server weather folder.
      [    "lib_directory",      "STRING",        true,        false,             "Lib Directory",               "../../lib/btap/resources/constructions",               nil,          nil,          nil,	                       nil					]
            
    ]
    #set up arguments. 
    args = OpenStudio::Ruleset::OSArgumentVector.new
    self.argument_setter(args)
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      BTAP::runner_register("Error","Bad Arguments.", runner)
      return false
    end
    #Set argument to instance variables. 
    self.argument_getter(model, runner,user_arguments)
    
    ################ Start Measure code here ################################
    
    #Check weather directory Weather File
    unless (Pathname.new @lib_directory).absolute?
      @lib_directory = File.expand_path(File.join(File.dirname(__FILE__), @lib_directory))
    end
    lib_file = File.join(@lib_directory, @lib_file_name)
    if File.exists?(lib_file) and @lib_file_name.downcase.include? ".osm"
      BTAP::runner_register("Info","#{@lib_file_name} Found!.", runner)
    else
      BTAP::runner_register("Error","#{lib_file} does not exist or is not an .osm file.", runner)
      return false
    end
         
    #load model and test.
    construction_set = BTAP::Resources::Envelope::ConstructionSets::get_construction_set_from_library( lib_file, @construction_set_name )
    #Set Construction Set.
    unless model.building.get.setDefaultConstructionSet( construction_set.clone( model ).to_DefaultConstructionSet.get )
      BTAP::runner_register("Error","Could not set Default Construction #{@construction_set_name} ", runner)
      return false
    end
    BTAP::runner_register("FinalCondition","Default Construction set to #{@construction_set_name} from #{lib_file}",runner)
    ##########################################################################
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

# register the measure to be used by the application
SetDefaultConstructionSet.new.registerWithApplication
