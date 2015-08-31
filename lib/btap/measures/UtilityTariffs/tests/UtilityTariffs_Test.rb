require 'openstudio'
require 'minitest/autorun'
require_relative '../measure.rb'

class UtilityTariffsTest < MiniTest::Unit::TestCase
  model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/system_2.osm")
  # translate osm to idf
  ft = OpenStudio::EnergyPlus::ForwardTranslator.new
  workspace = ft.translateModel(model)
    
  # create an instance of the measure, a runner and an empty model
  measure = UtilityTariffsModelSetup.new
  runner = OpenStudio::Ruleset::OSRunner.new

  #might need arg variables but they are empty. 
  argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(OpenStudio::Ruleset::OSArgumentVector.new())

  # run the measure
  measure.run(workspace, runner, argument_map)
  workspace.save("#{File.dirname(__FILE__)}/system_2.idf",true)
#  BTAP::FileIO::save_idf(model, "#{File.dirname(__FILE__)}/system_2.idf")
end
