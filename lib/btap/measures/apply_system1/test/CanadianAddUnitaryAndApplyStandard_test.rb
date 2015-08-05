require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'

require_relative '../measure.rb'

require 'fileutils'

require 'json'

class CanadianAddUnitaryAndApplyStandardTest < MiniTest::Unit::TestCase

  # def setup
  # end

  # def teardown
  # end



  def test_one()   
    # create an instance of the measure, a runner and an empty model
    measure = CanadianAddUnitaryAndApplyStandard.new
    runner = OpenStudio::Ruleset::OSRunner.new
    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
    weather_file = BTAP::Environment::WeatherFile.new("C:/EnergyPlusV8-2-0/WeatherData/CAN_ON_Toronto.716240_CWEC.epw")
    weather_file.set_weather_file(model)
    
    #create argument map

    
    #might need arg variables but they are empty. 
    args  = OpenStudio::Ruleset::OSArgumentVector.new();
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(args)


    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    #save file

    BTAP::FileIO::save_osm(model, "#{File.dirname(__FILE__)}/necbsys1-test.osm")
    puts "File saved."
    assert_equal("Success", result.value.valueName)
  end


  #


  
end
