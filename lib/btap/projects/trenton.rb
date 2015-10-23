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
# To change this template, choose Tools | Templates
# and open the template in the editor.
require 'btap/btap'
require 'spreadsheet'

#set spreadsheet encoding to utf-8
Spreadsheet.client_encoding = 'UTF-8'
#open Trenton Data sheet. 
trenton_book = Spreadsheet.open '/path/to/an/excel-file.xls'
baseline_sheet = Book.worksheet 'Trenton Archetype Baseline'
baseline_space_exceptions_sheet = Book.worksheet 'Trenton Archetype System Exceptions'




model = OpenStudio::Model::Model.new()

#------------------------------Trenton Envelope Data----------------------------------------------------------------------------------------------------------------------------

#Opaque Materials
#Resources::Envelope::Materials::Opaque::create_opaque_material(model, name, thickness, conductivity, density, specific_heat, roughness, thermal_absorptance, solar_absorptance, visible_absorptance)
gypsum_board_17 =     BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Gypsum Board 17mm",    0.01716024,   0.16026282,   800,	1088.568  )
gypsum_board_12 =     BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Gypsum Board 12mm",    0.01271016,   0.16026282,   800,	1088.568  )
mineral_fiber =       BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Mineral Fiber",        0.3048,       0.043319421,	9.6,	711.756  )
plywood_13 =          BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Plywood 13mm",         0.012701016,	0.11630304,   544,	1214.172  )
plywood_19 =          BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Plywood 19mm",         0.01905,      0.11630304,   544,	1214.172  )
metal_deck =          BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Metal Deck",           0.00149352,   62.703261,    7824,	502.416  )
polystyrene =         BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Polystyrene",          0.3048,       0.028845001,	28.8,	1214.172  )
built_up_roof =       BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Build-up Roof",        0.009525,     0.16389729,   1120,	1465.38 )
gravel_51 =           BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Gravel 50mm",          0.0509016,    1.80269712,   1600,	837.36  )
generic_brick =       BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Brick face 100mm" ,    0.1016,       1.311136364,	2080,	795.492 )
concrete_50 =         BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Concrete 50mm",        0.0508,       1.8016587,    2240,	837.36  )
concrete_100 =        BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Concrete 100mm",       0.1014984,    1.8016587,    2240,	837.36  )
acoustic_tile =       BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "Acoutic Tile",         0.019100,     0.060000,   368.0,	837.36  )
internal_wall_mat =   BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "internal_wall_mat",    0.152,        0.6375,     1329.5,	837.0   )#from eQuest
internal_floor_mat =  BTAP::Resources::Envelope::Materials::Opaque::create_opaque_material(model, "internal_floor_mat",   0.152,        1.7296,     2242.6,	837.0   ) #from eQuest

#Glazing Materials
#shgc  = 0.10 ,ufactor = 0.10,thickness = 0.005,visible_transmittance = 0.8
simple_glazing = BTAP::Resources::Envelope::Materials::Fenestration::create_simple_glazing(model,"simple glazing",0.10 ,0.10,0.005,0.8)


#All Constructions
#Resources::Envelope::Constructions::create_construction(model, name, materials, insulationLayer)
roof_type1 =    BTAP::Resources::Envelope::Constructions::create_construction( model, "Roof1",        [mineral_fiber ,gypsum_board_17],                     mineral_fiber )
metal_roof =    BTAP::Resources::Envelope::Constructions::create_construction( model, "Roof2",        [plywood_13,mineral_fiber ,gypsum_board_17],          mineral_fiber)
deck_roof=     BTAP::Resources::Envelope::Constructions::create_construction( model,  "Roof3",        [gravel_51,built_up_roof,polystyrene,metal_deck],     polystyrene)
brick_wall =    BTAP::Resources::Envelope::Constructions::create_construction( model, "BrickWall",    [generic_brick,polystyrene,gypsum_board_17],polystyrene)
metal_wall =    BTAP::Resources::Envelope::Constructions::create_construction( model, "MetalWall",    [plywood_13,polystyrene,gypsum_board_17],   polystyrene)
conc_wall =     BTAP::Resources::Envelope::Constructions::create_construction( model, "ConcWall",    [concrete_100,polystyrene,gypsum_board_17], polystyrene)
floating_floor =Resources::Envelope::Constructions::create_construction( model, "Floor1",       [gypsum_board_12,mineral_fiber ,plywood_19],          mineral_fiber)
floor_type2 =   BTAP::Resources::Envelope::Constructions::create_construction( model, "Floor2",       [gypsum_board_12,polystyrene,concrete_50],            polystyrene)
ugwall       =  BTAP::Resources::Envelope::Constructions::create_construction( model, "UGWall1",      [polystyrene,concrete_100],                           polystyrene)
ugfloor      =  BTAP::Resources::Envelope::Constructions::create_construction( model, "UGFloor1",     [polystyrene,concrete_100],                           polystyrene)
internal_wall = BTAP::Resources::Envelope::Constructions::create_construction( model,"int_wall",      [internal_wall_mat])
internal_floor= BTAP::Resources::Envelope::Constructions::create_construction( model,"int_floor",     [internal_floor_mat])
window        = BTAP::Resources::Envelope::Constructions::create_construction( model,"simple_window", [simple_glazing])


