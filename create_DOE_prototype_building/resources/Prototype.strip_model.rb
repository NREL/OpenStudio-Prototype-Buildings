require 'openstudio'
require_relative 'Prototype.utilities'

full_filename = "RefBldgSmallHotelPost1980_v1.4_7.2_3C_USA_CA_SAN_FRANCISCO.osm"

if full_filename && (File.file?(full_filename) || File.file?(File.join(Dir.pwd, full_filename)))
	model = safe_load_model(full_filename)

	model = strip_model(model)

	new_path = OpenStudio::Path.new("#{Dir.pwd}/stripped_model.osm")

	model.save(new_path, true)

	puts "Stripped model was saved to #{new_path}"
else
	puts "Pass a valid file path to this script"
end
