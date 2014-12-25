
require 'openstudio'
require_relative 'utilities'

model = safe_load_model('C:/GitRepos/OpenStudio-Prototype-Buildings/create_DOE_prototype_building/resources/prototype data/small_office_pret_1980_raw.osm')

model = strip_model(model)

new_path = OpenStudio::Path.new("#{Dir.pwd}/stripped_model.osm")

model.save(new_path, true)

puts "Stripped model was saved to #{new_path}"
