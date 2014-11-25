# This script adds the sqlite request to all of the
# legacy Prototype Building IDF files so that results
# can be retrieved.

################################################################################

require 'find'

# Find all IDF files in the legacy prototype idf files directory,
# load the file, and add the sqlite results request.
Find.find("#{Dir.pwd}/legacy prototype idf files") do |path|
  if path =~ /.*\.idf/i
    
    type = "service_water_heating"
    
    # "detailed"
    # "timestep"
    # "hourly"
    # "daily"
    # "monthly"
  
    vars = []
    case type
    when "service_water_heating"
      var_names << ["Water Heater Water Volume Flow Rate","timestep"]
      var_names << ["Water Use Equipment Hot Water Volume Flow Rate","timestep"]
      var_names << ["Water Use Equipment Cold Water Volume Flow Rate","timestep"]
      var_names << ["Water Use Equipment Hot Water Temperature","timestep"]
      var_names << ["Water Use Equipment Cold Water Temperature","timestep"]
      var_names << ["Water Use Equipment Mains Water Volume","timestep"]
      var_names << ["Water Use Equipment Target Water Temperature","timestep"]
      var_names << ["Water Use Equipment Mixed Water Temperature","timestep"]
      var_names << ["Water Heater Tank Temperature","timestep"]
      var_names << ["Water Heater Use Side Mass Flow Rate","timestep"]
      var_names << ["Water Heater Heating Rate","timestep"]
      var_names << ["Water Heater Water Volume Flow Rate","timestep"]
      var_names << ["Water Heater Water Volume","timestep"]
    end
  
    File.open(path, 'a') do |file|  
      var_names.each do |var_name, reporting_frequency|
        file.puts "Output:Variable,*,#{var_name},#{reporting_frequency};"
      end
    end

  end
end

puts "Finished adding debugging variables for #{type} to IDF files."
