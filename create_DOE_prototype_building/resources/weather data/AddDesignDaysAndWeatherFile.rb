def add_design_days_and_weather_file(model)
# def add_design_days_and_weather_file(params)
    
  # zip_code = params["zip_code"]  
  
  # #first, connect to your local BCL library
  # #this is where things that are downloaded get stored
  # library = OpenStudio::LocalBCL::instance()

  # #throw error if no BCL authentication key exists
  # raise "BCL authentication required" if (library::prodAuthKey().empty?)

  # #get the weather file from the remote BCL
  # remote = OpenStudio::RemoteBCL.new
  
  # #search for weather files
  # responses = remote.searchComponentLibrary("location:#{zip_code}", "Weather File")
  # raise "No results" if (responses.size() < 1)

  # #download first result (closest location to this zip code)
  # remote.downloadComponent(responses[0].uid)
  # component = remote.waitForComponentDownload()

  # #grab this component from the local BCL library after download  
  # raise "Cannot find local component" if component.empty?
  # component = component.get
    
  # #get epw file path
  # files = component.files("epw")
  # raise "No epw file found" if files.empty?
  # epw_path = component.files("epw")[0]

  # #attach the weather file to the model
  # epw_file = OpenStudio::EpwFile.new(OpenStudio::system_complete(OpenStudio::Path.new(epw_path)))
  # OpenStudio::Model::WeatherFile::setWeatherFile(self, epw_file).get
  
  # #get the design daysfrom the remote BCL
  # remote = OpenStudio::RemoteBCL.new

  # #specify the design days we want
  # #in this case, using the 99% design conditions
  # dsn_day_searches = ["location:#{zip_code} Heating_99",
  #                     "location:#{zip_code} _Annual_Cooling_(DP_MDB)",
  #                     "location:#{zip_code} _Annual_Cooling_(DB_MWB)"]

  # dsn_day_searches.each do |dsn_day_search|               
  #   #search for the design day
  #   responses = remote.searchComponentLibrary(dsn_day_search, "Design Day")
  #   raise "No results" if (responses.size() < 1)

  #   #download first result (closest location to this zip code)
  #   remote.downloadComponent(responses[0].uid)
  #   component = remote.waitForComponentDownload()

  #   #grab this component from the local BCL library after download  
  #   raise "Cannot find local component" if component.empty?
  #   component = component.get
      
  #   #get design day
  #   files = component.files("osm")
  #   raise "No osm file found" if files.empty?
  #   osm_path = component.files("osm")[0]

    #make a version translator
    version_translator = OpenStudio::OSVersion::VersionTranslator.new()

    ddy_locations = Dir.glob("#{Dir.pwd}/*.ddy")
    ddy_path = nil
    if File.file?("#{ddy_locations[0]}")
      ddy_path = OpenStudio::Path.new("#{ddy_locations[0]}")
      @runner.registerInfo("Found weather file: '#{ddy_path}'")
      puts "Found weather file: '#{ddy_path}'"
    else
      @runner.registerError("Could not find weather file, sizing run not performed.")
      return false
    end
     
    #load the osm containing the design day files and clone into our model
    ddy_idf = OpenStudio::IdfFile.load(ddy_path)
    ddy_workspace = OpenStudio::Workspace.new(ddy_idf.get)
    reverse_translator = OpenStudio::EnergyPlus::ReverseTranslator.new
    ddy_model = reverse_translator.translateWorkspace(ddy_workspace)
    ddy_objects = []
    ddy_model.getDesignDays.each do |ddy_object|
      if ddy_object.name.get.include?(".4") || ddy_object.name.get.include?("99.6")
        ddy_objects << ddy_object
      end
    end
    model.addObjects(ddy_objects)

  # end

  return true

end
