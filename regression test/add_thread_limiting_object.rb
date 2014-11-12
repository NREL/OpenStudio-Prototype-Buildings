# This script adds the ProgramControl object to the
# legacy Prototype Building IDF files so that each simulation
# is limited to a single thread.  This improves simulation speed.

################################################################################

require 'find'

# Find all IDF files in the legacy prototype idf files directory,
# load the file, and add the ProgramControl object.
idf_dirs = ["#{Dir.pwd}/legacy reference idf files", "#{Dir.pwd}/legacy prototype idf files"]

idf_dirs.each do |idf_dir|
  Find.find(idf_dir) do |path|
    if path =~ /.*\.idf/i
      puts "Editing IDF File = #{path}"

      File.open(path, 'a') do |file|  
        file.puts "ProgramControl, 1 ;        !- Number of Threads Allowed" 
      end
      
    end
  end
end

puts "Finished adding thread limiting requests to IDF files."
