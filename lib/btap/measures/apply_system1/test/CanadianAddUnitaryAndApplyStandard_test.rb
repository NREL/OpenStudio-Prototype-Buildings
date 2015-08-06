require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'

require_relative '../measure.rb'

require 'fileutils'

require 'json'

class CanadianAddUnitaryAndApplyStandardTest < MiniTest::Unit::TestCase



#  def test_system_1()
#    boiler_fueltypes = ["NaturalGas","Electricity","PropaneGas","FuelOil#1","FuelOil#2","Coal","Diesel","Gasoline","OtherFuel1"]
#    mau_types = [true, false]
#    mau_heating_coil_types = ["Hot Water", "Electric"]
#    baseboard_types = ["Hot Water" , "Electric"]
#    chiller_types = ["Scroll","Centrifugal","Screw","Reciprocating"]
#    mua_cooling_types = ["DX","Hydronic"]
#    heating_coil_types_sys3 = ["Electric", "Gas", "DX"]
#    heating_coil_types_sys4and6 = ["Electric", "Gas"]
#    fan_types = ["AF_or_BI_rdg_fancurve","AF_or_BI_inletvanes","fc_inletvanes","var_speed_drive"]
#    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
#    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
#    BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys1( model, model.getThermalZones, boiler_fueltype, mau, mau_heating_coil_type, baseboard_type )
#    run_the_measure(model)
#    BTAP::FileIO::save_osm(model, "#{File.dirname(__FILE__)}/system_1.osm")
#  end
#  
#  def test_system_2()
#    boiler_fueltypes = ["NaturalGas","Electricity","PropaneGas","FuelOil#1","FuelOil#2","Coal","Diesel","Gasoline","OtherFuel1"]
#    mau_types = [true, false]
#    mau_heating_coil_types = ["Hot Water", "Electric"]
#    baseboard_types = ["Hot Water" , "Electric"]
#    chiller_types = ["Scroll","Centrifugal","Screw","Reciprocating"]
#    mua_cooling_types = ["DX","Hydronic"]
#    heating_coil_types_sys3 = ["Electric", "Gas", "DX"]
#    heating_coil_types_sys4and6 = ["Electric", "Gas"]
#    fan_types = ["AF_or_BI_rdg_fancurve","AF_or_BI_inletvanes","fc_inletvanes","var_speed_drive"]
#    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
#    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
#    BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys2(model, model.getThermalZones, boiler_fueltype, chiller_type, mua_cooling_type)
#    run_the_measure(model)
#    BTAP::FileIO::save_osm(model, "#{File.dirname(__FILE__)}/system_2.osm")
#  end
#  
#  def test_system_3()
#    boiler_fueltypes = ["NaturalGas","Electricity","PropaneGas","FuelOil#1","FuelOil#2","Coal","Diesel","Gasoline","OtherFuel1"]
#    mau_types = [true, false]
#    mau_heating_coil_types = ["Hot Water", "Electric"]
#    baseboard_types = ["Hot Water" , "Electric"]
#    chiller_types = ["Scroll","Centrifugal","Screw","Reciprocating"]
#    mua_cooling_types = ["DX","Hydronic"]
#    heating_coil_types_sys3 = ["Electric", "Gas", "DX"]
#    heating_coil_types_sys4and6 = ["Electric", "Gas"]
#    fan_types = ["AF_or_BI_rdg_fancurve","AF_or_BI_inletvanes","fc_inletvanes","var_speed_drive"]
#    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
#    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
#    BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys3(model, model.getThermalZones, boiler_fueltype, heating_coil_type, baseboard_type)
#    run_the_measure(model)
#    BTAP::FileIO::save_osm(model, "#{File.dirname(__FILE__)}/system_3.osm")
#  end
  
  def test_system_4()
    boiler_fueltypes = ["NaturalGas","Electricity","PropaneGas","FuelOil#1","FuelOil#2","Coal","Diesel","Gasoline","OtherFuel1"]
    mau_types = [true, false]
    mau_heating_coil_types = ["Hot Water", "Electric"]
    baseboard_types = ["Hot Water" , "Electric"]
    chiller_types = ["Scroll","Centrifugal","Screw","Reciprocating"]
    mua_cooling_types = ["DX","Hydronic"]
    heating_coil_types_sys3 = ["Electric", "Gas", "DX"]
    heating_coil_types_sys4and6 = ["Electric", "Gas"]
    fan_types = ["AF_or_BI_rdg_fancurve","AF_or_BI_inletvanes","fc_inletvanes","var_speed_drive"]
    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
    BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys4(model, model.getThermalZones, 'NaturalGas', 'Electric', 'Electric')
    run_the_measure(model)
    BTAP::FileIO::save_osm(model, "#{File.dirname(__FILE__)}/system_4.osm")
  end
