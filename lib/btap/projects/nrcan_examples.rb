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
require 'openstudio'
require 'openstudio/energyplus/find_energyplus'
require 'pathname'
require 'fileutils'
require 'rexml/document'
require 'singleton'
require 'weather_file'

require 'analysis'
require 'utilities'
class NRCanExamples


  def initialize()
# Before starting, I strongly suggest that you take the time to read the ruby in
# 20 minutes primer or something similar. Mixing programming and simulation can be
# very powerful and time saving, but you need to understand the basics of
# Object Oriented programming and the syntax of the Ruby language. That being
# said, Ruby is a nice, easy to learn language similar to Perl or Visual Basic.
# It is very popular in the web application development world. If you are new to
# Ruby programming, please look up Loops, Arrays, Scope Operators "::", modules
# classes.
#
# OpenStudio is built on a C++ base. It uses swig to expose the classes and methods
# from C++ to other languages such as Ruby.
#Procedural Modelling.
#****************Model Creations and environment****************************
#The first this you need to do is create a empty model. This object will contain
# all the data for your model.
#   model = OpenStudio::Model::new()
#
#*****************Constructions, Materials and Sets*****************************
#
#*****************Schedules, Loads and SpaceTypes*****************************
#
# ****************Geometry**************************************************
# Massing
# There are a few methods to add geometry (Surfaces and Spaces) to a model
# 1. Import an OSM file created in either in Sketchup, or gbxml/ifc imported into
# sketchup 
#   model = OpenStudio::Model::new()
#   model.load_osm("your_file.osm")
#
# 2. Import a eQuest file
#   doe = DOEBuilding.new()
#   doe.read_input_file("your_equest_file.inp")
#   model = doe.create_openstudio_model_new()
#
# 3. Use the geometry wizard methods
#   model = OpenStudio::Model::new()
#   BTAP::Geometry::self.create_shape_rectangle(model,
#      length = 100.0,
#      width = 100.0,
#      num_floors = 3,
#      floor_to_floor_height = 3.8,
#      plenum_height = 1,
#      perimeter_zone_depth = 4.57
#    )
#  
# Searching for Objects in the model
# You can search the model geometry to find items that you wish to operate on.
# There are high level methods that will find all the object of a specific
# openstudio type. For example to find all the BuildingStory objects in the
# model, use this method.
#   all_floors = model.getBuildingStorys()
# This will return an array of the buildingStory object. You can iterate through
# them and, for example print their names.
#    all_floors.each do |floor|
#      puts floor.name
#    end
# You can look up all the object names available here
# https://openstudio.nrel.gov/c-sdk-documentation/model-0
#
# There is another method that you can get a specific instance of an object by name.
# floor_2 = model.getBuildingStoryByName("Second_Floor")
#
# There are some customized classes that wrap some of this work for you in the
# Geometry class. Lets set the southern wall only on the 1st and 3rd floor to have a fwr
# of 50%.
#
# The BTAP::Geometry::get_all_surfaces_from_floors method will get from the "model"
# object an array of all the surfaces from the 1st and 3rd floor. We default to ruby counting
# convention of starting at zero. so "0" is the 1st floor.
#
#   floor1_and_3_surfaces = BTAP::Geometry::get_all_surfaces_from_floors(model,[0,2])
#
# You can then filter the surfaces based on the characteristics of the surface.
#   found_surfaces = filter_by_boundary_condition("Outdoors").filter_by_surface_types("Wall").filter_by_azimuth_and_tilt(180.0, 180.0, 90.0, 90.0,0.5)
# Now we can set these surfaces
#   found_surfaces.each do |surface|
#     surface.setWindowToWallRatio(ratio = 0.50, offset = 0.5 ,heightOffsetFromFloor = true)
#   end
# Please view the Geometry class for examples. You may add more geometric
# searching methods there as well that suit your needs.
#
#************************Constructions Sets**************************************
# You can create materials and construction programmatically, but in honesty, the
# easiest method is to use the OS model editor create a default set there and
# then import the set into our model programmatically. This methodology can be used not only with
# constructions but any OS command object. But for instruction purposes, we will
# create a basic opaque material and fenestration construction.
# ****Create Materials
# Ex: new_material = OpenStudio::Model::StandardOpaqueMaterial.new( model, "Smooth" , thickness, conductance , density, specific_heat ).setAttribute("name", name_of_material)
#   gypsum_board_12 = create_opaque_material(model, "MNECB Gypsum Board 12",	0.01271016,	0.16026282,	800,	1088.568)
#   air_space = OpenStudio::Model::AirGap.new(model,0.10000).setAttribute("name", "MNECB air space")
#   mineral_fiber = create_opaque_material(model, "MNECB Generic Mineral Fiber",	0.3048,	0.043319421,	9.6,	711.756)
#   concrete_100 = create_opaque_material(model, "MNECB Generic concrete",	0.1014984,	1.8016587,	2240,	837.36)
#
# ****Create Opaque Constructions
# Now that we have the material layers, lets create constructions. For simplicity sake we will assume all surface types have the same construction.
#   my_wall  = BTAP::Resources::create_opaque_construction(model, "My Fantastic Wall",[gypsum_board_12,air_space,mineral_fiber,concrete_100])
#   my_floor = BTAP::Resources::create_opaque_construction(model, "My Fantastic Floor",[gypsum_board_12,air_space,mineral_fiber,concrete_100])
#   my_roof  = BTAP::Resources::create_opaque_construction(model, "My Fantastic Roof",[gypsum_board_12,air_space,mineral_fiber,concrete_100])
#
# ****Create Opaque Construction Sets
# We now can create construction sets if we wish. This is a set of construction
# assigned to floors, roof, wall for each boundary condition domain (outdoors,
# ground, internal, and a special one for sub-surfaces). Once again, to simplify
# things for this example, lets assume we will be using the same construction set
# for the whole building.
#   exterior_construction_set = BTAP::Resources::create_construction_set( model, "my exterior constructions", my_wall, my_floor,my_roof )
#   interior_construction_set = BTAP::Resources::create_construction_set( model, "my interior constructions", my_wall, my_floor,my_roof )
#   ground_construction_set   = BTAP::Resources::create_construction_set( model, "my ground constructions", my_wall, my_floor,my_roof )
#
# ****Create
# ****Create Default Construction Set
# We now can create a complete default construction set.
#   full_construction_set = BTAP::Resources::create_default_construction_set(model, name, exterior_construction_set,interior_construction_set,ground_construction_set,subsurface_construction_set)





    #Example: Create a default example file. (Single zone model)
    model = OpenStudio::Model::exampleModel()

    #Clear Output Variables
    model.clear_output_variables()

    #Example Alternative: load a osm file.
    # original = OpenStudio::Model::new()
    # original.load_osm("your_file.osm")

    #Example: Purge unused building objects.
    model.purgeUnusedResourceObjects

    #Example: Assign Weather file to model.
    model.set_weather_file("C:\\EnergyPlusV7-2-0\\WeatherData\\USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw")

    #Example run elimination and parametric routines.
    #    a= Analysis.new
    #    a.full_analysis(model,"E:/test/")


    #Get possible Output variables
     model.get_possible_output_variables()
    

    #Example: make a copy of the building.
    copy = model.deep_copy

    #Example: Assigning a name to the building model and printing it out.
    copy.building.get.setAttribute("name","copy_of_original")

    #Example: alter the building copy.
    copy.remove_all_subsurfaces

    copy.set_ext_wall_fwr(0.10)

    copy.save(OpenStudio::Path.new(BTAP::TESTING_FOLDER + "/fwr.osm"))


    #Example: Set NECB 2011 constructions based on hdd = 4000
    copy.setNECB2011Envelope(4000)

    #Example: See your changes in a diff from the copy to the original osm.
    Utilities.kdiff3_model_osm(model, copy)

    #Example: See your changes in a diff from the copy to the original idf.
    Utilities.kdiff3_model_idf(model, copy)


    #Example: Perform a single run.
    #Create Run folder.
    Dir::mkdir("C:\\run_folder") unless File.exists?("C:\\run_folder")
    #Run simulation (Uncomment to run)
    model.run_simulation("C:\\run_folder")

    #Example: Perform a multi-run.
    #-Create RunManager
    process_manager = ProcessManager.new("C:\\multi_run_folder")
    #-Add Models
    process_manager.addModel(model)
    process_manager.addModel(copy)
    #-Start multicore simulation. (uncomment to run)
    process_manager.start_sims

    #Data Model access examples.

    #Example: Iterate through all ThermalZones and spaces.
    # OS:ThermalZone definition here.
    # http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/classopenstudio_1_1model_1_1_thermal_zone.html
    model.getThermalZones.each do |zone|
      puts zone
      zone.spaces do |space|
        puts space
      end
    end

    #Example: Iterate through all Spaces and all surfaces in each space.
    # OS:Space definition here.
    # http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/classopenstudio_1_1model_1_1_space.html
    model.getSpaces.each do |space|
      puts space
      space.surfaces.each do |surface|
        puts surface
      end
    end


    #Example:Iterate through all Surfaces
    # OS:Surface definition here.
    # http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/classopenstudio_1_1model_1_1_surface.html
    model.getSurfaces.each do |surface|
      puts surface
    end

    #Example:Iterate through all SubSurfaces
    # http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/classopenstudio_1_1model_1_1_sub_surface.html
    model.getSubSurfaces.each do |subsurface|
      puts subsurface
    end

    #Example: Find an object by name using get<Object>byName(model, SearchString, true) Will return an empty object if nothing is found.
    #Short format...
    space3 = model.getSpacesByName("Space 3",true)
    #Long format
    space3 = OpenStudio::Model::getSpacesByName(model,"Space 3",true)
    puts space3 unless space3.empty?


    #Create NECB schedules
    model = OpenStudio::Model::Model.new()
    model.add_necb_schedules()
    if File.exist?(BTAP::TESTING_FOLDER + "/necb2011.osm")
      File.delete(BTAP::TESTING_FOLDER + "/necb2011.osm")
    end
    model.save(OpenStudio::Path.new(BTAP::TESTING_FOLDER + "/necb2011.osm"))



    starttime = Time.new



  end
end