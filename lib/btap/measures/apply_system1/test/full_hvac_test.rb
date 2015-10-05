require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'

require_relative '../measure.rb'

require 'fileutils'

require 'json'
require 'rubygems'

class CanadianAddUnitaryAndApplyStandardTest < MiniTest::Unit::TestCase
  PERFORM_STANDARDS = true
  FULL_SIMULATIONS = true

  def test_system_1()
    name = String.new
    output_folder = "#{File.dirname(__FILE__)}/output/system_1"
    FileUtils.rm_rf( output_folder )
    FileUtils::mkdir_p( output_folder )
    #all permutation and combinations. 
    boiler_fueltypes = ["NaturalGas","Electricity","FuelOil#2"]
    mau_types = [true, false]
    mau_heating_coil_types = ["Hot Water", "Electric"]
    baseboard_types = ["Hot Water" , "Electric"]
    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
    #interate through combinations. 
    boiler_fueltypes.each do |boiler_fueltype|
      baseboard_types.each do |baseboard_type|
        mau_types.each do |mau_type|
          if mau_type == true
            mau_heating_coil_types.each do |mau_heating_coil_type|
              name = "sys1_Boiler~#{boiler_fueltype}_Mau~#{mau_type}_MauCoil~#{mau_heating_coil_type}_Baseboard~#{baseboard_type}"
              BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys1(
                model, 
                model.getThermalZones, 
                boiler_fueltype, 
                mau_type, 
                mau_heating_coil_type, 
                baseboard_type)
              run_the_measure(model) 
              BTAP::FileIO::save_osm(model, "#{output_folder}/#{name}.osm")
            end
          else
            name =  "sys1_Boiler~#{boiler_fueltype}_Mau~#{mau_type}_MauCoil~None_Baseboard~#{baseboard_type}"
            BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys1(
              model, 
              model.getThermalZones, 
              boiler_fueltype, 
              mau_type, 
              "Electric", #value will not be used.  
              baseboard_type)
            runner = run_the_measure(model) 
            assert_equal("Success", runner.result.value.valueName,"Failure in Standards for #{name}")
            BTAP::FileIO::save_osm(model, "#{output_folder}/#{name}.osm")  
          end
        end
      end
    end
    if FULL_SIMULATIONS == true
      BTAP::SimManager::simulate_all_files_in_folder(output_folder) 
      BTAP::Reporting::get_all_annual_results_from_runmanger(output_folder) 
    end
  end
  

  def test_system_2()
    name = String.new
    output_folder = "#{File.dirname(__FILE__)}/output/system_2"
    FileUtils.rm_rf( output_folder )
    FileUtils::mkdir_p( output_folder )

    boiler_fueltypes = ["NaturalGas","Electricity","FuelOil#2",]
    chiller_types = ["Scroll","Centrifugal","Rotary Screw","Reciprocating"]
    mua_cooling_types = ["DX","Hydronic"]
    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
    boiler_fueltypes.each do |boiler_fueltype|
      chiller_types.each do |chiller_type|
        mua_cooling_types.each do |mua_cooling_type|
          name = "sys2_Boiler~#{boiler_fueltype}_Chiller#~#{chiller_type}_MuACoolingType~#{mua_cooling_type}"
          BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys2(
            model, 
            model.getThermalZones, 
            boiler_fueltype, 
            chiller_type, 
            mua_cooling_type)
          runner = run_the_measure(model) 
          assert_equal("Success", runner.result.value.valueName,"Failure in Standards for #{name}")
          BTAP::FileIO::save_osm(model, "#{output_folder}/#{name}.osm")
        end
      end
    end
    if FULL_SIMULATIONS == true
      BTAP::SimManager::simulate_all_files_in_folder(output_folder) 
      BTAP::Reporting::get_all_annual_results_from_runmanger(output_folder) 
    end
  end

  

  def test_system_3()
    name = String.new
    output_folder = "#{File.dirname(__FILE__)}/output/system_3"
    FileUtils.rm_rf( output_folder )
    FileUtils::mkdir_p( output_folder )
    boiler_fueltypes = ["NaturalGas","Electricity","FuelOil#2"]
    baseboard_types = ["Hot Water" , "Electric"]
    heating_coil_types_sys3 = ["Electric", "Gas", "DX"]

    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
    boiler_fueltypes.each do |boiler_fueltype|
      baseboard_types.each do |baseboard_type|
        heating_coil_types_sys3.each do |heating_coil_type_sys3|
          name = "sys3_Boiler~#{boiler_fueltype}_HeatingCoilType#~#{heating_coil_type_sys3}_BaseboardType~#{baseboard_type}"
          BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys3(
            model, 
            model.getThermalZones, 
            boiler_fueltype, 
            heating_coil_type_sys3, 
            baseboard_type)
          runner = run_the_measure(model) 
          assert_equal("Success", runner.result.value.valueName,"Failure in Standards for #{name}")
          BTAP::FileIO::save_osm(model, "#{output_folder}/.osm")
        end
      end
    end
    if FULL_SIMULATIONS == true
      BTAP::SimManager::simulate_all_files_in_folder(output_folder) 
      BTAP::Reporting::get_all_annual_results_from_runmanger(output_folder) 
    end
  end

  

  def test_system_4()
    name = String.new
    output_folder = "#{File.dirname(__FILE__)}/output/system_4"
    FileUtils.rm_rf( output_folder )
    FileUtils::mkdir_p( output_folder )
    boiler_fueltypes = ["NaturalGas","Electricity","FuelOil#2",]
    baseboard_types = ["Hot Water" , "Electric"]
    heating_coil_types_sys4 = ["Electric", "Gas"]
    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
    boiler_fueltypes.each do |boiler_fueltype|
      baseboard_types.each do |baseboard_type|
        heating_coil_types_sys4.each do |heating_coil|
          name = "sys4_Boiler~#{boiler_fueltype}_HeatingCoilType#~#{heating_coil}_BaseboardType~#{baseboard_type}"
          BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys4(
            model, 
            model.getThermalZones, 
            boiler_fueltype, 
            heating_coil, 
            baseboard_type)
          runner = run_the_measure(model) 
          assert_equal("Success", runner.result.value.valueName,"Failure in Standards for #{name}")
          BTAP::FileIO::save_osm(model, "#{output_folder}/#{name}.osm")
        end
      end
    end
    if FULL_SIMULATIONS == true
      BTAP::SimManager::simulate_all_files_in_folder(output_folder) 
      BTAP::Reporting::get_all_annual_results_from_runmanger(output_folder) 
    end
  end

  

  def test_system_5()
    name = String.new
    output_folder = "#{File.dirname(__FILE__)}/output/system_5"
    FileUtils.rm_rf( output_folder )
    FileUtils::mkdir_p( output_folder )
    boiler_fueltypes = ["NaturalGas","Electricity","FuelOil#2"]
    chiller_types = ["Scroll","Centrifugal","Rotary Screw","Reciprocating"]
    mua_cooling_types = ["DX","Hydronic"]
    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
    boiler_fueltypes.each do |boiler_fueltype|
      chiller_types.each do |chiller_type|
        mua_cooling_types.each do |mua_cooling_type|
          name = "sys5_Boiler~#{boiler_fueltype}_ChillerType~#{chiller_type}_MuaCoolingType~#{mua_cooling_type}"
          BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys5(
            model, 
            model.getThermalZones, 
            boiler_fueltype, 
            chiller_type, 
            mua_cooling_type)
          runner = run_the_measure(model) 
          assert_equal("Success", runner.result.value.valueName,"Failure in Standards for #{name}") 
          BTAP::FileIO::save_osm(model, "#{output_folder}/#{name}.osm")
        end
      end 
    end
    if FULL_SIMULATIONS == true
      BTAP::SimManager::simulate_all_files_in_folder(output_folder) 
      BTAP::Reporting::get_all_annual_results_from_runmanger(output_folder) 
    end
  end

  
  
  


  def test_system_6()
    name = String.new
    output_folder = "#{File.dirname(__FILE__)}/output/system_6"
    FileUtils.rm_rf( output_folder )
    FileUtils::mkdir_p( output_folder )
    boiler_fueltypes = ["NaturalGas","Electricity","FuelOil#2",]
    baseboard_types = ["Hot Water" , "Electric"]
    chiller_types = ["Scroll","Centrifugal","Rotary Screw","Reciprocating"]
    heating_coil_types_sys6 = ["Electric", "Hot Water"]
    fan_types = ["AF_or_BI_rdg_fancurve","AF_or_BI_inletvanes","fc_inletvanes","var_speed_drive"]
    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
    boiler_fueltypes.each do |boiler_fueltype|
      chiller_types.each do |chiller_type|
        baseboard_types.each do |baseboard_type|
          heating_coil_types_sys6.each do |heating_coil_type|
            fan_types.each do |fan_type|
              name = "sys5_Boiler~#{boiler_fueltype}_ChillerType~#{chiller_type}_BaseboardType~#{baseboard_type}_HeatingCoilType#~#{heating_coil_type}_FanType#{fan_type}"
              BTAP::runner_register("INFO", "Creating : sys5_Boiler~#{boiler_fueltype}_ChillerType~#{chiller_type}_BaseboardType~#{baseboard_type}_HeatingCoilType#~#{heating_coil_type}_FanType#{fan_type}")
              BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys6(
                model, 
                model.getThermalZones, 
                boiler_fueltype, 
                heating_coil_type, 
                baseboard_type, 
                chiller_type, 
                fan_type)
              runner = run_the_measure(model) 
              assert_equal("Success", runner.result.value.valueName,"Failure in Standards for #{name}")
              BTAP::FileIO::save_osm(model, "#{output_folder}/#{name}.osm")
            end
          end
        end
      end
    end
    if FULL_SIMULATIONS == true
      BTAP::SimManager::simulate_all_files_in_folder(output_folder) 
      BTAP::Reporting::get_all_annual_results_from_runmanger(output_folder) 
    end
  end



  def test_system_7()
    name = String.new
    output_folder = "#{File.dirname(__FILE__)}/output/system_7"
    FileUtils.rm_rf( output_folder )
    FileUtils::mkdir_p( output_folder )
    boiler_fueltypes = ["NaturalGas","Electricity","FuelOil#2"]
    chiller_types = ["Scroll","Centrifugal","Rotary Screw","Reciprocating"]
    mua_cooling_types = ["DX","Hydronic"]
    model = BTAP::FileIO::load_osm("#{File.dirname(__FILE__)}/5ZoneNoHVAC.osm")
    BTAP::Environment::WeatherFile.new("#{File.dirname(__FILE__)}/../../../weather/CAN_ON_Toronto.716240_CWEC.epw").set_weather_file(model)
    boiler_fueltypes.each do |boiler_fueltype|
      chiller_types.each do |chiller_type|
        mua_cooling_types.each do |mua_cooling_type|
          name = "sys7_Boiler~#{boiler_fueltype}_ChillerType~#{chiller_type}_MuaCoolingType~#{mua_cooling_type}"
          BTAP::Resources::HVAC::HVACTemplates::NECB2011::assign_zones_sys2(
            model, 
            model.getThermalZones, 
            boiler_fueltype, 
            chiller_type, 
            mua_cooling_type)
          runner = run_the_measure(model) 
          assert_equal("Success", runner.result.value.valueName,"Failure in Standards for #{name}")
          BTAP::FileIO::save_osm(model, "#{output_folder}/#{name}.osm")
        end
      end
    end
    if FULL_SIMULATIONS == true
      BTAP::SimManager::simulate_all_files_in_folder(output_folder) 
      BTAP::Reporting::get_all_annual_results_from_runmanger(output_folder) 
    end
  end


  def run_the_measure(model) 
    if PERFORM_STANDARDS
      # create an instance of the measure, a runner and an empty model
      measure = CanadianAddUnitaryAndApplyStandard.new
      runner = OpenStudio::Ruleset::OSRunner.new

      #might need arg variables but they are empty. 
      argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(OpenStudio::Ruleset::OSArgumentVector.new())

      # run the measure
      measure.run(model, runner, argument_map)
      #return condition of measure.
      
      
      return runner
    end 
  end
end

#def test_auto_zoner()
#  #try loading the file. 
#  BTAP::FileIO::get_find_files_from_folder_by_extension( "#{File.dirname(__FILE__)}/../../../weather/resources/models/DOEArchetypes/OSM_NECB_Space_Types", '.osm' ).each do |file|
#    model = BTAP::FileIO::load_osm( file )
#    #suto zone it and assign systems. 
#    BTAP::Compliance::NECB2011::necb_autozoner( model )
#    #save file under new name
#    new_file = "#{File.dirname(file)}/auto_zoned/#{File.basename(file,".osm")}.osm"
#    BTAP::FileIO::save_osm( model, new_file )
#  end
#end