#  
#  def test_system_5()
#    boiler_fueltypes = ["NaturalGas","Electricity","PropaneGas","FuelOil#1","FuelOil#2","Coal","Diesel","Gasoline","OtherFuel1"]
#    mau_types = [true, false]
#    mau_heating_coil_types = ["Hot Water", "Electric"]
#    baseboard_types = ["Hot Water" , "Electric"]
#    chiller_types = ["Scroll","Centrifugal","Screw","Reciprocating"]
#    mua_cooling_types = ["DX","Hydronic"]
#    heating_coil_types_sys3 = ["Electric", "Gas", "DX"]
#    heating_coil_types_sys4and6 = ["Electric", "Gas"]
#    fan_types = ["AF_or_BI_rdg_fancurve","AF_or_BI_inletvanes","fc_inletvanes","var_speed_drive"]
#    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
#    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
#    BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys5(model, model.getThermalZones, boiler_fueltype, chiller_type, mua_cooling_type)
#    run_the_measure(model)
#    BTAP::FileIO::save_osm(model, "#{File.dirname(__FILE__)}/system_5.osm")
#  end
#  
#  def test_system_6()
#    boiler_fueltypes = ["NaturalGas","Electricity","PropaneGas","FuelOil#1","FuelOil#2","Coal","Diesel","Gasoline","OtherFuel1"]
#    mau_types = [true, false]
#    mau_heating_coil_types = ["Hot Water", "Electric"]
#    baseboard_types = ["Hot Water" , "Electric"]
#    chiller_types = ["Scroll","Centrifugal","Screw","Reciprocating"]
#    mua_cooling_types = ["DX","Hydronic"]
#    heating_coil_types_sys3 = ["Electric", "Gas", "DX"]
#    heating_coil_types_sys4and6 = ["Electric", "Gas"]
#    fan_types = ["AF_or_BI_rdg_fancurve","AF_or_BI_inletvanes","fc_inletvanes","var_speed_drive"]
#    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
#    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
#    BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys6(model, model.getThermalZones, boiler_fueltype, heating_coil_type, baseboard_type, chiller_type, fan_type)
#    run_the_measure(model)
#    BTAP::FileIO::save_osm(model, "#{File.dirname(__FILE__)}/system_6.osm")
#  end
#  
#  def test_system_7()
#    boiler_fueltypes = ["NaturalGas","Electricity","PropaneGas","FuelOil#1","FuelOil#2","Coal","Diesel","Gasoline","OtherFuel1"]
#    mau_types = [true, false]
#    mau_heating_coil_types = ["Hot Water", "Electric"]
#    baseboard_types = ["Hot Water" , "Electric"]
#    chiller_types = ["Scroll","Centrifugal","Screw","Reciprocating"]
#    mua_cooling_types = ["DX","Hydronic"]
#    heating_coil_types_sys3 = ["Electric", "Gas", "DX"]
#    heating_coil_types_sys4and6 = ["Electric", "Gas"]
#    fan_types = ["AF_or_BI_rdg_fancurve","AF_or_BI_inletvanes","fc_inletvanes","var_speed_drive"]
#    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
#    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
#    BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys7(model, model.getThermalZones, boiler_fueltype, chiller_type, mua_cooling_type)
#    run_the_measure(model)
#    BTAP::FileIO::save_osm(model, "#{File.dirname(__FILE__)}/system_7.osm")
#  end
#  

  def run_the_measure(model)   
    # create an instance of the measure, a runner and an empty model
    measure = CanadianAddUnitaryAndApplyStandard.new
    runner = OpenStudio::Ruleset::OSRunner.new

    #might need arg variables but they are empty. 
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(OpenStudio::Ruleset::OSArgumentVector.new())

    # run the measure
    measure.run(model, runner, argument_map)
    #return condition of measure.
    assert_equal("Success", runner.result.value.valueName)
  end 
end
