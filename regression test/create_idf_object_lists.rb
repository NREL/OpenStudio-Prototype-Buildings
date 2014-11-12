#Let Ruby know that we will be using some OpenStudio Ruby scripts
require 'openstudio'

#Open the model as an IDF
idf_paths = Array.new 

###############START USER INPUT############################

root_path = '/Users/m5z/Downloads/SchoolSecondary/'

Dir.glob(root_path + '*.idf') do |idf_file|
  idf_paths << idf_file
end

###############END USER INPUT############################


idf_paths.each do|idf_path|

  #load up the idf
  workspace = OpenStudio::IdfFile.load(OpenStudio::Path.new(idf_path))
  if workspace
    workspace = OpenStudio::Workspace.new(workspace.get)
  else
    puts "#{idf_path} not found"
  end

  
  #define a hash to count the workspace
  idd_objects_count = Hash.new(0)
  
  workspace.objects.each do |object|
    object_type_name = object.iddObject().name()   
    idd_objects_count[object_type_name] = idd_objects_count[object_type_name] + 1  
  end
  
  idd_objects_count = idd_objects_count.sort
  
  #puts idd_objects_count
  
  
  #creates a file to store the results
  results_file_path = "#{File.dirname(idf_path)}/#{File.basename(idf_path, '.idf')}_idd_objects_count.txt"
  #puts results_file_path
  
  File.open(results_file_path, 'w') do |file|
    idd_objects_count.each do |object_type,object_count|
      file.puts object_type.to_s + " ***** "+object_count.to_s
    end
  end
end

puts "The list of idf objects was created successfully."

