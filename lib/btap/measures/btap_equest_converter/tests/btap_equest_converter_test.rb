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



  def import_inp_test(inp_file)   
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
    #save file

    filename = "#{File.dirname(__FILE__)}/#{inp_file}.osm"
    File.delete(filename) if File.exist?(filename)
    model.save(OpenStudio::Path.new(filename))
    puts "File #{filename} saved."
    assert_equal("Success", result.value.valueName)
  end



  def test_4StoreyBuilding()
    self.import_inp_test("#{File.dirname(__FILE__)}/./4StoreyBuilding.inp" )
  end
  def test_ReaganBuilding_Calibrated()
    self.import_inp_test("#{File.dirname(__FILE__)}/./ReaganBuilding_Calibrated.inp")
  end
  def test_5ZoneFloorRotationTest()
    self.import_inp_test("#{File.dirname(__FILE__)}/./5ZoneFloorRotationTest.inp")
  end
  def test_basic_2storey_with_basement_wizard_geometry
    self.import_inp_test("#{File.dirname(__FILE__)}/./basic_2storey_with_basement_wizard_geometry.inp")
  end
  def test_Custom_Concave_Polygon()
    self.import_inp_test("#{File.dirname(__FILE__)}/./Custom_Concave_Polygon.inp" )
  end
  def test_Custom_Convex_Polygon()
    self.import_inp_test("#{File.dirname(__FILE__)}/./Custom_Convex_Polygon.inp")
  end
  def test_H_Shape()
    self.import_inp_test("#{File.dirname(__FILE__)}/./H_Shape.inp")
  end
  def test_Nealon_Calibrated()
    self.import_inp_test("#{File.dirname(__FILE__)}/./Nealon_Calibrated.inp")
  end
  def test_Plus_Shape()
    self.import_inp_test("#{File.dirname(__FILE__)}/./Plus_Shape.inp")
  end
  def test_Rectangle_minus_corner()
    self.import_inp_test("#{File.dirname(__FILE__)}/./Rectangle_minus_corner.inp")
  end
  def test_Rectangle()
    self.import_inp_test("#{File.dirname(__FILE__)}/./Rectangle.inp")
  end
  def test_Rectangular_Atrium()
    self.import_inp_test("#{File.dirname(__FILE__)}/./Rectangular_Atrium.inp")
  end
  def test_SingleZonePerFloorRotation()
    self.import_inp_test("#{File.dirname(__FILE__)}/./SingleZonePerFloorRotation.inp" )
  end
  def test_T_Shape()
    self.import_inp_test("#{File.dirname(__FILE__)}/./T_Shape.inp")
  end
  def test_Trapezoid()
    self.import_inp_test("#{File.dirname(__FILE__)}/./Trapezoid.inp")
  end
  def test_Triangle()
    self.import_inp_test("#{File.dirname(__FILE__)}/./Triangle.inp")
  end
  def test_U_Shape()
    self.import_inp_test("#{File.dirname(__FILE__)}/./U_Shape.inp")
  end
  def test_Overhang()
    self.import_inp_test("#{File.dirname(__FILE__)}/./Overhang.inp")
  end
  
end