#Construction Default Groups
#Resources::Envelope::ConstructionSets::create_default_surface_constructions(model, name, wall, floor, roof)
metal_exterior_default_construction =     BTAP::Resources::Envelope::ConstructionSets::create_default_surface_constructions(model, "metal_ext_construction", metal_wall, floating_floor, metal_roof)
concrete_exterior_default_construction =  BTAP::Resources::Envelope::ConstructionSets::create_default_surface_constructions(model, "conc_ext_construction", conc_wall, floating_floor, deck_roof)
ground_default_construction =             BTAP::Resources::Envelope::ConstructionSets::create_default_surface_constructions(model, "ground_ext_construction", ugwall, ugfloor, ugfloor)
interior_default_construction =           BTAP::Resources::Envelope::ConstructionSets::create_default_surface_constructions(model, "interior_construction", internal_wall, internal_floor, internal_floor)
#Resources::Envelope::ConstructionSets::create_subsurface_construction_set(model, fixedWindowConstruction, operableWindowConstruction, setDoorConstruction, setGlassDoorConstruction, overheadDoorConstruction, skylightConstruction, tubularDaylightDomeConstruction, tubularDaylightDiffuserConstruction)
sub_surface_default_construction = BTAP::Resources::Envelope::ConstructionSets::create_subsurface_construction_set(model, window, window, window, window, window, window, window, window)

#Constructions Whole Building sets.
#Resources::Envelope::ConstructionSets::create_default_construction_set(model, name, exterior_construction_set, interior_construction_set, ground_construction_set, subsurface_exterior_construction_set, subsurface_interior_construction_set)
concrete_construction_set = BTAP::Resources::Envelope::ConstructionSets::create_default_construction_set(
  model, "concreate_default_set", concrete_exterior_default_construction, interior_default_construction, ground_default_construction, sub_surface_default_construction, sub_surface_default_construction)
#metal_construction_set = BTAP::Resources::Envelope::ConstructionSets::create_default_construction_set(model, "concreate_default_set", metal_exterior_construction_set, interior_construction_set, ground_construction_set, sub_surface_construction_set, sub_surface_construction_set)


glazing_rsi = [
  ["baseline",2.2,2.8,2.8,3.2]
]



ground_constructions_rsi =
  [
  ["baseline",1.8,1.8,1.8,1.8]
]

wall_conc_array_rsi =
  [
  ["Concrete_Wall_Baseline",  0.88, 1.40,	2.11,	2.82],
  ["Concrete_Wall_Retro1",    2.88, 2.72,	3.43,	4.14],
  ["Concrete_Wall_Retro2",    2.20, 2.72,	3.43,	4.14],
  ["Concrete_Wall_Retro3",    2.88, 2.72,	4.11,	5.64]
]
wall_metal_array_rsi =
  [
  ["Metal_Wall_Baseline",0.88	,1.4,	2.11,		2.82 ],
  ["Metal_Wall_Retro1",  2.88 ,3.4,	4.11,		4.82 ],
  ["Metal_Wall_Retro2",  2.20 ,"NA",	"NA",		"NA" ],
  ["Metal_Wall_Retro3",  2.88 ,"NA",	"NA",		"NA" ]
]

