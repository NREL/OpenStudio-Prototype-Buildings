
#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide
require 'fileutils'
require "date"
release_mode = false
folder = "#{File.dirname(__FILE__)}/../../../../lib/btap/lib/"

if release_mode == true
  #Copy BTAP files to measure from lib folder. Use this to create independant measure. 
  Dir.glob("#{folder}/**/*rb").each do |file|
    FileUtils.cp(file, File.dirname(__FILE__))
  end
  require "#{File.dirname(__FILE__)}/btap.rb"
else
  #For only when using git hub development environment.
  require "#{File.dirname(__FILE__)}/../../../../lib/btap/lib/btap.rb"
end





#start the measure
class ConvertDOEReferenceToNECBOSM < BTAP::Measures::OSMeasures::BTAPModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ConvertDOEReferenceToNECBOSM"
  end



  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    return args
  end #end the arguments method


  def measure_code(model,runner)
    #get idf files in measure
    BTAP::runner_register("INFO", "IDF folder is #{File.dirname(__FILE__)}", runner)
    idf_files = BTAP::FileIO::get_find_files_from_folder_by_extension("#{File.dirname(__FILE__)}", '.idf')
    
    #Note: place output folder locally to run faster! (e.g. your C drive)
    
    output_folder = "#{File.dirname(__FILE__)}/output"
    BTAP::runner_register("INFO", "IDF folder is #{output_folder}", runner)
    
    
    idf_files.each do |idf_filename|
      #Convert to osm and necb space types. 
      new_model = BTAP::Compliance::NECB2011::convert_idf_to_osm_and_map_doe_zones_to_necb_space_types(idf_filename)

      #Autozone and set to ideal airloads
      use_ideal_air_loads = true
      BTAP::Compliance::NECB2011::necb_autozone_and_autosystem( new_model ,use_ideal_air_loads,runner )
      file_path = "#{output_folder}/#{File.basename(idf_filename, ".rb")}.osm"
      BTAP::FileIO::save_osm(new_model, file_path)
      BTAP::runner_register("INFO", "IDF file converted to OSM #{file_path}", runner)
    end
  end
  
end #end the measure
#this allows the measure to be use by the application
ConvertDOEReferenceToNECBOSM.new.registerWithApplication