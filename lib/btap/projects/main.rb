# *********************************************************************
# *  Copyright (c) 2008-2015, Natural Resources Canada
# *  All rights reserved.
# *
# *  This library is free software; you can redistribute it and/or
# *  modify it under the terms of the GNU Lesser General Public
# *  License as published by the Free Software Foundation; either
# *  version 2.1 of the License, or (at your option) any later version.
# *
# *  This library is distributed in the hope that it will be useful,
# *  but WITHOUT ANY WARRANTY; without even the implied warranty of
# *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# *  Lesser General Public License for more details.
# *
# *  You should have received a copy of the GNU Lesser General Public
# *  License along with this library; if not, write to the Free Software
# *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
# **********************************************************************/

require "#{File.dirname(__FILE__)}/../lib/btap/"
idf_folder = "../lib/btap/resources/models/DOEArchetypes/Original/"
weather_file = "C:/projects/OpenStudio-analysis-spreadsheet\\weather\\CAN_AB_Calgary.718770_CWEC.epw"
construction_library_file = "C:\\projects\\OpenStudio-analysis-spreadsheet\\btap\\resources\\common\\BTAP_Construction_Library.osm"
example_file = "C:/projects/OpenStudio-analysis-spreadsheet/btap/resources/BasicFiles/5ZoneNoHVAC.osm"
construction_set_name = "DND-Concrete"
models = BTAP::Compliance::NECB2011::convert_all_doe_to_necb_reference_building(idf_folder)

#loads File. 
model = BTAP::FileIO::load_osm("C:/test/midelecbb.osm")
construct_model = BTAP::FileIO::load_osm("C:/test/midelecbb.osm")
@default_construction_set_name = "189.1-2009 - CZ7-8 - Office"
#Get construction set.. I/O expensive so doing it here.

vintage_construction_set = construct_model.getDefaultConstructionSetByName(@default_construction_set_name)
if vintage_construction_set.empty?
  raise("#{@default_construction_set_name} does not exist in  ")
else
  vintage_construction_set = construct_model.getDefaultConstructionSetByName(@default_construction_set_name).get
end

#remove all construction sets from surfaces. 
model.getSurfaces.each {|surface| surface.resetConstruction()}
#Set default const set
new_construction_set = vintage_construction_set.clone(model).to_DefaultConstructionSet.get
model.building.get.setDefaultConstructionSet( new_construction_set )

#set adiabatic surfaces to any construction. 
#Give adiabatic surfaces a construction. Does not matter what. This is a bug in Openstudio that leave these surfaces unassigned by the default construction set.
all_adiabatic_surfaces = BTAP::Geometry::Surfaces::filter_by_boundary_condition(model.getSurfaces, "Adiabatic")
unless all_adiabatic_surfaces.empty?
  BTAP::Geometry::Surfaces::set_surfaces_construction( all_adiabatic_surfaces, model.building.get.defaultConstructionSet.get.defaultInteriorSurfaceConstructions.get.wallConstruction.get)
end
BTAP::FileIO::save_osm(model , "C:/test/midelecbb_out.osm")