roof_deck_array_rsi =
  [
  ["Deck_Roof_Baseline",0.70	,	0.70,	1.76,3.52	],
  ["Deck_Roof_Retro1",  3.34  ,	3.34,	3.52,5.28	],
  ["Deck_Roof_Retro2",  4.57  ,	4.57,	5.63,7.39	],
  ["Deck_Roof_Retro3",  5.28  ,	3.34,	5.63,"NA"	]
]

roof_metal_array_rsi =
  [
  ["Metal_Roof_Baseline",0.70	,	1.05,	2.81,3.51	],
  ["Metal_Roof_Retro1",  3.34 ,	3.69,	5.45,5.27	],
  ["Metal_Roof_Retro2",  4.40 ,	4.75,	4.21,4.91	],
  ["Metal_Roof_Retro3",  4.57 ,	4.92,	5.97,"NA"	]
]

concrete_building_envelope = [wall_conc_array_rsi,roof_deck_array_rsi]

metal_building_envelope = [wall_conc_array_rsi , roof_deck_array_rsi]



#infilitration rates L/s/m2
infiltration_rates = [
  ["Training Bldgs",                 0.70, 0.50, 0.35, 0.20],
  ["Warehouses (Sheds)",             0.80, 0.75, 0.45, 0.30],
  ["Recreational / Club Bldgs",      0.70, 0.50, 0.35, 0.20],
  ["Storage Bldgs",                  0.70, 0.50, 0.35, 0.20],
  ["Workshops",                      0.80, 0.75 ,0.45, 0.30],
  ["Communications & Control",       0.70, 0.50, 0.35, 0.20],
  ["Misc. Bldgs < 100m2",            0.70, 0.50, 0.35, 0.20],
  ["Hangars",                        0.80, 0.75, 0.45, 0.30],
  ["Air Terminal",                   0.70, 0.50, 0.35, 0.20],
  ["Training Bldgs",                 0.70, 0.50, 0.35, 0.20],
  ["Warehouses (Storage Bldgs)",     0.80, 0.75, 0.45, 0.30],
  ["Motel Type Residences",          0.70, 0.50, 0.35, 0.20],
  ["University Dormitory Type",      0.70, 0.50, 0.35, 0.20],
  ["Sleeping barracks",              0.70, 0.50, 0.35, 0.20],
  ["Fitness & Rec. - Multi-gym",     0.70, 0.50, 0.35, 0.20],
  ["Fitness & Rec. - Arena",	       0.70, 0.50, 0.35, 0.20],
  ["Fitness & Rec. - Pool",	         0.70, 0.50, 0.35, 0.20],
  ["Offices",                        0.70, 0.50, 0.35, 0.20],
  ["Food Services",                  0.70, 0.50, 0.35, 0.20],
  ["Infrastructure",                 0.80, 0.75, 0.45, 0.30],
  ["Workshops",                      0.80, 0.75, 0.45, 0.30],
  ["Medical Facilities",             0.70, 0.50, 0.35, 0.20],
  ["Retail Bldgs",                   0.70, 0.50, 0.35, 0.20],
  ["Religious Bldgs",                0.70, 0.50, 0.35, 0.20],
  ["Control Tower"  ,                0.70, 0.50, 0.35, 0.20],
  ["Fire Hall",                      0.80, 0.75, 0.45, 0.30],
  ["Museum",                         0.70, 0.50, 0.35, 0.20]
]






#Temperature Schedules
sample_schedule = BTAP::Resources::Schedules::create_annual_ruleset_schedule_detailed(model, "My Schedule", "TEMPERATURE", 
  [ [
      ["Jan-01","May-31"], # Date Period
      ["M","T","W","TH","F","S","SN","Wkd","Wke","All"], #days of the week
      [ [ "9:00",  13.0 ], [ "17:00", 21.0 ], [ "24:00", 13.0 ]]],
    #hours of the day and values.
    [["Jun-01","Dec-31"],# Date Period.
      ["M","T","W","TH","F","S","SN","Wkd","Wke","All"],
      [ [ "9:00",  13.0 ], [ "17:00", 21.0 ], [ "24:00", 13.0 ]]]
  ])







