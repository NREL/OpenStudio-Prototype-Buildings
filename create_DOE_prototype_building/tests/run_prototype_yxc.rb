require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'json'
require_relative '../measure.rb'
require 'fileutils'
require 'socket'

# Create a set of models, return a list of failures
def create_models(building_type, building_vintage, climate_zone)
  #### Create the prototype building
  model_name = "#{building_type}-#{building_vintage}-#{climate_zone}"
  puts "****Testing #{model_name}****"
  failures = []
  # Create an instance of the measure
  measure = CreateDOEPrototypeBuilding.new

  # Create an instance of a runner
  runner = OpenStudio::Ruleset::OSRunner.new

  # Make an empty model
  model = OpenStudio::Model::Model.new

  # Set argument values
  arguments = measure.arguments(model)
  argument_map = OpenStudio::Ruleset::OSArgumentMap.new
  building_type_arg = arguments[0].clone
  building_type_arg.setValue(building_type)
  argument_map['building_type'] = building_type_arg

  building_vintage_arg = arguments[1].clone
  building_vintage_arg.setValue(building_vintage)
  argument_map['building_vintage'] = building_vintage_arg

  climate_zone_arg = arguments[2].clone
  climate_zone_arg.setValue(climate_zone)
  argument_map['climate_zone'] = climate_zone_arg

  measure.run(model, runner, argument_map)
  result = runner.result
  show_output(result)
  if result.value.valueName != 'Success'
    failures << "Error - #{model_name} - Model was not created successfully."
  end

  model_directory = "#{Dir.pwd}/build/#{building_type}-#{building_vintage}-#{climate_zone}"

  # Convert the model to energyplus idf
  forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
  idf = forward_translator.translateModel(model)
  idf_path_string = "#{model_directory}/#{model_name}.idf"
  idf_path = OpenStudio::Path.new(idf_path_string)
  idf.save(idf_path,true)

  return failures
end

# Create a set of models, return a list of failures
def run_models(building_type, building_vintage, climate_zone)
  # Open a channel to log info/warning/error messages
  msg_log = OpenStudio::StringStreamLogSink.new
  msg_log.setLogLevel(OpenStudio::Info)

  #### Run the specified models
  failures = []

  # Make a run manager and queue up the sizing run
  run_manager_db_path = OpenStudio::Path.new("#{Dir.pwd}/build/#{building_type}-#{building_vintage}-#{climate_zone}/run.db")
  run_manager = OpenStudio::Runmanager::RunManager.new(run_manager_db_path, true)

  # Configure the run manager with the correct versions of Ruby and E+
  config_opts = OpenStudio::Runmanager::ConfigOptions.new
  config_opts.findTools(false, false, false, false)
  run_manager.setConfigOptions(config_opts)

  # Load the .osm
  model = nil
  model_directory = "#{Dir.pwd}/build/#{building_type}-#{building_vintage}-#{climate_zone}"
  model_name = "#{building_type}-#{building_vintage}-#{climate_zone}"
  model_path_string = "#{model_directory}/final.osm"
  model_path = OpenStudio::Path.new(model_path_string)
  if OpenStudio::exists(model_path)
    version_translator = OpenStudio::OSVersion::VersionTranslator.new
    model = version_translator.loadModel(model_path)
    if model.empty?
      failures << "Error - #{model_name} - Version translation failed"
      return failures
    else
      model = model.get
    end
  else
    failures << "Error - #{model_name} - #{model_path_string} couldn't be found"
    return failures
  end

  # Delete the old ModelToIdf and SizingRun1 directories if they exist
  FileUtils.rm_rf("#{model_directory}/ModelToIdf")
  FileUtils.rm_rf("#{model_directory}/SizingRun1")

  # Convert the model to energyplus idf
  forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
  idf = forward_translator.translateModel(model)
  idf_path_string = "#{model_directory}/#{model_name}.idf"
  idf_path = OpenStudio::Path.new(idf_path_string)
  idf.save(idf_path,true)

  # Find the weather file
  epw_path = nil
  if model.weatherFile.is_initialized
    epw_path = model.weatherFile.get.path
    if epw_path.is_initialized
      if File.exist?(epw_path.get.to_s)
        epw_path = epw_path.get
      else
        failures << "Error - #{model_name} - Model has not been assigned a weather file."
        return failures
      end
    else
      failures << "Error - #{model_name} - Model has a weather file assigned, but the file is not in the specified location."
      return failures
    end
  else
    failures << "Error - #{model_name} - Model has not been assigned a weather file."
    return failures
  end

  # Set the output path
  output_path = OpenStudio::Path.new("#{model_directory}/")

  # Create a new workflow for the model to go through
  workflow = OpenStudio::Runmanager::Workflow.new
  workflow.addJob(OpenStudio::Runmanager::JobType.new('ModelToIdf'))
  workflow.addJob(OpenStudio::Runmanager::JobType.new('ExpandObjects'))
  workflow.addJob(OpenStudio::Runmanager::JobType.new('EnergyPlusPreProcess'))
  workflow.addJob(OpenStudio::Runmanager::JobType.new('EnergyPlus'))
  workflow.add(config_opts.getTools)
  job = workflow.create(output_path, model_path, epw_path)

  run_manager.enqueue(job, true)

  # Start the runs and wait for them to finish.
  while run_manager.workPending
    sleep 5
    OpenStudio::Application::instance.processEvents
  end

  return failures
end

bldg_type = ARGV[0]
vintage = ARGV[1]
climate_zone = ARGV[2]
failures =[]
# Create the models
failures += create_models(bldg_type, vintage, climate_zone)

# Run the models
failures += run_models(bldg_type, vintage, climate_zone)