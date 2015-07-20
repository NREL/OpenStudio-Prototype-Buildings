require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'

require_relative '../measure.rb'

require 'fileutils'

class BtapEquestConverterTest < MiniTest::Unit::TestCase

  # def setup
  # end

  # def teardown
  # end



  def import_inp_test(inp_file, number_of_zones,number_of_surfaces,number_of_subsurfaces)   
    # create an instance of the measure, a runner and an empty model
    measure = BtapEquestConverter.new
    runner = OpenStudio::Ruleset::OSRunner.new
    model = OpenStudio::Model::Model.new
    #create argument map
    facade = OpenStudio::Ruleset::OSArgument::makeStringArgument("inp_file");
    facade.setValue(inp_file);

    args  = OpenStudio::Ruleset::OSArgumentVector.new();
    args << facade
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(args)


    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    assert_equal("Success", result.value.valueName)



  end



  def test_number_of_arguments_and_argument_names()
    self.import_inp_test("./4StoreyBuilding.inp", 1, 1,1)
  end
  
end
