require "singleton"
require 'fileutils'
require 'csv'

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


module BTAP
  
  module Common
    #This model checks to see if the obj_array passed is
    #the object we require, or if a string is given to search for a object of that strings name.
    #@author Phylroy A. Lopez
    #@params model [OpenStudio::model::Model] A model object
    #@params obj_array <Object>
    #@params object_type [Object]
    def self.validate_array(model,obj_array,object_type)

      command =
        %Q^#make copy of argument to avoid side effect.
        object_array = obj_array
        new_object_array = Array.new()
        #check if it is not an array
        unless  obj_array.is_a?(Array)
          if object_array.is_a?(String)
            #if the arguement is a simple string, convert to an array.
            object_array = [object_array]
            #check if it is a single object_type
          elsif not object_array.to_#{object_type}.empty?()
            object_array = [object_array]
          else
            raise("Object passed is neither a #{object_type} or a name of a #{object_type}. Please choose a #{object_type} name that exists such as :\n\#{object_names.join("\n")}")
          end
        end

        object_array.each do |object|
          #if it is a string name of an object, try to find it and insert it into the
          # return array.
          if object.is_a?(String)
            if model.get#{object_type}ByName(object).empty?
               #if we could not find an exact match. raise an exception.
               object_names = Array.new
               model.get#{object_type}s.each { |object| object_names << object.name }
              raise("Object passed is neither  a #{object_type} or a name of a #{object_type}. Please choose a #{object_type} name that exists such as :\n\#{object_names.join("\n")}")
            else
            new_object_array << model.get#{object_type}ByName(object).get
            end
          elsif not object.to_#{object_type}.empty?
          #if it is already a #{object_type}. insert it into the array.
          new_object_array << object
          else
            raise("invalid object")
          end
        end
        return new_object_array
      ^
      eval(command)
    end

    #This method gets a date from a string.
    #@author phylroy.lopez@nrcan.gc.ca
    #@params datestring [String] a date string
    def self.get_date_from_string(datestring)
      month = datestring.split("-")[0].to_s
      day   = datestring.split("-")[1].to_i
      month_list = ["Jan","Feb","Mar","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
      raise ("Month given #{month} is not in format required please enter month with following 3 letter format#{month_list}.") unless month_list.include?(month)
      OpenStudio::Date.new(OpenStudio::MonthOfYear.new(month),day)
    end

    #This method gets a time from a string.
    #@author phylroy.lopez@nrcan.gc.ca
    #@params timestring [String] a time string
    def self.get_time_from_string(timestring)
      #ensure that it is in 0-24 hour format.
      hour = timestring.split(":")[0].to_i
      min = timestring.split(":")[1].to_i
      raise ("invalid time format #{timestring} please use 0-24 as a range for the hour and 0-59 for range for the minutes: Clock starts at 0:00 and stops at 24:00") if (hour < 0 or hour > 24) or ( min < 0 or min > 59 ) or (hour == 24 and min > 0)
      OpenStudio::Time.new(timestring)
    end
  end
  
  
  module Geometry

    def self.enumerate_spaces_model(model,prepend_name = false)
      #enumerate stories.
      BTAP::Geometry::BuildingStoreys::auto_assign_spaces_to_stories(model)
      #Enumerate spaces
      model.getBuildingStorys.each do |story|
        spaces = Array.new
        spaces.concat( story.spaces )
        spaces.sort! do |a, b|
          (a.xOrigin <=> b.xOrigin).nonzero? ||
            (a.yOrigin <=> b.yOrigin)
        end
        counter = 1
        spaces.each do |space|
          puts "old space name : #{space.name}"
          if prepend_name == true
            space.setName("#{story.name}-#{counter.to_s}:#{space.name}")
          else
            space.setName("#{story.name}-#{counter.to_s}")
          end
          counter = counter + 1
          puts "new space name : #{space.name}"
        end
      end
    end
    
    #this was a copy of the sketchup plugin method. 
    def self.rename_zones_based_on_spaces(model)

      # loop through thermal zones
      model.getThermalZones.each do |thermal_zone| # this is going through all, not just selection
        puts "old zone name : #{thermal_zone.name}"
        # reset the array of spaces to be empty
        spaces_in_thermal_zone = []
        # reset length of array of spaces
        number_of_spaces = 0
      
        # get list of spaces in thermal zone
        spaces = thermal_zone.spaces
        spaces.each do |space|

          # make an array instead of the puts statement
          spaces_in_thermal_zone.push space.name.to_s
 
        end
      
        # store length of array
        number_of_spaces = spaces_in_thermal_zone.size
      
        # sort the array
        spaces_in_thermal_zone = spaces_in_thermal_zone.sort
      
        # setup a suffix if the thermal zone contains more than one space
        if number_of_spaces > 1
          multi = " - Plus"
        else
          multi = ""
        end
      
        # rename thermal zone based on first space with prefix added e.g. ThermalZone 203
        if number_of_spaces > 0
          new_name = "ZN:" + spaces_in_thermal_zone[0] + multi
          thermal_zone.setName(new_name)
        else
          puts "#{thermal_zone.name.to_s} did not have any spaces, and will not be renamed." 
        end
        puts "new zone name : #{thermal_zone.name}"
      end
    end
    
    #This method will rename the zone equipment to have the zone name as a prefix for a model. 
    #It will also rename the hot water coils for: 
    #    AirTerminalSingleDuctVAVReheat
    #    ZoneHVACBaseboardConvectiveWater
    #    ZoneHVACUnitHeater
   
    def self.prefix_equipment_with_zone_name(model)
      puts "Renaming zone equipment."
      # get all thermal zones
      thermal_zones = model.getThermalZones

      # loop through thermal zones
      thermal_zones.each do |thermal_zone| # this is going through all, not just selection

        thermal_zone.equipment.each do |equip|

          #For the hydronic conditions below only, it will rename the zonal coils as well. 
          if not equip.to_AirTerminalSingleDuctVAVReheat.empty?

            equip.setName("#{thermal_zone.name}:AirTerminalSingleDuctVAVReheat")
            reheat_coil = equip.to_AirTerminalSingleDuctVAVReheat.get.reheatCoil
            reheat_coil.setName("#{thermal_zone.name}:ReheatCoil")
            puts reheat_coil.name
          elsif not equip.to_ZoneHVACBaseboardConvectiveWater.empty?
            equip.setName("#{thermal_zone.name}:ZoneHVACBaseboardConvectiveWater")
            heatingCoil = equip.to_ZoneHVACBaseboardConvectiveWater.get.heatingCoil
            heatingCoil.setName("#{thermal_zone.name}:Baseboard HW Htg Coil")
            puts heatingCoil.name
          elsif not equip.to_ZoneHVACUnitHeater.empty?
            equip.setName("#{thermal_zone.name}:ZoneHVACUnitHeater")
            heatingCoil = equip.to_ZoneHVACUnitHeater.get.heatingCoil
            heatingCoil.setName("#{thermal_zone.name}:Unit Heater Htg Coil")
            puts heatingCoil.name
            #Add more cases if you wish!!!!!
          else #if the equipment does not follow the above cases, rename
            # it generically and not touch the underlying coils, etc. 
            equip.setName("#{thermal_zone.name}:#{equip.name}")
          end
          
        end
      end
      puts "Done zone renaming equipment"
    end
      
      

    module Wizards
      def self.create_shape_courtyard(model,
          length = 50,
          width = 30,
          courtyard_length = 15,
          courtyard_width = 5 ,
          num_floors = 3,
          floor_to_floor_height = 3.8,
          plenum_height = 1,
          perimeter_zone_depth = 4.57)
        if length <= 1e-4
          raise("Length must be greater than 0.")
          return false
        end

        if width <= 1e-4
          raise("Width must be greater than 0.")
          return false
        end

        if courtyard_length <= 1e-4
          raise("Courtyard length must be greater than 0.")
          return false
        end

        if courtyard_width <= 1e-4
          raise("Courtyard width must be greater than 0.")
          return false
        end

        if num_floors <= 1e-4
          raise("Number of floors must be greater than 0.")
          return false
        end

        if floor_to_floor_height <= 1e-4
          raise("Floor to floor height must be greater than 0.")
          return false
        end

        if plenum_height < 0
          raise("Plenum height must be greater than or equal to 0.")
          return false
        end

        shortest_side = [length,width].min
        if perimeter_zone_depth < 0 or 4*perimeter_zone_depth >= (shortest_side - 1e-4)
          raise("Perimeter zone depth must be greater than or equal to 0 and less than #{shortest_side/4}m.")
          return false
        end

        if courtyard_length >= (length - 4*perimeter_zone_depth - 1e-4)
          raise("Courtyard length must be less than #{length - 4*perimeter_zone_depth}m.")
          return false
        end

        if courtyard_width >= (width - 4*perimeter_zone_depth - 1e-4)
          raise("Courtyard width must be less than #{width - 4*perimeter_zone_depth}m.")
          return false
        end


        # Loop through the number of floors
        for floor in (0..num_floors-1)

          z = floor_to_floor_height * floor

          #Create a new story within the building
          story = OpenStudio::Model::BuildingStory.new(model)
          story.setNominalFloortoFloorHeight(floor_to_floor_height)
          story.setName("Story #{floor+1}")


          nw_point = OpenStudio::Point3d.new(0,width,z)
          ne_point = OpenStudio::Point3d.new(length,width,z)
          se_point = OpenStudio::Point3d.new(length,0,z)
          sw_point = OpenStudio::Point3d.new(0,0,z)

          courtyard_nw_point = OpenStudio::Point3d.new((length-courtyard_length)/2,(width-courtyard_width)/2+courtyard_width,z)
          courtyard_ne_point = OpenStudio::Point3d.new((length-courtyard_length)/2+courtyard_length,(width-courtyard_width)/2+courtyard_width,z)
          courtyard_se_point = OpenStudio::Point3d.new((length-courtyard_length)/2+courtyard_length,(width-courtyard_width)/2,z)
          courtyard_sw_point = OpenStudio::Point3d.new((length-courtyard_length)/2,(width-courtyard_width)/2,z)

          # Identity matrix for setting space origins
          m = OpenStudio::Matrix.new(4,4,0)
          m[0,0] = 1
          m[1,1] = 1
          m[2,2] = 1
          m[3,3] = 1

          # Define polygons for a building with a courtyard
          if perimeter_zone_depth > 0
            outer_perimeter_nw_point = nw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
            outer_perimeter_ne_point = ne_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
            outer_perimeter_se_point = se_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
            outer_perimeter_sw_point = sw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)
            inner_perimeter_nw_point = courtyard_nw_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
            inner_perimeter_ne_point = courtyard_ne_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)
            inner_perimeter_se_point = courtyard_se_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
            inner_perimeter_sw_point = courtyard_sw_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)

            west_outer_perimeter_polygon = OpenStudio::Point3dVector.new
            west_outer_perimeter_polygon << sw_point
            west_outer_perimeter_polygon << nw_point
            west_outer_perimeter_polygon << outer_perimeter_nw_point
            west_outer_perimeter_polygon << outer_perimeter_sw_point
            west_outer_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(west_outer_perimeter_polygon, floor_to_floor_height, model)
            west_outer_perimeter_space = west_outer_perimeter_space.get
            m[0,3] = sw_point.x
            m[1,3] = sw_point.y
            m[2,3] = sw_point.z
            west_outer_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_outer_perimeter_space.setBuildingStory(story)
            west_outer_perimeter_space.setName("Story #{floor+1} West Outer Perimeter Space")



            north_outer_perimeter_polygon = OpenStudio::Point3dVector.new
            north_outer_perimeter_polygon << nw_point
            north_outer_perimeter_polygon << ne_point
            north_outer_perimeter_polygon << outer_perimeter_ne_point
            north_outer_perimeter_polygon << outer_perimeter_nw_point
            north_outer_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(north_outer_perimeter_polygon, floor_to_floor_height, model)
            north_outer_perimeter_space = north_outer_perimeter_space.get
            m[0,3] = outer_perimeter_nw_point.x
            m[1,3] = outer_perimeter_nw_point.y
            m[2,3] = outer_perimeter_nw_point.z
            north_outer_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_outer_perimeter_space.setBuildingStory(story)
            north_outer_perimeter_space.setName("Story #{floor+1} North Outer Perimeter Space")



            east_outer_perimeter_polygon = OpenStudio::Point3dVector.new
            east_outer_perimeter_polygon << ne_point
            east_outer_perimeter_polygon << se_point
            east_outer_perimeter_polygon << outer_perimeter_se_point
            east_outer_perimeter_polygon << outer_perimeter_ne_point
            east_outer_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(east_outer_perimeter_polygon, floor_to_floor_height, model)
            east_outer_perimeter_space = east_outer_perimeter_space.get
            m[0,3] = outer_perimeter_se_point.x
            m[1,3] = outer_perimeter_se_point.y
            m[2,3] = outer_perimeter_se_point.z
            east_outer_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_outer_perimeter_space.setBuildingStory(story)
            east_outer_perimeter_space.setName("Story #{floor+1} East Outer Perimeter Space")



            south_outer_perimeter_polygon = OpenStudio::Point3dVector.new
            south_outer_perimeter_polygon << se_point
            south_outer_perimeter_polygon << sw_point
            south_outer_perimeter_polygon << outer_perimeter_sw_point
            south_outer_perimeter_polygon << outer_perimeter_se_point
            south_outer_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(south_outer_perimeter_polygon, floor_to_floor_height, model)
            south_outer_perimeter_space = south_outer_perimeter_space.get
            m[0,3] = sw_point.x
            m[1,3] = sw_point.y
            m[2,3] = sw_point.z
            south_outer_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_outer_perimeter_space.setBuildingStory(story)
            south_outer_perimeter_space.setName("Story #{floor+1} South Outer Perimeter Space")


            west_core_polygon = OpenStudio::Point3dVector.new
            west_core_polygon << outer_perimeter_sw_point
            west_core_polygon << outer_perimeter_nw_point
            west_core_polygon << inner_perimeter_nw_point
            west_core_polygon << inner_perimeter_sw_point
            west_core_space = OpenStudio::Model::Space::fromFloorPrint(west_core_polygon, floor_to_floor_height, model)
            west_core_space = west_core_space.get
            m[0,3] = outer_perimeter_sw_point.x
            m[1,3] = outer_perimeter_sw_point.y
            m[2,3] = outer_perimeter_sw_point.z
            west_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_core_space.setBuildingStory(story)
            west_core_space.setName("Story #{floor+1} West Core Space")


            north_core_polygon = OpenStudio::Point3dVector.new
            north_core_polygon << outer_perimeter_nw_point
            north_core_polygon << outer_perimeter_ne_point
            north_core_polygon << inner_perimeter_ne_point
            north_core_polygon << inner_perimeter_nw_point
            north_core_space = OpenStudio::Model::Space::fromFloorPrint(north_core_polygon, floor_to_floor_height, model)
            north_core_space = north_core_space.get
            m[0,3] = inner_perimeter_nw_point.x
            m[1,3] = inner_perimeter_nw_point.y
            m[2,3] = inner_perimeter_nw_point.z
            north_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_core_space.setBuildingStory(story)
            north_core_space.setName("Story #{floor+1} North Core Space")


            east_core_polygon = OpenStudio::Point3dVector.new
            east_core_polygon << outer_perimeter_ne_point
            east_core_polygon << outer_perimeter_se_point
            east_core_polygon << inner_perimeter_se_point
            east_core_polygon << inner_perimeter_ne_point
            east_core_space = OpenStudio::Model::Space::fromFloorPrint(east_core_polygon, floor_to_floor_height, model)
            east_core_space = east_core_space.get
            m[0,3] = inner_perimeter_se_point.x
            m[1,3] = inner_perimeter_se_point.y
            m[2,3] = inner_perimeter_se_point.z
            east_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_core_space.setBuildingStory(story)
            east_core_space.setName("Story #{floor+1} East Core Space")


            south_core_polygon = OpenStudio::Point3dVector.new
            south_core_polygon << outer_perimeter_se_point
            south_core_polygon << outer_perimeter_sw_point
            south_core_polygon << inner_perimeter_sw_point
            south_core_polygon << inner_perimeter_se_point
            south_core_space = OpenStudio::Model::Space::fromFloorPrint(south_core_polygon, floor_to_floor_height, model)
            south_core_space = south_core_space.get
            m[0,3] = outer_perimeter_sw_point.x
            m[1,3] = outer_perimeter_sw_point.y
            m[2,3] = outer_perimeter_sw_point.z
            south_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_core_space.setBuildingStory(story)
            south_core_space.setName("Story #{floor+1} South Core Space")


            west_inner_perimeter_polygon  = OpenStudio::Point3dVector.new
            west_inner_perimeter_polygon << inner_perimeter_sw_point
            west_inner_perimeter_polygon << inner_perimeter_nw_point
            west_inner_perimeter_polygon << courtyard_nw_point
            west_inner_perimeter_polygon << courtyard_sw_point
            west_inner_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(west_inner_perimeter_polygon, floor_to_floor_height, model)
            west_inner_perimeter_space = west_inner_perimeter_space.get
            m[0,3] = inner_perimeter_sw_point.x
            m[1,3] = inner_perimeter_sw_point.y
            m[2,3] = inner_perimeter_sw_point.z
            west_inner_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_inner_perimeter_space.setBuildingStory(story)
            west_inner_perimeter_space.setName("Story #{floor+1} West Inner Perimeter Space")


            north_inner_perimeter_polygon  = OpenStudio::Point3dVector.new
            north_inner_perimeter_polygon << inner_perimeter_nw_point
            north_inner_perimeter_polygon << inner_perimeter_ne_point
            north_inner_perimeter_polygon << courtyard_ne_point
            north_inner_perimeter_polygon << courtyard_nw_point
            north_inner_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(north_inner_perimeter_polygon, floor_to_floor_height, model)
            north_inner_perimeter_space = north_inner_perimeter_space.get
            m[0,3] = courtyard_nw_point.x
            m[1,3] = courtyard_nw_point.y
            m[2,3] = courtyard_nw_point.z
            north_inner_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_inner_perimeter_space.setBuildingStory(story)
            north_inner_perimeter_space.setName("Story #{floor+1} North Inner Perimeter Space")


            east_inner_perimeter_polygon  = OpenStudio::Point3dVector.new
            east_inner_perimeter_polygon << inner_perimeter_ne_point
            east_inner_perimeter_polygon << inner_perimeter_se_point
            east_inner_perimeter_polygon << courtyard_se_point
            east_inner_perimeter_polygon << courtyard_ne_point
            east_inner_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(east_inner_perimeter_polygon, floor_to_floor_height, model)
            east_inner_perimeter_space = east_inner_perimeter_space.get
            m[0,3] = courtyard_se_point.x
            m[1,3] = courtyard_se_point.y
            m[2,3] = courtyard_se_point.z
            east_inner_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_inner_perimeter_space.setBuildingStory(story)
            east_inner_perimeter_space.setName("Story #{floor+1} East Inner Perimeter Space")


            south_inner_perimeter_polygon  = OpenStudio::Point3dVector.new
            south_inner_perimeter_polygon << inner_perimeter_se_point
            south_inner_perimeter_polygon << inner_perimeter_sw_point
            south_inner_perimeter_polygon << courtyard_sw_point
            south_inner_perimeter_polygon << courtyard_se_point
            south_inner_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(south_inner_perimeter_polygon, floor_to_floor_height, model)
            south_inner_perimeter_space = south_inner_perimeter_space.get
            m[0,3] = inner_perimeter_sw_point.x
            m[1,3] = inner_perimeter_sw_point.y
            m[2,3] = inner_perimeter_sw_point.z
            south_inner_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_inner_perimeter_space.setBuildingStory(story)
            south_inner_perimeter_space.setName("Story #{floor+1} South Inner Perimeter Space")


            # Minimal zones
          else
            west_polygon = OpenStudio::Point3dVector.new
            west_polygon << sw_point
            west_polygon << nw_point
            west_polygon << courtyard_nw_point
            west_polygon << courtyard_sw_point
            west_space = OpenStudio::Model::Space::fromFloorPrint(west_polygon, floor_to_floor_height, model)
            west_space = west_space.get
            m[0,3] = sw_point.x
            m[1,3] = sw_point.y
            m[2,3] = sw_point.z
            west_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_space.setBuildingStory(story)
            west_space.setName("Story #{floor+1} West Space")


            north_polygon = OpenStudio::Point3dVector.new
            north_polygon << nw_point
            north_polygon << ne_point
            north_polygon << courtyard_ne_point
            north_polygon << courtyard_nw_point
            north_space = OpenStudio::Model::Space::fromFloorPrint(north_polygon, floor_to_floor_height, model)
            north_space = north_space.get
            m[0,3] = courtyard_nw_point.x
            m[1,3] = courtyard_nw_point.y
            m[2,3] = courtyard_nw_point.z
            north_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_space.setBuildingStory(story)
            north_space.setName("Story #{floor+1} North Space")


            east_polygon = OpenStudio::Point3dVector.new
            east_polygon << ne_point
            east_polygon << se_point
            east_polygon << courtyard_se_point
            east_polygon << courtyard_ne_point
            east_space = OpenStudio::Model::Space::fromFloorPrint(east_polygon, floor_to_floor_height, model)
            east_space = east_space.get
            m[0,3] = courtyard_se_point.x
            m[1,3] = courtyard_se_point.y
            m[2,3] = courtyard_se_point.z
            east_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_space.setBuildingStory(story)
            east_space.setName("Story #{floor+1} East Space")


            south_polygon = OpenStudio::Point3dVector.new
            south_polygon << se_point
            south_polygon << sw_point
            south_polygon << courtyard_sw_point
            south_polygon << courtyard_se_point
            south_space = OpenStudio::Model::Space::fromFloorPrint(south_polygon, floor_to_floor_height, model)
            south_space = south_space.get
            m[0,3] = sw_point.x
            m[1,3] = sw_point.y
            m[2,3] = sw_point.z
            south_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_space.setBuildingStory(story)
            south_space.setName("Story #{floor+1} South Space")
          end
          #Set vertical story position
          story.setNominalZCoordinate(z)
        end #End of floor loop
        BTAP::Geometry::match_surfaces(model)
        return model
      end

      def self.create_shape_h(model,
          length = 40.0,
          left_width = 40.0,
          center_width = 10.0,
          right_width = 40.0,
          left_end_length = 15.0,
          right_end_length = 15.0,
          left_upper_end_offset = 15.0,
          right_upper_end_offset = 15.0,
          num_floors = 3,
          floor_to_floor_height = 3.8,
          plenum_height = 1,
          perimeter_zone_depth = 4.57)


        if length <= 1e-4
          raise("Length must be greater than 0.")
          return false
        end

        if left_width <= 1e-4
          raise("Left width must be greater than 0.")
          return false
        end

        if right_width <= 1e-4
          raise("Right width must be greater than 0.")
          return false
        end

        if center_width <= 1e-4 or center_width >= ([left_width,right_width].min - 1e-4)
          raise("Center width must be greater than 0 and less than #{[left_width,right_width].min}m.")
          return false
        end

        if left_end_length <= 1e-4 or left_end_length >= (length - 1e-4)
          raise("Left end length must be greater than 0 and less than #{length}m.")
          return false
        end

        if right_end_length <= 1e-4 or right_end_length >= (length - left_end_length - 1e-4)
          raise("Right end length must be greater than 0 and less than #{length - left_end_length}m.")
          return false
        end

        if left_upper_end_offset <= 1e-4 or left_upper_end_offset >= (left_width - center_width - 1e-4)
          raise("Left upper end offset must be greater than 0 and less than #{left_width - center_width}m.")
          return false
        end

        if right_upper_end_offset <= 1e-4 or right_upper_end_offset >= (right_width - center_width - 1e-4)
          raise("Right upper end offset must be greater than 0 and less than #{right_width - center_width}m.")
          return false
        end

        if num_floors <= 1e-4
          raise("Number of floors must be greater than 0.")
          return false
        end

        if floor_to_floor_height <= 1e-4
          raise("Floor to floor height must be greater than 0.")
          return false
        end

        if plenum_height < 0
          raise("Plenum height must be greater than or equal to 0.")
          return false
        end

        shortest_side = [length/2,left_width,center_width,right_width,left_end_length,right_end_length].min
        if perimeter_zone_depth < 0 or 2*perimeter_zone_depth >= (shortest_side - 1e-4)
          raise("Perimeter zone depth must be greater than or equal to 0 and less than #{shortest_side/2}m.")
          return false
        end



        # Loop through the number of floors
        for floor in (0..num_floors-1)

          z = floor_to_floor_height * floor

          #Create a new story within the building
          story = OpenStudio::Model::BuildingStory.new(model)
          story.setNominalFloortoFloorHeight(floor_to_floor_height)
          story.setName("Story #{floor+1}")


          left_origin = (right_width - right_upper_end_offset) > (left_width - left_upper_end_offset) ? (right_width - right_upper_end_offset) - (left_width - left_upper_end_offset) : 0

          left_nw_point = OpenStudio::Point3d.new(0,left_width + left_origin,z)
          left_ne_point = OpenStudio::Point3d.new(left_end_length,left_width + left_origin,z)
          left_se_point = OpenStudio::Point3d.new(left_end_length,left_origin,z)
          left_sw_point = OpenStudio::Point3d.new(0,left_origin,z)
          center_nw_point = OpenStudio::Point3d.new(left_end_length,left_ne_point.y - left_upper_end_offset,z)
          center_ne_point = OpenStudio::Point3d.new(length - right_end_length,center_nw_point.y,z)
          center_se_point = OpenStudio::Point3d.new(length - right_end_length,center_nw_point.y - center_width,z)
          center_sw_point = OpenStudio::Point3d.new(left_end_length,center_se_point.y,z)
          right_nw_point = OpenStudio::Point3d.new(length - right_end_length,center_ne_point.y + right_upper_end_offset,z)
          right_ne_point = OpenStudio::Point3d.new(length,right_nw_point.y,z)
          right_se_point = OpenStudio::Point3d.new(length,right_ne_point.y-right_width,z)
          right_sw_point = OpenStudio::Point3d.new(length - right_end_length,right_se_point.y,z)

          # Identity matrix for setting space origins
          m = OpenStudio::Matrix.new(4,4,0)
          m[0,0] = 1
          m[1,1] = 1
          m[2,2] = 1
          m[3,3] = 1

          # Define polygons for a L-shape building with perimeter core zoning
          if perimeter_zone_depth > 0
            perimeter_left_nw_point = left_nw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_left_ne_point = left_ne_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_left_se_point = left_se_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_left_sw_point = left_sw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_center_nw_point = center_nw_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_center_ne_point = center_ne_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_center_se_point = center_se_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_center_sw_point = center_sw_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_right_nw_point = right_nw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_right_ne_point = right_ne_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_right_se_point = right_se_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_right_sw_point = right_sw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)

            west_left_perimeter_polygon = OpenStudio::Point3dVector.new
            west_left_perimeter_polygon << left_sw_point
            west_left_perimeter_polygon << left_nw_point
            west_left_perimeter_polygon << perimeter_left_nw_point
            west_left_perimeter_polygon << perimeter_left_sw_point
            west_left_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(west_left_perimeter_polygon, floor_to_floor_height, model)
            west_left_perimeter_space = west_left_perimeter_space.get
            m[0,3] = left_sw_point.x
            m[1,3] = left_sw_point.y
            m[2,3] = left_sw_point.z
            west_left_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_left_perimeter_space.setBuildingStory(story)
            west_left_perimeter_space.setName("Story #{floor+1} West Left Perimeter Space")


            north_left_perimeter_polygon = OpenStudio::Point3dVector.new
            north_left_perimeter_polygon << left_nw_point
            north_left_perimeter_polygon << left_ne_point
            north_left_perimeter_polygon << perimeter_left_ne_point
            north_left_perimeter_polygon << perimeter_left_nw_point
            north_left_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(north_left_perimeter_polygon, floor_to_floor_height, model)
            north_left_perimeter_space = north_left_perimeter_space.get
            m[0,3] = perimeter_left_nw_point.x
            m[1,3] = perimeter_left_nw_point.y
            m[2,3] = perimeter_left_nw_point.z
            north_left_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_left_perimeter_space.setBuildingStory(story)
            north_left_perimeter_space.setName("Story #{floor+1} North Left Perimeter Space")


            east_upper_left_perimeter_polygon = OpenStudio::Point3dVector.new
            east_upper_left_perimeter_polygon << left_ne_point
            east_upper_left_perimeter_polygon << center_nw_point
            east_upper_left_perimeter_polygon << perimeter_center_nw_point
            east_upper_left_perimeter_polygon << perimeter_left_ne_point
            east_upper_left_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(east_upper_left_perimeter_polygon, floor_to_floor_height, model)
            east_upper_left_perimeter_space = east_upper_left_perimeter_space.get
            m[0,3] = perimeter_center_nw_point.x
            m[1,3] = perimeter_center_nw_point.y
            m[2,3] = perimeter_center_nw_point.z
            east_upper_left_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_upper_left_perimeter_space.setBuildingStory(story)
            east_upper_left_perimeter_space.setName("Story #{floor+1} East Upper Left Perimeter Space")


            north_center_perimeter_polygon = OpenStudio::Point3dVector.new
            north_center_perimeter_polygon << center_nw_point
            north_center_perimeter_polygon << center_ne_point
            north_center_perimeter_polygon << perimeter_center_ne_point
            north_center_perimeter_polygon << perimeter_center_nw_point
            north_center_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(north_center_perimeter_polygon, floor_to_floor_height, model)
            north_center_perimeter_space = north_center_perimeter_space.get
            m[0,3] = perimeter_center_nw_point.x
            m[1,3] = perimeter_center_nw_point.y
            m[2,3] = perimeter_center_nw_point.z
            north_center_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_center_perimeter_space.setBuildingStory(story)
            north_center_perimeter_space.setName("Story #{floor+1} North Center Perimeter Space")


            west_upper_right_perimeter_polygon = OpenStudio::Point3dVector.new
            west_upper_right_perimeter_polygon << center_ne_point
            west_upper_right_perimeter_polygon << right_nw_point
            west_upper_right_perimeter_polygon << perimeter_right_nw_point
            west_upper_right_perimeter_polygon << perimeter_center_ne_point
            west_upper_right_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(west_upper_right_perimeter_polygon, floor_to_floor_height, model)
            west_upper_right_perimeter_space = west_upper_right_perimeter_space.get
            m[0,3] = center_ne_point.x
            m[1,3] = center_ne_point.y
            m[2,3] = center_ne_point.z
            west_upper_right_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_upper_right_perimeter_space.setBuildingStory(story)
            west_upper_right_perimeter_space.setName("Story #{floor+1} West Upper Right Perimeter Space")


            north_right_perimeter_polygon = OpenStudio::Point3dVector.new
            north_right_perimeter_polygon << right_nw_point
            north_right_perimeter_polygon << right_ne_point
            north_right_perimeter_polygon << perimeter_right_ne_point
            north_right_perimeter_polygon << perimeter_right_nw_point
            north_right_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(north_right_perimeter_polygon, floor_to_floor_height, model)
            north_right_perimeter_space = north_right_perimeter_space.get
            m[0,3] = perimeter_right_nw_point.x
            m[1,3] = perimeter_right_nw_point.y
            m[2,3] = perimeter_right_nw_point.z
            north_right_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_right_perimeter_space.setBuildingStory(story)
            north_right_perimeter_space.setName("Story #{floor+1} North Right Perimeter Space")


            east_right_perimeter_polygon = OpenStudio::Point3dVector.new
            east_right_perimeter_polygon << right_ne_point
            east_right_perimeter_polygon << right_se_point
            east_right_perimeter_polygon << perimeter_right_se_point
            east_right_perimeter_polygon << perimeter_right_ne_point
            east_right_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(east_right_perimeter_polygon, floor_to_floor_height, model)
            east_right_perimeter_space = east_right_perimeter_space.get
            m[0,3] = perimeter_right_se_point.x
            m[1,3] = perimeter_right_se_point.y
            m[2,3] = perimeter_right_se_point.z
            east_right_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_right_perimeter_space.setBuildingStory(story)
            east_right_perimeter_space.setName("Story #{floor+1} East Right Perimeter Space")



            south_right_perimeter_polygon = OpenStudio::Point3dVector.new
            south_right_perimeter_polygon << right_se_point
            south_right_perimeter_polygon << right_sw_point
            south_right_perimeter_polygon << perimeter_right_sw_point
            south_right_perimeter_polygon << perimeter_right_se_point
            south_right_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(south_right_perimeter_polygon, floor_to_floor_height, model)
            south_right_perimeter_space = south_right_perimeter_space.get
            m[0,3] = right_sw_point.x
            m[1,3] = right_sw_point.y
            m[2,3] = right_sw_point.z
            south_right_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_right_perimeter_space.setBuildingStory(story)
            south_right_perimeter_space.setName("Story #{floor+1} South Right Perimeter Space")


            west_lower_right_perimeter_polygon = OpenStudio::Point3dVector.new
            west_lower_right_perimeter_polygon << right_sw_point
            west_lower_right_perimeter_polygon << center_se_point
            west_lower_right_perimeter_polygon << perimeter_center_se_point
            west_lower_right_perimeter_polygon << perimeter_right_sw_point
            west_lower_right_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(west_lower_right_perimeter_polygon, floor_to_floor_height, model)
            west_lower_right_perimeter_space = west_lower_right_perimeter_space.get
            m[0,3] = right_sw_point.x
            m[1,3] = right_sw_point.y
            m[2,3] = right_sw_point.z
            west_lower_right_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_lower_right_perimeter_space.setBuildingStory(story)
            west_lower_right_perimeter_space.setName("Story #{floor+1} West Lower Right Perimeter Space")


            south_center_perimeter_polygon = OpenStudio::Point3dVector.new
            south_center_perimeter_polygon << center_se_point
            south_center_perimeter_polygon << center_sw_point
            south_center_perimeter_polygon << perimeter_center_sw_point
            south_center_perimeter_polygon << perimeter_center_se_point
            south_center_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(south_center_perimeter_polygon, floor_to_floor_height, model)
            south_center_perimeter_space = south_center_perimeter_space.get
            m[0,3] = center_sw_point.x
            m[1,3] = center_sw_point.y
            m[2,3] = center_sw_point.z
            south_center_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_center_perimeter_space.setBuildingStory(story)
            south_center_perimeter_space.setName("Story #{floor+1} South Center Perimeter Space")


            east_lower_left_perimeter_polygon = OpenStudio::Point3dVector.new
            east_lower_left_perimeter_polygon << center_sw_point
            east_lower_left_perimeter_polygon << left_se_point
            east_lower_left_perimeter_polygon << perimeter_left_se_point
            east_lower_left_perimeter_polygon << perimeter_center_sw_point
            east_lower_left_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(east_lower_left_perimeter_polygon, floor_to_floor_height, model)
            east_lower_left_perimeter_space = east_lower_left_perimeter_space.get
            m[0,3] = perimeter_left_se_point.x
            m[1,3] = perimeter_left_se_point.y
            m[2,3] = perimeter_left_se_point.z
            east_lower_left_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_lower_left_perimeter_space.setBuildingStory(story)
            east_lower_left_perimeter_space.setName("Story #{floor+1} East Lower Left Perimeter Space")


            south_left_perimeter_polygon = OpenStudio::Point3dVector.new
            south_left_perimeter_polygon << left_se_point
            south_left_perimeter_polygon << left_sw_point
            south_left_perimeter_polygon << perimeter_left_sw_point
            south_left_perimeter_polygon << perimeter_left_se_point
            south_left_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(south_left_perimeter_polygon, floor_to_floor_height, model)
            south_left_perimeter_space = south_left_perimeter_space.get
            m[0,3] = left_sw_point.x
            m[1,3] = left_sw_point.y
            m[2,3] = left_sw_point.z
            south_left_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_left_perimeter_space.setBuildingStory(story)
            south_left_perimeter_space.setName("Story #{floor+1} South Left Perimeter Space")


            west_core_polygon = OpenStudio::Point3dVector.new
            west_core_polygon << perimeter_left_sw_point
            west_core_polygon << perimeter_left_nw_point
            west_core_polygon << perimeter_left_ne_point
            west_core_polygon << perimeter_center_nw_point
            west_core_polygon << perimeter_center_sw_point
            west_core_polygon << perimeter_left_se_point
            west_core_space = OpenStudio::Model::Space::fromFloorPrint(west_core_polygon, floor_to_floor_height, model)
            west_core_space = west_core_space.get
            m[0,3] = perimeter_left_sw_point.x
            m[1,3] = perimeter_left_sw_point.y
            m[2,3] = perimeter_left_sw_point.z
            west_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_core_space.setBuildingStory(story)
            west_core_space.setName("Story #{floor+1} West Core Space")


            center_core_polygon = OpenStudio::Point3dVector.new
            center_core_polygon << perimeter_center_sw_point
            center_core_polygon << perimeter_center_nw_point
            center_core_polygon << perimeter_center_ne_point
            center_core_polygon << perimeter_center_se_point
            center_core_space = OpenStudio::Model::Space::fromFloorPrint(center_core_polygon, floor_to_floor_height, model)
            center_core_space = center_core_space.get
            m[0,3] = perimeter_center_sw_point.x
            m[1,3] = perimeter_center_sw_point.y
            m[2,3] = perimeter_center_sw_point.z
            center_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            center_core_space.setBuildingStory(story)
            center_core_space.setName("Story #{floor+1} Center Core Space")


            east_core_polygon = OpenStudio::Point3dVector.new
            east_core_polygon << perimeter_right_sw_point
            east_core_polygon << perimeter_center_se_point
            east_core_polygon << perimeter_center_ne_point
            east_core_polygon << perimeter_right_nw_point
            east_core_polygon << perimeter_right_ne_point
            east_core_polygon << perimeter_right_se_point
            east_core_space = OpenStudio::Model::Space::fromFloorPrint(east_core_polygon, floor_to_floor_height, model)
            east_core_space = east_core_space.get
            m[0,3] = perimeter_right_sw_point.x
            m[1,3] = perimeter_right_sw_point.y
            m[2,3] = perimeter_right_sw_point.z
            east_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_core_space.setBuildingStory(story)
            east_core_space.setName("Story #{floor+1} East Core Space")


            # Minimal zones
          else
            west_polygon = OpenStudio::Point3dVector.new
            west_polygon << left_sw_point
            west_polygon << left_nw_point
            west_polygon << left_ne_point
            west_polygon << center_nw_point
            west_polygon << center_sw_point
            west_polygon << left_se_point
            west_space = OpenStudio::Model::Space::fromFloorPrint(west_polygon, floor_to_floor_height, model)
            west_space = west_space.get
            m[0,3] = left_sw_point.x
            m[1,3] = left_sw_point.y
            m[2,3] = left_sw_point.z
            west_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_space.setBuildingStory(story)
            west_space.setName("Story #{floor+1} West Space")


            center_polygon = OpenStudio::Point3dVector.new
            center_polygon << center_sw_point
            center_polygon << center_nw_point
            center_polygon << center_ne_point
            center_polygon << center_se_point
            center_space = OpenStudio::Model::Space::fromFloorPrint(center_polygon, floor_to_floor_height, model)
            center_space = center_space.get
            m[0,3] = center_sw_point.x
            m[1,3] = center_sw_point.y
            m[2,3] = center_sw_point.z
            center_space.changeTransformation(OpenStudio::Transformation.new(m))
            center_space.setBuildingStory(story)
            center_space.setName("Story #{floor+1} Center Space")


            east_polygon = OpenStudio::Point3dVector.new
            east_polygon << right_sw_point
            east_polygon << center_se_point
            east_polygon << center_ne_point
            east_polygon << right_nw_point
            east_polygon << right_ne_point
            east_polygon << right_se_point
            east_space = OpenStudio::Model::Space::fromFloorPrint(east_polygon, floor_to_floor_height, model)
            east_space = east_space.get
            m[0,3] = right_sw_point.x
            m[1,3] = right_sw_point.y
            m[2,3] = right_sw_point.z
            east_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_space.setBuildingStory(story)
            east_space.setName("Story #{floor+1} East Space")


          end

          #Set vertical story position
          story.setNominalZCoordinate(z)

        end #End of floor loop
        BTAP::Geometry::match_surfaces(model)
        return model
      end

      def self.create_shape_l(
          model,
          length = 40.0,
          width = 40.0,
          lower_end_width = 20.0,
          upper_end_length = 20.0,
          num_floors = 3,
          floor_to_floor_height = 3.8,
          plenum_height = 1.0,
          perimeter_zone_depth = 4.57
        )

        if length <= 1e-4
          raise("Length must be greater than 0.")
          return false
        end

        if width <= 1e-4
          raise("Width must be greater than 0.")
          return false
        end

        if lower_end_width <= 1e-4 or lower_end_width >= (width - 1e-4)
          raise("Lower end width must be greater than 0 and less than #{width}m.")
          return false
        end

        if upper_end_length <= 1e-4 or upper_end_length >= (length - 1e-4)
          raise("Upper end length must be greater than 0 and less than #{length}m.")
          return false
        end

        if num_floors <= 1e-4
          raise("Number of floors must be greater than 0.")
          return false
        end

        if floor_to_floor_height <= 1e-4
          raise("Floor to floor height must be greater than 0.")
          return false
        end

        if plenum_height < 0
          raise("Plenum height must be greater than or equal to 0.")
          return false
        end

        shortest_side = [lower_end_width,upper_end_length].min
        if perimeter_zone_depth < 0 or 2*perimeter_zone_depth >= (shortest_side - 1e-4)
          raise("Perimeter zone depth must be greater than or equal to 0 and less than #{shortest_side/2}m.")
          return false
        end

        # Create progress bar
        #    runner.createProgressBar("Creating Spaces")
        #    num_total = perimeter_zone_depth>0 ? num_floors*8 : num_floors*2
        #    num_complete = 0

        # Loop through the number of floors
        for floor in (0..num_floors-1)

          z = floor_to_floor_height * floor

          #Create a new story within the building
          story = OpenStudio::Model::BuildingStory.new(model)
          story.setNominalFloortoFloorHeight(floor_to_floor_height)
          story.setName("Story #{floor+1}")


          nw_point = OpenStudio::Point3d.new(0,width,z)
          upper_ne_point = OpenStudio::Point3d.new(upper_end_length,width,z)
          upper_sw_point = OpenStudio::Point3d.new(upper_end_length,lower_end_width,z)
          lower_ne_point = OpenStudio::Point3d.new(length,lower_end_width,z)
          se_point = OpenStudio::Point3d.new(length,0,z)
          sw_point = OpenStudio::Point3d.new(0,0,z)

          # Identity matrix for setting space origins
          m = OpenStudio::Matrix.new(4,4,0)
          m[0,0] = 1
          m[1,1] = 1
          m[2,2] = 1
          m[3,3] = 1

          # Define polygons for a L-shape building with perimeter core zoning
          if perimeter_zone_depth > 0
            perimeter_nw_point = nw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_upper_ne_point = upper_ne_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_upper_sw_point = upper_sw_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_lower_ne_point = lower_ne_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_se_point = se_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_lower_sw_point = sw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)

            west_perimeter_polygon  = OpenStudio::Point3dVector.new
            west_perimeter_polygon << sw_point
            west_perimeter_polygon << nw_point
            west_perimeter_polygon << perimeter_nw_point
            west_perimeter_polygon << perimeter_lower_sw_point
            west_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(west_perimeter_polygon, floor_to_floor_height, model)
            west_perimeter_space = west_perimeter_space.get
            m[0,3] = sw_point.x
            m[1,3] = sw_point.y
            m[2,3] = sw_point.z
            west_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_perimeter_space.setBuildingStory(story)
            west_perimeter_space.setName("Story #{floor+1} West Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            north_upper_perimeter_polygon = OpenStudio::Point3dVector.new
            north_upper_perimeter_polygon << nw_point
            north_upper_perimeter_polygon << upper_ne_point
            north_upper_perimeter_polygon << perimeter_upper_ne_point
            north_upper_perimeter_polygon << perimeter_nw_point
            north_upper_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(north_upper_perimeter_polygon, floor_to_floor_height, model)
            north_upper_perimeter_space = north_upper_perimeter_space.get
            m[0,3] = perimeter_nw_point.x
            m[1,3] = perimeter_nw_point.y
            m[2,3] = perimeter_nw_point.z
            north_upper_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_upper_perimeter_space.setBuildingStory(story)
            north_upper_perimeter_space.setName("Story #{floor+1} North Upper Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            east_upper_perimeter_polygon = OpenStudio::Point3dVector.new
            east_upper_perimeter_polygon << upper_ne_point
            east_upper_perimeter_polygon << upper_sw_point
            east_upper_perimeter_polygon << perimeter_upper_sw_point
            east_upper_perimeter_polygon << perimeter_upper_ne_point
            east_upper_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(east_upper_perimeter_polygon, floor_to_floor_height, model)
            east_upper_perimeter_space = east_upper_perimeter_space.get
            m[0,3] = perimeter_upper_sw_point.x
            m[1,3] = perimeter_upper_sw_point.y
            m[2,3] = perimeter_upper_sw_point.z
            east_upper_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_upper_perimeter_space.setBuildingStory(story)
            east_upper_perimeter_space.setName("Story #{floor+1} East Upper Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            north_lower_perimeter_polygon = OpenStudio::Point3dVector.new
            north_lower_perimeter_polygon << upper_sw_point
            north_lower_perimeter_polygon << lower_ne_point
            north_lower_perimeter_polygon << perimeter_lower_ne_point
            north_lower_perimeter_polygon << perimeter_upper_sw_point
            north_lower_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(north_lower_perimeter_polygon, floor_to_floor_height, model)
            north_lower_perimeter_space = north_lower_perimeter_space.get
            m[0,3] = perimeter_upper_sw_point.x
            m[1,3] = perimeter_upper_sw_point.y
            m[2,3] = perimeter_upper_sw_point.z
            north_lower_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_lower_perimeter_space.setBuildingStory(story)
            north_lower_perimeter_space.setName("Story #{floor+1} North Lower Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            east_lower_perimeter_polygon = OpenStudio::Point3dVector.new
            east_lower_perimeter_polygon << lower_ne_point
            east_lower_perimeter_polygon << se_point
            east_lower_perimeter_polygon << perimeter_se_point
            east_lower_perimeter_polygon << perimeter_lower_ne_point
            east_lower_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(east_lower_perimeter_polygon, floor_to_floor_height, model)
            east_lower_perimeter_space = east_lower_perimeter_space.get
            m[0,3] = perimeter_se_point.x
            m[1,3] = perimeter_se_point.y
            m[2,3] = perimeter_se_point.z
            east_lower_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_lower_perimeter_space.setBuildingStory(story)
            east_lower_perimeter_space.setName("Story #{floor+1} East Lower Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            south_perimeter_polygon = OpenStudio::Point3dVector.new
            south_perimeter_polygon << se_point
            south_perimeter_polygon << sw_point
            south_perimeter_polygon << perimeter_lower_sw_point
            south_perimeter_polygon << perimeter_se_point
            south_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(south_perimeter_polygon, floor_to_floor_height, model)
            south_perimeter_space = south_perimeter_space.get
            m[0,3] = sw_point.x
            m[1,3] = sw_point.y
            m[2,3] = sw_point.z
            south_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_perimeter_space.setBuildingStory(story)
            south_perimeter_space.setName("Story #{floor+1} South Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            west_core_polygon = OpenStudio::Point3dVector.new
            west_core_polygon << perimeter_lower_sw_point
            west_core_polygon << perimeter_nw_point
            west_core_polygon << perimeter_upper_ne_point
            west_core_polygon << perimeter_upper_sw_point
            west_core_space = OpenStudio::Model::Space::fromFloorPrint(west_core_polygon, floor_to_floor_height, model)
            west_core_space = west_core_space.get
            m[0,3] = perimeter_lower_sw_point.x
            m[1,3] = perimeter_lower_sw_point.y
            m[2,3] = perimeter_lower_sw_point.z
            west_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_core_space.setBuildingStory(story)
            west_core_space.setName("Story #{floor+1} West Core Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            east_core_polygon = OpenStudio::Point3dVector.new
            east_core_polygon << perimeter_upper_sw_point
            east_core_polygon << perimeter_lower_ne_point
            east_core_polygon << perimeter_se_point
            east_core_polygon << perimeter_lower_sw_point
            east_core_space = OpenStudio::Model::Space::fromFloorPrint(east_core_polygon, floor_to_floor_height, model)
            east_core_space = east_core_space.get
            m[0,3] = perimeter_lower_sw_point.x
            m[1,3] = perimeter_lower_sw_point.y
            m[2,3] = perimeter_lower_sw_point.z
            east_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_core_space.setBuildingStory(story)
            east_core_space.setName("Story #{floor+1} East Core Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            # Minimal zones
          else
            west_polygon = OpenStudio::Point3dVector.new
            west_polygon << sw_point
            west_polygon << nw_point
            west_polygon << upper_ne_point
            west_polygon << upper_sw_point
            west_space = OpenStudio::Model::Space::fromFloorPrint(west_polygon, floor_to_floor_height, model)
            west_space = west_space.get
            m[0,3] = sw_point.x
            m[1,3] = sw_point.y
            m[2,3] = sw_point.z
            west_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_space.setBuildingStory(story)
            west_space.setName("Story #{floor+1} West Space")

            num_complete += 1
            runner.updateProgress(100*num_complete/num_total)

            east_polygon = OpenStudio::Point3dVector.new
            east_polygon << sw_point
            east_polygon << upper_sw_point
            east_polygon << lower_ne_point
            east_polygon << se_point
            east_space = OpenStudio::Model::Space::fromFloorPrint(east_polygon, floor_to_floor_height, model)
            east_space = east_space.get
            m[0,3] = sw_point.x
            m[1,3] = sw_point.y
            m[2,3] = sw_point.z
            east_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_space.setBuildingStory(story)
            east_space.setName("Story #{floor+1} East Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

          end

          #Set vertical story position
          story.setNominalZCoordinate(z)

        end #End of floor loop
        BTAP::Geometry::match_surfaces(model)
        return model
      end

      def self.create_shape_rectangle(model,
          length = 100.0,
          width = 100.0,
          num_floors = 3,
          floor_to_floor_height = 3.8,
          plenum_height = 1,
          perimeter_zone_depth = 4.57
        )

        if length <= 1e-4
          raise("Length must be greater than 0.")
          return false
        end

        if width <= 1e-4
          raise("Width must be greater than 0.")
          return false
        end

        if num_floors <= 1e-4
          raise("Number of floors must be greater than 0.")
          return false
        end

        if floor_to_floor_height <= 1e-4
          raise("Floor to floor height must be greater than 0.")
          return false
        end

        if plenum_height < 0
          raise("Plenum height must be greater than or equal to 0.")
          return false
        end

        shortest_side = [length,width].min
        if perimeter_zone_depth < 0 or 2*perimeter_zone_depth >= (shortest_side - 1e-4)
          raise("Perimeter zone depth must be greater than or equal to 0 and less than #{shortest_side/2}m")
          return false
        end

        #    # Create progress bar
        #    runner.createProgressBar("Creating Spaces")
        #    num_total = perimeter_zone_depth>0 ? num_floors*5 : num_floors
        #    num_complete = 0

        #Loop through the number of floors
        for floor in (0..num_floors-1)

          z = floor_to_floor_height * floor

          #Create a new story within the building
          story = OpenStudio::Model::BuildingStory.new(model)
          story.setNominalFloortoFloorHeight(floor_to_floor_height)
          story.setName("Story #{floor+1}")


          nw_point = OpenStudio::Point3d.new(0,width,z)
          ne_point = OpenStudio::Point3d.new(length,width,z)
          se_point = OpenStudio::Point3d.new(length,0,z)
          sw_point = OpenStudio::Point3d.new(0,0,z)

          # Identity matrix for setting space origins
          m = OpenStudio::Matrix.new(4,4,0)
          m[0,0] = 1
          m[1,1] = 1
          m[2,2] = 1
          m[3,3] = 1

          #Define polygons for a rectangular building
          if perimeter_zone_depth > 0
            perimeter_nw_point = nw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_ne_point = ne_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_se_point = se_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_sw_point = sw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)

            west_polygon = OpenStudio::Point3dVector.new
            west_polygon << sw_point
            west_polygon << nw_point
            west_polygon << perimeter_nw_point
            west_polygon << perimeter_sw_point
            west_space = OpenStudio::Model::Space::fromFloorPrint(west_polygon, floor_to_floor_height, model)
            west_space = west_space.get
            m[0,3] = sw_point.x
            m[1,3] = sw_point.y
            m[2,3] = sw_point.z
            west_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_space.setBuildingStory(story)
            west_space.setName("Story #{floor+1} West Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            north_polygon = OpenStudio::Point3dVector.new
            north_polygon << nw_point
            north_polygon << ne_point
            north_polygon << perimeter_ne_point
            north_polygon << perimeter_nw_point
            north_space = OpenStudio::Model::Space::fromFloorPrint(north_polygon, floor_to_floor_height, model)
            north_space = north_space.get
            m[0,3] = perimeter_nw_point.x
            m[1,3] = perimeter_nw_point.y
            m[2,3] = perimeter_nw_point.z
            north_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_space.setBuildingStory(story)
            north_space.setName("Story #{floor+1} North Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            east_polygon = OpenStudio::Point3dVector.new
            east_polygon << ne_point
            east_polygon << se_point
            east_polygon << perimeter_se_point
            east_polygon << perimeter_ne_point
            east_space = OpenStudio::Model::Space::fromFloorPrint(east_polygon, floor_to_floor_height, model)
            east_space = east_space.get
            m[0,3] = perimeter_se_point.x
            m[1,3] = perimeter_se_point.y
            m[2,3] = perimeter_se_point.z
            east_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_space.setBuildingStory(story)
            east_space.setName("Story #{floor+1} East Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            south_polygon = OpenStudio::Point3dVector.new
            south_polygon << se_point
            south_polygon << sw_point
            south_polygon << perimeter_sw_point
            south_polygon << perimeter_se_point
            south_space = OpenStudio::Model::Space::fromFloorPrint(south_polygon, floor_to_floor_height, model)
            south_space = south_space.get
            m[0,3] = sw_point.x
            m[1,3] = sw_point.y
            m[2,3] = sw_point.z
            south_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_space.setBuildingStory(story)
            south_space.setName("Story #{floor+1} South Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            core_polygon = OpenStudio::Point3dVector.new
            core_polygon << perimeter_sw_point
            core_polygon << perimeter_nw_point
            core_polygon << perimeter_ne_point
            core_polygon << perimeter_se_point
            core_space = OpenStudio::Model::Space::fromFloorPrint(core_polygon, floor_to_floor_height, model)
            core_space = core_space.get
            m[0,3] = perimeter_sw_point.x
            m[1,3] = perimeter_sw_point.y
            m[2,3] = perimeter_sw_point.z
            core_space.changeTransformation(OpenStudio::Transformation.new(m))
            core_space.setBuildingStory(story)
            core_space.setName("Story #{floor+1} Core Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            # Minimal zones
          else
            core_polygon = OpenStudio::Point3dVector.new
            core_polygon << sw_point
            core_polygon << nw_point
            core_polygon << ne_point
            core_polygon << se_point
            core_space = OpenStudio::Model::Space::fromFloorPrint(core_polygon, floor_to_floor_height, model)
            core_space = core_space.get
            m[0,3] = sw_point.x
            m[1,3] = sw_point.y
            m[2,3] = sw_point.z
            core_space.changeTransformation(OpenStudio::Transformation.new(m))
            core_space.setBuildingStory(story)
            core_space.setName("Story #{floor+1} Core Space")
            #
            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

          end

          #Set vertical story position
          story.setNominalZCoordinate(z)

        end #End of floor loop

        #    runner.destroyProgressBar
        BTAP::Geometry::match_surfaces(model)
        return model
      end

      def self.create_shape_t(model,
          length = 40.0,
          width = 40.0,
          upper_end_width = 20.0,
          lower_end_length = 20.0,
          left_end_offset = 10.0,
          num_floors = 3,
          floor_to_floor_height = 3.8,
          plenum_height = 1.0,
          perimeter_zone_depth = 4.57
        )

        if length <= 1e-4
          raise("Length must be greater than 0.")
          return false
        end

        if width <= 1e-4
          raise("Width must be greater than 0.")
          return false
        end

        if upper_end_width <= 1e-4 or upper_end_width >= (width - 1e-4)
          raise("Upper end width must be greater than 0 and less than #{width}m.")
          return false
        end

        if lower_end_length <= 1e-4 or lower_end_length >= (length - 1e-4)
          raise("Lower end length must be greater than 0 and less than #{length}m.")
          return false
        end

        if left_end_offset <= 1e-4 or left_end_offset >= (length - lower_end_length - 1e-4)
          raise("Left end offset must be greater than 0 and less than #{length - lower_end_length}m.")
          return false
        end

        if num_floors <= 1e-4
          raise("Number of floors must be greater than 0.")
          return false
        end

        if floor_to_floor_height <= 1e-4
          raise("Floor to floor height must be greater than 0.")
          return false
        end

        if plenum_height < 0
          raise("Plenum height must be greater than or equal to 0.")
          return false
        end

        shortest_side = [length,width,upper_end_width,lower_end_length].min
        if perimeter_zone_depth < 0 or 2*perimeter_zone_depth >= (shortest_side - 1e-4)
          raise("Perimeter zone depth must be greater than or equal to 0 and less than #{shortest_side/2}m.")
          return false
        end

        # Create progress bar
        #    runner.createProgressBar("Creating Spaces")
        #    num_total = perimeter_zone_depth>0 ? num_floors*10 : num_floors*2
        #    num_complete = 0

        # Loop through the number of floors
        for floor in (0..num_floors-1)

          z = floor_to_floor_height * floor

          #Create a new story within the building
          story = OpenStudio::Model::BuildingStory.new(model)
          story.setNominalFloortoFloorHeight(floor_to_floor_height)
          story.setName("Story #{floor+1}")


          lower_ne_point = OpenStudio::Point3d.new(left_end_offset,width - upper_end_width,z)
          upper_sw_point = OpenStudio::Point3d.new(0,width - upper_end_width,z)
          upper_nw_point = OpenStudio::Point3d.new(0,width,z)
          upper_ne_point = OpenStudio::Point3d.new(length,width,z)
          upper_se_point = OpenStudio::Point3d.new(length,width - upper_end_width,z)
          lower_nw_point = OpenStudio::Point3d.new(left_end_offset + lower_end_length,width - upper_end_width,z)
          lower_se_point = OpenStudio::Point3d.new(left_end_offset + lower_end_length,0,z)
          lower_sw_point = OpenStudio::Point3d.new(left_end_offset,0,z)

          # Identity matrix for setting space origins
          m = OpenStudio::Matrix.new(4,4,0)
          m[0,0] = 1
          m[1,1] = 1
          m[2,2] = 1
          m[3,3] = 1

          # Define polygons for a L-shape building with perimeter core zoning
          if perimeter_zone_depth > 0
            perimeter_lower_ne_point = lower_ne_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_upper_sw_point = upper_sw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_upper_nw_point = upper_nw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_upper_ne_point = upper_ne_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_upper_se_point = upper_se_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_lower_nw_point = lower_nw_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_lower_se_point = lower_se_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_lower_sw_point = lower_sw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)

            west_lower_perimeter_polygon = OpenStudio::Point3dVector.new
            west_lower_perimeter_polygon << lower_sw_point
            west_lower_perimeter_polygon << lower_ne_point
            west_lower_perimeter_polygon << perimeter_lower_ne_point
            west_lower_perimeter_polygon << perimeter_lower_sw_point
            west_lower_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(west_lower_perimeter_polygon, floor_to_floor_height, model)
            west_lower_perimeter_space = west_lower_perimeter_space.get
            m[0,3] = lower_sw_point.x
            m[1,3] = lower_sw_point.y
            m[2,3] = lower_sw_point.z
            west_lower_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_lower_perimeter_space.setBuildingStory(story)
            west_lower_perimeter_space.setName("Story #{floor+1} West Lower Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            south_upper_left_perimeter_polygon = OpenStudio::Point3dVector.new
            south_upper_left_perimeter_polygon << lower_ne_point
            south_upper_left_perimeter_polygon << upper_sw_point
            south_upper_left_perimeter_polygon << perimeter_upper_sw_point
            south_upper_left_perimeter_polygon << perimeter_lower_ne_point
            south_upper_left_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(south_upper_left_perimeter_polygon, floor_to_floor_height, model)
            south_upper_left_perimeter_space = south_upper_left_perimeter_space.get
            m[0,3] = upper_sw_point.x
            m[1,3] = upper_sw_point.y
            m[2,3] = upper_sw_point.z
            south_upper_left_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_upper_left_perimeter_space.setBuildingStory(story)
            south_upper_left_perimeter_space.setName("Story #{floor+1} South Upper Left Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            west_upper_perimeter_polygon = OpenStudio::Point3dVector.new
            west_upper_perimeter_polygon << upper_sw_point
            west_upper_perimeter_polygon << upper_nw_point
            west_upper_perimeter_polygon << perimeter_upper_nw_point
            west_upper_perimeter_polygon << perimeter_upper_sw_point
            west_upper_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(west_upper_perimeter_polygon, floor_to_floor_height, model)
            west_upper_perimeter_space = west_upper_perimeter_space.get
            m[0,3] = upper_sw_point.x
            m[1,3] = upper_sw_point.y
            m[2,3] = upper_sw_point.z
            west_upper_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_upper_perimeter_space.setBuildingStory(story)
            west_upper_perimeter_space.setName("Story #{floor+1} West Upper Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            north_perimeter_polygon = OpenStudio::Point3dVector.new
            north_perimeter_polygon << upper_nw_point
            north_perimeter_polygon << upper_ne_point
            north_perimeter_polygon << perimeter_upper_ne_point
            north_perimeter_polygon << perimeter_upper_nw_point
            north_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(north_perimeter_polygon, floor_to_floor_height, model)
            north_perimeter_space = north_perimeter_space.get
            m[0,3] = perimeter_upper_nw_point.x
            m[1,3] = perimeter_upper_nw_point.y
            m[2,3] = perimeter_upper_nw_point.z
            north_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_perimeter_space.setBuildingStory(story)
            north_perimeter_space.setName("Story #{floor+1} North Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            east_upper_perimeter_polygon = OpenStudio::Point3dVector.new
            east_upper_perimeter_polygon << upper_ne_point
            east_upper_perimeter_polygon << upper_se_point
            east_upper_perimeter_polygon << perimeter_upper_se_point
            east_upper_perimeter_polygon << perimeter_upper_ne_point
            east_upper_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(east_upper_perimeter_polygon, floor_to_floor_height, model)
            east_upper_perimeter_space = east_upper_perimeter_space.get
            m[0,3] = perimeter_upper_se_point.x
            m[1,3] = perimeter_upper_se_point.y
            m[2,3] = perimeter_upper_se_point.z
            east_upper_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_upper_perimeter_space.setBuildingStory(story)
            east_upper_perimeter_space.setName("Story #{floor+1} East Upper Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            south_upper_right_perimeter_polygon = OpenStudio::Point3dVector.new
            south_upper_right_perimeter_polygon << upper_se_point
            south_upper_right_perimeter_polygon << lower_nw_point
            south_upper_right_perimeter_polygon << perimeter_lower_nw_point
            south_upper_right_perimeter_polygon << perimeter_upper_se_point
            south_upper_right_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(south_upper_right_perimeter_polygon, floor_to_floor_height, model)
            south_upper_right_perimeter_space = south_upper_right_perimeter_space.get
            m[0,3] = lower_nw_point.x
            m[1,3] = lower_nw_point.y
            m[2,3] = lower_nw_point.z
            south_upper_right_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_upper_right_perimeter_space.setBuildingStory(story)
            south_upper_right_perimeter_space.setName("Story #{floor+1} South Upper Left Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            east_lower_perimeter_polygon = OpenStudio::Point3dVector.new
            east_lower_perimeter_polygon << lower_nw_point
            east_lower_perimeter_polygon << lower_se_point
            east_lower_perimeter_polygon << perimeter_lower_se_point
            east_lower_perimeter_polygon << perimeter_lower_nw_point
            east_lower_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(east_lower_perimeter_polygon, floor_to_floor_height, model)
            east_lower_perimeter_space = east_lower_perimeter_space.get
            m[0,3] = perimeter_lower_se_point.x
            m[1,3] = perimeter_lower_se_point.y
            m[2,3] = perimeter_lower_se_point.z
            east_lower_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_lower_perimeter_space.setBuildingStory(story)
            east_lower_perimeter_space.setName("Story #{floor+1} East Lower Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            south_lower_perimeter_polygon = OpenStudio::Point3dVector.new
            south_lower_perimeter_polygon << lower_se_point
            south_lower_perimeter_polygon << lower_sw_point
            south_lower_perimeter_polygon << perimeter_lower_sw_point
            south_lower_perimeter_polygon << perimeter_lower_se_point
            south_lower_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(south_lower_perimeter_polygon, floor_to_floor_height, model)
            south_lower_perimeter_space = south_lower_perimeter_space.get
            m[0,3] = lower_sw_point.x
            m[1,3] = lower_sw_point.y
            m[2,3] = lower_sw_point.z
            south_lower_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_lower_perimeter_space.setBuildingStory(story)
            south_lower_perimeter_space.setName("Story #{floor+1} South Lower Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            north_core_polygon = OpenStudio::Point3dVector.new
            north_core_polygon << perimeter_upper_sw_point
            north_core_polygon << perimeter_upper_nw_point
            north_core_polygon << perimeter_upper_ne_point
            north_core_polygon << perimeter_upper_se_point
            north_core_polygon << perimeter_lower_nw_point
            north_core_polygon << perimeter_lower_ne_point
            north_core_space = OpenStudio::Model::Space::fromFloorPrint(north_core_polygon, floor_to_floor_height, model)
            north_core_space = north_core_space.get
            m[0,3] = perimeter_upper_sw_point.x
            m[1,3] = perimeter_upper_sw_point.y
            m[2,3] = perimeter_upper_sw_point.z
            north_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_core_space.setBuildingStory(story)
            north_core_space.setName("Story #{floor+1} North Core Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            south_core_polygon = OpenStudio::Point3dVector.new
            south_core_polygon << perimeter_lower_sw_point
            south_core_polygon << perimeter_lower_ne_point
            south_core_polygon << perimeter_lower_nw_point
            south_core_polygon << perimeter_lower_se_point
            south_core_space = OpenStudio::Model::Space::fromFloorPrint(south_core_polygon, floor_to_floor_height, model)
            south_core_space = south_core_space.get
            m[0,3] = perimeter_lower_sw_point.x
            m[1,3] = perimeter_lower_sw_point.y
            m[2,3] = perimeter_lower_sw_point.z
            south_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_core_space.setBuildingStory(story)
            south_core_space.setName("Story #{floor+1} South Core Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            # Minimal zones
          else
            north_polygon = OpenStudio::Point3dVector.new
            north_polygon << upper_sw_point
            north_polygon << upper_nw_point
            north_polygon << upper_ne_point
            north_polygon << upper_se_point
            north_polygon << lower_nw_point
            north_polygon << lower_ne_point
            north_space = OpenStudio::Model::Space::fromFloorPrint(north_polygon, floor_to_floor_height, model)
            north_space = north_space.get
            m[0,3] = upper_sw_point.x
            m[1,3] = upper_sw_point.y
            m[2,3] = upper_sw_point.z
            north_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_space.setBuildingStory(story)
            north_space.setName("Story #{floor+1} North Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            south_polygon = OpenStudio::Point3dVector.new
            south_polygon << lower_sw_point
            south_polygon << lower_ne_point
            south_polygon << lower_nw_point
            south_polygon << lower_se_point
            south_space = OpenStudio::Model::Space::fromFloorPrint(south_polygon, floor_to_floor_height, model)
            south_space = south_space.get
            m[0,3] = lower_sw_point.x
            m[1,3] = lower_sw_point.y
            m[2,3] = lower_sw_point.z
            south_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_space.setBuildingStory(story)
            south_space.setName("Story #{floor+1} South Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

          end

          #Set vertical story position
          story.setNominalZCoordinate(z)

        end #End of floor loop

        BTAP::Geometry::match_surfaces(model)
        return model
      end

      def self.create_shape_u(model,
          length = 40.0,
          left_width = 40.0,
          right_width = 40.0,
          left_end_length = 15.0,
          right_end_length = 15.0,
          left_end_offset = 25.0,
          num_floors = 3.0,
          floor_to_floor_height = 3.8,
          plenum_height = 1.0,
          perimeter_zone_depth = 4.57
        )

        if length <= 1e-4
          raise("Length must be greater than 0.")
          return false
        end

        if left_width <= 1e-4
          raise("Left width must be greater than 0.")
          return false
        end

        if left_end_length <= 1e-4 or left_end_length >= (length - 1e-4)
          raise("Left end length must be greater than 0 and less than #{length}m.")
          return false
        end

        if right_end_length <= 1e-4 or right_end_length >= (length - left_end_length - 1e-4)
          raise("Right end length must be greater than 0 and less than #{length - left_end_length}m.")
          return false
        end

        if left_end_offset <= 1e-4 or left_end_offset >= (left_width - 1e-4)
          raise("Left end offset must be greater than 0 and less than #{left_width}m.")
          return false
        end

        if right_width <= (left_width - left_end_offset - 1e-4)
          raise("Right width must be greater than #{left_width - left_end_offset}m.")
          return false
        end

        if num_floors <= 1e-4
          raise("Number of floors must be greater than 0.")
          return false
        end

        if floor_to_floor_height <= 1e-4
          raise("Floor to floor height must be greater than 0.")
          return false
        end

        if plenum_height < 0
          raise("Plenum height must be greater than or equal to 0.")
          return false
        end

        shortest_side = [length/2,left_width,right_width,left_end_length,right_end_length,left_width-left_end_offset].min
        if perimeter_zone_depth < 0 or 2*perimeter_zone_depth >= (shortest_side - 1e-4)
          raise("Perimeter zone depth must be greater than or equal to 0 and less than #{shortest_side/2}m.")
          return false
        end

        # Create progress bar
        #    runner.createProgressBar("Creating Spaces")
        #    num_total = perimeter_zone_depth>0 ? num_floors*11 : num_floors*3
        #    num_complete = 0

        # Loop through the number of floors
        for floor in (0..num_floors-1)

          z = floor_to_floor_height * floor

          #Create a new story within the building
          story = OpenStudio::Model::BuildingStory.new(model)
          story.setNominalFloortoFloorHeight(floor_to_floor_height)
          story.setName("Story #{floor+1}")


          left_nw_point = OpenStudio::Point3d.new(0,left_width,z)
          left_ne_point = OpenStudio::Point3d.new(left_end_length,left_width,z)
          upper_sw_point = OpenStudio::Point3d.new(left_end_length,left_width - left_end_offset,z)
          upper_se_point = OpenStudio::Point3d.new(length - right_end_length,left_width - left_end_offset,z)
          right_nw_point = OpenStudio::Point3d.new(length - right_end_length,right_width,z)
          right_ne_point = OpenStudio::Point3d.new(length,right_width,z)
          lower_se_point = OpenStudio::Point3d.new(length,0,z)
          lower_sw_point = OpenStudio::Point3d.new(0,0,z)

          # Identity matrix for setting space origins
          m = OpenStudio::Matrix.new(4,4,0)
          m[0,0] = 1
          m[1,1] = 1
          m[2,2] = 1
          m[3,3] = 1

          # Define polygons for a L-shape building with perimeter core zoning
          if perimeter_zone_depth > 0
            perimeter_left_nw_point = left_nw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_left_ne_point = left_ne_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_upper_sw_point = upper_sw_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_upper_se_point = upper_se_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_right_nw_point = right_nw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_right_ne_point = right_ne_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
            perimeter_lower_se_point = lower_se_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
            perimeter_lower_sw_point = lower_sw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)

            west_left_perimeter_polygon = OpenStudio::Point3dVector.new
            west_left_perimeter_polygon << lower_sw_point
            west_left_perimeter_polygon << left_nw_point
            west_left_perimeter_polygon << perimeter_left_nw_point
            west_left_perimeter_polygon << perimeter_lower_sw_point
            west_left_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(west_left_perimeter_polygon, floor_to_floor_height, model)
            west_left_perimeter_space = west_left_perimeter_space.get
            m[0,3] = lower_sw_point.x
            m[1,3] = lower_sw_point.y
            m[2,3] = lower_sw_point.z
            west_left_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_left_perimeter_space.setBuildingStory(story)
            west_left_perimeter_space.setName("Story #{floor+1} West Left Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            north_left_perimeter_polygon = OpenStudio::Point3dVector.new
            north_left_perimeter_polygon << left_nw_point
            north_left_perimeter_polygon << left_ne_point
            north_left_perimeter_polygon << perimeter_left_ne_point
            north_left_perimeter_polygon << perimeter_left_nw_point
            north_left_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(north_left_perimeter_polygon, floor_to_floor_height, model)
            north_left_perimeter_space = north_left_perimeter_space.get
            m[0,3] = perimeter_left_nw_point.x
            m[1,3] = perimeter_left_nw_point.y
            m[2,3] = perimeter_left_nw_point.z
            north_left_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_left_perimeter_space.setBuildingStory(story)
            north_left_perimeter_space.setName("Story #{floor+1} North Left Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            east_left_perimeter_polygon = OpenStudio::Point3dVector.new
            east_left_perimeter_polygon << left_ne_point
            east_left_perimeter_polygon << upper_sw_point
            east_left_perimeter_polygon << perimeter_upper_sw_point
            east_left_perimeter_polygon << perimeter_left_ne_point
            east_left_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(east_left_perimeter_polygon, floor_to_floor_height, model)
            east_left_perimeter_space = east_left_perimeter_space.get
            m[0,3] = perimeter_upper_sw_point.x
            m[1,3] = perimeter_upper_sw_point.y
            m[2,3] = perimeter_upper_sw_point.z
            east_left_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_left_perimeter_space.setBuildingStory(story)
            east_left_perimeter_space.setName("Story #{floor+1} East Left Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            north_lower_perimeter_polygon = OpenStudio::Point3dVector.new
            north_lower_perimeter_polygon << upper_sw_point
            north_lower_perimeter_polygon << upper_se_point
            north_lower_perimeter_polygon << perimeter_upper_se_point
            north_lower_perimeter_polygon << perimeter_upper_sw_point
            north_lower_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(north_lower_perimeter_polygon, floor_to_floor_height, model)
            north_lower_perimeter_space = north_lower_perimeter_space.get
            m[0,3] = perimeter_upper_sw_point.x
            m[1,3] = perimeter_upper_sw_point.y
            m[2,3] = perimeter_upper_sw_point.z
            north_lower_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_lower_perimeter_space.setBuildingStory(story)
            north_lower_perimeter_space.setName("Story #{floor+1} North Lower Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            west_right_perimeter_polygon = OpenStudio::Point3dVector.new
            west_right_perimeter_polygon << upper_se_point
            west_right_perimeter_polygon << right_nw_point
            west_right_perimeter_polygon << perimeter_right_nw_point
            west_right_perimeter_polygon << perimeter_upper_se_point
            west_right_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(west_right_perimeter_polygon, floor_to_floor_height, model)
            west_right_perimeter_space = west_right_perimeter_space.get
            m[0,3] = upper_se_point.x
            m[1,3] = upper_se_point.y
            m[2,3] = upper_se_point.z
            west_right_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_right_perimeter_space.setBuildingStory(story)
            west_right_perimeter_space.setName("Story #{floor+1} West Right Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            north_right_perimeter_polygon = OpenStudio::Point3dVector.new
            north_right_perimeter_polygon << right_nw_point
            north_right_perimeter_polygon << right_ne_point
            north_right_perimeter_polygon << perimeter_right_ne_point
            north_right_perimeter_polygon << perimeter_right_nw_point
            north_right_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(north_right_perimeter_polygon, floor_to_floor_height, model)
            north_right_perimeter_space = north_right_perimeter_space.get
            m[0,3] = perimeter_right_nw_point.x
            m[1,3] = perimeter_right_nw_point.y
            m[2,3] = perimeter_right_nw_point.z
            north_right_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            north_right_perimeter_space.setBuildingStory(story)
            north_right_perimeter_space.setName("Story #{floor+1} North Right Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            east_right_perimeter_polygon = OpenStudio::Point3dVector.new
            east_right_perimeter_polygon << right_ne_point
            east_right_perimeter_polygon << lower_se_point
            east_right_perimeter_polygon << perimeter_lower_se_point
            east_right_perimeter_polygon << perimeter_right_ne_point
            east_right_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(east_right_perimeter_polygon, floor_to_floor_height, model)
            east_right_perimeter_space = east_right_perimeter_space.get
            m[0,3] = perimeter_lower_se_point.x
            m[1,3] = perimeter_lower_se_point.y
            m[2,3] = perimeter_lower_se_point.z
            east_right_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_right_perimeter_space.setBuildingStory(story)
            east_right_perimeter_space.setName("Story #{floor+1} East Right Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            south_lower_perimeter_polygon = OpenStudio::Point3dVector.new
            south_lower_perimeter_polygon << lower_se_point
            south_lower_perimeter_polygon << lower_sw_point
            south_lower_perimeter_polygon << perimeter_lower_sw_point
            south_lower_perimeter_polygon << perimeter_lower_se_point
            south_lower_perimeter_space = OpenStudio::Model::Space::fromFloorPrint(south_lower_perimeter_polygon, floor_to_floor_height, model)
            south_lower_perimeter_space = south_lower_perimeter_space.get
            m[0,3] = lower_sw_point.x
            m[1,3] = lower_sw_point.y
            m[2,3] = lower_sw_point.z
            south_lower_perimeter_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_lower_perimeter_space.setBuildingStory(story)
            south_lower_perimeter_space.setName("Story #{floor+1} South Lower Perimeter Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            west_core_polygon = OpenStudio::Point3dVector.new
            west_core_polygon << perimeter_lower_sw_point
            west_core_polygon << perimeter_left_nw_point
            west_core_polygon << perimeter_left_ne_point
            west_core_polygon << perimeter_upper_sw_point
            west_core_space = OpenStudio::Model::Space::fromFloorPrint(west_core_polygon, floor_to_floor_height, model)
            west_core_space = west_core_space.get
            m[0,3] = perimeter_lower_sw_point.x
            m[1,3] = perimeter_lower_sw_point.y
            m[2,3] = perimeter_lower_sw_point.z
            west_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_core_space.setBuildingStory(story)
            west_core_space.setName("Story #{floor+1} West Core Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            south_core_polygon = OpenStudio::Point3dVector.new
            south_core_polygon << perimeter_upper_sw_point
            south_core_polygon << perimeter_upper_se_point
            south_core_polygon << perimeter_lower_se_point
            south_core_polygon << perimeter_lower_sw_point
            south_core_space = OpenStudio::Model::Space::fromFloorPrint(south_core_polygon, floor_to_floor_height, model)
            south_core_space = south_core_space.get
            m[0,3] = perimeter_lower_sw_point.x
            m[1,3] = perimeter_lower_sw_point.y
            m[2,3] = perimeter_lower_sw_point.z
            south_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_core_space.setBuildingStory(story)
            south_core_space.setName("Story #{floor+1} South Core Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            east_core_polygon = OpenStudio::Point3dVector.new
            east_core_polygon << perimeter_upper_se_point
            east_core_polygon << perimeter_right_nw_point
            east_core_polygon << perimeter_right_ne_point
            east_core_polygon << perimeter_lower_se_point
            east_core_space = OpenStudio::Model::Space::fromFloorPrint(east_core_polygon, floor_to_floor_height, model)
            east_core_space = east_core_space.get
            m[0,3] = perimeter_upper_se_point.x
            m[1,3] = perimeter_upper_se_point.y
            m[2,3] = perimeter_upper_se_point.z
            east_core_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_core_space.setBuildingStory(story)
            east_core_space.setName("Story #{floor+1} East Core Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            # Minimal zones
          else
            west_polygon = OpenStudio::Point3dVector.new
            west_polygon << lower_sw_point
            west_polygon << left_nw_point
            west_polygon << left_ne_point
            west_polygon << upper_sw_point
            west_space = OpenStudio::Model::Space::fromFloorPrint(west_polygon, floor_to_floor_height, model)
            west_space = west_space.get
            m[0,3] = lower_sw_point.x
            m[1,3] = lower_sw_point.y
            m[2,3] = lower_sw_point.z
            west_space.changeTransformation(OpenStudio::Transformation.new(m))
            west_space.setBuildingStory(story)
            west_space.setName("Story #{floor+1} West Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            south_polygon = OpenStudio::Point3dVector.new
            south_polygon << lower_sw_point
            south_polygon << upper_sw_point
            south_polygon << upper_se_point
            south_polygon << lower_se_point
            south_space = OpenStudio::Model::Space::fromFloorPrint(south_polygon, floor_to_floor_height, model)
            south_space = south_space.get
            m[0,3] = lower_sw_point.x
            m[1,3] = lower_sw_point.y
            m[2,3] = lower_sw_point.z
            south_space.changeTransformation(OpenStudio::Transformation.new(m))
            south_space.setBuildingStory(story)
            south_space.setName("Story #{floor+1} South Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

            east_polygon = OpenStudio::Point3dVector.new
            east_polygon << upper_se_point
            east_polygon << right_nw_point
            east_polygon << right_ne_point
            east_polygon << lower_se_point
            east_space = OpenStudio::Model::Space::fromFloorPrint(east_polygon, floor_to_floor_height, model)
            east_space = east_space.get
            m[0,3] = upper_se_point.x
            m[1,3] = upper_se_point.y
            m[2,3] = upper_se_point.z
            east_space.changeTransformation(OpenStudio::Transformation.new(m))
            east_space.setBuildingStory(story)
            east_space.setName("Story #{floor+1} East Space")

            #        num_complete += 1
            #        runner.updateProgress(100*num_complete/num_total)

          end

          #Set vertical story position
          story.setNominalZCoordinate(z)

        end #End of floor loop

        #    runner.destroyProgressBar
        BTAP::Geometry::match_surfaces(model)
        return model
      end

      def self.test_geometry()
        courtyard = OpenStudio::Model::Model.new()
        Geometry.create_shape_courtyard(courtyard)
        courtyard.save(OpenStudio::Path.new(BTAP::TESTING_FOLDER + "/courtyard.osm"))

        rectangle = OpenStudio::Model::Model.new()
        Geometry.create_shape_rectangle(rectangle)
        Geometry.scale_model(rectangle,2,0.5,1.0)
        Geometry.rotate_model(rectangle,45.0)
        File.delete(BTAP::TESTING_FOLDER + "/rectangle.osm")
        rectangle.save(OpenStudio::Path.new(BTAP::TESTING_FOLDER + "/rectangle.osm"))

        l_shape = OpenStudio::Model::Model.new()
        Geometry.create_shape_l(l_shape)
        l_shape.save(OpenStudio::Path.new(BTAP::TESTING_FOLDER + "/l_shape.osm"))

        h_shape = OpenStudio::Model::Model.new()
        Geometry.create_shape_h(h_shape)
        h_shape.save(OpenStudio::Path.new(BTAP::TESTING_FOLDER + "/h_shape.osm"))

        t_shape = OpenStudio::Model::Model.new()
        Geometry.create_shape_t(t_shape)
        t_shape.save(OpenStudio::Path.new(BTAP::TESTING_FOLDER + "/t_shape.osm"))

        u_shape = OpenStudio::Model::Model.new()
        Geometry.create_shape_u(u_shape)
        u_shape.save(OpenStudio::Path.new(BTAP::TESTING_FOLDER + "/u_shape.osm"))
      end
    end
    def self.match_surfaces(model)
      model.getSpaces.each do |space1|
        model.getSpaces.each do |space2|
          space1.matchSurfaces(space2)
        end
      end
      return model
    end
    # This method will scale the model
    # @params model [OpenStudio::Model::Model] the model object.
    # @params x [Float] x scalar multiplier.
    # @params y [Float] y scalar multiplier.
    # @params z [Float] z scalar multiplier.
    # @return model [OpenStudio::Model::Model] the model object.
    def self.scale_model(model,x,y,z)
      # Identity matrix for setting space origins
      m = OpenStudio::Matrix.new(4,4,0)

      m[0,0] = 1.0/x
      m[1,1] = 1.0/y
      m[2,2] = 1.0/z
      m[3,3] = 1.0
      t = OpenStudio::Transformation.new(m)
      model.getPlanarSurfaceGroups().each do |planar_surface|
        planar_surface.changeTransformation(t)
      end
      return model
    end

    def self.get_fwdr(model)
      outdoor_surfaces = BTAP::Geometry::Surfaces::filter_by_boundary_condition(model.getSurfaces(), "Outdoors")
      outdoor_walls = BTAP::Geometry::Surfaces::filter_by_surface_types(outdoor_surfaces, "Wall")
      self.get_surface_to_subsurface_ratio(outdoor_walls)
    end

    def self.get_srr(model)
      outdoor_surfaces = BTAP::Geometry::Surfaces::filter_by_boundary_condition(model.getSurfaces(), "Outdoors")
      outdoor_roofs = BTAP::Geometry::Surfaces::filter_by_surface_types(outdoor_surfaces, "RoofCeiling")
      self.get_surface_to_subsurface_ratio(outdoor_roofs)
    end

    def self.get_surface_to_subsurface_ratio(surfaces)
      total_gross_surface_area = 0.0
      total_net_surface_area = 0.0
      surfaces.each do |surface|
        total_gross_surface_area  = total_gross_surface_area + surface.grossArea
        total_net_surface_area = total_net_surface_area + surface.netArea
      end
      return 1.0  - (total_net_surface_area/total_gross_surface_area )
    end



    # This method will rotate the model
    # @params model [OpenStudio::Model::Model] the model object.
    # @params degrees [Float] rotation value
    # @return model [OpenStudio::Model::Model] the model object.
    def self.rotate_model(model, degrees)
      # Identity matrix for setting space origins
      t = OpenStudio::Transformation::rotation(OpenStudio::Vector3d.new(0,0,1),degrees*Math::PI/180)
      model.getPlanarSurfaceGroups().each { |planar_surface| planar_surface.changeTransformation(t) }
      return model
    end


    module BuildingStoreys

      #This method will delete any exisiting stories and then try to assign stories based on 
      # the z-axis origin of the space.
      def self.auto_assign_spaces_to_stories(model)
        #delete existing stories.
        model.getBuildingStorys.each {|buildingstory| buildingstory.remove }
        #create hash of building storeys, index is the Z-axis origin of the space.
        building_story_hash = Hash.new()
        model.getSpaces.each do |space|
          if building_story_hash[space.zOrigin].nil?
            building_story_hash[space.zOrigin] = OpenStudio::Model::BuildingStory.new(model)
            building_story_hash[space.zOrigin].setName( building_story_hash.length.to_s )
          end


          space.setBuildingStory(building_story_hash[space.zOrigin])
        end
      end
      
      # override run to implement the functionality of your script
      # model is an OpenStudio::Model::Model, runner is a OpenStudio::Ruleset::UserScriptRunner
      def self.auto_assign_stories(model)    

        # get all spaces
        spaces = model.getSpaces
    
        puts("Assigning Stories to Spaces")
  
        # make has of spaces and minz values
        sorted_spaces = Hash.new
        spaces.each do |space|
          # loop through space surfaces to find min z value
          z_points = []
          space.surfaces.each do |surface|
            surface.vertices.each do |vertex|
              z_points << vertex.z
            end
          end
          minz = z_points.min + space.zOrigin
          sorted_spaces[space] = minz
        end
  
        # pre-sort spaces
        sorted_spaces = sorted_spaces.sort{|a,b| a[1]<=>b[1]} 
  
  
        # this should take the sorted list and make and assign stories
        sorted_spaces.each do |space|
          space_obj = space[0]
          space_minz = space[1]
          if space_obj.buildingStory.empty?
          
            story = getStoryForNominalZCoordinate(model, space_minz)
            puts("Setting story of Space " + space_obj.name.get + " to " + story.name.get + ".")
            space_obj.setBuildingStory(story)
          end
        end
      end
  
      # find the first story with z coordinate, create one if needed
      def self.getStoryForNominalZCoordinate(model, minz)
  
        model.getBuildingStorys.each do |story|
          z = story.nominalZCoordinate
          if not z.empty?
            if minz == z.get
              return story
            end
          end
        end
    
        story = OpenStudio::Model::BuildingStory.new(model)
        story.setNominalZCoordinate(minz)
        return story
      end
      
    end


    #This module contains helper functions that deal with Space objects.
    module Spaces

      #This method will return the horizontal placement type. (N,S,W,E,C) In the 
      # case of a corner, it will take whatever surface area it faces is the 
      # largest. It will also return the top, bottom or middle conditions.   
      
      def self.get_space_placement(space)
        horizontal_placement = nil
        vertical_placement = nil
        
        #get all exterior surfaces. 
        surfaces =  BTAP::Geometry::Surfaces::filter_by_boundary_condition(space.surfaces, ["Outdoors",
            "Ground",
            "GroundFCfactorMethod",
            "GroundSlabPreprocessorAverage",
            "GroundSlabPreprocessorCore",
            "GroundSlabPreprocessorPerimeter",
            "GroundBasementPreprocessorAverageWall",
            "GroundBasementPreprocessorAverageFloor",
            "GroundBasementPreprocessorUpperWall",
            "GroundBasementPreprocessorLowerWall"])

        #exterior Surfaces
        ext_wall_surfaces = BTAP::Geometry::Surfaces::filter_by_surface_types(surfaces,["Wall"])
        ext_bottom_surface = BTAP::Geometry::Surfaces::filter_by_surface_types(surfaces,["Floor"])
        ext_top_surface = BTAP::Geometry::Surfaces::filter_by_surface_types(surfaces,["RoofCeiling"])
        
        #Interior Surfaces..if needed....
        internal_surfaces =  BTAP::Geometry::Surfaces::filter_by_boundary_condition( space.surfaces, ["Surface"] )
        int_wall_surfaces = BTAP::Geometry::Surfaces::filter_by_surface_types( internal_surfaces,["Wall"] )
        int_bottom_surface = BTAP::Geometry::Surfaces::filter_by_surface_types( internal_surfaces,["Floor"] )
        int_top_surface = BTAP::Geometry::Surfaces::filter_by_surface_types( internal_surfaces,["RoofCeiling"] )
        
        
        vertical_placement = "NA"
        #determine if space is a top or bottom, both or middle space. 
        if ext_bottom_surface.size > 0 and ext_top_surface.size > 0 and int_bottom_surface.size == 0 and int_top_surface.size == 0
          vertical_placement = "single_story_space"
        elsif  int_bottom_surface.size > 0 and ext_top_surface.size > 0 and int_bottom_surface.size > 0 
          vertical_placement = "top"
        elsif ext_bottom_surface.size > 0 and ext_top_surface.size == 0 
          vertical_placement = "bottom"
        elsif ext_bottom_surface.size == 0 and ext_top_surface.size == 0
          vertical_placement = "middle"
        end


        
        #determine if what cardinal direction has the majority of external 
        #surface area of the space. 

        walls_area_array = Array.new
        [0,1,2,3].each { |index| walls_area_array[index] = 0.0 }
        #east is defined as 315-45 degs
        BTAP::Geometry::Surfaces::filter_by_azimuth_and_tilt(ext_wall_surfaces,  0.00,   45.0, 0.00, 180.00).each do |surface|
          #          puts "northern surface found 0-46: #{surface}"
          #          puts surface.azimuth / ( Math::PI / 180.0 )
          walls_area_array[0]  = walls_area_array[0]  + surface.grossArea
        end
        BTAP::Geometry::Surfaces::filter_by_azimuth_and_tilt(ext_wall_surfaces,  315.001,   360.0, 0.00, 180.00).each do |surface|
          #          puts "northern surface found: #{surface}"
          #          puts surface.azimuth / ( Math::PI / 180.0 )
          walls_area_array[0]  = walls_area_array[0]  + surface.grossArea
        end
        
        BTAP::Geometry::Surfaces::filter_by_azimuth_and_tilt(ext_wall_surfaces,  45.001,   135.0, 0.00, 180.00).each do |surface|
          #          puts "eastern surface found: #{surface}"
          #          puts surface.azimuth / ( Math::PI / 180.0 )
          walls_area_array[1]  = walls_area_array[1]  + surface.grossArea
        end
        
        BTAP::Geometry::Surfaces::filter_by_azimuth_and_tilt(ext_wall_surfaces,  135.001,   225.0, 0.00, 180.00).each do |surface|
          #          puts "south surface found: #{surface}"
          #          puts surface.azimuth / ( Math::PI / 180.0 )
          walls_area_array[2]  = walls_area_array[2]  + surface.grossArea
        end
        
        BTAP::Geometry::Surfaces::filter_by_azimuth_and_tilt(ext_wall_surfaces,  225.001,   315.0, 0.00, 180.00).each do |surface|
          #          puts "west surface found: #{surface}"
          #          puts surface.azimuth / ( Math::PI / 180.0 )
          walls_area_array[3]  = walls_area_array[3]  + surface.grossArea
        end
        
        
        
        #find our which cardinal driection has the most exterior surface and declare it that orientation.  
        case walls_area_array.index(walls_area_array.max)
        when 0
          horizontal_placement = "north"
        when 1
          horizontal_placement = "east"
        when 2
          horizontal_placement = "south"
        when 3
          horizontal_placement = "west"
        end
        if walls_area_array.inject{|sum,x| sum + x } == 0.0
          horizontal_placement = "core"
        end
        return horizontal_placement , vertical_placement
      end
      
      

      def self.is_perimeter_space?(model,space)
        return Array.new(BTAP::Common::validate_array(model,space,"Space").first.surfaces).filterByBoundaryConditions(["Outdoors","Ground",
            "GroundFCfactorMethod",
            "GroundSlabPreprocessorAverage",
            "GroundSlabPreprocessorCore",
            "GroundSlabPreprocessorPerimeter",
            "GroundBasementPreprocessorAverageWall",
            "GroundBasementPreprocessorAverageFloor",
            "GroundBasementPreprocessorUpperWall",
            "GroundBasementPreprocessorLowerWall"]).size > 0

      end
      def self.show(model,space)
        if drawing_interface = BTAP::Common::validate_array(model,space,"Space").first.drawing_interface
          if entity = drawing_interface.entity
            entity.visible = true
          end
        end
      end
      def self.hide(model,space)
        if drawing_interface = BTAP::Common::validate_array(model,space,"Space").first.drawing_interface
          if entity = drawing_interface.entity
            entity.visible = false
          end
        end
      end










      # This method will return a Array of surfaces that are contained within the
      # passed spaces. Note: if you wish to avoid to create an array of spaces,
      # simply put the space variable in [] brackets
      # Ex: get_all_surfaces_from_spaces( [space1,space2] )
      # @params spaces_array an array of type [OpenStudio::Model::Space]
      # @return an array of surfaces contained in the passed spaces.
      def self.get_surfaces_from_spaces(model, spaces_array)
        BTAP::Geometry::Surfaces::get_surfaces_from_spaces(spaces_array)
      end

      # This method will return a SpaceArray of surfaces that are contained within the
      # passed floors. Note: if you wish to avoid to create an array of spaces,
      # simply put the space variable in [] brackets
      # Ex: get_all_surfaces_from_spaces( [space1,space2] )
      # @params spaces_array an array of type [OpenStudio::Model::Space]
      # @return an array of surfaces contained in the passed spaces.
      def self.get_spaces_from_storeys(model,floors)
        floors = BTAP::Common::validate_array(model,floors,"BuildingStory")
        spaces = Array.new()
        floors.each { |floor| spaces.concat(floor.spaces) }
        return spaces
      end

      # This method will filter an array of spaces that have an external wall
      # passed floors. Note: if you wish to avoid to create an array of spaces,
      # simply put the space variable in [] brackets
      # Ex: get_all_surfaces_from_spaces( [space1,space2] )
      # @params spaces_array an array of type [OpenStudio::Model::Space]
      # @return an array of spaces.
      def self.filter_perimeter_spaces(model, spaces_array)
        spaces_array = BTAP::Common::validate_array(model,spaces_array,"Space")
        array = Array.new()
        spaces_array.each do |space|
          if space.is_a_perimeter_space?()
            array.push(space)
          end
        end
        return array
      end

      # This method will filter an array of spaces that have no external wall
      # passed floors. Note: if you wish to avoid to create an array of spaces,
      # simply put the space variable in [] brackets
      # Ex: get_all_surfaces_from_spaces( [space1,space2] )
      # @params spaces_array an array of type [OpenStudio::Model::Space]
      # @return an array of spaces.
      def self.filter_core_spaces(model,spaces_array)
        spaces_array = BTAP::Common::validate_array(model,spaces_array,"Space")
        array = Array.new()
        spaces_array.each do |space|
          unless space.is_a_perimeter_space?()
            array.push(space)
          end
        end
        return array
      end


      def self.filter_spaces_by_space_types(model,spaces_array,spacetype_array)
        spaces_array = BTAP::Common::validate_array(model,spaces_array,"Space")
        spacetype_array = BTAP::Common::validate_array(model,spacetype_array,"SpaceType")
        #validate space array
        returnarray = Array.new()
        spaces_array.each do |space|
          returnarray << spacetype_array.include?(space.spaceType())
        end
        return returnarray
      end

      #to do write test.
      def self.assign_spaces_to_thermal_zone(model,spaces_array,thermal_zone)
        spaces_array = BTAP::Common::validate_array(model,spaces_array,"Space")
        thermal_zone = BTAP::Common::validate_array(model,thermal_zone,"ThermalZone")[0]
        spaces_array.each do|space|
          space.setThermalZone(thermal_zone)
        end
      end

    end

    #This Module contains methods that create, modify and query Thermal zone objects.
    module Zones

      def self.enumerate_model(model)

      end




      # This method will filter an array of zones that have an external wall
      # passed floors. Note: if you wish to avoid to create an array of spaces,
      # simply put the space variable in [] brackets
      # Ex: get_all_surfaces_from_spaces( [space1,space2] )
      # @params spaces_array an array of type [OpenStudio::Model::Space]
      # @return an array of thermal zones.
      def self.filter_perimeter_zones(thermal_zones)
        array = Array.new()
        thermal_zones.each do |zone|
          zone.space.each do |space|
            if space.is_a_perimeter_space?()
              array.push(zone)
              next
            end
          end
        end
        return array
      end


      # This method will filter an array of zones that have no external wall
      # passed floors. Note: if you wish to avoid to create an array of spaces,
      # simply put the space variable in [] brackets
      # Ex: ( [space1,space2] )
      # @params zone_array an array of type [OpenStudio::Model::ThermalZone]
      # @return an array of thermal zones.
      def self.filter_core_zones( thermal_zones )
        array = Array.new()
        thermal_zones.getThermalZones.each do |zone|
          zone.space.each do |space|
            if not space.is_a_perimeter_space?()
              array.push(zone)
              next
            end
          end
        end
        return array
      end

      def self.get_surfaces_from_thermal_zones(thermal_zone_array)
        BTAP::Geometry::Surfaces::get_all_surfaces_from_thermal_zones(thermal_zone_array)
      end

      def self.create_thermal_zone(model, spaces_array = "")
        thermal_zone = OpenStudio::Model::ThermalZone.new(model)
        BTAP::Geometry::Spaces::assign_spaces_to_thermal_zone(model, spaces_array, thermal_zone)
        return thermal_zone
      end

    end
    module Surfaces

      def self.create_surface(model,name,os_point3d_array, boundary_condition = "",construction = "")
        os_surface = OpenStudio::Model::Surface.new(os_point3d_array, model)
        os_surface.setName( name )
        if OpenStudio::Model::Surface::validOutsideBoundaryConditionValues.include?(boundary_condition)
          self.set_surfaces_boundary_condition([os_surface], boundary_condition)
        else
          puts "boundary condition not set for #{name}"
        end
        self.set_surfaces_construction([os_surface],construction)
        return os_surface
      end

      # This method will rotate a surface
      # @params surface [OpenStudio::Model::Surface] the model object.
      # @params azimuth_degrees [Float] rotation value
      # @params tilt_degrees [Float] rotation value
      # @return model [OpenStudio::Model::Model] the model object.
      def self.rotate_tilt_translate_surfaces(planar_surfaces, azimuth_degrees, tilt_degrees = 0.0, translation_vector = OpenStudio::Vector3d.new(0.0,0.0,0.0) )
        # Identity matrix for setting space origins
        azimuth_matrix = OpenStudio::Transformation::rotation(OpenStudio::Vector3d.new(0,0,1),azimuth_degrees*Math::PI/180)
        tilt_matrix = OpenStudio::Transformation::rotation(OpenStudio::Vector3d.new(0,0,1),tilt_degrees*Math::PI/180)
        translation_matrix = OpenStudio::createTranslation(translation_vector)
        planar_surfaces.each do |surface|
          surface.changeTransformation(azimuth_matrix)
          surface.changeTransformation(tilt_matrix)
          surface.changeTransformation(translation_matrix)
        end
        return planar_surfaces
      end

      def self.set_fenestration_to_wall_ratio(surfaces,ratio,offset = 0, height_offset_from_floor = true, floor = "all")
        surfaces.each do |surface|
          result = surface.setWindowToWallRatio(ratio,offset,height_offset_from_floor)
          raise( "Unable to set FWR for surface " +
              surface.getAttribute("name").to_s +
              " . Possible reasons are  if the surface is not a wall, if the surface
          is not rectangular in face coordinates, if requested ratio is too large
          (window area ~= surface area) or too small (min dimension of window < 1 foot),
          or if the window clips any remaining sub surfaces. Otherwise, removes all
          existing windows and adds new window to meet requested ratio.") unless result
        end
        return surfaces
      end



      # This Method removes all the subsurfaces in a model (Windows, Doors )
      # @author Phylroy A. Lopez
      # @return [OpenStudio::Model::Model] the OpenStudio model object (self reference).
      def self.remove_all_subsurfaces(surfaces)
        surfaces.each do |subsurface|
          subsurface.remove
        end
        return surfaces
      end

      def self.get_surfaces_from_spaces(spaces_array)
        surfaces = Array.new()
        spaces_array.each do |space|
          surfaces.concat(space.surfaces())
        end
        return surfaces
      end

      def self.get_surfaces_from_building_stories(story_array)
        surfaces = Array.new()
        get_spaces_from_storeys(story_array).each do |space|
          surfaces.concat(space.surfaces())
        end
        return surfaces
      end

      def self.get_surfaces_from_thermal_zones(thermal_zone_array)
        surfaces = Array.new()
        thermal_zone_array.each do |thermal_zone|
          thermal_zone.spaces.each do |space|
            surfaces.concat(space.surfaces())
          end
          return surfaces
        end
      end

      def self.get_subsurfaces_from_surfaces(surface_array)
        subsurfaces = Array.new()
        surface_array.each do |surface|
          subsurfaces.concat(surface.subSurfaces)
        end
        return subsurfaces
      end



      #determine average conductance on set of surfaces or subsurfaces.
      def self.get_weighted_average_surface_conductance(surfaces)
        total_area = 0.0
        temp = 0.0
        surfaces.each do |surface|
          temp = temp + BTAP::Geometry::Surfaces::get_surface_net_area(surface) * BTAP::Geometry::Surfaces::get_surface_construction_conductance(surface)
          total_area = total_area + BTAP::Geometry::Surfaces::get_surface_net_area(surface)
        end
        average_conductance = "NA"
        average_conductance =  temp / total_area unless total_area == 0.0
        return average_conductance
      end

      #get total exterior surface area of building.
      def self.get_total_ext_wall_area(model)
        outdoor_surfaces = BTAP::Geometry::Surfaces::filter_by_boundary_condition(model.getSurfaces(), "Outdoors")
        outdoor_walls = BTAP::Geometry::Surfaces::filter_by_surface_types(outdoor_surfaces, "Wall")



      end

      def self.get_total_ext_floor_area(model)

        outdoor_floors = BTAP::Geometry::Surfaces::filter_by_surface_types(outdoor_surfaces, "Floor")
      end

      def self.get_total_ext_fenestration_area(model)

      end

      def self.get_total_ext_roof_area(model)
        outdoor_roofs = BTAP::Geometry::Surfaces::filter_by_surface_types(outdoor_surfaces, "RoofCeiling")

      end






      #["FixedWindow" , "OperableWindow" , "Door" , "GlassDoor", "OverheadDoor" , "Skylight", "TubularDaylightDiffuser","TubularDaylightDome"]
      def self.filter_subsurfaces_by_types(subsurfaces,subSurfaceTypes)

        #check to see if a string or an array was passed.
        if subSurfaceTypes.kind_of?(String)
          temp = subSurfaceTypes
          subSurfaceTypes = Array.new()
          subSurfaceTypes.push(temp)
        end
        subSurfaceTypes.each do |subSurfaceType|
          unless OpenStudio::Model::SubSurface::validSubSurfaceTypeValues.include?(subSurfaceType)
            raise( "ERROR: Invalid surface type = #{subSurfaceType} Correct Values are: #{OpenStudio::Model::SubSurface::validSubSurfaceTypeValues}")
          end
        end
        return_array = Array.new()
        if subSurfaceTypes.size == 0 or subSurfaceTypes[0].upcase == "All".upcase
          return_array = self
        else
          subsurfaces.each do |subsurface|
            subSurfaceTypes.each do |subSurfaceType|
              if subsurface.subSurfaceType == subSurfaceType
                return_array.push(subsurface)
              end
            end
          end
        end
        return return_array

      end

      #This method creates a new construction based on the current, changes the rsi and assign the construction to the current surface.
      #Most of the meat of this method is in the construction class. Testing is done there.
      def self.set_surfaces_construction_conductance(surfaces , conductance)
        surfaces.each do |surface|
          #a bit of acrobatics to get the construction object from the ConstrustionBase object's name.
          construction = OpenStudio::Model::getConstructionByName(surface.model,surface.construction.get.name.to_s).get
          #create a new construction with the requested conductance value based on the current construction.

          new_construction = BTAP::Resources::Envelope::Constructions::customize_opaque_construction(surface.model,construction,conductance)
          surface.setConstruction(new_construction)
        end
        return surfaces
      end

      #This method creates a new construction based on the current, changes the rsi and assign the construction to the current surface.
      #Most of the meat of this method is in the construction class. Testing is done there.
      def self.get_surface_construction_conductance(surface)
        #a bit of acrobatics to get the construction object from the ConstrustionBase object's name.
        construction = OpenStudio::Model::getConstructionByName(surface.model,surface.construction.get.name.to_s).get
        #create a new construction with the requested RSI value based on the current construction.
        return  BTAP::Resources::Envelope::Constructions::get_conductance(construction)
      end

      def self.get_surface_net_area(surface)
        return surface.netArea()
      end

      def self.get_sub_surface_net_area(subsurface)
        return subsurface.netArea()
      end


      def self.set_surfaces_construction(surfaces,construction)
        surfaces.each do |surface|
          surface.setConstruction(construction)
        end
      end

      #  This method sets the boundary condition for a surface and it's matching surface.
      #  If set to adiabatic, it will remove all subsurfaces since E+ cannot have adiabatic sub surfaces.
      def self.set_surfaces_boundary_condition(model,surfaces, boundaryCondition)
        surfaces = BTAP::Common::validate_array(model,surfaces,"Surface")
        if OpenStudio::Model::Surface::validOutsideBoundaryConditionValues.include?(boundaryCondition)
          surfaces.each do |surface|
            if boundaryCondition == "Adiabatic"
              #need to remove subsurface as you cannot have a adiabatic surface with a
              #subsurface.
              surface.subSurfaces.each do |subsurface|
                subsurface.remove
              end

              #A bug with adiabatic surfaces. They do not hold the default contruction. 
              surface.setConstruction( surface.construction.get() ) if surface.isConstructionDefaulted
            end

            surface.setOutsideBoundaryCondition(boundaryCondition)
            adj_surface = surface.adjacentSurface
            unless adj_surface.empty?
              adj_surface.get.setOutsideBoundaryCondition( boundaryCondition )
            end
          end
        else
          puts "ERROR: Invalid Boundary Condition = " + boundary_condition
          puts "Correct Values are:"
          puts OpenStudio::Model::Surface::validOutsideBoundaryConditionValues
        end
      end

      def self.filter_by_non_defaulted_surfaces(surfaces)
        non_defaulted_surfaces = Array.new()
        surfaces.each { |surface| non_defaulted_surfaces << surface unless surface.isConstructionDefaulted }
        return non_defaulted_surfaces
      end


      def self.filter_by_boundary_condition(surfaces, boundary_conditions)
        #check to see if a string or an array was passed.
        if boundary_conditions.kind_of?(String)
          temp = boundary_conditions
          boundary_conditions = Array.new()
          boundary_conditions.push(temp)
        end
        #ensure boundary conditions are valid
        boundary_conditions.each do |boundary_condition|
          unless OpenStudio::Model::Surface::validOutsideBoundaryConditionValues.include?(boundary_condition)
            raise "ERROR: Invalid Boundary Condition = " + boundary_condition + "Correct Values are:" + OpenStudio::Model::Surface::validOutsideBoundaryConditionValues.to_s
          end
        end
        #create return array.
        return_array = Array.new()

        if boundary_conditions.size == 0 or boundary_conditions[0].upcase == "All".upcase
          return_array = surfaces
        else
          surfaces.each do |surface|
            boundary_conditions.each do |condition|
              if surface.outsideBoundaryCondition == condition
                return_array.push(surface)
              end
            end
          end
        end
        return return_array
      end

      def self.filter_by_surface_types(surfaces,surfaceTypes)

        #check to see if a string or an array was passed.
        if surfaceTypes.kind_of?(String)
          temp = surfaceTypes
          surfaceTypes = Array.new()
          surfaceTypes.push(temp)
        end
        surfaceTypes.each do |surfaceType|
          unless OpenStudio::Model::Surface::validSurfaceTypeValues.include?(surfaceType)
            raise( "ERROR: Invalid surface type = #{surfaceType} Correct Values are: #{OpenStudio::Model::Surface::validSurfaceTypeValues}")
          end
        end
        return_array = Array.new()
        if surfaceTypes.size == 0 or surfaceTypes[0].upcase == "All".upcase
          return_array = self
        else
          surfaces.each do |surface|
            surfaceTypes.each do |surfaceType|
              if surface.surfaceType == surfaceType
                return_array.push(surface)
              end
            end
          end
        end
        return return_array
      end

      def self.filter_by_interzonal_surface(surfaces)
        return_array = Array.new()
        surfaces.each do |surface|
          unless surface.adjacentSurface().empty?
            return_array.push(surface)
          end
          return return_array
        end
      end

      # Azimuth start from Y axis, Tilts starts from Z-axis
      def self.filter_by_azimuth_and_tilt(surfaces,azimuth_from,azimuth_to,tilt_from,tilt_to,tolerance = 1.0)
        return OpenStudio::Model::PlanarSurface::findPlanarSurfaces(surfaces, OpenStudio::OptionalDouble.new(azimuth_from), OpenStudio::OptionalDouble.new(azimuth_to), OpenStudio::OptionalDouble.new(tilt_from), OpenStudio::OptionalDouble.new(tilt_to),tolerance)
      end


      def self.show(surfaces)
        surfaces.each do |surface|
          if drawing_interface = surface.drawing_interface
            if entity = drawing_interface.entity
              entity.visible = false
            end
          end
        end
      end

      def self.hide(surfaces)
        surfaces.each do |surface|
          if drawing_interface = surface.drawing_interface
            if entity = drawing_interface.entity
              entity.visible = false
            end
          end
        end
      end


    end #Module Surfaces
  end #module Geometry
end

module BTAP
  module FileIO


    # Get the name of the model.
    # @author Phylroy A. Lopez
    # @return [String] the name of the model.
    def self.get_name(model)
      unless model.building.get.getAttribute("name").empty?
        return model.building.get.getAttribute("name").get.valueAsString
      else
        return ""
      end
    end

    # @author Phylroy A. Lopez
    # Get the name of the model.
    # @author Phylroy A. Lopez
    # @return [String] the name of the model.
    def self.set_name(model,name)
      unless model.building.empty?
        model.building.get.setName(name)
      end
    end

    # @author Phylroy A. Lopez
    # Get the name of the model.
    # @author Phylroy A. Lopez
    # @return [String] the name of the model.
    def self.set_sql_file(model,sql_path)
      model.setSqlFile(OpenStudio::Path.new( sql_path) )
    end
    #@author Phylroy A. Lopez
    # Get the filepath of all files with extention
    # @param folder [String} the path to the folder to be scanned.
    # @param ext [String] the file extension name, ex ".epw"
    def self.get_find_files_from_folder_by_extension(folder, ext)
      Dir.glob("#{folder}/**/*#{ext}")
    end
    
    def self.delete_files_in_folder_by_extention(folder,ext)
      BTAP::FileIO::get_find_files_from_folder_by_extension(folder, ext).each do |file|
        FileUtils.rm(file)
        puts "#{file} deleted."
      end
    end
    
    def self.find_file_in_folder_by_filename(folder,filename)
      Dir.glob("#{folder}/**/*#{filename}")
    end
    
    def self.fix_url_to_path(url_string)
      if  url_string =~/\/([a-zA-Z]:.*)/
        return $1
      else
        return url_string
      end
    end


    # This method loads an Openstudio file into the model.
    # @author Phylroy A. Lopez
    # @param filepath [String] path to the OSM file.
    # @param name [String] optional model name to be set to model.
    # @return [OpenStudio::Model::Model] an OpenStudio model object.
    def self.load_idf(filepath, name = "")
      #load file
      unless File.exist?(filepath)
        raise 'File does not exist: ' + filepath.to_s
      end
      puts "loading file #{filepath}..."
      model_path = OpenStudio::Path.new(filepath.to_s)
      #Upgrade version if required.
      version_translator = OpenStudio::OSVersion::VersionTranslator.new
      model = OpenStudio::EnergyPlus::loadAndTranslateIdf(model_path)
      version_translator.errors.each {|error| puts "Error: #{error.logMessage}\n\n"}
      version_translator.warnings.each {|warning| puts "Warning: #{warning.logMessage}\n\n"}
      #If model did not load correctly.
      if model.empty?
        raise 'something went wrong'
      end
      model = model.get
      if name != ""
        self.set_name(model,name)
      end
      puts "File #{filepath} loaded."
      return model
    end


    # This method loads an Openstudio file into the model.
    # @author Phylroy A. Lopez
    # @param filepath [String] path to the OSM file.
    # @param name [String] optional model name to be set to model.
    # @return [OpenStudio::Model::Model] an OpenStudio model object.
    def self.load_osm(filepath, name = "")

      #load file
      unless File.exist?(filepath)
        raise 'File does not exist: ' + filepath.to_s
      end
      puts "loading file #{filepath}..."
      model_path = OpenStudio::Path.new(filepath.to_s)
      #Upgrade version if required.
      version_translator = OpenStudio::OSVersion::VersionTranslator.new
      model = version_translator.loadModel(model_path)
      version_translator.errors.each {|error| puts "Error: #{error.logMessage}\n\n"}
      version_translator.warnings.each {|warning| puts "Warning: #{warning.logMessage}\n\n"}
      #If model did not load correctly.
      if model.empty?
        raise 'could not load #{filepath}'
      end
      model = model.get
      if name != "" and not name.nil?
        self.set_name(model,name)
      end
      puts "File #{filepath} loaded."

      return model
    end

    # This method loads an *Quest file into the model.
    # @author Phylroy A. Lopez
    # @param filepath [String] path to the OSM file.
    # @param name [String] optional model name to be set to model.
    # @return [OpenStudio::Model::Model] an OpenStudio model object.
    def self.load_e_quest(filepath)
      #load file
      unless File.exist?(filepath)
        raise 'File does not exist: ' + filepath.to_s
      end
      puts "loading equest file #{filepath}. This will only convert geometry."
      #Create an instancse of a DOE model
      doe_model = BTAP::EQuest::DOEBuilding.new()
      #Load the inp data into the DOE model.
      doe_model.load_inp(filepath)

      #Convert the model to a OSM format.
      model = doe_model.create_openstudio_model_new()
      return model
    end

    #This method will inject OSM objects from a OSM file/library into the current
    # model.
    # @author Phylroy A. Lopez
    # @param filepath [String] path to the OSM library file.
    # @return [OpenStudio::Model::Model] an OpenStudio model object (self reference).
    def self.inject_osm_file(model, filepath)
      osm_data = BTAP::FileIO::load_osm(filepath)
      model.addObjects(osm_data.objects);
      return model
    end

    # This method will return a deep copy of the model.
    # Simply because I don't trust the clone method yet.
    # @author Phylroy A. Lopez
    # @return [OpenStudio::Model::Model] a copy of the OpenStudio model object.
    def self.deep_copy(model,bool = true)
      return model.clone(bool).to_Model
      #      model.save(OpenStudio::Path.new("deep_copy.osm"))
      #      model_copy =  self.load_osm("deep_copy.osm")
      #      File.delete("deep_copy.osm")
      #      return model_copy
    end

    # This method will save the model to an osm file.
    # @author Phylroy A. Lopez
    # @param model
    # @param filename The full path to save to.
    # @return [OpenStudio::Model::Model] a copy of the OpenStudio model object.
    def self.save_osm(model,filename)
      FileUtils.mkdir_p(File.dirname(filename))
      File.delete(filename) if File.exist?(filename)
      model.save(OpenStudio::Path.new(filename))
      puts "File #{filename} saved."
    end

    # This method will translate to an E+ IDF format and save the model to an idf file.
    # @author Phylroy A. Lopez
    # @param model
    # @param filename The full path to save to.
    # @return [OpenStudio::Model::Model] a copy of the OpenStudio model object.
    def self.save_idf(model,filename)
      OpenStudio::EnergyPlus::ForwardTranslator.new().translateModel(model).toIdfFile().save(OpenStudio::Path.new(filename),true)
    end

    # This method will recursively translate all IDFs in a folder to OSMs, and save them to the OSM_-No_Space_Types folder
    # @author Brendan Coughlin
    # @param filepath The directory that holds the IDFs - usually DOEArchetypes\Original
    # @return nil
    def self.convert_idf_to_osm(filepath)
      Find.find(filepath) { |file|
        if file[-4..-1] == ".idf"
          model = FileIO.load_idf(file)
          # this is a bit ugly but it works properly when called on a recursive folder structure
          FileIO.save_osm(model, (File.expand_path("..\\OSM-No_Space_Types\\", filepath) << "\\" << Pathname.new(file).basename.to_s)[0..-5])
          puts # empty line break
        end
      }
    end

   



    def self.get_timestep_data(osm_file,sql_file,variable_name_array, env_period = nil, hourly_time_step = nil )
      column_data = get_timeseries_arrays(sql, env_period, hourly_time_step, "Boiler Fan Coil Part Load Ratio")
    end

    
    def self.convert_all_eso_to_csv(in_folder,out_folder)
      list_of_csv_files = Array.new
      FileUtils.mkdir_p(out_folder)
      osmfiles = BTAP::FileIO::get_find_files_from_folder_by_extension(in_folder,".eso")

      osmfiles.each do |eso_file_path|

        #Run ESO Vars command must be run in folder.
        root_folder = Dir.getwd()
        puts File.dirname(eso_file_path)
        Dir.chdir(File.dirname(eso_file_path))
        if File.exist?("eplustbl.htm")
          File.open("dummy.rvi", 'w') {|f| f.write("") } 


          system("#{BTAP::SimManager::ProcessManager::find_read_vars_eso()} dummy.rvi unlimited")
          #get name of run from html file.
          runname = ""
          f = File.open("eplustbl.htm")
          f.each_line do |line|
            if line =~ /<p>Building: <b>(.*)<\/b><\/p>/
              puts  "Found name: #{$1}"
              runname = $1
              break
            end
          end
          f.close
          #copy files over with distinct names
          puts "copy hourly results to #{out_folder}/#{runname}_eplusout.csv"
          FileUtils.cp("eplusout.csv","#{out_folder}/#{runname}_eplusout.csv")
          puts "copy html results to #{out_folder}/#{runname}_eplustbl.htm"
          FileUtils.cp("eplustbl.htm","#{out_folder}/#{runname}_eplustbl.htm")
          puts "copy sql results to #{out_folder}/#{runname}_eplusout.sql"
          FileUtils.cp("eplusout.sql","#{out_folder}/#{runname}_eplusout.sql")

          
          list_of_csv_files << "#{out_folder}/#{runname}_eplusout.csv"
        end
        Dir.chdir(root_folder)
      end
      return list_of_csv_files
    end


    # This method will read a CSV file and return rows as hashes based on the selection given.
    # @author Phylroy Lopez
    # @param filepath The path to the csv file.
    # @param searchHash
    # @return matches A Array of rows that match the searchHash. The row is a Hash itself.
    def self.csv_look_up_rows(file, searchHash)
      options = {
        :headers =>       true,
        :converters =>     :numeric }
      table = CSV.read( file, options )
      # we'll save the matches here
      matches = nil
      # save a copy of the headers
      matches = table.find_all do |row|
        row
        match = true
        searchHash.keys.each do |key|
          match = match && ( row[key] == searchHash[key] )
        end
        match
      end
      return matches
    end

    def self.csv_look_up_unique_row(file, searchHash)
      #Load Vintage database information.
      matches = BTAP::FileIO::csv_look_up_rows(file, searchHash)
      raise( "Error:  CSV lookup found more than one row that met criteria #{searchHash} in #{@file} ") if matches.size() > 1
      raise( "Error:  CSV lookup found no rows that met criteria #{searchHash} in #{@file}") if matches.size() < 1
      return matches[0]
    end


    # This method will read a CSV file and return the unique values in a given column header.
    # @author Phylroy Lopez
    # @param filepath The path to the csv file.
    # @param colHeader The header name in teh csv file. 
    # @return matches A Array of rows that match the searchHash. The row is a Hash itself.
    def self.csv_look_up_unique_col_data(file, colHeader)
      column_data = Array.new
      CSV.foreach( file, :headers => true ) do |row|
        column_data << row[colHeader] # For each row, give me the cell that is under the colHeader column
      end
      return column_data.sort!.uniq
    end

    def self.sum_row_headers(row,headers)
      total = 0.0
      headers.each { |header| total = total + row[header] }
      return total
    end

    def self.terminus_hourly_output(csv_file)
      puts "Starting Terminus output processing."
      puts "reading #{csv_file} being processed"
      #reads csv file into memory.
      original = CSV.read(csv_file,
        {
          :headers =>       true, #This flag tell the parser that there are headers.
          :converters =>     :numeric  #This tell it to convert string data into numeric when possible.
        }
      )
      puts "done reading #{csv_file} being processed"
      # We are going to collect the header names  that fit a pattern. But first we need to
      # create array containers to save the header name. In ruby we can use the string header names
      # as the array index.

      #Create arrays to store the header names for each type.
      waterheater_gas_rate_headers = Array.new()
      waterheater_electric_rate_headers = Array.new()
      waterheater_heating_rate_headers = Array.new()
      cooling_coil_electric_power_headers = Array.new()
      cooling_coil_total_cooling_rate_headers = Array.new()
      heating_coil_air_heating_rate_headers = Array.new()
      heating_coil_gas_rate_headers = Array.new()
      plant_supply_heating_demand_rate_headers = Array.new()
      facility_total_electrical_demand_headers = Array.new()
      boiler_gas_rate_headers = Array.new()
      time_index  = Array.new()
      boiler_gas_rate_headers = Array.new()
      heating_coil_electric_power_headers = Array.new()


      #remove rows 2-169 (or 1-168 in computer array terms)
      original = self.remove_rows_from_csv_table(0,72,original)


      #Scan the CSV file to file all the headers that match the pattern. This will go through all the headers and find
      # any header that matches our regular expression if a match is made, the header name is stuffed into the string array.
      original.headers.each do |header|
        stripped_header = header.strip
        waterheater_electric_rate_headers                      << header if stripped_header =~/^.*:Water Heater Electric Power \[W\]\(Hourly\)$/
        waterheater_gas_rate_headers                           << header if stripped_header =~/^.*:Water Heater Gas Rate \[W\]\(Hourly\)$/
        waterheater_heating_rate_headers                       << header if stripped_header =~/^.*:Water Heater Heating Rate \[W\]\(Hourly\)$/
        cooling_coil_electric_power_headers                    << header if stripped_header =~/^.*:Cooling Coil Electric Power \[W\]\(Hourly\)$/
        cooling_coil_total_cooling_rate_headers                << header if stripped_header =~/^.*:Cooling Coil Total Cooling Rate \[W\]\(Hourly\)$/
        heating_coil_air_heating_rate_headers                  << header if stripped_header =~/^.*:Heating Coil Air Heating Rate \[W\]\(Hourly\)$/
        heating_coil_gas_rate_headers                          << header if stripped_header =~/^.*:Heating Coil Gas Rate \[W\]\(Hourly\)$/
        heating_coil_electric_power_headers                     << header if stripped_header =~/^.*:Heating Coil Electric Power \[W\]\(Hourly\)$/
        plant_supply_heating_demand_rate_headers               << header if stripped_header =~/^(?!SWH PLANT LOOP).*:Plant Supply Side Heating Demand Rate \[W\]\(Hourly\)$/
        facility_total_electrical_demand_headers               << header if stripped_header =~/^.*:Facility Total Electric Demand Power \[W\]\(Hourly\)$/
        boiler_gas_rate_headers                                << header if stripped_header =~/^.*:Boiler Gas Rate \[W\]\(Hourly\)/

      end
      #Debug printout stuff. Make sure the output it captures the headers you want otherwise modify the regex above
      puts waterheater_gas_rate_headers
      puts waterheater_electric_rate_headers
      puts waterheater_heating_rate_headers

      puts cooling_coil_electric_power_headers
      puts cooling_coil_total_cooling_rate_headers

      puts heating_coil_air_heating_rate_headers
      puts heating_coil_gas_rate_headers

      puts plant_supply_heating_demand_rate_headers
      puts facility_total_electrical_demand_headers
      puts boiler_gas_rate_headers
      puts heating_coil_electric_power_headers


      #open up a new file to save the file to..Note: This will fail it the file is open in EXCEL.
      CSV.open("#{csv_file}.terminus_hourly.csv", 'w') do |csv|
        #Create header row for new terminus hourly file.
        csv << [
          "Date/Time",
          "water_heater_gas_rate_total",
          "water_heater_electric_rate_total",
          "water_heater_heating_rate_total",
          "cooling_coil_electric_power_total",
          "cooling_coil_total_cooling_rate_total",
          "heating_coil_air_heating_rate_total",
          "heating_coil_gas_rate_total",
          "heating_coil_electric_power_total",
          "plant_supply_heating_demand_rate_total",
          "facility_total_electrical_demand_total",
          "boiler_gas_rate_total"
        ]
        original.each do |row|

          # We are now writing data to the new csv file. This is where we can manipulate the data, row by row.
          # sum the headers collected above and store in specific *_total variables.
          # This is done via a small function self.sum_row_headers. There may only be a single
          # header collected.. That is fine. It is better to be flexible than hardcode anything.
          water_heater_gas_rate_total = self.sum_row_headers(row,waterheater_gas_rate_headers)
          water_heater_electric_rate_total = self.sum_row_headers(row,waterheater_electric_rate_headers)
          water_heater_heating_rate_total  = self.sum_row_headers(row,waterheater_heating_rate_headers)
          cooling_coil_electric_power_total = self.sum_row_headers(row, cooling_coil_electric_power_headers)
          cooling_coil_total_cooling_rate_total = self.sum_row_headers(row, cooling_coil_total_cooling_rate_headers)
          heating_coil_air_heating_rate_total = self.sum_row_headers(row, heating_coil_air_heating_rate_headers)
          heating_coil_gas_rate_total = self.sum_row_headers(row, heating_coil_gas_rate_headers)
          heating_coil_electric_power_total = self.sum_row_headers(row, heating_coil_electric_power_headers)
          plant_supply_heating_demand_rate_total = self.sum_row_headers(row, plant_supply_heating_demand_rate_headers)
          facility_total_electrical_demand_total = self.sum_row_headers(row, facility_total_electrical_demand_headers)
          boiler_gas_rate_headers_total = self.sum_row_headers(row, boiler_gas_rate_headers)



          #Write the data out. Should match header row as above.
          csv << [
            row["Date/Time"], #Time index is hardcoded because every file will have a "Date/Time" column header.
            water_heater_gas_rate_total,
            water_heater_electric_rate_total,
            water_heater_heating_rate_total,
            cooling_coil_electric_power_total,
            cooling_coil_total_cooling_rate_total,
            heating_coil_air_heating_rate_total,
            heating_coil_gas_rate_total,
            heating_coil_electric_power_total,
            plant_supply_heating_demand_rate_total,
            facility_total_electrical_demand_total,
            boiler_gas_rate_headers_total
          ]
        end
      end
      puts "Ending Terminus output processing."
    end

    def self.remove_rows_from_csv_table(start_index,stop_index,table)
      total_rows_to_remove = stop_index - start_index
      (0..total_rows_to_remove-1).each do |counter|
        table.delete(start_index)
      end
      return table
    end


    #load a model into OS & version translates, exiting and erroring if a problem is found
    def safe_load_model(model_path_string)
      model_path = OpenStudio::Path.new(model_path_string)
      if OpenStudio::exists(model_path)
        versionTranslator = OpenStudio::OSVersion::VersionTranslator.new
        model = versionTranslator.loadModel(model_path)
        if model.empty?
          raise "Version translation failed for #{model_path_string}"
        else
          model = model.get
        end
      else
        raise "#{model_path_string} couldn't be found"
      end
      return model
    end

    #load a sql file, exiting and erroring if a problem is found
    def safe_load_sql(sql_path_string)
      sql_path = OpenStudio::Path.new(sql_path_string)
      if OpenStudio::exists(sql_path)
        sql = OpenStudio::SqlFile.new(sql_path)
      else
        puts "#{sql_path} couldn't be found"
        exit
      end
      return sql
    end

    #function to wrap debug == true puts
    def debug_puts(puts_text)
      if Debug_Mode == true
        puts "#{puts_text}"
      end
    end

    def get_timeseries_arrays(openstudio_sql_file, timestep, variable_name_array, regex_name_filter = /.*/, env_period = nil)
      returnArray = Array.new()
      variable_name_array.each do |variable_name|
        possible_key_values = openstudio_sql_file.availableKeyValues(env_period,timestep,variable_name)
        possible_variable_names = openstudio_sql_file.availableVariableNames(env_period,timestep).include?(variable_name)
        if not possible_variable_names.nil?  and  possible_variable_names.include?(variable_name) and not possible_key_values.nil?
          possible_key_values.get.each do |key_value|
            unless regex_name_filter.match(key_value).nil?
              returnArray << get_timeseries_array(openstudio_sql_file, timestep, variable_name, key_value)
            end
          end
        end
        return returnArray
      end
    end




    #gets a time series data vector from the sql file and puts the values into a standard array of numbers
    def get_timeseries_array(openstudio_sql_file, timestep, variable_name, key_value)
      zone_time_step = "Zone Timestep"
      hourly_time_step = "Hourly"
      hvac_time_step = "HVAC System Timestep"
      timestep = hourly_time_step
      env_period = openstudio_sql_file.availableEnvPeriods[0]
      #puts openstudio_sql_file.class
      #puts env_period.class
      #puts timestep.class
      #puts variable_name.class
      #puts key_value.class
      key_value = key_value.upcase  #upper cases the key_value b/c it is always uppercased in the sql file.
      #timestep = timestep.capitalize  #capitalize the timestep b/c it is always capitalized in the sql file
      #timestep = timestep.split(" ").each{|word| word.capitalize!}.join(" ")
      #returns an array of all keyValues matching the variable name, envPeriod, and reportingFrequency
      #we'll use this to check if the query will work before we send it.
      puts "*#{env_period}*#{timestep}*#{variable_name}"
      time_series_array = []
      puts env_period.class
      if env_period.nil?
        puts "here"
        time_series_array = [nil]
        return time_series_array
      end
      possible_env_periods = openstudio_sql_file.availableEnvPeriods()
      if possible_env_periods.nil?
        time_series_array = [nil]
        return time_series_array
      end
      possible_timesteps = openstudio_sql_file.availableReportingFrequencies(env_period)
      if possible_timesteps.nil?
        time_series_array = [nil]
        return time_series_array
      end
      possible_variable_names = openstudio_sql_file.availableVariableNames(env_period,timestep)
      if possible_variable_names.nil?
        time_series_array = [nil]
        return time_series_array
      end
      possible_key_values = openstudio_sql_file.availableKeyValues(env_period,timestep,variable_name)
      if possible_key_values.nil?
        time_series_array = [nil]
        return time_series_array
      end

      if possible_key_values.include? key_value and
          possible_variable_names.include? variable_name and
          possible_env_periods.include? env_period and
          possible_timesteps.include? timestep
        #the query is valid
        time_series = openstudio_sql_file.timeSeries(env_period, timestep, variable_name, key_value)
        if time_series #checks to see if time_series exists
          time_series = time_series.get.values
          debug_puts "  #{key_value} time series length = #{time_series.size}"
          for i in 0..(time_series.size - 1)
            #puts "#{i.to_s} -- #{time_series[i]}"
            time_series_array << time_series[i]
          end
        end
      else
        #do this if the query is not valid.  The comments might help troubleshoot.
        time_series_array = [nil]
        debug_puts "***The pieces below do NOT make a valid query***"
        debug_puts "  *#{key_value}* - this key value might not exist for the variable you are looking for"
        debug_puts "  *#{timestep}* - this value should be Hourly, Monthly, Zone Timestep, HVAC System Timestep, etc"
        debug_puts "  *#{variable_name}* - every word should be capitalized EG:  Refrigeration System Total Compressor Electric Energy "
        debug_puts "  *#{env_period}* - you can get an array of all the valid env periods by using the sql_file.availableEnvPeriods() method "
        debug_puts "  Possible key values: #{possible_key_values}"
        debug_puts "  Possible Variable Names: #{possible_variable_names}"
        debug_puts "  Possible run periods:  #{possible_env_periods}"
        debug_puts "  Possible timesteps:  #{possible_timesteps}"
      end
      return time_series_array
    end

    #gets the average of the numbers in an array
    def non_zero_array_average(arr)
      debug_puts "average of the entire array = #{arr.inject{ |sum, el| sum + el }.to_f / arr.size}"
      arr.delete(0)
      debug_puts "average of the non-zero numbers in the array = #{arr.inject{ |sum, el| sum + el }.to_f / arr.size}"
      return arr.inject{ |sum, el| sum + el }.to_f / arr.size
    end

    #method for converting from IP to SI if you know the strings of the input and the output
    def ip_to_si(number, ip_unit_string, si_unit_string)
      ip_unit = OpenStudio::createUnit(ip_unit_string, "IP".to_UnitSystem).get
      si_unit = OpenStudio::createUnit(si_unit_string, "SI".to_UnitSystem).get
      #puts "#{ip_unit} --> #{si_unit}"
      ip_quantity = OpenStudio::Quantity.new(number, ip_unit)
      si_quantity = OpenStudio::convert(ip_quantity, si_unit).get
      #puts "#{ip_quantity} = #{si_quantity}"
      return si_quantity.value
    end


  end #FileIO





end #BTAP


module BTAP
  module EQuest
    # Author::    Phylroy Lopez  (mailto:plopez@nrcan.gc.ca)
    # Copyright:: Copyright (c) NRCan
    # License::   GNU Public Licence
    #This class contains encapsulates the generic interface for the DOE2.x command
    #set. It stores the u type, commands, and keyword pairs for each command. It also
    #stores the parent and child command relationships w.r.t. the building envelope
    #and the hvac systems. I have attempted to make the underlying storage of data
    #private so, if required, we could move to a database solution in the future
    #if required for web development..

    class DOECommand

      # Contains the user specified name
      attr_accessor :utype
      #Contains the u-value
      attr_accessor :uvalue
      # Contains the DOE-2 command name.
      attr_accessor :commandName
      # Contains the Keyword Pairs.
      attr_accessor :keywordPairs
      # Lists all ancestors in increasing order.
      attr_accessor :parents
      # An Array of all the children of this command.
      attr_accessor :children
      # The command type.
      attr_accessor :commandType
      # Flag to see if this component is exempt.
      attr_accessor :exempt
      # Comments. To be added to the command.
      attr_accessor :comments
      # A list of all the non_utype_commands.
      attr_accessor :non_utype_commands
      # A list of all the one line commands (no keyword pairs)
      attr_accessor :one_line_commands
      # Pointer to the building obj.
      attr_accessor :building

      #This method will return the value of the keyword pair if available.
      #Example:
      #If you object has this data in it...
      #
      #"EL1 West Perim Spc (G.W4)" = SPACE
      #SHAPE            = POLYGON
      #ZONE-TYPE        = CONDITIONED
      #PEOPLE-SCHEDULE  = "EL1 Bldg Occup Sch"
      #LIGHTING-SCHEDUL = ( "EL1 Bldg InsLt Sch" )
      #EQUIP-SCHEDULE   = ( "EL1 Bldg Misc Sch" )
      #
      #
      #then calling
      #
      #get_keyword_value("ZONE-TYPE")
      #
      #will return the string
      #
      #"CONDITIONED".
      #
      #if the keyword does not exist, it will return a nil object.

      # Returns the value associated with the keyword.
      def get_keyword_value(string)
        return_string = String.new()
        found = false
        @keywordPairs.each do |pair|
          if pair[0] == string
            found = true
            return_string = pair[1]
          end
        end
        if found == false
          raise "Error: In the command #{@utype}:#{@command_name} Attempted to get a Keyword pair #{string} present in the command\n Is this keyword missing? \n#{output}"
        end
        return return_string
      end

      # Sets the keyword value.
      def set_keyword_value(keyword, value)
        found = false
        unless @keywordPairs.empty?
          @keywordPairs.each do |pair|
            if pair[0] == keyword
              pair[1] = value
              found = true
            end
          end
          if (found == false)
            @keywordPairs.push([keyword,value])
          end
        else
          #First in the array...
          add_keyword_pair(keyword,value)
        end
      end

      # Removes the keyword pair.
      def remove_keyword_pair(string)
        return_string = String.new()
        @keywordPairs.each do |pair|
          if pair[0] == string
            @keywordPairs.delete(pair)
          end
        end
        return return_string
      end

      def is_this_an_envelope_heirchy_command()
        @envelopeLevel
      end

      def initialize
        @utype = String.new()
        @commandName= String.new()
        @keywordPairs=Array.new()
        @parents = Array.new()
        @children = Array.new()
        @commandType = String.new()
        @exempt = false
        #HVAC Hierarchry
        @comments =Array.new()
        @hvacLevel = Array.new()
        @hvacLevel[0] =["SYSTEM"]
        @hvacLevel[1] =["ZONE"]
        #Envelope Hierachy
        @envelopeLevel = Array.new()
        @envelopeLevel[0] = ["FLOOR"]
        @envelopeLevel[1] = ["SPACE"]

        @envelopeLevel[2] = [
          "EXTERIOR-WALL",
          "INTERIOR-WALL",
          "UNDERGROUND-WALL",
          "ROOF"
        ]

        @envelopeLevel[3] = [
          "WINDOW",
          "DOOR"]

        @non_utype_commands = Array.new()
        @non_utype_commands = [
          "TITLE",
          "SITE-PARAMETERS",
          "BUILD-PARAMETER",
          "LOADS_REPORT",
          "SYSTEMS-REPORT",
          "MASTERS-METERS",
          "ECONOMICS-REPORT",
          "PLANT-REPORT",
          "LOADS-REPORT",
          "COMPLIANCE"
        ]
        @one_line_commands = Array.new()
        @one_line_commands = ["INPUT","RUN-PERIOD","DIAGNOSTIC","ABORT", "END", "COMPUTE", "STOP", "PROJECT-DATA"]
      end

      # Determines the DOE scope, either envelope or hvac (Window, Wall, Space Floor) or (System->Plant) 
      # Hierarchy) this is required to determine parent/child relationships in the building. 
      def doe_scope
        scope = "none"
        @envelopeLevel.each_index do |index|
          @envelopeLevel[index].each do |name|
            if (@commandName == name )
              scope = "envelope"
            end
          end
        end

        @hvacLevel.each_index do |index|
          @hvacLevel[index].each do |name|
            if (@commandName == name )
              scope = "hvac"
            end
          end
        end
        return scope
      end
      # Determines the DOE scope depth (Window, Wall, Space Floor) or (System->Plant) Hierarchy)
      def depth
        level = 0
        scopelist=[]
        if (doe_scope == "hvac")
          scopelist = @hvacLevel
        else
          scopelist = @envelopeLevel
        end
        scopelist.each_index do |index|
          scopelist[index].each do |name|
            if (@commandName == name )
              level = index
            end
          end
        end
        return level
      end

      #Outputs the command in DOE 2.2 format.
      def output
        return basic_output()
      end

      #Outputs the command in DOE 2.2 format.
      def basic_output()
        temp_string = String.new()

        if (@utype != "")
          temp_string = temp_string + "#{@utype} = "
        end
        temp_string = temp_string + @commandName
        temp_string = temp_string + "\n"
        @keywordPairs.each {|array| temp_string = temp_string +  "\t#{array[0]} = #{array[1]}\n" }
        temp_string = temp_string + "..\n"

        temp_string = temp_string + "$Parents\n"
        @parents.each do |array|
          temp_string = temp_string +  "$\t#{array.utype} = #{array.commandName}\n"
        end
        temp_string = temp_string + "..\n"

        temp_string = temp_string + "$Children\n"
        @children.each {|array| temp_string = temp_string +  "$\t#{array.utype} = #{array.commandName}\n" }
        temp_string = temp_string + "..\n"

      end

      # Creates the command informantion based on DOE 2.2 syntax.
      def get_command_from_string(command_string)
        #Split the command based on the equal '=' sign.
        remove = ""
        keyword=""
        value=""

        if (command_string != "")
          #Get command and u-value
          if ( command_string.match(/(^\s*(\".*?\")\s*\=\s*(\S+)\s*)/) )
            @commandName=$3.strip
            @utype = $2.strip
            remove = Regexp.escape($1)

          else
            # if no u-value, get just the command.
            command_string.match(/(^\s*(\S*)\s)/ )
            remove = Regexp.escape($1)
            @commandName=$2.strip
          end
          #Remove command from string.

          command_string.sub!(/#{remove}/,"")
          command_string.strip!


          #Loop throught the keyword values.
          while ( command_string.length > 0 )
            #DOEMaterial, or SCHEDULES
            if ( command_string.match(/(^\s*(MATERIAL|DAY-SCHEDULES|WEEK-SCHEDULES)\s*(\=?)\s*(.*)\s*)/))
              #puts "Bracket"
              keyword = $2.strip
              value = $4.strip
              remove = Regexp.escape($1)
              #Stars
            elsif ( command_string.match(/(^\s*(\S*)\s*(\=?)\s*(\*.*?\*)\s*)/))
              #puts "Bracket"
              keyword = $2.strip
              value = $4.strip
              remove = Regexp.escape($1)

              #Brackets
            elsif ( command_string.match(/(^\s*(\S*)\s*(\=?)\s*(\(.*?\))\s*)/))
              #puts "Bracket"
              keyword = $2.strip
              value = $4.strip
              remove = Regexp.escape($1)
              #Quotes
            elsif ( command_string.match(/(^\s*(\S*)\s*(\=?)\s*(".*?")\s*)/) )
              #puts "Quotes"
              keyword = $2
              value = $4.strip
              remove = Regexp.escape($1)
              #single command
            elsif command_string.match(/(^\s*(\S*)\s*(\=?)\s*(\S+)\s*)/)
              #puts "Other"
              keyword = $2
              value = $4.strip
              remove = Regexp.escape($1)
            end
            #puts "DOE22::DOECommand: #{command_string}"
            #puts "K = #{keyword} V = #{value}\n"
            if (keyword != "")
              set_keyword_value(keyword,value)
            end
            command_string.sub!(/#{remove}/,"")
          end
          #puts "Keyword"
          #puts keywordPairs
        end
      end

      #Returns an array of the commands parents.
      def get_parents
        return @parents
      end

      #Returns an array of the commands children.
      def get_children
        return children
      end

      # Gets name.
      def get_name()
        return @utype
      end

      # Check if keyword exists.
      def check_keyword?(keyword)
        @keywordPairs.each do |pair|
          if pair[0] == keyword
            return true
          end
        end
        return false
      end

      # Gets the parent of command...if any.
      def get_parent(keyword)

        get_parents().each do |findcommand|

          if ( findcommand.commandName == keyword)
            return findcommand
          end
        end
        raise("#{keyword} parent not defined!")

      end

      #Gets children of command, if any.
      def get_children_of_command(keyword)
        array = Array.new()
        children.each do |findcommand|
          if ( findcommand.commandName == keyword)
            array.push(findcommand)
          end
        end
        return array
      end

      def name()
        return utype
      end

      private
      def add_keyword_pair(keyword,pair)
        array = [keyword,pair]
        keywordPairs.push(array)
      end
    end
    class DOEZone < BTAP::EQuest::DOECommand
      attr_accessor :space
      # a vector of spaces used when the declaration of space is "combined"
      attr_accessor :space_uses
      # a lighting object which stores the lighting characteristics of each zone
      attr_accessor :lighting
      #defines the thermal mass characteristics of the zone.
      #could be a string object or a user defined object
      attr_accessor :thermal_mass
      # stores a constant floating value of the amount of air leakage,
      #accoriding to rule #4.3.5.9.
      attr_accessor :air_leakage
      # this will be a vector consisting of heat transfer objects,
      # which contains a pointer to the adjacent thermal block and a pointer
      # to the wall in between them
      attr_accessor :heat_transfers
      def initialize
        super()
      end

      def output

        temp_string = basic_output()
        if (@space == nil)
          temp_string = temp_string + "$ No space found to match zone!\n"
        else
          temp_string = temp_string + "$Space\n"
          temp_string = temp_string +  "$\t#{@space.utype} = #{@space.commandName}\n"
        end
        return temp_string
      end

      # This method finds all the exterior surfaces, ie. Exterior Wall and Roof
      # Output => surfaces as an Array of commands
      def get_exterior_surfaces()
        surfaces = Array.new()
        @space.get_children().each do |child|

          if child.commandName == "EXTERIOR-WALL" ||
              child.commandName == "ROOF"
            surfaces.push(child)
          end
        end
        return surfaces
      end

      # This method returns all the children of the space
      def get_children()
        return @space.get_children()
      end

      # This method returns "Electricity" as the default fuel source
      def get_heating_fuel_source()
        return "Electricity"
      end

      # This method returns "direct" as the default condition type
      def condition_type()
        return "direct"
        #return "indirect"
      end

      # This method returns the area of the space
      def get_area()
        @space.get_area()
      end

      # This method returns "office" as the default usage of the space
      def get_space_use()
        return "Office"
      end

      def set_occupant_number(value)
        #according to rule 4.3.1.3.2 if the condition is "indirect
        #then the number of occupants is set to zero
      end

      def set_recepticle_power( value)
        #according to rule 4.3.1.3.2 if the condition is "indirect
        #then the receptical power is set to zero
      end

      def set_service_water_heating( value )
        #according to rule 4.3.1.3.2 if the condition is "indirect
        #then the service water heating is set to zero
      end

      def set_min_outdoor_air( value )
        #according to rule 4.3.1.3.2 if the condition is "indirect
        #then the minimum outdoor air is set to zero
      end

      def convert_to_openstudio(model)
        if self.space.get_shape() == "NO-SHAPE"
          puts "Thermal Zone contains a NO-SHAPE space. OS does not support no shape spaces.  Thermal Zone will not be created."
        else
          os_zone = OpenStudio::Model::ThermalZone.new(model)
          os_zone.setAttribute("name", self.name)
          #set space to thermal zone
          OpenStudio::Model::getSpaceByName(model,self.space.name).get.setThermalZone(os_zone)
          puts "\tThermalZone: " + self.name + " created"
        end
      end
    end
    
    class DOESystem < DOECommand
      def initialize
        super()
      end
    end
    class DOESurface < DOECommand
      attr_accessor :construction
      attr_accessor :polygon

      def initialize
        super()
        @polygon = nil
      end

      def get_azimuth()
        #puts OpenStudio::radToDeg( OpenStudio::getAngle(OpenStudio::Vector3d.new(0.0, 0.0, 0.0), OpenStudio::Vector3d.new(1.0, 0.0, 0.0) ) )
        if check_keyword?("LOCATION")
          case get_keyword_value("LOCATION")
          when /SPACE-\s*V\s*(.*)/
            index = $1.strip.to_i - 1
            point0 = self.get_parent("SPACE").polygon.point_list[index]
            point1 = self.get_parent("SPACE").polygon.point_list[index + 1] ? get_parent("SPACE").polygon.point_list[index + 1] : get_parent("SPACE").polygon.point_list[0]
            edge = point1-point0

            sign = OpenStudio::Vector3d.new(1.0, 0.0, 0.0).dot(( edge )) > 0 ? 1 :-1
            angle = OpenStudio::radToDeg( sign * OpenStudio::getAngle(OpenStudio::Vector3d.new(1.0, 0.0, 0.0), ( point1 - point0 ) ) )

            #since get angle only get acute angles we need to get sign and completment for reflex angle
            angle = angle + 180 if edge.y < 0
            return angle
          when "FRONT"
            return  OpenStudio::radToDeg( OpenStudio::getAngle(OpenStudio::Vector3d.new(0.0, 1.0, 0.0), ( get_parent("SPACE").polygon.point_list[1] - get_parent("SPACE").polygon.point_list[0] ) ) )
          when "RIGHT"
            return OpenStudio::radToDeg( OpenStudio::getAngle(OpenStudio::Vector3d.new(0.0, 1.0, 0.0), ( get_parent("SPACE").polygon.point_list[2] - get_parent("SPACE").polygon.point_list[1] ) ) )
          when "BACK"
            return OpenStudio::radToDeg( OpenStudio::getAngle(OpenStudio::Vector3d.new(0.0, 1.0, 0.0), ( get_parent("SPACE").polygon.point_list[3] - get_parent("SPACE").polygon.point_list[2] ) ) )
          when "LEFT"
            return OpenStudio::radToDeg( OpenStudio::getAngle(OpenStudio::Vector3d.new(0.0, 1.0, 0.0), ( get_parent("SPACE").polygon.point_list[0] - get_parent("SPACE").polygon.point_list[3] ) ) )
          end
        end
        return self.check_keyword?("AZIMUTH")? self.get_keyword_value("AZIMUTH").to_f : 0.0
      end

      def get_tilt()
        #puts OpenStudio::radToDeg( OpenStudio::getAngle(OpenStudio::Vector3d.new(0.0, 0.0, 0.0), OpenStudio::Vector3d.new(1.0, 0.0, 0.0) ) )
        if check_keyword?("LOCATION")
          case get_keyword_value("LOCATION")
          when "FRONT","BACK","LEFT","RIGHT",/SPACE-\s*V\s*(.*)/
            return  90.0
          when "TOP"
            return 0.0
          when "BOTTOM"
            return 180.0
          end
        end
        return self.check_keyword?("TILT")? self.get_keyword_value("TILT").to_f : 0.0
      end




      def get_origin()
        space_xref = self.check_keyword?("X")? self.get_keyword_value("X").to_f : 0.0
        space_yref = self.check_keyword?("Y")? self.get_keyword_value("Y").to_f : 0.0
        space_zref = self.check_keyword?("Z")? self.get_keyword_value("Z").to_f : 0.0
        return OpenStudio::Vector3d.new(space_xref,space_yref,space_zref)
      end
      
      def get_sub_surface_origin()
        height = ""
        puts "geting origin"
        origin = ""
        if self.check_keyword?("X") and self.check_keyword?("Y") and self.check_keyword?("Z")
          puts "XYZ definition"
          space_xref = self.get_keyword_value("X").to_f
          space_yref = self.get_keyword_value("Y").to_f
          space_zref = self.get_keyword_value("Z").to_f
          return OpenStudio::Vector3d.new(space_xref,space_yref,space_zref)
        end
        puts get_name()
        array = Array.new()
        origin = ""
        floor = get_parent("FLOOR")
        space = get_parent("SPACE")
        case space.get_keyword_value("ZONE-TYPE")
        when "PLENUM"
          height = floor.get_keyword_value("FLOOR-HEIGHT").to_f  - floor.get_keyword_value("SPACE-HEIGHT").to_f
        when "CONDITIONED","UNCONDITIONED"
          height =  space.check_keyword?("HEIGHT") ? space.get_keyword_value("HEIGHT").to_f : floor.get_keyword_value("SPACE-HEIGHT").to_f

        end

        puts "Space is #{space.get_shape}"
        case space.get_shape
        when "BOX"
          puts "Box Space Detected...."
          #get height, width and depth of box.
          height = space.check_keyword?("HEIGHT").to_f ? space.check_keyword?("HEIGHT") : height
          width = space.get_keyword_value("WIDTH").to_f
          depth = space.get_keyword_value("DEPTH").to_f

          case get_keyword_value("LOCATION")
          when "TOP"
            puts "Top of Box...."
            #counter clockwise
            origin = OpenStudio::Point3d.new(0.0,0.0,height)

          when "BOTTOM"
            puts "Bottom of Box...."
            #counter clockwise
            origin = OpenStudio::Point3d.new( 0.0, 0.0, 0.0 )
          when "FRONT"
            puts "Front of Box...."
            #counter clockwise
            origin = OpenStudio::Point3d.new( 0.0, 0.0, 0.0 )
          when "RIGHT"
            puts "Right of Box...."
            #counter clockwise
            origin = OpenStudio::Point3d.new(width, 0.0, 0.0)
          when "BACK"
            puts "Back of Box...."
            #counter clockwise
            origin = OpenStudio::Point3d.new(width,depth,0.0)
          when "LEFT"
            puts "Left of Box...."
            #counter clockwise
            origin = OpenStudio::Point3d.new(0.0,depth,0.0)

          end

        when "POLYGON"
          puts "Polygon Space definition detected..."
          if check_keyword?("LOCATION")
            puts "LOCATION surface definition detected..."
            case get_keyword_value("LOCATION")
            when "BOTTOM"
              origin = OpenStudio::Vector3d.new(0.0,0.0, 0.0 )
            when "TOP"
              puts "TOP surface definition detected..."
              #need to move floor polygon up to space height for top. Using Transformation.translation matrix for this.
                
              origin = OpenStudio::Vector3d.new(0.0,0.0, height ) #to-do!!!!!!!!!!!
            when /SPACE-\s*V\s*(.*)/
              puts "SPACE-V#{$1} surface definition detected..."
              index = $1.strip.to_i - 1
              point0 = space.polygon.point_list[index]
              #counter clockwise
              origin = OpenStudio::Point3d.new( point0.x, point0.y, 0.0)

            end
          else
            puts "CATCH-ALL for surface definition.."
            #nasty. The height is NOT defined if the height is the same as the space height...so gotta get it from it's parent space. 
            space_height =  space.check_keyword?("HEIGHT") ? space.get_keyword_value("HEIGHT").to_f : floor.get_keyword_value("SPACE-HEIGHT").to_f
            height = self.check_keyword?("HEIGHT") ? self.get_keyword_value("HEIGHT").to_f : space_height
            width =  self.get_keyword_value("WIDTH").to_f
            #origin
            origin = OpenStudio::Point3d.new(width,0.0,0.0)
          end
        when "NO-SHAPE"
          raise("Using SHAPE = NO-SHAPE deifnition for space is not supported by open Studio")
        end
        
        origin =  OpenStudio::Vector3d.new(origin.x,origin.y,origin.z)
        puts "Surface origin vector is #{origin}"
        return origin
      end
      


      def get_transformation_matrix
        #Rotate points around z (azimuth) and x (Tilt)
        translation = OpenStudio::createTranslation(self.get_origin) 
        e_a = OpenStudio::EulerAngles.new(	OpenStudio::degToRad( self.get_tilt ), 0.0, OpenStudio::degToRad( 180.0 - self.get_azimuth  ) )
        rotations = OpenStudio::Transformation::rotation(e_a)
        return  translation * rotations
      end

      def get_3d_polygon()
        puts get_name()
        array = Array.new()
        origin = ""
        floor = get_parent("FLOOR")
        space = get_parent("SPACE")
        case space.get_keyword_value("ZONE-TYPE")
        when "PLENUM"
          height = floor.get_keyword_value("FLOOR-HEIGHT").to_f  - floor.get_keyword_value("SPACE-HEIGHT").to_f
        when "CONDITIONED","UNCONDITIONED"
          height =  space.check_keyword?("HEIGHT") ? space.get_keyword_value("HEIGHT").to_f : floor.get_keyword_value("SPACE-HEIGHT").to_f
        end

        #if the surface has been given a polygon. Then use it.
        if check_keyword?("POLYGON")
          puts "Polygon Surface Detected...Doing a local transform.."
          
          puts "Point List"
          puts self.polygon.point_list
          puts "Origin"
          puts self.get_origin
          puts "azimuth"
          puts self.get_azimuth
          puts "tilt"
          puts self.get_tilt
          

          
          #all other methods below create points relative to the space. This method however, need to be transformed.
          array = self.polygon.point_list


          #if surfaces are defined by shape of space.
        else
          case space.get_shape
          when "BOX"
            puts "Box Space Detected...."
            #get height, width and depth of box.
            height = space.check_keyword?("HEIGHT").to_f ? space.check_keyword?("HEIGHT") : height
            width = space.get_keyword_value("WIDTH").to_f
            depth = space.get_keyword_value("DEPTH").to_f

            case get_keyword_value("LOCATION")
            when "TOP"
              puts "Top of Box...."
              #counter clockwise
              origin = OpenStudio::Point3d.new(0.0,0.0,height)
              p2 = OpenStudio::Point3d.new(width,0.0,height)
              p3 = OpenStudio::Point3d.new(width,depth,height)
              p4 = OpenStudio::Point3d.new(0.0,depth,height)
              array =  [origin,p2,p3,p4]
            when "BOTTOM"
              puts "Bottom of Box...."
              #counter clockwise
              origin = OpenStudio::Point3d.new( 0.0, 0.0, 0.0 )
              p2 = OpenStudio::Point3d.new( 0.0, depth, 0.0)
              p3 = OpenStudio::Point3d.new( width, depth, 0.0)
              p4 = OpenStudio::Point3d.new( width,0.0 ,0.0 )
              array =  [origin,p2,p3,p4]
            when "FRONT"
              puts "Front of Box...."
              #counter clockwise
              origin = OpenStudio::Point3d.new( 0.0, 0.0, 0.0 )
              p2 = OpenStudio::Point3d.new( width,0.0 ,0.0 )
              p3 = OpenStudio::Point3d.new( width, 0.0, height)
              p4 = OpenStudio::Point3d.new( 0.0, 0.0, height)
              array =  [origin,p2,p3,p4]
            when "RIGHT"
              puts "Right of Box...."
              #counter clockwise
              origin = OpenStudio::Point3d.new(width, 0.0, 0.0)
              p2 = OpenStudio::Point3d.new(width,depth, 0.0)
              p3 = OpenStudio::Point3d.new(width,depth,height)
              p4 = OpenStudio::Point3d.new(width,0.0,height)
              array =  [origin,p2,p3,p4]
            when "BACK"
              puts "Back of Box...."
              #counter clockwise
              origin = OpenStudio::Point3d.new(width,depth,0.0)
              p2 = OpenStudio::Point3d.new(0.0,depth,0.0)
              p3 = OpenStudio::Point3d.new(0.0,depth,height)
              p4 = OpenStudio::Point3d.new(width,depth,height)
              array =  [origin,p2,p3,p4]
            when "LEFT"
              puts "Left of Box...."
              #counter clockwise
              origin = OpenStudio::Point3d.new(0.0,depth,0.0)
              p2 = OpenStudio::Point3d.new( 0.0, 0.0, 0.0 )
              p3 = OpenStudio::Point3d.new(0.0, 0.0,height)
              p4 = OpenStudio::Point3d.new(0.0,depth,height)
              array =  [origin,p2,p3,p4]
            end

          when "POLYGON"
            puts "Polygon Space definition detected..."
            if check_keyword?("LOCATION")
              puts "LOCATION surface definition detected..."
              case get_keyword_value("LOCATION")
              when "BOTTOM"
                puts "BOTTOM surface definition detected..."
                #reverse array
                array = space.polygon.point_list.dup
                first = array.pop
                array.insert(0,first).reverse!
              when "TOP"
                puts "TOP surface definition detected..."
                #need to move floor polygon up to space height for top. Using Transformation.translation matrix for this.
                array = OpenStudio::createTranslation(OpenStudio::Vector3d.new(0.0,0.0, height )) * space.polygon.point_list
              when /SPACE-\s*V\s*(.*)/
                puts "SPACE-V#{$1} surface definition detected..."
                index = $1.strip.to_i - 1
                point0 = space.polygon.point_list[index]
                point1 = space.polygon.point_list[index + 1] ? space.polygon.point_list[index + 1] : space.polygon.point_list[0]
                #counter clockwise
                origin = OpenStudio::Point3d.new( point0.x, point0.y, 0.0)
                p2 = OpenStudio::Point3d.new(     point1.x, point1.y, 0.0)
                p3 = OpenStudio::Point3d.new(     point1.x, point1.y, height )
                p4 = OpenStudio::Point3d.new(     point0.x, point0.y, height )
                array =  [origin,p2,p3,p4]
              end
            else
              puts "CATCH-ALL for surface definition.."
              #nasty. The height is NOT defined if the height is the same as the space height...so gotta get it from it's parent space. 
              space_height =  space.check_keyword?("HEIGHT") ? space.get_keyword_value("HEIGHT").to_f : floor.get_keyword_value("SPACE-HEIGHT").to_f
              height = self.check_keyword?("HEIGHT") ? self.get_keyword_value("HEIGHT").to_f : space_height
              width =  self.get_keyword_value("WIDTH").to_f
              #counter clockwise
              origin = OpenStudio::Point3d.new(width,0.0,0.0)
              p2 = OpenStudio::Point3d.new( 0.0,0.0,0.0 )
              p3 = OpenStudio::Point3d.new(0.0,0.0,height)
              p4 = OpenStudio::Point3d.new(width,0.0,height)
              array = [p4, p3, p2, origin]
  

              
            end
          when "NO-SHAPE"
            raise("Using SHAPE = NO-SHAPE deifnition for space is not supported...yet")
          end
        end
        #        if self.check_keyword?("AZIMUTH") or self.check_keyword?("TILT")
        #          puts "Did a transform"
        #          return get_transformation_matrix * array
        #        else
        #          return array
        #        end
        return array
      end


      def get_windows()
        return self.get_children_of_command("WINDOW")
      end

      def get_doors()
        return self.get_children_of_command("DOOR")
      end



      # This method finds all the commands within the building that are "Construction"
      # and if the utype matches, it gets the construction
      def determine_user_defined_construction()
        constructions = @building.find_all_commands("CONSTRUCTION")
        constructions.each do |construction|
          if ( construction.utype == get_keyword_value("CONSTRUCTION") )
            @construction = construction
          end
        end
        return @construction
      end

      #This method will try to convert a DOE inp file to an openstudio file.. 
      def convert_to_openstudio(model)
        #Get 3d polygon of surface and tranform the points based on space origin and the floor origin since they each may use their own co-ordinate base system.
        total_transform = ""
        if self.check_keyword?("AZIMUTH") or self.check_keyword?("TILT")
          total_transform =  get_parent("FLOOR").get_transformation_matrix() * get_parent("SPACE").get_transformation_matrix() * get_transformation_matrix()
        else
          total_transform =  get_parent("FLOOR").get_transformation_matrix() * get_parent("SPACE").get_transformation_matrix()
        end
        surface_points = total_transform * self.get_3d_polygon()
        #Add the surface to the new openstudio model. 
        os_surface = OpenStudio::Model::Surface.new(surface_points, model)
        #set the name of the surface. 
        os_surface.setAttribute("name", self.name)
        #Set the surface boundary condition if it is a ground surface. 
        BTAP::Geometry::Surfaces::set_surfaces_boundary_condition(model,os_surface, "Ground") if self.commandName == "UNDERGROUND-WALL"
        #Add to parent space that was already created. 
        os_surface.setSpace(OpenStudio::Model::getSpaceByName( model,get_parent("SPACE").name).get )
        #output to console for debugging. 
        puts "\tSurface: " + self.name + " created"
        #check if we need to create a mirror surface in another space.
        if self.check_keyword?("NEXT-TO")
          #reverse the points.
          new_array = surface_points.dup
          first = new_array.pop
          new_array.insert(0,first).reverse!
          #...then add the reverse surface to the model and assign the name with a mirror suffix. 
          os_surface_mirror = OpenStudio::Model::Surface.new(new_array, model)
          os_surface_mirror.setAttribute("name", self.name + "-mirror" )
          #Assign the mirror surface to the parent space that is NEXT-TO
          os_surface_mirror.setSpace(OpenStudio::Model::getSpaceByName(model,get_keyword_value("NEXT-TO")).get)
          #output to console for debugging. 
          puts "\tSurface: " + self.name + "-mirror"  + " created"
        end #if statement
        
        #Some switches for debugging. 
        convert_sub_surfaces = true
        convert_sub_surfaces_as_surfaces = false
        
        #
        if convert_sub_surfaces
          #convert subsurfaces
          self.get_children().each do |child|
            puts "child #{child}"
            #Get height and width of subsurface
            height = child.get_keyword_value("HEIGHT").to_f
            width = child.get_keyword_value("WIDTH").to_f
          
            #Sum the origin of the surface and the translation of the window
            x = os_surface.vertices.first().x + ( child.check_keyword?("X")?  child.get_keyword_value("X").to_f : 0.0 )
            y = os_surface.vertices.first().y + ( child.check_keyword?("Y")?  child.get_keyword_value("Y").to_f : 0.0 )
            z = os_surface.vertices.first().z
          
            #counter clockwise
            origin = OpenStudio::Point3d.new( x, y , z )
            p2 = OpenStudio::Point3d.new(x + width , y, z )
            p3 = OpenStudio::Point3d.new(x + width , y + height , z )
            p4 = OpenStudio::Point3d.new(x, y + height, z )
            polygon =  [origin,p2,p3,p4]

            #get floot and space rotations
            space_azi = 360.0 - get_parent("SPACE").get_azimuth()
            floor_azi = 360.0 - get_parent("FLOOR").get_azimuth()

          
            tilt_trans = OpenStudio::Transformation::rotation(os_surface.vertices.first(), OpenStudio::Vector3d.new(1.0,0.0,0.0), OpenStudio::degToRad( self.get_tilt ))
            azi_trans = OpenStudio::Transformation::rotation(os_surface.vertices.first(), OpenStudio::Vector3d.new(0.0,0.0,1.0), OpenStudio::degToRad( 360.0 - self.get_azimuth + space_azi + floor_azi  ))
            surface_points =  azi_trans  * tilt_trans * polygon
            if convert_sub_surfaces_as_surfaces
              #Debug subsurface
              os_sub_surface = OpenStudio::Model::Surface.new(surface_points, model)
              #set the name of the surface. 
              os_sub_surface.setAttribute("name", child.name)
              #Add to parent space that was already created. 
              os_sub_surface.setSpace(OpenStudio::Model::getSpaceByName( model,self.get_parent("SPACE").name).get )
            else
              #Add the subsurface to the new openstudio model. 
              os_sub_surface = OpenStudio::Model::SubSurface.new(surface_points, model)
              #set the name of the surface. 
              os_sub_surface.setAttribute("name", child.name )
              #Add to parent space that was already created. 
              os_sub_surface.setSurface(os_surface)
              #output to console for debugging. 
              puts "\tSubSurface: " + child.name + " created"
              case child.commandName
              when "WINDOW"
                #By default it is a window. 
              when "DOOR"
                os_sub_surface.setSubSurfaceType( "Door" )
              end #end case.
            end
          end
        end
      end

    end
    
    #This class allows to manipulate a subsurface (window/door) in inherits from surface. 
    class DOESubSurface < DOESurface

      def initialize
        #run the parent class initialization. 
        super()
      end

      # This method returns the area of the window
      def get_area()
        unless check_keyword?("HEIGHT")  and check_keyword?("WIDTH")
          raise "Error: In the command #{@utype}:#{@command_name} the area could not be evaluated. Either the HEIGHT or WIDTH is invalid.\n #{output}"
        end
        return get_keyword_value("WIDTH").to_f * get_keyword_value("HEIGHT").to_f
      end

      #Return the widow polygon with an origin of zero
      def get_3d_polygon()
        height = get_keyword_value("HEIGHT").to_f
        width = get_keyword_value("WIDTH").to_f
        x = self.check_keyword?("X")?  self.get_keyword_value("X").to_f : 0.0
        y = self.check_keyword?("Y")?  self.get_keyword_value("Y").to_f : 0.0
        #counter clockwise
        origin = OpenStudio::Point3d.new( x, y , 0.0 )
        p2 = OpenStudio::Point3d.new(x + width , y,0.0 )
        p3 = OpenStudio::Point3d.new(x + width , y + height , 0.0 )
        p4 = OpenStudio::Point3d.new(x, y + height,0.0 )
        return [origin,p2,p3,p4]
      end

      #Returns the origin relative to the parent surface. 
      def get_origin()
        origin = get_parent_surface().get_sub_surface_origin()
        return origin
      end

      #Gets azimuth, based on parent surface. 
      def get_azimuth()
        get_parent_surface().get_azimuth()
      end

      #gets tilt based on parent surface. 
      def get_tilt()
        get_parent_surface().get_tilt()
      end

      #return the parent surface of the subsurface. 
      def get_parent_surface()
        get_parents().each do |findcommand|
          [
            "EXTERIOR-WALL",
            "INTERIOR-WALL",
            "UNDERGROUND-WALL",
            "ROOF"
          ].each do |type|

            if ( findcommand.commandName == type)
              return findcommand
            end
          end
        end
        raise("#no parent surface defined!")
      end

      #returns the translation matrix reletive to its parent ( the surface ) 
      def get_transformation_matrix
        return  self.get_rotation_matrix() * self.get_translation_matrix()
      end
      
      def get_rotation_matrix
        #Rotate points around z (azimuth) and x (Tilt)
        e_a = OpenStudio::EulerAngles.new(	OpenStudio::degToRad( self.get_tilt ), 0.0, OpenStudio::degToRad( 0.0  ) )
        rotations = OpenStudio::Transformation::rotation(e_a)
        return  rotations 
      end
      
      def get_translation_matrix
        #Rotate points around z (azimuth) and x (Tilt)
        translation = OpenStudio::createTranslation(self.get_origin) 
        return  translation 
      end
      
      
      
      

      # this will translate the subsurface to the openstudio model. 
      def convert_to_openstudio(model)        
      end
    end
    
    #Subclass for a DOE window...the implemenation is the same as the base class. 
    class DOEWindow < DOESubSurface
      def initialize
        super()
      end
    end
    
    #Subclass for a DOE door. the implemenation is the same as the base class. 
    class DOEDoor < DOESubSurface
      #Contains uvalue of door
      def initialize
        super()
      end

    end
    
    #an attempt to organize the BDLlibs...don't think it works well at all. 
    class DOEBDLlib

      attr_accessor :db, :materials

      include Singleton




      # stores the name of the individual materials

      attr_accessor :commandList
      # stores the name of the individual layers


      def initialize
        @commandList = Array.new()
        @db = Sequel.sqlite
        @db.create_table :materials do # Create a new table
          primary_key :id, :integer, :auto_increment => true
          column :command_name, :text
          column :name, :text
          column :type, :text
          column :thickness, :float
          column :conductivity, :float
          column :resistance, :float
          column :density, :float
          column :spec_heat, :float
        end
        @materials = @db[:materials] # Create a dataset

        @db.create_table :layers do # Create a new table
          primary_key :id, :integer, :auto_increment => true
          column :command_name, :text
          column :name, :text
          column :material, :text
          column :inside_film_res, :float
        end
        @layers = @db[:layers] # Create a dataset


        store_material()
      end



      def find_material(utype)
        posts =  @materials.filter(:name => utype)
        record = posts.first()
        #Create the new command object.
        command = DOE2::DOECommand.new()
        #Insert the collected information into the object.
        command.commandName = "MATERIAL"
        command.utype = record[:name]
        command.set_keyword_value("TYPE", record[:type])
        command.set_keyword_value("THICKNESS", record[:thickness])
        command.set_keyword_value("CONDUCTIVITY", record[:conductivity])
        command.set_keyword_value("DENSITY", record[:density])
        command.set_keyword_value("SPECIFIC HEAT", record[:spec_heat])

        return command
      end


      def find_layer(utype)
        posts =  @layers.filter(:name => utype)
        record = posts.first()
        #Create the new command object.
        command = DOE2::DOECommand.new()
        #Insert the collected information into the object.
        command.commandName = "LAYERS"
        command.utype = record[:name]
        command.set_keyword_value("MATERIAL", record[:material])
        command.set_keyword_value("THICKNESS", record[:thickness])
        command.set_keyword_value("CONDUCTIVITY", record[:conductivity])
        command.set_keyword_value("DENSITY", record[:density])
        command.set_keyword_value("SPECIFIC HEAT", record[:spec_heat])

        return command
      end





      # stores the material information using keywordPairs into the command structure
      # accessed using the find_command method
      private
      def store_material

        begin
          f = File.open("../Resources/DOE2_2/bdllib.dat")
        rescue
          f = File.open("Resources/DOE2_2/bdllib.dat")
        end

        lines = f.readlines
        # Iterating through the file.
        lines.each_index do |i|
          command_string = ""
          # If we find a material.
          if lines[i].match(/\$LIBRARY-ENTRY\s(.{32})MAT .*/)
            #Get the name strips the white space.
            name = ("\""+$1.strip + "\"")

            #Is this the last line?
            command_string = get_data(command_string, i, lines)
            #Extract data for material type PROPERTIES.
            if (match = command_string.match(/^\s*TYPE\s*=\s*(\S*)\s*TH\s*=\s*(\S*)\s*COND\s*=\s*(\S*)\s*DENS\s*=\s*(\S*)\s*S-H\s*=\s*(\S*)\s*$/) )
              #Create the new command object.
              command = DOE2::DOECommand.new()
              #Insert the collected information into the object.
              command.commandName = "MATERIAL"
              command.utype = name
              command.set_keyword_value("TYPE", $1.strip)
              command.set_keyword_value("THICKNESS", $2.strip.to_f.to_s)
              command.set_keyword_value("CONDUCTIVITY", $3.strip.to_f.to_s)
              command.set_keyword_value("DENSITY", $4.strip.to_f.to_s)
              command.set_keyword_value("SPECIFIC HEAT", $5.strip.to_f.to_s)
              #Push the object into the array for storage.
              @commandList.push(command)
              @materials << {:name => name,
                :command_name => 'MATERIAL',
                :type =>  $1.strip,
                :thickness =>  $2.strip.to_f.to_s,
                :conductivity =>  $3.strip.to_f.to_s,
                :density =>  $4.strip.to_f.to_s,
                :spec_heat =>  $5.strip.to_f.to_s}



              #Extract data for material type RESISTANCE.
            elsif (match = command_string.match(/^\s*TYPE\s*=\s*(\S*)\s*RES\s*=\s*(\S*)\s*$/) )
              command = DOE2::DOECommand.new()
              command.commandName = "MATERIAL"
              command.utype = name
              command.set_keyword_value("TYPE", $1.strip)
              command.set_keyword_value("RESISTANCE", $2.strip.to_f.to_s)
              #Push the object into the array for storage.
              @materials << {:name => name,
                :command_name => 'MATERIAL',
                :type =>  $1.strip,
                :resistance =>  $2.strip.to_f.to_s}

              @commandList.push(command)
            else
              raise("data not extracted")
            end
          end

          if lines[i].match(/\$LIBRARY-ENTRY\s(.{32})LA .*/)
            #Get the name
            name = ("\""+$1.strip + "\"")
            #Is this the last line?
            command_string = get_data(command_string, i, lines)
            #Extract data into the command.
            if (match = command_string.match(/^\s*MAT\s*=\s*(.*?)\s*I-F-R\s*=\s*(\S*)\s*$/) )
              command = DOE2::DOECommand.new()
              command.commandName = "LAYERS"
              command.utype = name
              command.set_keyword_value("MATERIAL",$1)
              #Push the object into the array for storage.
              @layers << {:name => name,
                :command_name => 'LAYER',
                :material =>  $1.strip,
                :inside_film_res =>  $2.strip.to_f.to_s}
              @commandList.push(command)
            else
              raise("data not extracted")
            end
          end
        end
        #@materials.print
        #@layers.print
      end

      private
      # This method will get all the
      def get_data(command_string, i, lines)
        #Do this while this is NOT the last line of data.
        while (! lines[i].match(/^(.*?)\.\.\s*(.{6})?\s*?(\d*)?/) )
          #Grab all the data in between.
          if ( lines[i].match(/^\$.*$/) )
          elsif ( myarray = lines[i].match(/^(.*?)\s*(.{6})?\s*?(\d*)?\s*$/) )
            command_string = command_string + $1.strip
          end
          #Increment counter.
          i = i + 1
        end
        #Get the last line
        lines[i].match(/^(.*?)\.\.\s*(.{6})?\s*?(\d*)?/)
        command_string = command_string + $1.strip
        if command_string == ""
          raise("error")
        end
        i  = i + 1
        command_string
      end
    end
    
    #class that 
    class DOEExteriorWall < DOESurface

      def initialize
        #call the parent class. 
        super()
      end

      # This method finds the area of the exterior wall
      def get_area()
        OpenStudio::getArea(self.get_3d_polygon())
      end

      #This method finds the floor parent
      def get_floor()
        get_parent("FLOOR")
      end

      #This method finds the space parent command
      def get_space()
        get_parent("SPACE")
      end

      #This method gets the construction command
      def get_construction_name()
        get_keyword_value("CONSTRUCTION")
      end

      #This method returns the window area
      def get_window_area()
        get_children_area("WINDOW")
      end

      #This method returns the door area
      def get_door_area()
        get_children_area("DOOR")
      end

      # This method returns the difference between the wall area and the window
      # and door
      def get_opaque_area()
        get_area.to_f - get_window_area().to_f - get_door_area().to_f
      end

      # This method returns the fraction of the wall dominated by the window
      def get_fwr()
        get_window_area().to_f / get_area.to_f
      end

      # This method returns the area of the children classes based on the given
      # commandname.
      # Input => A command_name as a String
      # Output => Total area as a float
      def get_children_area(scommand_name)
        area = 0.0
        @children.each do |child|

          if child.commandName == scommand_name
            area = child.get_area() + area
          end
        end
        return area
      end





      # This method checks if the construction only has a defined U-value
      def just_u_value?()
        @construction.check_keyword?("U-VALUE")
      end


    end
    
    
    #The interface for the Interior wall command.. same as parent. 
    class DOEInteriorWall < DOESurface
      def initialize
        super()
      end
      # Finds the area of the interior wall
    end
    
    #The interface for the UG wall command.. same as parent. 
    class DOEUndergroundWall < DOESurface
      def initialize
        super()
      end

    end
    
    #The interface for the roof command.. same as parent. 
    class DOERoof < DOECommand
      def initialize
        super()
      end

      # This method finds the area of the roof
      def get_area

        # Finds the floor and space parents and assigns them to @floor and @space
        # variables to be used later
        parent = get_parents
        parent.each do |findcommand|
          if ( findcommand.commandName == "FLOOR" )
            @floor = findcommand
          end
          if ( findcommand.commandName == "SPACE")
            @space = findcommand
          end
        end

        # Get the keyword value for location
        begin
          location = get_keyword_value("LOCATION")
        rescue
        end

        # Get the keyword value for polygon
        begin
          polygon_id = get_keyword_value("POLYGON")
        rescue
        end

        # if the polygon_id keyword value was nil and the location value was nil, then
        # the height and width are directly defined within the "roof" command


        if  ( location == "BOTTOM" || location == "TOP") && (@space.get_shape != "BOX")
          return @space.polygon.get_area

        elsif ( location == nil  && polygon_id == nil )
          height = get_keyword_value("HEIGHT")
          width = get_keyword_value("WIDTH")
          height = height.to_f
          width = width.to_f
          return height * width
        elsif ( location == nil && polygon_id != nil)
          return @space.polygon.get_area


          # if the location was defined as "SPACE...", it is immediately followed by a
          # vertex, upon which lies the width of the roof
        elsif location.match(/SPACE.*/)
          location = location.sub( /^(.{6})/, "")
          width = @space.polygon.get_length(location)
          height = @floor.get_space_height
          return width * height
          # if the shape was a box, the width and height would be taken from the
          # "SPACE" object
        elsif ( @space.get_shape == "BOX" )
          width = @space.get_width
          height = @space.get_height
          return width * height
        else
          raise "The area could not be evaluated"
        end
      end

      #returns tilt of roof surface. 
      def get_tilt()
        if check_keyword?("TILT") then return get_keyword_value("TILT").to_f
        else
          if check_keyword?("LOCATION")
            location = get_keyword_value("LOCATION")
            case location
            when "TOP"
              return 0.0
            when "BOTTOM"
              return 180.0
            when "LEFT", "RIGHT", "BACK", "FRONT"
              return 90.0
            end
          end
          # If it is a polygon or not defined, set to DOE default = 0.0
          return 0
        end
      end

      # This method returns the Azimuth value as a FLOAT if it exists
      # It first checks if the azimuth keyword value is present within the roof
      # command itself. If it does not find this, then it checks for the location
      # keyword and assigns the correct azimuth depending on the azimuth of the parent
      # space. However, if the shape of the parent space is defined as a polygon, then it
      # searches for the location of the roof and uses the polygon's get-azimuth for the vertex
      # to return the azimuth of the roof

      #NOTE: The FRONT is defined as 0, going clockwise, ie. RIGHT = 90 degrees

      #OUTPUT: Azimuth between the parent SPACE and the ROOF
      def get_azimuth()
        space = get_parent("SPACE")
        if check_keyword?("AZIMUTH") then return get_keyword_value("AZIMUTH").to_f
        else
          if check_keyword?("LOCATION")
            location = get_keyword_value("LOCATION")

            case location
            when "TOP"
              raise "Exception: Azimuth does not exist"
            when "BOTTOM"
              raise "Exception: Azimuth does not exist"
            when "FRONT"
              return 0.0 + space.get_azimuth
            when "RIGHT"
              return 90.0 + space.get_azimuth
            when "BACK"
              return 180.0 + space.get_azimuth
            when "LEFT"
              return 270.0 + space.get_azimuth
            end
          end
          if space.get_keyword_value("SHAPE") == "POLYGON"
            space_vertex = get_keyword_value("LOCATION")
            space_vertex.match(/SPACE-(.*)/)
            vertex = $1.strip
            return space.polygon.get_azimuth(vertex)
          end

        end
      end

      # This method returns the Azimuth value as a FLOAT if it exists
      # It first checks if the azimuth keyword value is present within the roof
      # command itself. If it does not find this, then it checks for the location
      # keyword and assigns the correct azimuth depending on the azimuth of the parent
      # space. However, if the shape of the parent space is defined as a polygon, then it
      # searches for the location of the roof and uses the polygon's get-azimuth for the vertex
      # and adding it on to the overall azimuth to get the Absolute Azimuth from True North

      #NOTE: The FRONT is defined as 0, going clockwise, ie. RIGHT = 90 degrees

      #OUTPUT: Azimuth between ROOF and TRUE NORTH
      def get_absolute_azimuth
        space = get_parent("SPACE")
        if check_keyword?("AZIMUTH")
          azimuth = get_keyword_value("AZIMUTH").to_f
          space_azimuth = space.get_absolute_azimuth
          return azimuth + space_azimuth
        else
          if check_keyword?("LOCATION")
            location = get_keyword_value("LOCATION")
            case location
            when "TOP"
              raise "Exception: Azimuth does not exist"
            when "BOTTOM"
              raise "Exception: Azimuth does not exist"
            when "FRONT"
              return 0.0 + space.get_absolute_azimuth
            when "RIGHT"
              return 90.0 + space.get_absolute_azimuth
            when "BACK"
              return 180.0 + space.get_absolute_azimuth
            when "LEFT"
              return 270.0 + space.get_absolute_azimuth
            end
          end
          if space.get_keyword_value("SHAPE") == "POLYGON"
            space_vertex = get_keyword_value("LOCATION")
            space_vertex.match(/SPACE-(.*)/)
            vertex = $1.strip
            return space.polygon.get_azimuth(vertex) + space.get_absolute_azimuth
          end
        end
      end
    end
    #Interface for the DOESpace Command. 
    class DOESpace < DOECommand
      attr_accessor :polygon
      attr_accessor :zone
      def initialize

        super()
      end

      #this outputs the command to a string. 
      def output
        temp_string = basic_output()
        if @polygon != nil
          temp_string = temp_string + "$Polygon\n"
          temp_string = temp_string +  "$\t#{@polygon.utype} = #{@polygon.commandName}\n"
        end
        if @zone != nil
          temp_string = temp_string + "$Zone\n"
          temp_string = temp_string +  "$\t#{@zone.utype} = #{@zone.commandName}\n"
        end
        return temp_string
      end

      # This method finds the area of the space
      def get_area

        # get the keyword value of shape
        shape = get_keyword_value("SHAPE")

        # if the shape value is nil, or it is defined as "NO-SHAPE", the get_area value
        # would be defined, and would represent the get_area of the space
        if ( shape == nil || shape == "NO-SHAPE")
          area = get_keyword_value("AREA")
          area = area.to_f
          return area

          # if the shape value is "BOX", the height and width key values are given,
          # and the get_area would be defined as their product
        elsif ( shape == "BOX" )
          height = get_keyword_value("HEIGHT")
          width = get_keyword_value("WIDTH")
          height = height.to_f
          width = width.to_f
          return height * width

          # if the shape value is defined as a polygon , the get_area of the polygon would
          # represent the get_area of the space
        elsif ( shape == "POLYGON")
          return @polygon.get_area
        else
          raise "Error: The area could not be evaluated. Please check inputs\n "

        end
      end

      # This method finds the volume of the space
      def get_volume

        # get the keyword value of "SHAPE"
        shape = get_keyword_value("SHAPE")

        # if the shape value returns nil, or is defined as "NO-SHAPE", the volume is
        # given directly
        if ( shape == nil || shape == "NO-SHAPE")
          volume = get_keyword_value("VOLUME")
          volume = volume.to_f
          return volume

          # if the shape is defined as a "BOX", the values for height, width, and
          # depth are given, from which you can get the volume
        elsif ( shape == "BOX" )
          height = get_keyword_value("HEIGHT")
          width = get_keyword_value("WIDTH")
          depth = get_keyword_value("DEPTH")
          height = height.to_f
          width = width.to_f
          depth = depth.to_f
          return height * width * depth

          # if the shape is defined as a "POLYGON", the get_area is defined as the area
          # of the polygon, and the height is given by the value of "HEIGHT"
        elsif ( shape == "POLYGON")
          height = getKeywordvalue("HEIGHT")
          temp = get_keyword_value("POLYGON")
          height = height.to_f
          @polygon.utype = temp
          return @polygon.get_area * height
        else
          raise "Error: The volume could not be evaluated. Please check inputs\n "

        end

      end

      def get_height()
        if check_keyword?("HEIGHT") then return get_keyword_value("HEIGHT").to_f end
        return get_floor.get_keyword_value("SPACE-HEIGHT").to_f
      end

      def get_width
        width = get_keyword_value("WIDTH")
        width = width.to_f
        return width
      end

      def get_depth
        depth = get_keyword_value("DEPTH")
        depth = depth.to_f
        return depth
      end

      def get_shape
        return "NO-SHAPE" unless check_keyword?("SHAPE")
        return get_keyword_value("SHAPE")
      end

      def get_floor
        get_parent("FLOOR")
      end


      def get_origin()
        space_origin = nil
        if check_keyword?("LOCATION") and ( not self.check_keyword?("X") or not self.check_keyword?("Y") or not self.check_keyword?("Z") )
          zero = OpenStudio::Point3d.new( 0.0, 0.0, 0.0 )
          case get_keyword_value("LOCATION")
          when /FLOOR-\s*V\s*(.*)/
            index = $1.strip.to_i - 1
            surf_vector =  get_parent("FLOOR").polygon.point_list[index] - zero
          when "FRONT"
            surf_vector =  get_parent("FLOOR").polygon.point_list[0] - zero
          when "RIGHT"
            surf_vector =  get_parent("FLOOR").polygon.point_list[1] - zero
          when "BACK"
            surf_vector =  get_parent("FLOOR").polygon.point_list[2] - zero
          when "LEFT"
            surf_vector =  get_parent("FLOOR").polygon.point_list[3] - zero
          end
          space_xref = self.check_keyword?("X")? self.get_keyword_value("X").to_f : 0.0
          space_yref = self.check_keyword?("Y")? self.get_keyword_value("Y").to_f : 0.0
          space_zref = self.check_keyword?("Z")? self.get_keyword_value("Z").to_f : 0.0
          space_origin = OpenStudio::Vector3d.new(space_xref,space_yref,space_zref)
          space_origin = surf_vector + space_origin
        else
          space_xref = self.check_keyword?("X")? self.get_keyword_value("X").to_f : 0.0
          space_yref = self.check_keyword?("Y")? self.get_keyword_value("Y").to_f : 0.0
          space_zref = self.check_keyword?("Z")? self.get_keyword_value("Z").to_f : 0.0
          space_origin = OpenStudio::Vector3d.new(space_xref,space_yref,space_zref)
        end
        puts "#{self.commandName} #{self.get_name} origin is : #{space_origin}"
        return space_origin
      end

      def get_azimuth()
        angle = 0.0
        #puts OpenStudio::radToDeg( OpenStudio::getAngle(OpenStudio::Vector3d.new(0.0, 0.0, 0.0), OpenStudio::Vector3d.new(1.0, 0.0, 0.0) ) )
        if check_keyword?("LOCATION") and not check_keyword?("AZIMUTH")
          case get_keyword_value("LOCATION")
          when /FLOOR-\s*V\s*(.*)/
            index = $1.strip.to_i - 1
            point0 = self.get_parent("FLOOR").polygon.point_list[index]
            point1 = self.get_parent("FLOOR").polygon.point_list[index + 1] ? get_parent("FLOOR").polygon.point_list[index + 1] : get_parent("FLOOR").polygon.point_list[0]
            edge = point1-point0


            sign = 1.0# OpenStudio::Vector3d.new(1.0, 0.0, 0.0).dot(( edge )) > 0 ? 1 :-1
            angle = OpenStudio::radToDeg( sign * OpenStudio::getAngle(OpenStudio::Vector3d.new(1.0, 0.0, 0.0), ( point1 - point0 ) ) )

            #since get angle only get acute angles we need to get sign and completment for reflex angle
            if edge.y > 0.0
              angle = -1.0 * angle 
            end

          when "FRONT"
            angle = OpenStudio::radToDeg( OpenStudio::getAngle(OpenStudio::Vector3d.new(0.0, 1.0, 0.0), ( get_parent("FLOOR").polygon.point_list[1] - get_parent("FLOOR").polygon.point_list[0] ) ) )
          when "RIGHT"
            angle = OpenStudio::radToDeg( OpenStudio::getAngle(OpenStudio::Vector3d.new(0.0, 1.0, 0.0), ( get_parent("FLOOR").polygon.point_list[2] - get_parent("FLOOR").polygon.point_list[1] ) ) )
          when "BACK"
            angle = OpenStudio::radToDeg( OpenStudio::getAngle(OpenStudio::Vector3d.new(0.0, 1.0, 0.0), ( get_parent("FLOOR").polygon.point_list[3] - get_parent("FLOOR").polygon.point_list[2] ) ) )
          when "LEFT"
            angle = OpenStudio::radToDeg( OpenStudio::getAngle(OpenStudio::Vector3d.new(0.0, 1.0, 0.0), ( get_parent("FLOOR").polygon.point_list[0] - get_parent("FLOOR").polygon.point_list[3] ) ) )
          end
        else
          angle =  self.check_keyword?("AZIMUTH")? self.get_keyword_value("AZIMUTH").to_f : 0.0
        end
        puts "#{self.commandName} #{self.get_name} azimuth is : #{angle}"
        return angle
      end


      def get_transformation_matrix()
        #This will transform the space vertices to normal space co-ordinates using Sketchup/OS convention
        return OpenStudio::createTranslation(self.get_origin) * OpenStudio::Transformation::rotation(OpenStudio::Vector3d.new(0.0, 0.0, 1.0), OpenStudio::degToRad(360.0 - self.get_azimuth()))
      end
      
      def get_rotation_matrix()
        return OpenStudio::Transformation::rotation(OpenStudio::Vector3d.new(0.0, 0.0, 1.0), OpenStudio::degToRad(360.0 - self.get_azimuth()))
      end

      def convert_to_openstudio(model)
        if self.get_keyword_value("SHAPE") == "NO-SHAPE"
          puts "OpenStudio does not support NO-SHAPE SPACE definitions currently. Not importing the space #{self.name}."
        else
          os_space = OpenStudio::Model::Space.new(model)
          os_space.setAttribute("name", self.name)
          #set floor
          os_space.setBuildingStory(OpenStudio::Model::getBuildingStoryByName(model,self.get_parent("FLOOR").name).get)
          puts "\tSpace: " + self.name + " created"
          puts "\t\t Azimuth:#{self.get_azimuth}"
          puts "\t\t Azimuth:#{self.get_origin}"
        end
      end

    end
    class DOE_Building_Parameter < DOECommand
      def initialize
        super()
      end
    end
    class DOEFloor < DOESurface
      attr_accessor :polygon
      # a string object which defines the type of roof (e.g. attic)
      attr_accessor :type
      # The absorptance of the exterior surface of the floor
      # (see rule #4.3.5.3.(6)
      attr_accessor :absorptance
      # thermal insulation of floors
      attr_accessor :thermal_insulation

      def initialize
        super()
      end

      #This method returns the floor area
      def get_area

        # get the keyword for the shape of the floor
        case get_keyword_value("SHAPE")

          # if the keyword value is "BOX", the width and depth values are defined
        when "BOX"
          return get_keyword_value("WIDTH").to_f * get_keyword_value("DEPTH").to_f

          # if the keyword value is "POLYGON", the get_area is defined as the area of the
          # given polygon
        when "POLYGON"
          return @polygon.get_area

          # if the keyword value of the floor is "No-SHAPE", the get_area is given as the
          # get_area keyword value
        when "NO-SHAPE"
          return get_keyword_value("AREA").to_f
        else
          raise "Error: The area could not be evaluated. Please check inputs\n "
        end
      end

      # This method returns the volume of the floor space
      def get_volume
        return get_floor_height.to_f * get_area.to_f
      end

      # gets the height of the floor
      def get_height
        return get_keyword_value("FLOOR-HEIGHT").to_f
      end

      # gets the space height
      def get_space_height
        return get_keyword_value("SPACE-HEIGHT").to_f
      end

      def get_origin()
        space_xref = self.check_keyword?("X")? self.get_keyword_value("X").to_f : 0.0
        space_yref = self.check_keyword?("Y")? self.get_keyword_value("Y").to_f : 0.0
        space_zref = self.check_keyword?("Z")? self.get_keyword_value("Z").to_f : 0.0
        return OpenStudio::Vector3d.new(space_xref,space_yref,space_zref)
      end

      def get_azimuth()
        return self.check_keyword?("AZIMUTH")? self.get_keyword_value("AZIMUTH").to_f : 0.0
      end

      def get_transformation_matrix()
        return OpenStudio::createTranslation(self.get_origin) * OpenStudio::Transformation::rotation(OpenStudio::Vector3d.new(0.0, 0.0, 1.0), OpenStudio::degToRad(360.0 - self.get_azimuth()))
      end
      
      def get_rotation_matrix()
        return OpenStudio::Transformation::rotation(OpenStudio::Vector3d.new(0.0, 0.0, 1.0), OpenStudio::degToRad(360.0 - self.get_azimuth()))
      end

      def convert_to_openstudio(model)
        floor = OpenStudio::Model::BuildingStory.new(model)
        floor.setAttribute("name", self.name)
        puts "\tBuildingStory: " + self.name + " created"
      end

    end
    #This class makes it easier to deal with DOE Polygons.
    class DOEPolygon < DOECommand

      attr_accessor :point_list

      #The constructor.
      def initialize
        super()
        @point_list = Array.new()
        #Convert Keywork Pairs to points.

      end

      def create_point_list()

        #Convert Keywork Pairs to points.
        @point_list.clear
        @keywordPairs.each do |array|

          array[1].match(/\(\s*(\-?\d*\.?\d*)\s*\,\s*(\-?\d*\.?\d*)\s*\)/)
          #puts array[1]

          point = OpenStudio::Point3d.new($1.to_f,$2.to_f,0.0)
          @point_list.push(point)
        end
        #      @point_list.each do |p|
        #        puts p.x.to_s + " " + p.y.to_s + " " + p.z.to_s + " "
        #      end
      end

      # This method returns the area of the polygon.
      def get_area
        openstudio::getArea(@points_list)
      end


      # This method must determine the length of the given point to the next point
      # in the polygon list. If the point is the last point, then it will be the
      # distance from the last point to the first.
      # point_name is the string named keyword in the keyword pair list.
      # Example:
      # "DOEPolygon 2" = POLYGON
      #   V1               = ( 0, 0 )
      #   V2               = ( 0, 1 )
      #   V3               = ( 2, 1 )
      #   V4               = ( 2 ,0 )
      # get_length(3) should return "2"
      # get_length(2) should return "1"

      def get_length(point_index)
        if @points_list.size < pointindex + 2
          return OpenStudio::getDistance(@point_list[0],@point_list.last)
        else
          return OpenStudio::getDistance(@point_list[point_index],@point_list[point_index + 1] )
        end
      end


      def get_azimuth(point_index)
        if @points_list.size < pointindex + 2
          return OpenStudio::radToDeg(OpenStudio::getAngle(@point_list.last - @point_list[0] , openstudio::Vector3d( 1.0, 0.0, 0.0)))
        else
          return OpenStudio::radToDeg(OpenStudio::getAngle(@point_list[point_index + 1] - @point_list[point_index] , openstudio::Vector3d( 1.0, 0.0, 0.0)))
        end
      end

    end
    class DOELayer < DOECommand
      # type of material (see rule #4.3.5.2.(3))
      attr_accessor :material
      # the thickness of the material (see rule #4.3.5.2.(3))
      attr_accessor :thickness
      def initialize
        super()
      end
    end
    class DOEMaterial < DOECommand
      # characteristics of the materials
      attr_accessor :density
      attr_accessor :specific_heat
      attr_accessor :thermal_conductivity
      def initialize
        super()
      end
    end
    class DOEConstruction < DOECommand

      def initialize
        super()
      end

      def get_materials()
        bdllib = DOE2::DOEBDLlib.instance
        materials = Array.new

        case self.get_keyword_value("TYPE")
        when "LAYERS"
          # finds the command associated with the layers keyword
          layers_command = building.find_command_with_utype( self.get_keyword_value("LAYERS") )

          #if Layres command cannot be found in the inp file... find it in the bdl database.
          layers_command = bdllib.find_layer(self.get_keyword_value("LAYERS")) unless layers_command.length == 1

          # if there ends up to be more than one command with the layers keyword
          # raise an exception
          raise "Layers was defined more than once " + self.get_keyword_value("LAYERS").to_s if layers_command.length > 1

          # get all the materials, separate it by the quotation marks and push it
          # onto the materials array
          layers_command[0].get_keyword_value("MATERIAL").scan(/(\".*?\")/).each do |material|
            material_command = ""

            #Try to find material in doe model.
            material_command_array = building.find_command_with_utype(material.to_s.strip)

            # if there ends up to be more than one, raise an exception
            raise "Material was defined more than once #{material}" if material_command_array.length > 1

            # if the material cannot be found within the model, find it within the doe2 database
            material_command = bdllib.find_material(material) if material_command_array.length < 1

            #If material was found then set it.
            material_command = material_command_array[0] if material_command_array.length == 1

            materials.push(material_command)
          end
          return materials
        when "U-VALUE"
          return nil
        end
      end

      # This method finds the u-value of the given construction
      # Output => total conductivity as a float
      def get_u_value()
        total_conductivity = 0.0
        case self.get_keyword_value("TYPE")
        when "LAYERS"
          self.get_materials().each do |material_command|
            case material_command.get_keyword_value("TYPE")
            when  "RESISTANCE"
              conductivity = 1 / material_command.get_keyword_value("RESISTANCE").to_f
            when "PROPERTIES"
              conductivity = material_command.get_keyword_value("CONDUCTIVITY").to_f
            else
              raise "Error in material properties"
            end
            total_conductivity = total_conductivity + conductivity
          end
          return total_conductivity
        when "U-VALUE"
          return self.get_keyword_value("U-VALUE").to_f
        end
      end


    end
    class DOECommandFactory
      def initialize

      end

      def DOECommandFactory.command_factory(command_string, building)
        
        command = ""
        command_name = ""
        if (command_string != "")
          #Get command and u-value
          if ( command_string.match(/(^\s*(\".*?\")\s*\=\s*(\S+)\s*)/) )
            command_name=$3.strip
          else
            # if no u-value, get just the command.
            command_string.match(/(^\s*(\S*)\s)/ )
            @command_name=$2.strip
            
          end
        end
        case command_name
        when  "SYSTEM" then
          command = DOESystem.new()
        when  "ZONE" then
          command = DOEZone.new()
        when  "FLOOR" then
          command = DOEFloor.new()
        when  "SPACE" then
          command = DOESpace.new()
        when  "EXTERIOR-WALL" then
          command = DOEExteriorWall.new()
        when  "INTERIOR-WALL" then
          command = DOEInteriorWall.new()
        when  "UNDERGROUND-WALL" then
          command = DOEUndergroundWall.new()
        when  "ROOF" then
          command = DOERoof.new()
        when "WINDOW" then
          command = DOEWindow.new()
        when "DOOR" then
          command = DOEDoor.new()
        when "POLYGON" then
          command = DOEPolygon.new()
        when "LAYER" then
          command = DOELayer.new()
        when "MATERIAL" then
          command = DOEMaterial.new()
        when "CONSTRUCTION" then
          command = DOEConstruction.new()

        else
          command = DOECommand.new()
        end
        
        command.get_command_from_string(command_string)
        command.building = building
        return command
      end
    end
    
    # This is the main interface dealing with DOE inp files. You can load, save
    # manipulate doe files with this interface at a command level. 
    class DOEBuilding

      #An array to contain all the DOE
      attr_accessor  :commands
      #An array to contain the current parent when reading in the input files.
      attr_accessor  :parents


      # This method makes a deep copy of the building object.
      def deep_clone
        Marshal::load(Marshal.dump(self))
      end

      # The Constructor.
      def initialize

        @commands=[]
        @parents=[]
        @commandList = Array.new()

      end

      # This method will find all Commands given the command name string.
      # Example
      # def find_all_Command("ZONE")  will return an array of all the ZONE commands
      # used in the building.
      def find_all_commands (sCOMMAND)
        array = Array.new()
        @commands.each do |command|
          if (command.commandName == sCOMMAND)
            array.push(command)
          end
        end
        return array
      end

      # This method will find all Commands given the command name string.
      # Example
      # def find_all_Command("Default Construction")  will return an array of all
      # the commands with "Default Construction" as the u-type used in the building.
      def find_command_with_utype (utype)
        array = Array.new()
        @commands.each do |command|
          if (command.utype == utype)
            array.push(command)
          end
        end
        return array
      end


      # Same as find_all_commands except you can use regular expressions.
      def find_all_regex(sCOMMAND)
        array = Array.new()
        search =/#{sCOMMAND}/
        @commands.each do |command|
          if (command.commandName.match(search) )
            array.push(command)
          end

        end
        return array
      end

      # Find a matching keyword value pair in from an array of commands.
      # Example:
      # find_keyword_value(building.commands, "TYPE", "CONDITIONED")  will return
      # all the commands that have the
      # TYPE = CONDITIONED"
      # Keyword pair.
      def find_keyword_value(arrayOfCommands, keyword, value)
        returnarray = Array.new()
        arrayOfCommands.each do |command|
          if ( command.keywordPairs[keyword] == value )
            returnarray.push(command)
          end
        end
        return returnarray
      end

      # Find the surface get_area of a wall, roof, space or zone..
      # Example if the command is a zone, roof or surface it will return the get_area.
      # If it is anything else, it will throw an exception.
      def find_area_of(command)
        #only if needed...About 1 days work for window, wall and space/zone.
      end

      # Will read an input file into memory and store all the commands into the
      # @commands array.
      def load_inp(filename)
        puts "loading file:" + filename
        #Open the file.
        #puts filename
        iter = 0


        File.exist?(filename)
        f = File.open(filename, "r")




        #Read the file into an array, line by line.
        lines = f.readlines
        #Set up the temp string.
        command_string =""
        #iterate through the file.
        parents = Array.new()
        children = Array.new()
        lines.each do|line|
          iter = iter.next
          #line.forced_encoding("US-ASCII")
          #Ignore comments (To do!...strip from file as well as in-line comments.
          if (!line.match(/\$.*/) )
            
            if (myarray = line.match(/(.*?)\.\./) )
              #Add the last part of the command to the newline...may be blank."
              command_string = command_string + myarray[1]
              #Determine correct command class to create, then populates it."
              command = DOECommandFactory.command_factory(command_string, self)
              #Push the command into the command array."
              @commands.push(command)
              command_string = ""
            else
              myarray = line.match(/(.*)/)
              command_string = command_string + myarray[1]
            end
          end
        end
        puts "Finished Loading File:" + filename
        organize_data()
      end

      def set_envelope_hierarchy()
        puts "Setting Geometry Hierarchy"
        @commands.each do |command|
          if command.doe_scope() == "envelope"
            #Sets parents of command.
            parents = determine_current_parents(command)
            if (!parents.empty?)
              command.parents = parents
            end
            #inserts current command into the parent's children.
            if (!command.parents.empty?)
              command.parents.last.children.push(command)
            end
          end
        end
        puts "Finished Setting Geometry Hierarchy"
      end

      def find_matching_command(searchCommand)
        @commands.each do |command|
          #Determine if it is the same command type and name.
          if ( (command.utype == searchCommand.utype) and ( command.commandName == searchCommand.commandName ) )
            puts "Found matching command and utype"
            #determine if all the keywords match.
            puts "Determine if all the keyword pairs match."
            found = 0
            searchCommand.keywordPairs.each { |searchPair|
              puts "Searching For...." + searchPair.to_s

              puts "iterate through keyword pairs."
              command.keywordPairs.each{ |pair|
                # puts "Current "
                # puts pair.to_s

                if ( (searchPair[0] == pair[0] ) and (searchPair[1] == pair[1]) )
                  found = found + 1
                  puts pair.to_s + " found!"
                  break
                end
              }
            }
            puts searchCommand.keywordPairs.length.to_s + " " + found.to_s
            if (searchCommand.keywordPairs.length != found)
              puts "Did not find matching Command: \n\t" + searchCommand.utype.to_s() + " = " + searchCommand.commandName.to_s
              # Commented out for causing a crash
              #  puts "With Keyword-pair:\n\t " + searchPair[0].to_s + " = " + searchPair[1].to_s + "\n"
              return false
            else
              return true
            end

          end
        end
        return false
      end





      # This will right a clean output file, meaning no comments. Good for doing
      # diffs
      def save_inp(string)
        array = @commands
        w = File.open(string, 'w')
        array.each { |command| w.print command.output }
        w.close
      end

      #Helper method to print banner comments in eQuest style.
      def header(string)
        outstring ="$ ---------------------------------------------------------\n$              #{string}\n$ ---------------------------------------------------------\n"
        return outstring
      end

      #Helper method to print big banner comments in eQuest style.
      def big_header(string)
        outstring = "$ *********************************************************\n$ **                                                     **\n$ **            #{string}             \n$ **                                                     **\n$ *********************************************************\n"
        return outstring
      end

      # This method determines the current parents of the current command. ONLY TO
      # BE USED BY READINPUTFILE method!
      def determine_current_parents(new_command)
        if (@last_command == nil)
          @last_command = new_command
        end
        #Check to see if scope (HVAC versus Envelope) has changed or the parent depth is undefined "0"
        if (!@parents.empty? and (new_command.doe_scope != @parents.last.doe_scope or new_command.depth == 0 ))
          @parents.clear
          #puts "Change of scope or no parent"
          #@last_command = new_command
          #return
        end
        #no change in parent.
        if ( (new_command.depth  == @last_command.depth))
          #no change
          @last_command = new_command
          #puts "#{new_command.commandName}"
        end
        #Parent depth added
        if ( new_command.depth  > @last_command.depth)
          @parents.push(@last_command)
          #puts "Added parent#{@last_command.commandName}"
          @last_command = new_command
        end
        #parent depth removed.
        if ( new_command.depth  < @last_command.depth)
          parent = @parents.pop
          #puts "Removed parent #{parent}"
          @last_command = new_command
        end
        array = Array.new(@parents)
        return array
      end


      #This routine organizes the hierarchy of the space <-> zones and the polygon
      # associations that are not formally identified by the sequential relationship
      # like the floor, walls, windows. It would seem that zones and spaces are 1 to
      # one relationships.  So each zone will have a reference to its space and vice versa.
      # If there is a polygon command in the space or floor definition, a reference to the
      # polygon class will be set.
      def organize_data()
        set_envelope_hierarchy()
        # Associating the polygons with the FLoor and spaces.
        polygons =  find_all_commands("POLYGON")
        spaces = find_all_commands("SPACE")
        floors = find_all_commands("FLOOR")
        zones = find_all_commands("ZONE")
        ext_walls = find_all_commands("EXTERIOR-WALL")
        roof = find_all_commands("ROOF")
        door = find_all_commands("DOOR")
        int_walls = find_all_commands("INTERIOR-WALL")
        underground_walls = find_all_commands("UNDERGROUND-WALL")
        underground_floors = find_all_commands("UNDERGROUND-FLOOR")
        constructions =find_all_commands("CONSTRUCTION")
        surface_lists = [ ext_walls, roof, door, int_walls, underground_walls, underground_floors]


        #Organize surface data.
        surface_lists.each do |surfaces|
          surfaces.each do |surface|
            #Assign constructions to surface objects
            constructions.each do |construction|
              if ( construction.utype == surface.get_keyword_value("CONSTRUCTION") )
                surface.construction = construction
              end
            end
            #Find Polygons associated with surface.
            polygons.each do |polygon|
              if ( surface.check_keyword?("POLYGON") and polygon.utype == surface.get_keyword_value("POLYGON")  )
                surface.polygon = polygon
              end
            end
          end
        end



        #Organize polygon data for space and floors.
        polygons.each do |polygon|
          #set up point list in polygon objects
          polygon.create_point_list()
          #Find Polygons associated with  floor and and reference to floor.
          floors.each do |floor|
            if ( polygon.utype == floor.get_keyword_value("POLYGON") )
              floor.polygon = polygon
            end
          end
          #Find Polygons for space and add reference to the space.
          spaces.each do |space|
            if space.check_keyword?("POLYGON")
              if ( polygon.utype == space.get_keyword_value("POLYGON") )
                space.polygon = polygon
              end
            end
          end
        end



        #    Find spaces that belong to the zone.
        zones.each do |zone|
          spaces.each do |space|
            if ( space.utype ==  zone.get_keyword_value("SPACE") )
              space.zone = zone
              zone.space = space
            end
          end
        end
      end

      #MNECB Commands Using MNECB terminology.

      def get_all_thermal_blocks()
        zones = find_all_commands("ZONE")
      end

      def get_building_transformation_matrix()
        build_params = self.find_all_commands("BUILD-PARAMETERS")[0]
        building_xref = build_params.check_keyword?("X-REF")? build_params.get_keyword?("X-REF") : 0.0
        building_yref = build_params.check_keyword?("Y-REF")? build_params.get_keyword?("Y-REF") : 0.0
        building_origin = OpenStudio::Vector3d.new(building_xref,building_yref,0.0)
        building_azimuth = build_params.check_keyword?("AZIMUTH")? build_params.get_keyword?("AZIMUTH") : 0.0
        return  OpenStudio::Transformation::rotation(OpenStudio::Vector3d(0.0, 0.0, 1.0), openstudio::degToRad(building_azimuth)) * OpenStudio::Transformation::translation(building_origin)
      end

      def get_all_surfaces()

        array = Array.new()
        @commands.each do |command|
          if (command.commandName == "EXTERIOR-WALL" or
                command.commandName == "INTERIOR-WALL" or
                command.commandName == "UNDERGROUND-WALL" or
                command.commandName == "ROOF")
            array.push(command)
          end
        end
        return array
      end

      def get_all_subsurfaces()

        array = Array.new()
        @commands.each do |command|
          if (command.commandName == "WINDOW" or
                command.commandName == "DOOR")
            array.push(command)
          end
        end
        return array
      end


      #this method will convert a DOE inp file to the OSM file.. This will return
      # and openstudio model object. 
      def create_openstudio_model_new()
        beginning_time = Time.now

        end_time = Time.now
        puts "Time elapsed #{(end_time - beginning_time)*1000} milliseconds"
        model = OpenStudio::Model::Model.new()
        #add All Materials
        #    find_all_commands( "Materials" ).each do |doe_material|
        #    end
        #
        #    find_all_commands( "Constructions" ).each do |doe_cons|
        #    end

        #this block will create OS story objects in the OS model. 
        puts "Exporting DOE FLOORS to OS"
        find_all_commands("FLOOR").each do |doe_floor|
          doe_floor.convert_to_openstudio(model)
        end
        puts OpenStudio::Model::getBuildingStorys(model).size.to_s + " floors created"

        #this block will create OS space objects in the OS model. 
        puts "Exporting DOE SPACES to OS"
        find_all_commands("SPACE").each do |doe_space|
          doe_space.convert_to_openstudio(model)
        end
        puts OpenStudio::Model::getSpaces(model).size.to_s + " spaces created"
        
        #this block will create OS space objects in the OS model. 
        puts "Exporting DOE ZONES to OS"
        find_all_commands("ZONE").each do |doe_zone|
          doe_zone.convert_to_openstudio(model)
        end
        puts OpenStudio::Model::getThermalZones(model).size.to_s + " zones created"
        
        #this block will create OS surface objects in the OS model.
        puts "Exporting DOE Surfaces to OS"
        get_all_surfaces().each do |doe_surface|
          doe_surface.convert_to_openstudio(model)
        end
        puts OpenStudio::Model::getSurfaces(model).size.to_s + " surfaces created"

        #this block will create OS surface objects in the OS model.
        puts "Exporting DOE SubSurfaces to OS"
        get_all_subsurfaces().each do |doe_subsurface|
          doe_subsurface.convert_to_openstudio(model)
        end
        puts OpenStudio::Model::getSubSurfaces(model).size.to_s + " sub_surfaces created"

        puts "Setting Boundary Conditions for surfaces"
        BTAP::Geometry::match_surfaces(model)
        
        x_scale = y_scale = z_scale = 0.3048
        
        puts "scaling model from feet to meters"
        model.getPlanarSurfaces.each do |surface|
          new_vertices = OpenStudio::Point3dVector.new
          surface.vertices.each do |vertex|
            new_vertices << OpenStudio::Point3d.new(vertex.x * x_scale, vertex.y * y_scale, vertex.z * z_scale)
          end    
          surface.setVertices(new_vertices)
        end
 
        model.getPlanarSurfaceGroups.each do |surface_group|
          transformation = surface_group.transformation
          translation = transformation.translation
          euler_angles = transformation.eulerAngles
          new_translation = OpenStudio::Vector3d.new(translation.x * x_scale, translation.y * y_scale, translation.z * z_scale)
          #TODO these might be in the wrong order
          new_transformation = OpenStudio::createRotation(euler_angles) * OpenStudio::createTranslation(new_translation) 
          surface_group.setTransformation(new_transformation)
        end
        
        puts "DOE2.2 -> OS Geometry Conversion Complete"

        puts "Summary of Conversion"
        puts OpenStudio::Model::getBuildingStorys(model).size.to_s + " floors created"
        puts OpenStudio::Model::getSpaces(model).size.to_s + " spaces created"
        puts OpenStudio::Model::getThermalZones(model).size.to_s + " thermal zones created"
        puts OpenStudio::Model::getSurfaces(model).size.to_s + " surfaces created"
        puts OpenStudio::Model::getSubSurfaces(model).size.to_s + " sub_surfaces created"
        puts "No Contruction were converted."
        puts "No Materials were converted"
        puts "No HVAC components were converted"
        puts "No Environment or Simulation setting were converted."

        end_time = Time.now
        puts "Time elapsed #{(end_time - beginning_time)} seconds"
        return model
      end





      def get_materials()
        puts "Spaces"
        find_all_commands("SPACE").each do |space|

          puts space.get_azimuth()
        end
        puts "Materials"
        find_all_commands("MATERIAL").each do |materials|
          puts materials.get_name()
        end

        puts "Layers"
        find_all_commands("LAYERS").each do |materials|
          puts materials.get_name()
        end

        puts "Constructions"
        find_all_commands("CONSTRUCTION").each do |materials|
          puts materials.get_name()
        end

      end


    end
    # This class will manage all the layer information of the Reference components.
    class LayerManager
      include Singleton
      class Layer

        attr_accessor :name
        attr_accessor :thickness
        attr_accessor :conductivity
        attr_accessor :density
        attr_accessor :specific_heat
        attr_accessor :air_space
        attr_accessor :resistance
        def initialize
          @air_space = false
        end

        def set( thickness, conductivity, density, specific_heat)
          @thickness, @conductivity, @density, @specific_heat =  thickness, conductivity, density, specific_heat
          @airspace = false
        end

        def set_air_space(thickness, resistance)
          @thickness, @resistance = thickness, resistance
          @air_space = true
        end

        def output
          string = "Airspace = #{@air_space}\nThickness = #{@thickness}\nConductivity = #{@conductivity}\nResistance = #{@resistance}\nDensity = #{@density}\nSpecificHeat = #{@specific_heat}\n"
        end
      end
      # Array of all the layers
      attr_accessor :layers
      def initialize
        @layers = Array.new()
      end

      #Add a layer. If the layer already exists. It will return the exi
      def add_layer(new_layer)
        #first determine if the layer already exists.
        @layers.each do  |current_layer|
          if new_layer == current_layer
            return current_layer
          end
        end
        @layers.push(new_layer)
        return @layers.last()
      end

      private

      def clear()
        @layers.clear()
      end
    end
    #This class manages all of the constructions that are used in the simulation. It
    #should remove any constructions that are doubly defined in the project.
    class ConstructionManager
      # An array containing all the constructions.
      attr_accessor :constructions

      # The layer manager all the constructions.
      attr_accessor :layer_manager
      class Construction

        #The unique name for the construction.
        attr_accessor :name
        #The array which contains the material layers of the construction.
        attr_accessor :layers

        def initialize
          #Set up the array for the layers.
          @layers = Array.new()
        end

        #Adds a layer object to the construction.
        # Must pass a Layer object as an arg.
        def add_layer_object( object )
          layers.push( object )
        end

        #Adds a layer based on the physical properties list.
        #All units are based on the simulators input.
        def add_layer(thickness, conductivity, density, specific_heat)
          layer = Layer.new()
          # Make sure all the values are > 0.
          layer.set(thickness, conductivity, density, specific_heat)
          @layers.push(layer)
        end

        # Adds an airspace to the construction based on the thickness and Resistances.
        #All units are based on the simulators input.
        def add_air_space(thickness, resistance )
          layer = Layer.new()
          layer.set_air_space(thickness, resistance)
          @layers.push(layer)
        end

        def output()
          soutput = ""
          @layers.each do|layer|
            soutput = soutput + layer.output() + "\n"
          end
          soutput
        end
      end


      def initialize
        @constructions = Array.new()
        @layer_manager = LayerManager.instance()
      end


      #Adds a new construction to the construction array.
      #Arg must be a construction object.
      def add_construction(new_construction)
        #first determine if the layer already exists.
        @constructions.each do  |current_construction|
          if new_construction == current_construction
            return current_construction
          end
        end
        new_construction.layers.each do |new_layer|
          #If the new layer already exists...use the old one instead.
          # it is the layerManager's job to decide this.
          new_layer = @layer_manager.add_layer(new_layer)
        end
        @constructions.push(new_construction)
        return @constructions.last()
      end

      def clear()
        @constructions.clear()
        @layer_manager.clear()
      end

    end
  end
end



# start the measure
class BtapEquestConverter < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "btap equest converter"
  end

  # human readable description
  def description
    return "This measure will take an eQuest *.inp file and attempt to convert the geomtry into openstudio.  This will save the file directly to a new file. It will NOT modify your existing file in the model editory.  Once the file is saved, you may open the new osm file.  INP file argument is the location of the INP file. It will create an OSM file with the same name in the same folder."
  end

  # human readable description of modeling approach
  def modeler_description
    return "This measure will read a DOE 2.2 *.inp file and attempt to convert the geometry to OS geometry (Surfaces, Zones, Floors). It does just geometry at the moment.  If there is interest, perhaps schedules and other items could be added to the converter.."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # the name of the space to add to the model
    #inp_file = OpenStudio::Ruleset::OSArgument::makePathArgument("INPModelPath",true,"osm")
    inp_file = OpenStudio::Ruleset::OSArgument.makeStringArgument("inp_file", true)
    inp_file.setDisplayName("inp_file")
    inp_file.setDescription("Full path of DOE 2.2 inp file. USE FORWARD SLASH ONLY IN PATH")
    args << inp_file

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    inp_file = runner.getStringArgumentValue("inp_file", user_arguments)

    # check the space_name for reasonableness
    if inp_file.empty?
      runner.registerError("Empty inp file path was entered was entered.")
      return false
    end

    # report initial condition of model
    runner.registerInitialCondition("Reading #{inp_file} for import.")

    #validate inp file path. 

    unless File.exist?(inp_file) 
      runner.registerError("File does not exist: #{inp_file}") 
      return false
    end


    runner.registerInfo("loading equest inp file #{inp_file}. This will only convert geometry.")
    #Create an instances of a DOE model
    doe_model = BTAP::EQuest::DOEBuilding.new()
    #Load the inp data into the DOE model.
    doe_model.load_inp(inp_file)

    #Convert the model to a OSM format.
    newModel = doe_model.create_openstudio_model_new()
    

    # pull original weather file object over
    weatherFile = newModel.getOptionalWeatherFile
    if not weatherFile.empty?
      weatherFile.get.remove
      runner.registerInfo("Removed alternate model's weather file object.")
    end
    originalWeatherFile = model.getOptionalWeatherFile
    if not originalWeatherFile.empty?
      originalWeatherFile.get.clone(newModel)
    end

    # pull original design days over
    newModel.getDesignDays.each { |designDay|
      designDay.remove
    }
    model.getDesignDays.each { |designDay|
      designDay.clone(newModel)
    }

    # remove existing objects from model
    handles = OpenStudio::UUIDVector.new
    model.objects.each do |obj|
      handles << obj.handle
    end
    model.removeObjects(handles)
    # add new file to empty model
    model.addObjects( newModel.toIdfFile.objects )

    #do some built in tests


    # check that number of thermal zones, surfaces or subsurfaces are the same in the inp and osm files. 
    doe_spaces = doe_model.find_all_commands("SPACE")
    osm_spaces = model.getSpaces
    runner.registerInfo("#{doe_spaces.size} spaces detected in inp file and #{osm_spaces.size} spaces created in osm.")
    if  doe_spaces.size != osm_spaces.size
      runner.registerWarning("INP and OSM number of spaces do not match. There may be errors in the import. \n Generating report...") 
      #find zones that were not imported and report them to user. 
      doe_spaces.each do |space|
        #Check to see if we already made one like this. If not throw a warning. 
        osm_space = OpenStudio::Model::getSpaceByName(model,space.name)
        if osm_space.empty?
          runner.registerWarning ("Zone #{space.name} was not created.")
        end
      end
    end
    
    
    
    # check that number of thermal zones, surfaces or subsurfaces are the same in the inp and osm files. 
    doe_zones = doe_model.find_all_commands("ZONE")
    osm_zones = model.getThermalZones
    runner.registerInfo ("#{doe_zones.size} zones detected in inp file and #{osm_zones.size} thermalzone created in osm.")
    if  doe_zones.size != osm_zones.size
      runner.registerWarning ("INP and OSM zone numbers do not match. There may be errors in the import. \n Generating report...") unless doe_zones.size
      #find zones that were not imported and report them to user. 
      doe_zones.each do |zone|
        #Check to see if we already made one like this. If not throw a warning. 
        thermal_zone = OpenStudio::Model::getThermalZoneByName(model,zone.name)
        if thermal_zone.empty?
          runner.registerWarning ("Zone #{zone.name} was not created.")
        end
      end
    end
    
    # number of all surfaces
    doe_surfaces = []
    doe_surfaces.concat( doe_model.find_all_commands("EXTERIOR-WALL") ) 
    doe_surfaces.concat( doe_model.find_all_commands("INTERIOR-WALL") )
    doe_surfaces.concat( doe_model.find_all_commands("UNDERGROUND-WALL") )
    doe_surfaces.concat( doe_model.find_all_commands("ROOF") )
    osm_number_of_mirror_surfaces = 0  
    model.getSurfaces.each do|surface| 
      if surface.name.to_s.include?("mirror") 
        osm_number_of_mirror_surfaces = osm_number_of_mirror_surfaces + 1
      end
    end
    osm_surfaces = model.getSurfaces
    runner.registerInfo ("#{doe_surfaces.size} EXTERIOR-WALL,INTERIOR-WALL, UNDERGROUND_WALL, and ROOF surfaces detected in inp file and #{osm_surfaces.size} Surfaces created in osm and #{osm_number_of_mirror_surfaces} are mirror surfaces.")
    #test if all surfaces were translated
    if doe_surfaces.size != ( osm_surfaces.size - osm_number_of_mirror_surfaces)
      runner.registerWarning ("INP and OSM surface numbers do not match. There may be errors in the import. Generating Report..") 
      #find items that were not imported and report them to user. 
      doe_surfaces.each do |surface|
        #Check to see if we already made one like this. If not throw a warning. 
        osm_surface = OpenStudio::Model::getSurfaceByName(model,surface.name)
        if osm_surface.empty?
          runner.registerWarning("Surface #{surface.name} was not created.")
        end
      end
    end
    
    #check subsurfaces
    #Get doe subsurfaces
    doe_subsurfaces = []
    doe_subsurfaces.concat( doe_model.find_all_commands("WINDOW") ) 
    doe_subsurfaces.concat( doe_model.find_all_commands("DOOR") )
    #get OS subsurfaces
    osm_subsurfaces = model.getSubSurfaces
    #inform user. 
    runner.registerInfo("#{doe_subsurfaces.size} WINDOW, and DOOR subsurfaces detected in inp file and #{osm_subsurfaces.size} SubSurfaces created in osm.")
    #Check to see if all items were imported. 
    if doe_subsurfaces.size != osm_subsurfaces.size
      runner.registerWarning("INP and OSM sub surface numbers do not match. There may be errors in the import. Generating Report")
      #find items that were not imported and report them to user. 
      doe_subsurfaces.each do |subsurface|
        #Check to see if we already made one like this. If not throw a warning. 
        osm_subsurface = OpenStudio::Model::getSubSurfaceByName(model,subsurface.name)
        if osm_subsurface.empty?
          runner.registerWarning("SubSurface #{subsurface.name} was not created.")
        end
      end
    end
    runner.registerInfo("No Construction , Materials, Schedules or HVAC were converted. These are not supported yet.")
    
    #****Performing geometry validation measure as taken from https://github.com/NREL/OpenStudio/blob/develop/openstudiocore/ruby/openstudio/sketchup_plugin/user_scripts/Reports/OSM_Diagnostic_Script.rb
    #**** on July 21st, 2015. 
    puts "Model has " + model.numObjects.to_s + " objects"

    # number of thermal zones
    thermal_zones = model.getThermalZones
    puts "Model has " + thermal_zones.size.to_s + " thermal zones"

    # number of spaces
    spaces = model.getSpaces
    puts "Model has " + spaces.size.to_s + " spaces"

    # number of surfaces
    surfaces = model.getPlanarSurfaces
    # puts "Model has " + surfaces.size.to_s + " planar surfaces"

    # number of base surfaces
    base_surfaces = model.getSurfaces
    puts "Model has " + base_surfaces.size.to_s + " base surfaces"

    # number of base surfaces
    sub_surfaces = model.getSubSurfaces
    puts "Model has " + sub_surfaces.size.to_s + " sub surfaces"

    # number of surfaces
    shading_surfaces = model.getShadingSurfaces
    puts "Model has " + shading_surfaces.size.to_s + " shading surfaces"

    # number of surfaces
    partition_surfaces = model.getInteriorPartitionSurfaces
    puts "Model has " + partition_surfaces.size.to_s + " interior partition surfaces"
    

    savediagnostic = false # this will change to true later in script if necessary

    puts ""
    puts "Removing catchall objects (objects unknown to your version of OpenStudio)"
    switch = 0
    model.getObjectsByType("Catchall".to_IddObjectType).each do |obj|
      puts "*(error) '" + obj.name.to_s + "' object type is unkown to OpenStudio"
      switch = 1
      if remove_errors
        puts "**(removing object)  '#{obj.name.to_s}'"
        remove = obj.remove
        savediagnostic = true
      end
    end
    if switch == 0 then puts "none" end

    puts ""
    puts "Removing objects that fail draft validity test"
    switch = 0
    model.objects.each do |object|
      if !object.isValid("Draft".to_StrictnessLevel)
        report = object.validityReport("Draft".to_StrictnessLevel)
        puts "*(error)" + report.to_s
        switch = 1
        if remove_errors
          puts "**(removing object)  '#{object.name}'"
          remove = object.remove
          savediagnostic = true
        end
      end
    end
    if switch == 0 then puts "none" end

    base_surfaces = model.getSurfaces
    # Find base surfaces with less than three vertices
    puts ""
    puts "Surfaces with less than three vertices"
    switch = 0
    base_surfaces.each do |base_surface|
      vertices = base_surface.vertices
      if vertices.size < 3
        puts "*(warning) '" + base_surface.name.to_s + "' has less than three vertices"
        switch = 1
        if remove_errors
          puts "**(removing object) '#{base_surface.name.to_s}'"
          # remove surfaces with less than three vertices
          remove = base_surface.remove
          savediagnostic = true
        end
      end
    end
    if switch == 0 then puts "none" end

    sub_surfaces = model.getSubSurfaces
    # Find base sub-surfaces with less than three vertices
    puts ""
    puts "Surfaces with less than three vertices"
    switch = 0
    sub_surfaces.each do |sub_surface|
      vertices = sub_surface.vertices
      if vertices.size < 3
        puts "*(warning) '" + sub_surface.name.to_s + "' has less than three vertices"
        switch = 1
        if remove_errors
          puts "**(removing object) '#{sub_surface.name.to_s}'"
          # remove sub-surfaces with less than three vertices
          remove = sub_surface.remove
          savediagnostic = true
        end
      end
    end
    if switch == 0 then puts "none" end

    surfaces = model.getSurfaces
    # Find surfaces with greater than 25 vertices (split out sub-surfaces and test if they hvae more than 4 vertices)
    puts ""
    puts "Surfaces with more than 25 vertices"
    switch = 0
    surfaces.each do |surface|
      vertexcount = surface.vertices.size
      if vertexcount > 25
        puts "*(info) '" + surface.name.to_s + "' has " + vertexcount.to_s + " vertices"
        switch = 1
      end
    end
    if switch == 0 then puts "none" end

    base_surfaces = model.getSurfaces
    # Find base surfaces with area < 0.1
    puts ""
    puts "Surfaces with area less than 0.1 m^2"
    switch = 0
    base_surfaces.each do |base_surface|
      grossarea = base_surface.grossArea
      if grossarea < 0.1
        puts "*(warning) '" + base_surface.name.to_s + "' has area of " + grossarea.to_s + " m^2"
        switch = 1
        if remove_warnings
          puts "**(removing object) '#{base_surface.name.to_s}'"
          # remove base surfaces with less than 0.1 m^2
          remove = base_surface.remove
          savediagnostic = true
        end
      end
    end
    if switch == 0 then puts "none" end

    sub_surfaces = model.getSubSurfaces
    # Find sub-surfaces with area < 0.1
    puts ""
    puts "Surfaces with area less than 0.1 m^2"
    switch = 0
    sub_surfaces.each do |sub_surface|
      grossarea = sub_surface.grossArea
      if grossarea < 0.1
        puts "*(warning) '" + sub_surface.name.to_s + "' has area of " + grossarea.to_s + " m^2"
        switch = 1
        if remove_warnings
          puts "**(removing object) '#{sub_surface.name.to_s}'"
          # remove sub-surfaces with less than three vertices
          remove = sub_surface.remove
          savediagnostic = true
        end
      end
    end
    if switch == 0 then puts "none" end

    # Find surfaces within surface groups that share same vertices
    puts ""
    puts "Surfaces and SubSurfaces which have similar geometry within same surface group"
    switch = 0
    planar_surface_groups = model.getPlanarSurfaceGroups
    planar_surface_groups.each do |planar_surface_group|

      planar_surfaces = []
      planar_surface_group.children.each do |child|
        planar_surface = child.to_PlanarSurface
        next if planar_surface.empty?
        planar_surfaces << planar_surface.get
      end

      n = planar_surfaces.size

      sub_surfaces = []
      (0...n).each do |k|
        planar_surfaces[k].children.each do |l|
          sub_surface = l.to_SubSurface
          next if sub_surface.empty?
          sub_surfaces << sub_surface.get
        end
      end

      all_surfaces = []
      sub_surfaces.each do |m|  # subsurfaces first so they get removed vs. base surface
        all_surfaces << m
      end
      planar_surfaces.each do |n|
        all_surfaces << n
      end

      n2 = all_surfaces.size # updated with sub-surfaces added at the beginning
      surfaces_to_remove = Hash.new
      (0...n2).each do |i|
        (i+1...n2).each do |j|

          p1 = all_surfaces[i]
          p2 = all_surfaces[j]
       
          if p1.equalVertices(p2) or p1.reverseEqualVertices(p2)
            switch = 1
            puts "*(error) '#{p1.name.to_s}' has similar geometry to '#{p2.name.to_s}' in the surface group named '#{planar_surface_group.name.to_s}'"
            if remove_errors
              puts "**(removing object) '#{p1.name.to_s}'" # remove p1 vs. p2 to avoid failure if three or more similar surfaces in a group
              # don't remove here, just mark to remove
              surfaces_to_remove[p1.handle.to_s] = p1
              savediagnostic = true
            end
          end
        end
      end
      surfaces_to_remove.each_pair {|handle, surface| surface.remove}

    end
    if switch == 0 then puts "none" end
  
    # Find duplicate vertices within surface
    puts ""
    puts "Surfaces and SubSurfaces which have duplicate vertices"
    switch = 0
    planar_surface_groups = model.getPlanarSurfaceGroups
    planar_surface_groups.each do |planar_surface_group|

      planar_surfaces = []
      planar_surface_group.children.each do |child|
        planar_surface = child.to_PlanarSurface
        next if planar_surface.empty?
        planar_surfaces << planar_surface.get
      end

      n = planar_surfaces.size

      sub_surfaces = []
      (0...n).each do |k|
        planar_surfaces[k].children.each do |l|
          sub_surface = l.to_SubSurface
          next if sub_surface.empty?
          sub_surfaces << sub_surface.get
        end
      end

      all_surfaces = []
      sub_surfaces.each do |m|  # subsurfaces first so they get removed vs. base surface
        all_surfaces << m
      end
      planar_surfaces.each do |n|
        all_surfaces << n
      end

      all_surfaces.each do |surface|
        # make array of vertices
        vertices = surface.vertices
    
        # loop through looking for duplicates
        n2 = vertices.size
        switch2 = 0

        (0...n2).each do |i|
          (i+1...n2).each do |j|

            p1 = vertices[i]
            p2 = vertices[j]
       
            # set flag if surface needs be removed
            
            if p1.x == p2.x and p1.y == p2.y and p1.z == p2.z
              switch2 = 1
            end

          end
        end
    
        if switch2 == 1
          switch == 1
          puts "*(error) '#{surface.name.to_s}' has duplicate vertices"
          if remove_errors
            puts "**(removing object) '#{surface.name.to_s}'" # remove p1 vs. p2 to avoid failure if three or more similar surfaces in a group
            remove = surface.remove
            savediagnostic = true
          end
        end
    
      end

    end
    if switch == 0 then puts "none" end
    
    # find and remove orphan sizing:zone objects
    puts ""
    puts "Removing sizing:zone objects that are not connected to any thermal zone"
    #get all sizing:zone objects in the model
    sizing_zones = model.getObjectsByType("OS:Sizing:Zone".to_IddObjectType)
    #make an array to store the names of the orphan sizing:zone objects
    orphaned_sizing_zones = Array.new
    #loop through all sizing:zone objects, checking for missing ThermalZone field
    sizing_zones.each do |sizing_zone|
      sizing_zone = sizing_zone.to_SizingZone.get
      if sizing_zone.isEmpty(1)
        orphaned_sizing_zones << sizing_zone.handle
        puts "*(error)#{sizing_zone.name} is not connected to a thermal zone"
        if remove_errors
          puts "**(removing object)#{sizing_zone.name} is not connected to a thermal zone"
          sizing_zone.remove
          savediagnostic = true
        end
      end
    end
    #summarize the results
    if orphaned_sizing_zones.length > 0
      puts "#{orphaned_sizing_zones.length} orphaned sizing:zone objects were found"
    else
      puts "no orphaned sizing:zone objects were found"
    end

    puts ""
    puts ">>diagnostic test complete"

    if savediagnostic
      newfilename = open_path.gsub(".osm","_diagnostic.osm")
      if File.exists? newfilename
        # I would like to add a prompt to ask the user if they want to overwrite their file
      end
      puts ""
      puts ">>saving temporary diagnostic version " + newfilename
      model.save(OpenStudio::Path.new(newfilename),true)

    end
    # End measure excerpt. 
    
    
    
    runner.registerFinalCondition("Model replaced with INP model at #{inp_file}. Weather file and design days retained from original. Please check warnings if any.")
    return true

  end
  
end

# register the measure to be used by the application
BtapEquestConverter.new.registerWithApplication
