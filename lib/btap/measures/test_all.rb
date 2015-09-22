# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.
t1 = Time.now
require "#{File.dirname(__FILE__)}/apply_system1/test/CanadianAddUnitaryAndApplyStandard_test.rb"
require "#{File.dirname(__FILE__)}/btap_equest_converter/test/btap_equest_converter_test.rb"
require "#{File.dirname(__FILE__)}/btap_change_building_location/test/btap_change_location_test.rb"
require "#{File.dirname(__FILE__)}/btap_set_default_construction_set/tests/set_default_construction_set_test.rb"
require "#{File.dirname(__FILE__)}/btap_replace_model/tests/replacemodel_test.rb"
require "#{File.dirname(__FILE__)}/UtilityTariffs/tests/UtilityTariffs_Test.rb"
puts "#{(Time.now - t1)/60} minutes"



