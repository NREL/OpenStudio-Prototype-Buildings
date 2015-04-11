
# open the class to add methods to apply HVAC efficiency standards
class OpenStudio::Model::Space
  
  # Returns a hash of values for the daylighted areas in the space.
  # {toplighted_area, primary_sidelighted_area, secondary_sidelighted_area, total_window_area, total_skylight_area}
  def daylightedAreas(vintage)
    
    result = {'toplighted_area' => nil,
              'primary_sidelighted_area' => nil,
              'secondary_sidelighted_area' => nil,
              'total_window_area' => nil,
              'total_skylight_area' => nil
              }
    
    total_window_area = 0
    total_skylight_area = 0
    
    # Make rendering colors to help debug visually
    # Yellow
    toplit_construction = OpenStudio::Model::Construction.new(model)
    toplit_color = OpenStudio::Model::RenderingColor.new(model)
    toplit_color.setRenderingRedValue(255)
    toplit_color.setRenderingGreenValue(255)
    toplit_color.setRenderingBlueValue(0)
    toplit_construction.setRenderingColor(toplit_color)  

    # Red
    pri_sidelit_construction = OpenStudio::Model::Construction.new(model)
    pri_sidelit_color = OpenStudio::Model::RenderingColor.new(model)
    pri_sidelit_color.setRenderingRedValue(255)
    pri_sidelit_color.setRenderingGreenValue(0)
    pri_sidelit_color.setRenderingBlueValue(0)
    pri_sidelit_construction.setRenderingColor(pri_sidelit_color)

    # Blue
    sec_sidelit_construction = OpenStudio::Model::Construction.new(model)
    sec_sidelit_color = OpenStudio::Model::RenderingColor.new(model)
    sec_sidelit_color.setRenderingRedValue(0)
    sec_sidelit_color.setRenderingGreenValue(0)
    sec_sidelit_color.setRenderingBlueValue(255)
    sec_sidelit_construction.setRenderingColor(sec_sidelit_color)

    # Light Blue
    flr_construction = OpenStudio::Model::Construction.new(model)
    flr_color = OpenStudio::Model::RenderingColor.new(model)
    flr_color.setRenderingRedValue(0)
    flr_color.setRenderingGreenValue(255)
    flr_color.setRenderingBlueValue(255)
    flr_construction.setRenderingColor(flr_color)

    # Move the polygon up slightly for viewability in sketchup
    up_translation_flr = OpenStudio::createTranslation(OpenStudio::Vector3d.new(0, 0, 0.05))
    up_translation_top = OpenStudio::createTranslation(OpenStudio::Vector3d.new(0, 0, 0.1))
    up_translation_pri = OpenStudio::createTranslation(OpenStudio::Vector3d.new(0, 0, 0.1))
    up_translation_sec = OpenStudio::createTranslation(OpenStudio::Vector3d.new(0, 0, 0.1))

    # Get the space's surface group's transformation
    space_transformation = self.transformation
    
    # Record a floor in the space for later use
    floor_surface = nil  
    
    # Record all floor polygons
    floor_polygons = []
    self.surfaces.each do |surface|
      if surface.surfaceType == "Floor"
        floor_surface = surface
        floor_polygons << surface.vertices
      end
    end
    
    # Make sure there is one floor surface
    if not floor_surface
      OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Space", "Could not find a floor in space #{self.name.get}, cannot determine daylighted areas.")
      return result
    end
    
    # TODO make a big surface that combines all the floor surfaces
    
    # Make a set of vertices representing each subsurfaces sidelighteding area
    # and fold them all down onto the floor of the self.
    toplit_polygons = []
    pri_sidelit_polygons = []
    sec_sidelit_polygons = []
    self.surfaces.each do |surface|
      if surface.outsideBoundaryCondition == "Outdoors" && surface.surfaceType == "Wall"
        surface.subSurfaces.each do |sub_surface|
          next unless sub_surface.outsideBoundaryCondition == "Outdoors" && (sub_surface.subSurfaceType == "FixedWindow" || sub_surface.subSurfaceType == "OperableWindow")
          
          #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "***#{sub_surface.name}***"
          total_window_area += sub_surface.netArea
          
          # Find the head height and sill height of the window
          vertex_heights_above_floor = []
          sub_surface.vertices.each do |vertex|
            vertex_on_floorplane = floor_surface.plane.project(vertex)
            vertex_heights_above_floor << (vertex - vertex_on_floorplane).length
          end
          sill_height_m = vertex_heights_above_floor.min
          head_height_m = vertex_heights_above_floor.max
          #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "head height = #{head_height_m.round(2)}m, sill height = #{sill_height_m.round(2)}m")
            
          # Find the width of the window
          rot_origin = nil
          if not sub_surface.vertices.size == 4
            OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "A sub-surface in space #{self.name} has other than 4 vertices; this sub-surface will not be included in the daylighted area calculation.")
            next
          end
          prev_vertex_on_floorplane = nil
          max_window_width_m = 0
          sub_surface.vertices.each do |vertex|
            vertex_on_floorplane = floor_surface.plane.project(vertex)
            if not prev_vertex_on_floorplane
              prev_vertex_on_floorplane = vertex_on_floorplane
              next
            end
            width_m = (prev_vertex_on_floorplane - vertex_on_floorplane).length
            if width_m > max_window_width_m
              max_window_width_m = width_m
              rot_origin = vertex_on_floorplane
            end
          end
          
          # Determine the extra width to add to the sidelighted area
          extra_width_m = 0
          if vintage == '90.1-2013'
            extra_width_m = head_height_m / 2
          elsif vintage == '90.1-2010'
            extra_width_m = OpenStudio.convert(2, 'ft', 'm').get
          end
          #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "Adding #{extra_width_m.round(2)}m to the width for the sidelighted area.")
          
          # Align the vertices with face coordinate system
          face_transform = OpenStudio::Transformation.alignFace(sub_surface.vertices)
          aligned_vertices = face_transform.inverse * sub_surface.vertices
          
          # Find the min and max x values
          min_x_val = 99999
          max_x_val = -99999
          aligned_vertices.each do |vertex|
            # Min x value
            if vertex.x < min_x_val
              min_x_val = vertex.x
            end
            # Max x value
            if vertex.x > max_x_val
              max_x_val = vertex.x
            end
          end
          #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "min_x_val = #{min_x_val.round(2)}, max_x_val = #{max_x_val.round(2)}")
          
          # Create polygons that are adjusted
          # to expand from the window shape to the sidelighteded areas.
          pri_sidelit_sub_polygon = []
          sec_sidelit_sub_polygon = []
          aligned_vertices.each do |vertex|
            
            # Primary sidelighted area
            # Move the x vertices outward by the specified amount.
            if vertex.x == min_x_val
              new_x = vertex.x - extra_width_m
            elsif vertex.x == max_x_val
              new_x = vertex.x + extra_width_m
            else
              new_x = 99.9
              OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "A window in space #{self.name} is non-rectangular; this sub-surface will not be included in the daylighted area calculation.")
            end
            
            # Zero-out the y for the bottom edge because the 
            # sidelighteding area extends down to the floor.
            if vertex.y == 0
              new_y = vertex.y - sill_height_m
            else
              new_y = vertex.y
            end        
            
            # Set z = 0 so that intersection works.
            new_z = 0

            # Make the new vertex
            new_vertex = OpenStudio::Point3d.new(new_x, new_y, new_z)
            pri_sidelit_sub_polygon << new_vertex
            #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "#{vertex.x.round(2)}, #{vertex.y.round(2)}, #{vertex.z.round(2)} ==> #{new_vertex.x.round(2)}, #{new_vertex.y.round(2)}, #{new_vertex.z.round(2)}")
            
            # Secondary sidelighted area
            # Move the x vertices outward by the specified amount.
            if vertex.x == min_x_val
              new_x = vertex.x - extra_width_m
            elsif vertex.x == max_x_val
              new_x = vertex.x + extra_width_m
            else
              new_x = 99.9
              OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "A window in space #{self.name} is non-rectangular; this sub-surface will not be included in the daylighted area calculation.")
            end
            
            # Add the head height of the window to all points
            # sidelighteding area extends down to the floor.
            if vertex.y == 0
              new_y = vertex.y - sill_height_m + head_height_m
            else
              new_y = vertex.y + head_height_m
            end        
            
            # Set z = 0 so that intersection works.
            new_z = 0

            # Make the new vertex
            new_vertex = OpenStudio::Point3d.new(new_x, new_y, new_z)
            sec_sidelit_sub_polygon << new_vertex
            #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "#{vertex.x.round(2)}, #{vertex.y.round(2)}, #{vertex.z.round(2)} ==> #{new_vertex.x.round(2)}, #{new_vertex.y.round(2)}, #{new_vertex.z.round(2)}")       
               
          end
          
          # Realign the vertices with space coordinate system
          pri_sidelit_sub_polygon = face_transform * pri_sidelit_sub_polygon
          sec_sidelit_sub_polygon = face_transform * sec_sidelit_sub_polygon
          
          # Rotate the sidelighteded areas down onto the floor
          down_vector = OpenStudio::Vector3d.new(0, 0, -1)
          outward_normal_vector = sub_surface.outwardNormal
          rot_vector = down_vector.cross(outward_normal_vector)
          ninety_deg_in_rad = OpenStudio::degToRad(90) # TODO change 
          new_rotation = OpenStudio::createRotation(rot_origin, rot_vector, ninety_deg_in_rad)
          pri_sidelit_sub_polygon = new_rotation * pri_sidelit_sub_polygon
          sec_sidelit_sub_polygon = new_rotation * sec_sidelit_sub_polygon

          # Make a new surface for each of the resulting polygons to visually inspect it
          # dummy_space = OpenStudio::Model::Space.new(model)  
          # pri_daylt_surf = OpenStudio::Model::Surface.new(up_translation_pri * pri_sidelit_sub_polygon, model)
          # pri_daylt_surf.setConstruction(pri_sidelit_construction)
          # pri_daylt_surf.setSpace(dummy_space)
          # sec_daylt_surf = OpenStudio::Model::Surface.new(up_translation_sec * sec_sidelit_sub_polygon, model)
          # sec_daylt_surf.setConstruction(sec_sidelit_construction)
          # sec_daylt_surf.setSpace(dummy_space)

          # Put the polygon vertices into counterclockwise order
          pri_sidelit_sub_polygon = pri_sidelit_sub_polygon.reverse
          sec_sidelit_sub_polygon = sec_sidelit_sub_polygon.reverse
      
          # Add these polygons to the list
          pri_sidelit_polygons << pri_sidelit_sub_polygon
          sec_sidelit_polygons << sec_sidelit_sub_polygon
          
        end # Next subsurface
      elsif surface.outsideBoundaryCondition == "Outdoors" && surface.surfaceType == "RoofCeiling"
        surface.subSurfaces.each do |sub_surface|
          next unless sub_surface.outsideBoundaryCondition == "Outdoors" && sub_surface.subSurfaceType == "Skylight"
          
          #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "***#{sub_surface.name}***")
          total_skylight_area += sub_surface.netArea
          
          # Project the skylight onto the floor plane
          polygon_on_floor = []
          vertex_heights_above_floor = []
          sub_surface.vertices.each do |vertex|
            vertex_on_floorplane = floor_surface.plane.project(vertex)
            vertex_heights_above_floor << (vertex - vertex_on_floorplane).length
            polygon_on_floor << vertex_on_floorplane
          end
          
          # Determine the ceiling height.
          # Assumes skylight is flush with ceiling.
          ceiling_height_m = vertex_heights_above_floor.max
          
          # Align the vertices with face coordinate system
          face_transform = OpenStudio::Transformation.alignFace(polygon_on_floor)
          aligned_vertices = face_transform.inverse * polygon_on_floor
          
          # Find the min and max x and y values
          min_x_val = 99999
          max_x_val = -99999
          min_y_val = 99999
          max_y_val = -99999
          aligned_vertices.each do |vertex|
            # Min x value
            if vertex.x < min_x_val
              min_x_val = vertex.x
            end
            # Max x value
            if vertex.x > max_x_val
              max_x_val = vertex.x
            end
            # Min y value
            if vertex.y < min_y_val
              min_y_val = vertex.y
            end
            # Max y value
            if vertex.y > max_x_val
              max_y_val = vertex.y
            end
          end
          #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "min_x_val = #{min_x_val.round(2)}, max_x_val = #{max_x_val.round(2)}")
          
          # Figure out how much to expand the window
          additional_extent_m = 0.7 * ceiling_height_m
          
          # Create polygons that are adjusted
          # to expand from the window shape to the sidelighteded areas.
          toplit_sub_polygon = []
          aligned_vertices.each do |vertex|
            
            # Move the x vertices outward by the specified amount.
            if vertex.x == min_x_val
              new_x = vertex.x - additional_extent_m
            elsif vertex.x == max_x_val
              new_x = vertex.x + additional_extent_m
            else
              new_x = 99.9
              OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "A skylight in space #{self.name} is non-rectangular; this sub-surface will not be included in the daylighted area calculation.")
            end
            
            # Move the y vertices outward by the specified amount.
            if vertex.y == min_y_val
              new_y = vertex.y - additional_extent_m
            elsif vertex.y == max_y_val
              new_y = vertex.y + additional_extent_m
            else
              new_y = 99.9
              OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "A skylight in space #{self.name} is non-rectangular; this sub-surface will not be included in the daylighted area calculation.")
            end       
            
            # Set z = 0 so that intersection works.
            new_z = 0

            # Make the new vertex
            new_vertex = OpenStudio::Point3d.new(new_x, new_y, new_z)
            toplit_sub_polygon << new_vertex
            #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "#{vertex.x.round(2)}, #{vertex.y.round(2)}, #{vertex.z.round(2)} ==> #{new_vertex.x.round(2)}, #{new_vertex.y.round(2)}, #{new_vertex.z.round(2)}")
            
          end
          
          # Realign the vertices with space coordinate system
          toplit_sub_polygon = face_transform * toplit_sub_polygon

          # Put the polygon vertices into counterclockwise order
          toplit_sub_polygon = toplit_sub_polygon.reverse
          
          # Make a new surface for each of the resulting polygons to visually inspect it
          # dummy_space = OpenStudio::Model::Space.new(model)  
          # toplt_surf = OpenStudio::Model::Surface.new(up_translation_top * toplit_sub_polygon, model)
          # toplt_surf.setConstruction(toplit_construction)
          # toplt_surf.setSpace(dummy_space)

          # Add these polygons to the list
          toplit_polygons << toplit_sub_polygon
          
        end # Next subsurface 
      
      end # End if outdoor wall or roofceiling
    
    end # Next surface
   
    # Join, then subtract
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "******Joining polygons******")
    
    # Wrapper to catch errors in joinAll method
    # [utilities.geometry.joinAll] <1> Expected polygons to join together
    def join_polygons(polygons, tol)
    
        # Open a log
        msg_log = OpenStudio::StringStreamLogSink.new
        msg_log.setLogLevel(OpenStudio::Info)
        
        combined_polygons = OpenStudio.joinAll(polygons, 0.01)

        # Count logged errors
        errs = 0
        msg_log.logMessages.each do |msg|
          if /utilities.geometry/.match(msg.logChannel)
            if msg.logMessage.include?("Expected polygons to join together")
              errs += 1
              
            end
          end
        end
        
        # Report logged errors to user
        if errs > 0
          OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "For #{self.name}, #{errs} of #{polygons.size} were not joined properly due to limitations of the geometry calculation methods.  The resulting daylighted areas will be smaller than they should be.")
        end
        
        return combined_polygons
        
    end
    
    # Join toplighted polygons into a single set

    combined_toplit_polygons = join_polygons(toplit_polygons, 0.01)
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "Joined #{toplit_polygons.size} toplit polygons into #{combined_toplit_polygons.size}"   )
    
    # Join primary sidelighted polygons into a single set
    combined_pri_sidelit_polygons = join_polygons(pri_sidelit_polygons, 0.01)
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "Joined #{pri_sidelit_polygons.size} primary sidelighted polygons into #{combined_pri_sidelit_polygons.size}")
    
    # Join secondary sidelighted polygons into a single set
    combined_sec_sidelit_polygons = join_polygons(sec_sidelit_polygons, 0.01)
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "Joined #{sec_sidelit_polygons.size} secondary sidelighted polygons into #{combined_sec_sidelit_polygons.size}")
    
    # Join floor polygons into a single set
    combined_floor_polygons = join_polygons(floor_polygons, 0.01)
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "Joined #{floor_polygons.size} floor polygons into #{combined_floor_polygons.size}"  )
    
    # Make a new surface for each of the resulting polygons to visually inspect it
    # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "******Making Surfaces to view in SketchUp******")

    # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "***combined_toplit_polygons"  )
    # combined_toplit_polygons.each do |polygon|
      # dummy_space = OpenStudio::Model::Space.new(model)
      # polygon = up_translation_top * polygon
      # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "combined_toplit_polygon")
      # daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
      # daylt_surf.setConstruction(toplit_construction)
      # daylt_surf.setSpace(dummy_space)
      # daylt_surf.setName("Top")
    # end  
    
    # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "***combined_pri_sidelit_polygons")
    # combined_pri_sidelit_polygons.each do |polygon|
      # dummy_space = OpenStudio::Model::Space.new(model)
      # polygon = up_translation_pri * polygon
      # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "combined_pri_sidelit_polygon")
      # daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
      # daylt_surf.setConstruction(pri_sidelit_construction)
      # daylt_surf.setSpace(dummy_space)
      # daylt_surf.setName("Pri")    
    # end
    
    # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "***combined_sec_sidelit_polygons")
    # combined_sec_sidelit_polygons.each do |polygon|
      # dummy_space = OpenStudio::Model::Space.new(model)
      # polygon = up_translation_sec * polygon
      # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "combined_sec_sidelit_polygon")
      # daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
      # daylt_surf.setConstruction(sec_sidelit_construction)
      # daylt_surf.setSpace(dummy_space)
      # daylt_surf.setName("Sec")
    # end

    # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "***combined_floor_polygons")
    # combined_floor_polygons.each do |polygon|
      # dummy_space = OpenStudio::Model::Space.new(model)
      # polygon = up_translation_flr * polygon
      # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "combined_floor_polygon")
      # daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
      # daylt_surf.setConstruction(flr_construction)
      # daylt_surf.setSpace(dummy_space)
      # daylt_surf.setName("Flr")
    # end  
    
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "******Subtracting overlapping areas******")

    # Subtracts one array of polygons from the next,
    # returning an array of resulting polygons.
    def a_polygons_minus_b_polygons(a_polygons, b_polygons)
    
      # Loop through all a polygons, and for each one,
      # subtract all the b polygons.
      final_polygons = []
      a_polygons.each do |a_polygon|
        
        # Translate the polygon to plain arrays
        a_polygon_ruby = []
        a_polygon.each do |vertex|
          a_polygon_ruby << [vertex.x, vertex.y, vertex.z]
        end
        
        # Perform the subtraction
        a_minus_b_polygons = OpenStudio.subtract(a_polygon, b_polygons, 0.01)
        #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "polygon minus #{b_polygons.size} = #{a_minus_b_polygons.size}")
        
        # TODO Remove this bug? workaround
        # Compare all polygons to the originals.
        # If no polygons are changed, keep them all.
        # If one polygon is changed but the ot
        unchanged_polygons = []
        changed_polygons = []
        a_minus_b_polygons.each do |a_minus_b_polygon|
          # Translate the resulting polygon to plain arrays
          a_minus_b_polygon_ruby = []
          a_minus_b_polygon.each do |vertex|
            a_minus_b_polygon_ruby << [vertex.x, vertex.y, vertex.z]
          end
          # Compare the resulting polygons to the original
          if a_minus_b_polygon_ruby == a_polygon_ruby 
            unchanged_polygons << a_minus_b_polygon
          else
            changed_polygons << a_minus_b_polygon
          end
        end
        # Output debugging
        #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "changed_polygons = #{changed_polygons.size}")
        #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "unchanged_polygons = #{unchanged_polygons.size}")
        if a_minus_b_polygons.size == 1
          #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "---not split"
          final_polygons.concat(changed_polygons)
          final_polygons.concat(unchanged_polygons)
        else
          #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "---split"
          final_polygons.concat(changed_polygons)
        end
          
      end  

      return final_polygons
      
    end
    
    # Subtract lower-priority daylighting areas from higher priority ones
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "primary polygons - toplighted polygons ")
    pri_minus_top_polygons = a_polygons_minus_b_polygons(combined_pri_sidelit_polygons, combined_toplit_polygons)
    
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "secondary polygons - toplighted polygons")
    sec_minus_top_polygons = a_polygons_minus_b_polygons(combined_sec_sidelit_polygons, combined_toplit_polygons)
    
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "(secondary polygons - toplighted polygons) - primary polygons")
    sec_minus_top_minus_pri_polygons = a_polygons_minus_b_polygons(sec_minus_top_polygons, combined_pri_sidelit_polygons)
   
    # Make a new surface for each of the resulting polygons to visually inspect it
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "******Making Surfaces to view in SketchUp******")
    dummy_space = OpenStudio::Model::Space.new(model)
    
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "***combined_toplit_polygons")  
    combined_toplit_polygons.each do |polygon|
      polygon = up_translation_top * polygon
      polygon = space_transformation * polygon
      #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "combined_toplit_polygon")
      daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
      daylt_surf.setConstruction(toplit_construction)
      daylt_surf.setSpace(dummy_space)
      daylt_surf.setName("Top")
    end  
    
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "***pri_minus_top_polygons")
    pri_minus_top_polygons.each do |polygon|
      polygon = up_translation_pri * polygon
      polygon = space_transformation * polygon
      #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "pri_minus_top_polygon")
      daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
      daylt_surf.setConstruction(pri_sidelit_construction)
      daylt_surf.setSpace(dummy_space)
      daylt_surf.setName("Pri")    
    end
    
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "***sec_minus_top_minus_pri_polygons")
    sec_minus_top_minus_pri_polygons.each do |polygon|
      polygon = up_translation_sec * polygon
      polygon = space_transformation * polygon
      #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "sec_minus_top_minus_pri_polygon")
      daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
      daylt_surf.setConstruction(sec_sidelit_construction)
      daylt_surf.setSpace(dummy_space)
      daylt_surf.setName("Sec")
    end

    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "***combined_floor_polygons")
    combined_floor_polygons.each do |polygon|
      polygon = up_translation_flr * polygon
      polygon = space_transformation * polygon
      #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "combined_floor_polygon")
      daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
      daylt_surf.setConstruction(flr_construction)
      daylt_surf.setSpace(dummy_space)
      daylt_surf.setName("Flr")
    end

    # Gets the total area of a series of polygons
    def total_area_of_polygons(polygons)
      total_area_m2 = 0
      polygons.each do |polygon|
        area_m2 = OpenStudio.getArea(polygon)
        if area_m2.is_initialized
          total_area_m2 += area_m2.get
        else
          OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "Could not get area for a polygon in #{self.name}, daylighted area calculation will not be accurate.")
        end
      end
    
      return total_area_m2
      
    end
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "******Calculating Daylighted Areas******")
    
    # Get the total floor area
    total_floor_area_m2 = total_area_of_polygons(combined_floor_polygons)
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "total_floor_area_m2 = #{total_floor_area_m2.round(1)}")
    
    # Toplighted area
    floor_minus_toplighted_polygons = a_polygons_minus_b_polygons(combined_floor_polygons, combined_toplit_polygons)
    floor_minus_toplighted_area_m2 = total_area_of_polygons(floor_minus_toplighted_polygons)
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "floor_minus_toplighted_area_m2 = #{floor_minus_toplighted_area_m2.round(1)}")
    toplighted_area_m2 = total_floor_area_m2 - floor_minus_toplighted_area_m2
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "toplighted_area_m2 = #{toplighted_area_m2.round(1)}")
    result['toplighted_area'] = toplighted_area_m2
    
    # Primary sidelighted area
    floor_minus_pri_sidelit_polygons = a_polygons_minus_b_polygons(combined_floor_polygons, pri_minus_top_polygons)
    floor_minus_pri_sidelit_area_m2 = total_area_of_polygons(floor_minus_pri_sidelit_polygons)
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "floor_minus_pri_sidelit_area_m2 = #{floor_minus_pri_sidelit_area_m2.round(1)}")
    primary_sidelighted_area_m2 = total_floor_area_m2 - floor_minus_pri_sidelit_area_m2
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "primary_sidelighted_area_m2 = #{primary_sidelighted_area_m2.round(1)}")
    result['primary_sidelighted_area'] = primary_sidelighted_area_m2
    
    # Secondary sidelighted area
    floor_minus_sec_sidelit_polygons = a_polygons_minus_b_polygons(combined_floor_polygons, sec_minus_top_minus_pri_polygons)
    floor_minus_sec_sidelit_area_m2 = total_area_of_polygons(floor_minus_sec_sidelit_polygons)
    #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "floor_minus_sec_sidelit_area_m2 = #{floor_minus_sec_sidelit_area_m2.round(1)}")
    secondary_sidelighted_area_m2 = total_floor_area_m2 - floor_minus_sec_sidelit_area_m2
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "secondary_sidelighted_area_m2 = #{secondary_sidelighted_area_m2.round(1)}")    
    result['secondary_sidelighted_area'] = secondary_sidelighted_area_m2
    
    result['total_window_area'] = total_window_area
    result['total_skylight_area'] = total_skylight_area
    
    return result
    
  end

  # Returns the sidelighting effective aperture
  def sidelightingEffectiveAperture(primary_sidelighted_area)
    
    # sidelighting_effective_aperture = E(window area * window VT) / primary_sidelighted_area
    sidelighting_effective_aperture = 9999
    
    # Loop through all windows and add up area * VT
    sum_window_area_times_vt = 0
    construction_name_to_vt_map = {}
    self.surfaces.each do |surface|
      next unless surface.outsideBoundaryCondition == "Outdoors" && surface.surfaceType == "Wall"
      surface.subSurfaces.each do |sub_surface|
        next unless sub_surface.outsideBoundaryCondition == "Outdoors" && (sub_surface.subSurfaceType == "FixedWindow" || sub_surface.subSurfaceType == "OperableWindow")
        
        # Get the area
        area_m2 = sub_surface.netArea
        
        # Get the window construction name
        construction_name = nil
        construction = sub_surface.construction
        if construction.is_initialized
          construction_name = construction.get.name.get
        else
          OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "For #{self.name}, ")
          next
        end
        
        # Store VT for this construction in map if not already looked up
        if construction_name_to_vt_map[construction_name].nil?
          
          sql = self.model.sqlFile
          
          if sql.is_initialized
            sql = sql.get
          
            row_query = "SELECT RowID
                        FROM tabulardatawithstrings
                        WHERE ReportName='EnvelopeSummary'
                        AND ReportForString='Entire Facility'
                        AND TableName='Exterior Fenestration'
                        AND Value='#{construction_name.upcase}'"
          
            row_id = sql.execAndReturnFirstDouble(row_query)
            
            if row_id.is_initialized
              row_id = row_id.get
            else
              OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Model", "VT data not found for query: #{row_query}")
              row_id = 9999
            end
          
            vt_query = "SELECT Value
                        FROM tabulardatawithstrings
                        WHERE ReportName='EnvelopeSummary'
                        AND ReportForString='Entire Facility'
                        AND TableName='Exterior Fenestration'
                        AND ColumnName='Glass Visible Transmittance'
                        AND RowID=#{row_id}"          
          
          
            vt = sql.execAndReturnFirstDouble(vt_query)
            
            if vt.is_initialized
              vt = vt.get
            else
              OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Model", "VT data not found for query: #{vt_query}")
              vt = 0.5
            end
                  
            # Record the VT
            construction_name_to_vt_map[construction_name] = vt

          else
            OpenStudio::logFree(OpenStudio::Error, 'openstudio.standards.Space', 'Model has no sql file containing results, cannot lookup data.')
          end

        end
  
        # Get the VT from the map
        vt = construction_name_to_vt_map[construction_name]
        if vt.nil?
          OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "For #{self.name}, ")
          return false
        end
  
        sum_window_area_times_vt += area_m2 * vt
  
      end
    end
    
    # Calculate the effective aperture
    if sum_window_area_times_vt == 0
      sidelighting_effective_aperture = 9999
    else
      sidelighting_effective_aperture = sum_window_area_times_vt/primary_sidelighted_area
    end
 
    return sidelighting_effective_aperture
    
  end

  # Returns the sidelighting effective aperture
  def skylightEffectiveAperture(toplighted_area)
    
    # skylight_effective_aperture = E(0.85 * skylight area * skylight VT * WF) / toplighted_area
    skylight_effective_aperture = nil
    
    # Assume that well factor (WF) is 0.9 (all wells are less than 2 feet deep)
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "Assuming that all skylight wells are less than 2 feet deep to calculate skylight effective aperture.")
    wf = 0.9
    
    # Loop through all windows and add up area * VT
    sum_85pct_time_skylight_area_times_vt_times_wf = 0
    construction_name_to_vt_map = {}
    self.surfaces.each do |surface|
      next unless surface.outsideBoundaryCondition == "Outdoors" && surface.surfaceType == "RoofCeiling"
      surface.subSurfaces.each do |sub_surface|
        next unless sub_surface.outsideBoundaryCondition == "Outdoors" && sub_surface.subSurfaceType == "Skylight"
        
        # Get the area
        area_m2 = sub_surface.netArea
        
        # Get the window construction name
        construction_name = nil
        construction = sub_surface.construction
        if construction.is_initialized
          construction_name = construction.name.get
        else
          OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "For #{self.name}, ")
          next
        end
        
        # Store VT for this construction in map if not already looked up
        if construction_name_to_vt_map[construction_name].nil?
          
          sql = self.model.sqlFile
          
          if sql.is_initialized
            sql = sql.get
          
            row_query = "SELECT RowID
                        FROM tabulardatawithstrings
                        WHERE ReportName='EnvelopeSummary'
                        AND ReportForString='Entire Facility'
                        AND TableName='Exterior Fenestration'
                        AND Value='#{construction_name}'"
          
            row_id = sql.execAndReturnFirstDouble(row_query)
            
            if row_id.is_initialized
              row_id = row_id.get
            else
              #OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Model", "Data not found for query: #{query}")
              return false
            end
          
            vt_query = "SELECT Value
                        FROM tabulardatawithstrings
                        WHERE ReportName='EnvelopeSummary'
                        AND ReportForString='Entire Facility'
                        AND TableName='Exterior Fenestration'
                        AND ColumnName='Glass Visible Transmittance'
                        AND RowID=#{row_id}"          
          
          
            vt = sql.execAndReturnFirstDouble(row_query)
            
            if vt.is_initialized
              vt = vt.get
            else
              #OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Model", "Data not found for query: #{query}")
              return false
            end
                  
            # Record the VT
            construction_name_to_vt_map[construction_name] = vt

          else
            OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', 'Model has no sql file containing results, cannot lookup data.')
          end

        end
  
        # Get the VT from the map
        vt = construction_name_to_vt_map[construction_name]
        if vt.nil?
          OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "For #{self.name}, ")
          return false
        end
  
        sum_85pct_time_skylight_area_times_vt_times_wf += 0.85 * area_m2 * vt * wf
  
      end
    end
    
    # Calculate the effective aperture
    if sum_window_area_times_vt == 0
      skylight_effective_aperture = nil
    else
      skylight_effective_aperture = sum_window_area_times_vt/toplighted_area
    end
 
    return skylight_effective_aperture
    
  end
  
  # Adds daylighting controls (sidelighting and toplighting) per the standard
  def addDaylightingControls(vintage)
    
    requires_toplighting_control = false
    requires_pri_sidelighting_control = false
    requires_sec_sidelighting_control = false
    
    # Get the area of the space
    space_area_m2 = self.floorArea
    
    # Get the LPD of the space
    space_lpd_w_per_m2 = self.lightingPowerPerFloorArea
    
    # Determine the type of control required
    case vintage
    when  'DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007'
    
      # Do nothing, no daylighting controls required
    
    when '90.1-2010'
      
      requires_toplighting_control = true
      requires_pri_sidelighting_control = true
      
      daylighted_areas = self.daylightedAreas(vintage)
      
      # Sidelighting
      # Check if the primary sidelit area < 250 ft2
      if space_area_m2 < OpenStudio.convert(250, 'ft^2', 'm^2').get
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, primary sidelighting control not required because space area < 250ft2 per 9.4.1.4.")
        requires_pri_sidelighting_control = false
      else
        # Check the size of the daylighted areas
        if daylighted_areas['primary_sidelighted_area'] == 0
          OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, primary sidelighting control not required because primary sidelighted area = 0ft2 per 9.4.1.4.")
          requires_pri_sidelighting_control = false
        else      
          # Check effective sidelighted aperture
          sidelighted_effective_aperture = self.sidelightingEffectiveAperture(daylighted_areas['primary_sidelighted_area'])
          if sidelighted_effective_aperture < 0.1
            OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, primary sidelighting control not required because sidelighted effective aperture < 0.1 per 9.4.1.4 Exception b.")
            requires_pri_sidelighting_control = false
          else
            # TODO Check the space type
            # if 
              # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, primary sidelighting control not required because space type is retail per 9.4.1.4 Exception c.")
              # requires_pri_sidelighting_control = false
            # end
          end
        end
      end
      
      # Toplighting
      # Check if the toplit area < 900 ft2
      if space_area_m2 < OpenStudio.convert(900, 'ft^2', 'm^2').get
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, toplighting control not required because space area < 900ft2 per 9.4.1.5.")
        requires_toplighting_control = false
      else
        # Check the size of the daylighted areas
        if daylighted_areas['toplighted_area'] == 0
          OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, toplighting control not required because toplighted area = 0ft2 per 9.4.1.5.")
          requires_toplighting_control = false
        else      
          # Check effective sidelighted aperture
          sidelighted_effective_aperture = self.skylightEffectiveAperture(daylighted_areas['toplighted_area'])
          if sidelighted_effective_aperture < 0.006
            OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, toplighting control not required because skylight effective aperture < 0.006 per 9.4.1.5 Exception b.")
            requires_toplighting_control = false
          else
            # TODO Check the climate zone.  Not required in CZ8 where toplit areas < 1500ft2
            # if 
              # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, toplighting control not required because space type is retail per 9.4.1.5 Exception c.")
              # requires_toplighting_control = false
            # end
          end
        end
      end
    
    when '90.1-2013'
    
      requires_toplighting_control = true
      requires_pri_sidelighting_control = true
      requires_sec_sidelighting_control = true
      
      daylighted_areas = self.daylightedAreas(vintage)
      
      # Primary Sidelighting
      # Check if the primary sidelit area contains less than 150W of lighting
      pri_sidelit_wattage = daylighted_areas['primary_sidelighted_area'] * space_lpd_w_per_m2
      if pri_sidelit_wattage < 150
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, primary sidelighting control not required because less than 150W of lighting are present in the primary daylighted area per 9.4.1.1 e.")
        requires_pri_sidelighting_control = false
      else
        # Check the size of the windows
        if daylighted_areas['total_window_area'] < 20
          OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, primary sidelighting control not required because there are less than 20ft2 of window per 9.4.1.1 e Exception 2.")
          requires_pri_sidelighting_control = false
        else      
          # TODO Check the space type
          # if 
            # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, primary sidelighting control not required because space type is retail per 9.4.1.1 e Exception c.")
            # requires_pri_sidelighting_control = false
          # end
        end
      end
      
      # Secondary Sidelighting
      # Check if the primary and secondary sidelit areas contains less than 300W of lighting
      sec_sidelit_wattage = daylighted_areas['primary_sidelighted_area'] * space_lpd_w_per_m2
      if sec_sidelit_wattage < 300
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, primary sidelighting control not required because less than 300W of lighting are present in the primary and secondary daylighted areas per 9.4.1.1 e.")
        requires_sec_sidelighting_control = false
      else
        # Check the size of the windows
        if daylighted_areas['total_window_area'] < 20
          OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, primary sidelighting control not required because there are less than 20ft2 of window per 9.4.1.1 e Exception 2.")
          requires_sec_sidelighting_control = false
        else      
          # TODO Check the space type
          # if 
            # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, primary sidelighting control not required because space type is retail per 9.4.1.1 e Exception c.")
            # requires_sec_sidelighting_control = false
          # end
        end
      end

      # Toplighting
      # Check if the toplit area contains less than 150W of lighting
      toplit_wattage = daylighted_areas['toplighted_area'] * space_lpd_w_per_m2
      if toplit_wattage < 150
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, toplighting control not required because less than 150W of lighting are present in the primary and secondary daylighted areas per 9.4.1.1 e.")
        requires_sec_sidelighting_control = false
      end   
    
    end # End of vintage case statement
    
    # Record a floor in the space for later use
    floor_surface = nil
    self.surfaces.each do |surface|
      if surface.surfaceType == "Floor"
        floor_surface = surface
        break
      end
    end    

    # Find all exterior windows/skylights in the space and record their azimuths and areas
    windows = {}
    self.surfaces.each do |surface|
    next unless surface.outsideBoundaryCondition == "Outdoors" && (surface.surfaceType == "Wall" || surface.surfaceType == "RoofCeiling")
      surface.subSurfaces.each do |sub_surface|
        next unless sub_surface.outsideBoundaryCondition == "Outdoors" && (sub_surface.subSurfaceType == "FixedWindow" || sub_surface.subSurfaceType == "OperableWindow" ||  sub_surface.subSurfaceType == "Skylight")
        
        # Find the area
        net_area_m2 = sub_surface.netArea
 
        # Find the head height and sill height of the window
        vertex_heights_above_floor = []
        sub_surface.vertices.each do |vertex|
          vertex_on_floorplane = floor_surface.plane.project(vertex)
          vertex_heights_above_floor << (vertex - vertex_on_floorplane).length
        end
        head_height_m = vertex_heights_above_floor.max
        #OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "---head height = #{head_height_m}m, sill height = #{sill_height_m}m")
 
        # Find the azimuth
        group = sub_surface.planarSurfaceGroup
        if group.is_initialized
          group = group.get
          site_transformation = group.buildingTransformation
          site_vertices = site_transformation * sub_surface.vertices
          site_outward_normal = OpenStudio::getOutwardNormal(site_vertices)
          if site_outward_normal.empty?
            OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Space", "could not compute outward normal for #{sub_surface.name.get}")
            return false
          end
          site_outward_normal = site_outward_normal.get
          north = OpenStudio::Vector3d.new(0.0,1.0,0.0)
          if site_outward_normal.x < 0.0
            azimuth = 360.0 - OpenStudio::radToDeg(OpenStudio::getAngle(site_outward_normal, north))
          else
            azimuth = OpenStudio::radToDeg(OpenStudio::getAngle(site_outward_normal, north))
          end
        end
        #TODO modify to work for buildings in the southern hemisphere?
        if (azimuth >= 315.0 || azimuth < 45.0)
          facade = "4-North"
        elsif (azimuth >= 45.0 && azimuth < 135.0)
          facade = "3-East"
        elsif (azimuth >= 135.0 && azimuth < 225.0)
          facade = "1-South"
        elsif (azimuth >= 225.0 && azimuth < 315.0)
          facade = "2-West"
        else
          facade = "0-Up"
        end

        # Log the window properties to use when creating daylight sensors
        properties = {:facade => facade, :area_m2 => net_area_m2, :handle => sub_surface.handle, :head_height_m => head_height_m}
        windows[sub_surface] = properties
        
      end #next sub-surface
    end #next surface
  
    # TODO Determine the illuminance setpoint for the controls based on space type
    daylight_stpt_lux = 300
    # space_name = space.name.get
    # daylight_stpt_lux = nil
    # if space_name.match(/post-office/i)# Post Office 500 Lux
      # daylight_stpt_lux = 500
    # elsif space_name.match(/medical-office/i)# Medical Office 3000 Lux
      # daylight_stpt_lux = 3000
    # elsif space_name.match(/office/i)# Office 500 Lux
      # daylight_stpt_lux = 500
    # elsif space_name.match(/education/i)# School 500 Lux
      # daylight_stpt_lux = 500
    # elsif space_name.match(/retail/i)# Retail 1000 Lux
      # daylight_stpt_lux = 1000
    # elsif space_name.match(/warehouse/i)# Warehouse 200 Lux
      # daylight_stpt_lux = 200
    # elsif space_name.match(/hotel/i)# Hotel 300 Lux
      # daylight_stpt_lux = 300
    # elsif space_name.match(/multifamily/i)# Apartment 200 Lux
      # daylight_stpt_lux = 200
    # elsif space_name.match(/courthouse/i)# Courthouse 300 Lux
      # daylight_stpt_lux = 300
    # elsif space_name.match(/library/i)# Library 500 Lux
      # daylight_stpt_lux = 500
    # elsif space_name.match(/community-center/i)# Community Center 300 Lux
      # daylight_stpt_lux = 300
    # elsif space_name.match(/senior-center/i)# Senior Center 1000 Lux
      # daylight_stpt_lux = 1000
    # elsif space_name.match(/city-hall/i)# City Hall 500 Lux
      # daylight_stpt_lux = 500
    # else
      # OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "Space #{space_name} is an unknown space type, assuming office and 300 Lux daylight setpoint")
      # daylight_stpt_lux = 300
    # end    
    
    # Get the zone that the space is in
    zone = self.thermalZone
    if zone.empty?
      OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Space", "Space #{self.name.get} has no thermal zone")
    else
      zone = zone.get
    end    
    
    # Sort by priority; first by facade, then by area
    sorted_windows = windows.sort_by { |window, vals| [vals[:facade], vals[:area]] }
    
    puts "Sorted windows = #{sorted_windows}"
    return true
    
    #primary sensor controlled fraction
    pri_daylight_window_info = sorted_daylight_windows[0][1]
    pri_daylight_area = pri_daylight_window_info[:daylight_area_m2]
    pri_ctrl_frac = pri_daylight_area/space.floorArea
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "primary daylighting control fraction = #{pri_ctrl_frac}")
    
    #secondary sensor controlled fraction
    sec_daylight_window_info = nil
    sec_ctrl_frac = nil
    if sorted_daylight_windows.size > 1
      sec_daylight_window_info = sorted_daylight_windows[1][1]
      sec_daylight_area = sec_daylight_window_info[:daylight_area_m2]
      sec_ctrl_frac = sec_daylight_area/space.floorArea
      # Check to avoid making the total of pri and sec control fraction more than 1-South
      if (pri_ctrl_frac + sec_ctrl_frac) > 1
        sec_ctrl_frac = 1 - pri_ctrl_frac
      end
      OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "secondary daylighting control fraction = #{sec_ctrl_frac}")
    end    
    
    # Add the required controls
    case vintage
    when  'DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007'
    
      # Do nothing, no daylighting controls required
    
    when '90.1-2010'
      
      # Divide the primary daylit fraction into 2 pieces
      # and assign to two separate sensors.
      
      
    when '90.1-2013'
    
      if requires_toplighting_control && requires_pri_sidelighting_control && requires_sec_sidelighting_control
        # First sensor under biggest skylight, controls 
        #pri_daylight_window_info = sorted_daylight_windows[0][1]
      elsif requires_pri_sidelighting_control && requires_sec_sidelighting_control
      
      elsif requires_pri_sidelighting_control
      
      else
        # Warn
        # Unexpected combo requires_toplighting_control = #{requires_toplighting_control}, requires_pri_sidelighting_control = #{requires_pri_sidelighting_control}, requires_sec_sidelighting_control = #{requires_sec_sidelighting_control}."
      end
    
    end # End of vintage case statement    
    
    
    
    
    
    
    
  
  
  end
  
end
