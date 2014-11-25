# This script adds the sqlite request to all of the
# legacy Prototype Building IDF files so that results
# can be retrieved.

################################################################################

require 'find'

# Find all IDF files in the legacy prototype idf files directory,
# load the file, and add the sqlite results request.
schedules = []
Find.find("#{Dir.pwd}/legacy prototype idf files") do |path|
  if path =~ /.*\.idf/i
  if path =~ /OfficeSmall/i
  
    text = File.read(path)
    schs = text.scan(/Schedule:Compact,.*$\s.*,/)
    next if schs.size == 0
    
    schedules += schs
    
  end
  end
  
end

puts schedules.size
puts schedules.uniq.size

clean_schedules = []
schedules.uniq.each do |sch|
  clean_sch = sch.gsub(/Schedule:Compact,\s*/,'')
  clean_sch = clean_sch.gsub(',','')
  clean_sch = clean_sch.upcase
  clean_schedules << clean_sch
end

puts "***"
puts clean_schedules.uniq.size
puts clean_schedules.uniq.sort
 

