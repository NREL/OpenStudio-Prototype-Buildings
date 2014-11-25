# This script adds the sqlite request to all of the
# legacy Prototype Building IDF files so that results
# can be retrieved.

################################################################################

require 'find'

# Find all IDF files in the legacy prototype idf files directory,
# load the file, and add the sqlite results request.
materials = []
Find.find("#{Dir.pwd}/legacy prototype idf files") do |path|
  if path =~ /.*\.idf/i
  #if path =~ /OfficeSmall/i
  
    text = File.read(path)
    schs = text.scan(/Material,.*$\s.*,/)
    next if schs.size == 0
    materials += schs

    schs = text.scan(/Material:NoMass,.*$\s.*,/)
    next if schs.size == 0
    materials += schs
    
  #end
  end
  
end

puts materials.size
puts materials.uniq.size

clean_materials = []
materials.uniq.each do |sch|
  clean_sch = sch.gsub(/Material:NoMass,/,'')
  clean_sch = sch.gsub(/Material,/,'')
  clean_sch = clean_sch.gsub(',','')
  clean_sch = clean_sch.gsub(/\s/,'')
  clean_sch = clean_sch.upcase
  clean_materials << clean_sch
end

puts "***"
puts clean_materials.uniq.size
puts clean_materials.uniq.sort
 

