# Andrew Parker
# NREL

# This script reads all of the schedule:compact objects out of the prototype
# buildings and converts them to OpenStudio::Model:::ScheduleRuleset objects

require 'openstudio'
require 'find'
require 'fileutils'
require_relative 'ScheduleTranslator'
require 'set'
require 'profile'

# Make the schedule library and pre-populate with
# schedule type limits.
sch_library_model = OpenStudio::Model::Model.new
sch_type_limits_map = {}

fraction_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(sch_library_model)
fraction_type_limits.setName("Fraction Sch Type Limits")
fraction_type_limits.setLowerLimitValue(0.0)
fraction_type_limits.setUpperLimitValue(1.0)
fraction_type_limits.setNumericType("Continuous")
fraction_type_limits.setUnitType("Dimensionless")
sch_type_limits_map["Fraction"] = fraction_type_limits

activity_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(sch_library_model)
activity_type_limits.setName("People Activity Sch Type Limits")
activity_type_limits.setLowerLimitValue(0.0)
activity_type_limits.setNumericType("Continuous")
activity_type_limits.setUnitType("ActivityLevel")
sch_type_limits_map["Activity"] = activity_type_limits

temp_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(sch_library_model)
temp_type_limits.setName("Temperature Sch Type Limits")
temp_type_limits.setLowerLimitValue(0.0)
temp_type_limits.setUpperLimitValue(100.0)
temp_type_limits.setNumericType("Continuous")
temp_type_limits.setUnitType("Temperature")
sch_type_limits_map["Temperature"] = temp_type_limits

on_off_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(sch_library_model)
on_off_type_limits.setName("On Off Operation Sch Type Limits")
on_off_type_limits.setLowerLimitValue(0)
on_off_type_limits.setUpperLimitValue(1)
on_off_type_limits.setNumericType("Discrete")
on_off_type_limits.setUnitType("Availability")
sch_type_limits_map["On Off Operation"] = on_off_type_limits

operation_mode_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(sch_library_model)
operation_mode_type_limits.setName("Control Mode Sch Type Limits")
operation_mode_type_limits.setLowerLimitValue(0)
operation_mode_type_limits.setUpperLimitValue(100)
operation_mode_type_limits.setNumericType("Discrete")
operation_mode_type_limits.setUnitType("ControlMode")
sch_type_limits_map["Control Mode"] = operation_mode_type_limits

temp_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(sch_library_model)
temp_type_limits.setName("Temperature Sch Type Limits")
temp_type_limits.setLowerLimitValue(0.0)
temp_type_limits.setUpperLimitValue(100.0)
temp_type_limits.setNumericType("Continuous")
temp_type_limits.setUnitType("Temperature")
sch_type_limits_map["Temperature"] = temp_type_limits

bldg_type_names = [
"ApartmentHighRise",
"ApartmentMidRise",
"Hospital",
"HotelLarge",
"HotelSmall",
"OfficeLarge",
"OfficeMedium",
"OfficeSmall",
"OutPatientHealthCare",
"RestaurantFastFood",
"RestaurantSitDown",
"RetailStandalone",
"RetailStripmall",
"SchoolPrimary",
"SchoolSecondary",
"Warehouse"
]

# Find all IDF files in the legacy prototype idf files directory,
# load the file to workspace.
i = 0
schedules_already_translated = Set.new
Find.find("#{Dir.pwd}/legacy prototype idf files") do |path|
  # Skip non-IDF files
  next unless path =~ /.*\.idf/i
  
  # Get the building type from the file name
  bldg_type = nil
  bldg_type_names.each do |bldg_type_name|
    if path.include?(bldg_type_name)
      bldg_type = bldg_type_name
    end
    break unless bldg_type.nil? 
  end  
  
  # Load the IDF file
  idf_path = OpenStudio::Path.new(path)
  idf_file = OpenStudio::IdfFile::load(idf_path)
  if idf_file.is_initialized   
    idf_file = idf_file.get
    puts ""
    puts "****Translating #{idf_path}"
  else
    puts "Skipping b/c unable to load the file #{idf_path}"
    next
  end
    
  # Loop through the schedules and translate them
  idf_file.getObjectsByType("Schedule:Compact".to_IddObjectType).each do |object|
    sch_name = object.getString(0).get
    sch_name = "#{bldg_type} #{sch_name}"
    #puts "Translating #{sch_name}"
    # Skip schedules that have already been translated,
    # assuming schedules with same names will be identical
    # over vintages and climate zones within a building type
    # next if schedules_already_translated.include?(sch_name)
    #if schedules_already_translated.bsearch {|x| x == sch_name }.nil?
    next if schedules_already_translated.include?(sch_name) 
    
    sch_translator = ScheduleTranslator.new(sch_library_model, object, sch_type_limits_map, bldg_type)
    os_sch = sch_translator.translate
    #puts os_sch
    
    # Record that this schedule has been translated already
    schedules_already_translated.add(sch_name)

  end

end

sch_library_model_path = "Prototype_Schedule_Library"
sch_library_model.save(OpenStudio::Path.new("#{Dir.pwd}/#{sch_library_model_path}.osm"), true)
