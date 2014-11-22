# This script adds the sqlite request to all of the
# legacy Prototype Building IDF files so that results
# can be retrieved.

################################################################################

require 'find'

# Find all IDF files in the legacy prototype idf files directory,
# load the file, and add the sqlite results request.
Find.find("#{Dir.pwd}/legacy prototype idf files") do |path|
  if path =~ /.*\.idf/i

    text = File.read(path)
    next if text.include?("AllSummary,")
    if text.include?("AnnualBuildingUtilityPerformanceSummary,")
      puts "Editing IDF File = #{path}"
      text = text.gsub("AnnualBuildingUtilityPerformanceSummary,", "AllSummary,")
      File.open(path, 'w') do |file|
        file.puts text
      end
    end
      
  end
  
end

puts "Finished adding AllSummary requests to IDF files."