#-----------------------Trenton General Building Data


puts Dir.getwd()
start = Time.now
#load files into memory.

model_folder = "C:/OSRuby/Resources/DND/Trenton/models/"
bldg19 = bldg56 = bldg58 = bldg111 = bldg113 = bldg119 = bldg120 = bldg155 = bldg231 = bldg239 = bldg260 = bldg358 = bldg362 = bldg404 = bldg405 = bldg424 = ""
bldg19 = BTAP::FileIO::load_osm(model_folder + "Bldg19.osm", "Bldg19")
#puts bldg19.building.get.getAttribute("name")
#bldg56 = BTAP::FileIO::load_osm(model_folder + "Bldg56.osm", "Bldg56")
#bldg58 = BTAP::FileIO::load_osm(model_folder + "Bldg58.osm", "Bldg58")
#bldg111 = BTAP::FileIO::load_osm(model_folder + "Bldg111.osm", "Bldg111")
#bldg113 = BTAP::FileIO::load_osm(model_folder + "Bldg113.osm", "Bldg113")
#bldg119 = BTAP::FileIO::load_osm(model_folder + "Bldg119.osm", "Bldg119")
#bldg120 = BTAP::FileIO::load_osm(model_folder + "Bldg120.osm", "Bldg120")
#bldg155 = BTAP::FileIO::load_osm(model_folder + "Bldg155.osm", "Bldg155")
#bldg231 = BTAP::FileIO::load_osm(model_folder + "Bldg231.osm", "Bldg231")
#bldg239 = BTAP::FileIO::load_osm(model_folder + "Bldg239.osm", "Bldg239")
#bldg260 = BTAP::FileIO::load_osm(model_folder + "Bldg260.osm", "Bldg260")
#bldg358 = BTAP::FileIO::load_osm(model_folder + "Bldg358.osm", "Bldg358")
#bldg362 = BTAP::FileIO::load_osm(model_folder + "Bldg362.osm", "Bldg362")
#bldg404 = BTAP::FileIO::load_osm(model_folder + "Bldg404.osm", "Bldg404")
#bldg405 = BTAP::FileIO::load_osm(model_folder + "Bldg405.osm", "Bldg405")
#bldg424 = BTAP::FileIO::load_osm(model_folder + "Bldg424.osm", "Bldg424")
puts (Time.now - start).to_s
all_buildings = [
  [bldg19,"Hangars"],
  #  [bldg56,"Hangars"],
  #  [bldg58,"Hangars"],
  #  [bldg111,"Hangars"],
  #  [bldg113,"Hangars"],
  #  [bldg119,"Hangars"],
  #  [bldg120,"Hangars"],
  #  [bldg155,"Hangars"],
  #  [bldg231,"Hangars"],
  #  [bldg239,"Hangars"],
  #  [bldg260,"Hangars"],
  #  [bldg358,"Hangars"],
  #  [bldg362,"Hangars"],
  #  [bldg404,"Hangars"],
  #  [bldg405,"Hangars"],
  #  [bldg424,"Hangars"]
]

trenton_library = model

#create vintage envelope baseline and retrofits

results_table = Array.new()
all_buildings.each do |archetype|
  archetype_model = archetype[0]
  building_type = archetype[1]
  counter = 0
  [1].each do |vintage|

    [concrete_building_envelope,metal_building_envelope].each do |envelope|
      wall = envelope[0]
      roof = envelope[1]
      wall.each do |wall_row|
        roof.each do |roof_row|
          wall_name = wall_row[0]
          roof_name = roof_row[0]
          wall_vintage_rsi = wall_row[vintage]
          roof_vintage_rsi = roof_row[vintage]
          vintage_name = "vintage_#{vintage}"
          #skip run if any of the RSIs are "NA"
          next if "NA" == wall_vintage_rsi  or "NA" == roof_vintage_rsi
          construction_name = "#{vintage_name}-wall-#{wall_name}-roof-#{roof_name}"
          
          BTAP::Resources::Envelope::ConstructionSets::customize_default_surface_constructions_rsi(model,construction_name,concrete_exterior_default_construction,wall_vintage_rsi, nil, roof_vintage_rsi )

        end
      end
      #Get Default Concrete contruction set.
    end
  end
end




