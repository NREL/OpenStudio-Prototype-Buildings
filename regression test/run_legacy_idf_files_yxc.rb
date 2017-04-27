bldg_type = ARGV[0]
vintage = ARGV[1]
climate_zone = ARGV[2]

require 'find'
require 'fileutils'

# Make the folder to store results, if it doesn't exist yet
regression_dir = "C:/Sites/OpenStudio-Prototype-Buildings/regression test/regression runs"
if !Dir.exists?(regression_dir)
  Dir.mkdir regression_dir
end

# Find EnergyPlus
# 7.2 for the Reference Buildings
EP_72_PATH = "C:/EnergyPlusV7-2-0/EnergyPlus.exe"
IDD_72_PATH =  "C:/EnergyPlusV7-2-0/Energy+.idd"

# 8.0 for the Prototype Buildings
EP_80_PATH = "C:/EnergyPlusV8-0-0/EnergyPlus.exe"
IDD_80_PATH = "C:/EnergyPlusV8-0-0/Energy+.idd"


puts "#{bldg_type}-#{vintage}-#{climate_zone}"

# Change the bldg_type based on the vintage since the naming
# conventions are different between Prototype and Reference buildings.
bldg_type_search = nil
if vintage == "Pre1980" || vintage == "Post1980" || vintage == "New2004"
  idf_file_path = "C:/Sites/OpenStudio-Prototype-Buildings/regression test/legacy reference idf files/"
  case bldg_type
    when "OfficeSmall" #1
      bldg_type_search = "SmallOffice"
    when "OfficeMedium" #2
      bldg_type_search = "MediumOffice"
    when "OfficeLarge" #3
      bldg_type_search = "LargeOffice"
    when "RetailStandalone" #4
      bldg_type_search = "Stand-aloneRetail"
    when "RetailStripmall" #5
      bldg_type_search = "StripMall"
    when "SchoolPrimary" #6
      bldg_type_search = "PrimarySchool"
    when "SchoolSecondary" #7
      bldg_type_search = "SecondarySchool"
    when "OutPatientHealthCare" #8
      bldg_type_search = "OutPatient"
    when "HotelSmall" #9
      bldg_type_search=  "SmallHotel"
    when "HotelLarge" #10
      bldg_type_search=  "LargeHotel"
    when "RestaurantFastFood" #11
      bldg_type_search=  "QuickServiceRestaurant"
    when "RestaurantSitDown" #12
      bldg_type_search=  "FullServiceRestaurant"
    when "ApartmentMidRise" #13
      bldg_type_search=  "MidriseApartment"
    else
      bldg_type_search = bldg_type  #14 Hospital #15 Warehouse
  end

  case climate_zone
    when "Memphis"
      climate_zone = "Atlanta"
    when "El Paso"
      climate_zone = "Las.Vegas"
    when "Salem"
      climate_zone = "Seattle"
    when "Boise"
      climate_zone = "Boulder"
    when "Burlington"
      climate_zone = "Minneapolis"
    when "San Francisco"
      climate_zone = "San.Francisco"
  end
else
  idf_file_path = "C:/Sites/OpenStudio-Prototype-Buildings/regression test/legacy prototype idf files/"
  case climate_zone
    when "El Paso"
      climate_zone = "El.Paso"
    when "San Francisco"
      climate_zone = "San.Francisco"
  end
  bldg_type_search = bldg_type
end

# Find the IDF file
# Prototype file naming convention = ASHRAE90.1_SchoolSecondary_STD2004_Fairbanks.idf
# Reference file naming convention = RefBldgSecondarySchoolPre1980_v1.4_7.2_8A_USA_AK_FAIRBANKS.idf
idf_file = nil
puts "IDF file path: " + idf_file_path
filenames = Dir.entries(idf_file_path).select {|f| !(File.directory? File.join(idf_file_path, f))}
filenames.each do |filename|
  path = idf_file_path + filename
  if path =~ /#{bldg_type_search}/i && path =~ /#{vintage}/i && path =~ /#{climate_zone}/i
    idf_file = path
    puts "  IDF File = #{path}"
    break
  end
end

if idf_file.nil?
  raise "  IDF File = IDF FILE NOT FOUND"
end

# Find the EPW file for this climate zone
epw_file = nil
weather_file_path = "C:/Sites/OpenStudio-Prototype-Buildings/regression test/weather files/"
filenames = Dir.entries(weather_file_path).select {|f| !(File.directory? File.join(weather_file_path, f))}
filenames.each do |filename|
  path = weather_file_path + filename
  if path =~ /#{climate_zone}/i && path =~ /epw/
    epw_file = path
    puts "  EPW File = #{path}"
    break
  end
end

if epw_file.nil?
  raise "  EPW File = EPW FILE NOT FOUND"
end

# Choose the correct version of EnergyPlus
ep_tool = nil
idd_path = nil
if vintage == "Pre1980" || vintage == "Post1980" ||  vintage == "New2004"
  ep_tool = EP_72_PATH
  idd_path = IDD_72_PATH
else
  ep_tool = EP_80_PATH
  idd_path = IDD_80_PATH
end

# Create the output path to store the results of the run
output_path_string = "C:/Sites/regression runs/#{bldg_type}.#{vintage}.#{climate_zone}"

if File.exist? output_path_string
  FileUtils.rm_rf output_path_string
  sleep(0.1)
end

Dir.mkdir(output_path_string)
FileUtils.cp idf_file,output_path_string+"/in.idf"
FileUtils.cp epw_file,output_path_string+"/in.epw"
FileUtils.cp idd_path,output_path_string+"/Energy+.idd"

Dir.chdir output_path_string

command = "#{ep_tool}"
system  command