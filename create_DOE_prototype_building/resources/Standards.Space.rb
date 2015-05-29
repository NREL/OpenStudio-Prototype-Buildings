
# open the class to add methods to apply HVAC efficiency standards
class OpenStudio::Model::Space
  
  # Returns a hash of values for the daylighted areas in the space.
  # {toplighted_area, primary_sidelighted_area, secondary_sidelighted_area, total_window_area, total_skylight_area}
  # Debugging input will  daylight 
  # areas added to the model as surfaces.
  # Yellow = toplighted area
  # Red = primary sidelighted area
  # Blue = secondary sidelighted area
  # Light Blue = floor
  def daylighted_areas(vintage, draw_daylight_areas_for_debugging = false)

    # A series of methods to modify polygons.  Most are 
    # wrappers of native OpenStudio methods, but with
    # workarounds for known issues or limitations.

    # Check the z coordinates of a polygon
    def check_z_zero(polygons, name, space)
      fails = []
      errs = 0
      polygons.each do |polygon|
        #OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Space", "Checking z=0: #{name} => #{polygon.to_s.gsub(/\[|\]/,'|')}.")
        polygon.each do |vertex|
          #clsss << vertex.class
          unless vertex.z == 0.0
            errs += 1
            fails << vertex.z
          end
        end
      end
      #OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Space", "Checking z=0: #{name} => #{clsss.uniq.to_s.gsub(/\[|\]/,'|')}.")
      if errs > 0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "***FAIL*** #{space} z=0 failed for #{errs} vertices in #{name}; #{fails.join(', ')}.")
      end
    end
    
    # A method to convert an array of arrays to
    # an array of OpenStudio::Point3ds.
    def ruby_polygons_to_point3d_z_zero(ruby_polygons)
    
      # Convert the final polygons back to OpenStudio
      os_polygons = []
      ruby_polygons.each do |ruby_polygon|
        os_polygon = []
        ruby_polygon.each do |vertex|
          vertex = OpenStudio::Point3d.new(vertex[0], vertex[1], 0.0) # Set z to hard-zero instead of vertex[2]
          os_polygon << vertex
        end
        os_polygons << os_polygon
      end
      
      return os_polygons
      
    end
    
    # A method to zero-out the z vertex of an array of polygons
    def polygons_set_z(polygons, new_z)
    
      #puts "### #{polygons}"
    
      # Convert the final polygons back to OpenStudio
      new_polygons = []
      polygons.each do |polygon|
        new_polygon = []
        polygon.each do |vertex|
          new_vertex = OpenStudio::Point3d.new(vertex.x, vertex.y, new_z) # Set z to hard-zero instead of vertex[2]
          new_polygon << new_vertex
        end
        new_polygons << new_polygon
      end
      
      return new_polygons
      
    end    
    
    # A method to returns the number of duplicate vertices in a polygon.
    # TODO does not actually wor
    def find_duplicate_vertices(ruby_polygon, tol = 0.001)
    
      puts "***"
      duplicates = []
      
      combos = ruby_polygon.combination(2).to_a
      puts "########{combos.size}"
      combos.each do |i, j|
        
        i_vertex = OpenStudio::Point3d.new(i[0], i[1], i[2])
        j_vertex = OpenStudio::Point3d.new(j[0], j[1], j[2])
        
        distance = OpenStudio.getDistance(i_vertex, j_vertex)
        puts "------- #{i.to_s} to #{j.to_s} = #{distance}"
        if distance < tol
          duplicates << i
        end
        
      end
      
      return duplicates
    
    end
    
    # Subtracts one array of polygons from the next,
    # returning an array of resulting polygons.
    def a_polygons_minus_b_polygons(a_polygons, b_polygons, a_name, b_name)
      
      final_polygons_ruby = []

      OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "#{a_polygons.size} #{a_name} minus #{b_polygons.size} #{b_name}")
      
      # Don't try to subtract anything if either set is empty
      if a_polygons.size == 0
        OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---#{a_name} - #{b_name}: #{a_name} contains no polygons.")
        return polygons_set_z(a_polygons, 0.0)
      elsif b_polygons.size == 0
        OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---#{a_name} - #{b_name}: #{b_name} contains no polygons.")
        return polygons_set_z(a_polygons, 0.0) 
      end
      
      # Loop through all a polygons, and for each one,
      # subtract all the b polygons.
      a_polygons.each do |a_polygon|
        
        # Translate the polygon to plain arrays
        a_polygon_ruby = []
        a_polygon.each do |vertex|
          a_polygon_ruby << [vertex.x, vertex.y, vertex.z]
        end
        
        # TODO Skip really small polygons
        # reduced_b_polygons = []
        # b_polygons.each do |b_polygon|
          # next
        # end
        
        # Perform the subtraction
        a_minus_b_polygons = OpenStudio.subtract(a_polygon, b_polygons, 0.01)      
        
        # Translate the resulting polygons to plain ruby arrays
        a_minus_b_polygons_ruby = []
        num_small_polygons = 0
        a_minus_b_polygons.each do |a_minus_b_polygon|
          
          # Drop any super small or zero-vertex polygons resulting from the subtraction          
          area = OpenStudio.getArea(a_minus_b_polygon)
          if area.is_initialized
            if area.get < 0.5 # 5 square feet
              num_small_polygons += 1
              next
            end
          else
            num_small_polygons += 1
            next
          end  
          
          # Translate polygon to ruby array
          a_minus_b_polygon_ruby = []
          a_minus_b_polygon.each do |vertex|
            a_minus_b_polygon_ruby << [vertex.x, vertex.y, vertex.z]
          end
          
          a_minus_b_polygons_ruby << a_minus_b_polygon_ruby  

        end
        
        if num_small_polygons > 0
          OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---Dropped #{num_small_polygons} small or invalid polygons resulting from subtraction.")
        end     
        
        # Remove duplicate polygons
        unique_a_minus_b_polygons_ruby = a_minus_b_polygons_ruby.uniq

        OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---Remove duplicates: #{a_minus_b_polygons_ruby.size} ==> #{unique_a_minus_b_polygons_ruby.size}")

        # TODO bug workaround?
        # If the result includes the a polygon, the a polygon
        # was unchanged; only include that polgon and throw away the other junk?/bug? polygons.
        # If the result does not include the a polygon, the a polygon was
        # split into multiple pieces.  Keep all those pieces.
        if unique_a_minus_b_polygons_ruby.include?(a_polygon_ruby)
          if unique_a_minus_b_polygons_ruby.size == 1
            final_polygons_ruby.concat([a_polygon_ruby])
            OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---includes only original polygon, keeping that one")
          else
            # Remove the original polygon
            unique_a_minus_b_polygons_ruby.delete(a_polygon_ruby)
            final_polygons_ruby.concat(unique_a_minus_b_polygons_ruby)
            OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---includes the original and others; keeping all other polygons")
          end
        else
          final_polygons_ruby.concat(unique_a_minus_b_polygons_ruby)
          OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---does not include original, keeping all resulting polygons") 
        end
          
      end  
      
      # Remove duplicate polygons again
      unique_final_polygons_ruby = final_polygons_ruby.uniq

      # TODO remove this workaround
      # Split any polygons that are joined by a line into two separate
      # polygons.  Do this by finding duplicate 
      # unique_final_polygons_ruby.each do |unique_final_polygon_ruby|
        # next if unique_final_polygon_ruby.size == 4 # Don't check 4-sided polygons
        # dupes = find_duplicate_vertices(unique_final_polygon_ruby)
        # if dupes.size > 0
          # OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Space", "---Two polygons attached by line = #{unique_final_polygon_ruby.to_s.gsub(/\[|\]/,'|')}")
        # end
      # end

      OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---Remove final duplicates: #{final_polygons_ruby.size} ==> #{unique_final_polygons_ruby.size}")

      OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---#{a_name} minus #{b_name} = #{unique_final_polygons_ruby.size} polygons.")
      
      # Convert the final polygons back to OpenStudio      
      unique_final_polygons = ruby_polygons_to_point3d_z_zero(unique_final_polygons_ruby)
        
      return unique_final_polygons
      
    end

    # Wrapper to catch errors in joinAll method
    # [utilities.geometry.joinAll] <1> Expected polygons to join together
    def join_polygons(polygons, tol, name)
    
      OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "Joining #{name} from #{self.name}")
  
      combined_polygons = []
  
      # Don't try to combine an empty array of polygons
      if polygons.size == 0
        OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---#{name} contains no polygons, not combining.")
        return combined_polygons
      end
  
      # Open a log
      msg_log = OpenStudio::StringStreamLogSink.new
      msg_log.setLogLevel(OpenStudio::Info)
      
      # Combine the polygons
      combined_polygons = OpenStudio.joinAll(polygons, 0.01)

      # Count logged errors
      join_errs = 0
      inner_loop_errs = 0
      msg_log.logMessages.each do |msg|
        if /utilities.geometry/.match(msg.logChannel)
          if msg.logMessage.include?("Expected polygons to join together")
            join_errs += 1
          elsif msg.logMessage.include?("Union has inner loops")
            inner_loop_errs += 1
          end
        end
      end
     
      # TODO remove this workaround, which is tried if there
      # are any join errors.  This handles the case of polygons
      # that make an inner loop, the most common case being
      # when all 4 sides of a space have windows.
      # If an error occurs, attempt to join n-1 polygons,
      # then subtract the
      if join_errs > 0
        
        # Open a log
        msg_log_2 = OpenStudio::StringStreamLogSink.new
        msg_log_2.setLogLevel(OpenStudio::Info)
        
        first_polygon = polygons.first
        polygons = polygons.drop(1)
        
        combined_polygons_2 = OpenStudio.joinAll(polygons, 0.01)
      
        join_errs_2 = 0
        inner_loop_errs_2 = 0
        msg_log_2.logMessages.each do |msg|
          if /utilities.geometry/.match(msg.logChannel)
            if msg.logMessage.include?("Expected polygons to join together")
              join_errs_2 += 1
            elsif msg.logMessage.include?("Union has inner loops")
              inner_loop_errs_2 += 1
            end
          end
        end
      
        if join_errs_2 > 0 || inner_loop_errs_2 > 0
          OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "For #{self.name}, the workaround for joining polygons failed.")
        else

        # First polygon minus the already combined polygons
        first_polygon_minus_combined = a_polygons_minus_b_polygons([first_polygon], combined_polygons_2, 'first_polygon', 'combined_polygons_2')
      
        # Add the result back
        combined_polygons_2 += first_polygon_minus_combined
        combined_polygons = combined_polygons_2
        join_errs = 0
        inner_loop_errs = 0
        
        end
      end

      # Report logged errors to user
      if join_errs > 0
        OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "For #{self.name}, #{join_errs} of #{polygons.size} #{name} were not joined properly due to limitations of the geometry calculation methods.  The resulting daylighted areas will be smaller than they should be.")
      end
      if inner_loop_errs > 0
        OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "For #{self.name}, #{inner_loop_errs} of #{polygons.size} #{name} were not joined properly becasue the joined polygons have an internal hole.  The resulting daylighted areas will be smaller than they should be.")
      end

      OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---Joined #{polygons.size} #{name} into #{combined_polygons.size} polygons.")
      
      return combined_polygons
        
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
        
    # Returns an array of resulting polygons.
    # Assumes that a_polygons don't overlap one another, and that b_polygons don't overlap one another
    def area_a_polygons_overlap_b_polygons(a_polygons, b_polygons, a_name, b_name)
    
      OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "#{a_polygons.size} #{a_name} overlaps #{b_polygons.size} #{b_name}")
    
      overlap_area = 0

      # Don't try anything if either set is empty
      if a_polygons.size == 0
        OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---#{a_name} overlaps #{b_name}: #{a_name} contains no polygons.")
        return overlap_area    
      elsif b_polygons.size == 0
        OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---#{a_name} overlaps #{b_name}: #{b_name} contains no polygons.")
        return overlap_area 
      end      
      
      # Loop through each base surface
      b_polygons.each do |b_polygon|

        # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "---b polygon = #{b_polygon_ruby.to_s.gsub(/\[|\]/,'|')}") 
    
        # Loop through each overlap surface and determine if it overlaps this base surface
        a_polygons.each do |a_polygon|

          # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "------a polygon = #{a_polygon_ruby.to_s.gsub(/\[|\]/,'|')}")  
          
          # If the entire a polygon is within the b polygon, count 100% of the area
          # as overlapping and remove a polygon from the list
          if OpenStudio.within(a_polygon, b_polygon, 0.01)

            OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---------a overlaps b ENTIRELY.")
            
            area = OpenStudio.getArea(a_polygon)
            if area.is_initialized
              overlap_area += area.get
              next
            else
              OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "Could not determine the area of #{a_polygon.to_s.gsub(/\[|\]/,'|')} in #{a_name}; #{a_name} overlaps #{b_name}.")
            end
            
          # If part of a polygon overlaps b polygon, determine the
          # original area of polygon b, subtract polygon a from b, 
          # then add the difference in area to the total.
          elsif OpenStudio.intersects(a_polygon, b_polygon, 0.01)
            
            OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---------a overlaps b PARTIALLY.")
            
            # Get the initial area
            area_initial = 0
            area = OpenStudio.getArea(b_polygon)
            if area.is_initialized
              area_initial = area.get
            else
              OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "Could not determine the area of #{a_polygon.to_s.gsub(/\[|\]/,'|')} in #{a_name}; #{a_name} overlaps #{b_name}.")
            end
            
            # Perform the subtraction
            b_minus_a_polygons = OpenStudio.subtract(b_polygon, [a_polygon], 0.01)
            
            # Get the final area
            area_final = 0
            b_minus_a_polygons.each do |polygon|
              # Skip polygons that have no vertices
              # resulting from the subtraction.
              if polygon.size == 0
                OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "Zero-vertex polygon resulting from #{b_polygon.to_s.gsub(/\[|\]/,'|')} minus #{a_polygon.to_s.gsub(/\[|\]/,'|')}.")
                next
              end
              # Find the area of real polygons
              area = OpenStudio.getArea(polygon)
              if area.is_initialized
                area_final += area.get
              else
                OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "Could not determine the area of #{polygon.to_s.gsub(/\[|\]/,'|')} in #{a_name}; #{a_name} overlaps #{b_name}.")
              end
            end
      
            # Add the diference to the total
            overlap_area += (area_initial - area_final)

          # There is no overlap
          else
            
            OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---------a does not overlaps b at all.")
            
          end

        end
      
      end
              
      return overlap_area
      
    end
        
    
    
    
    ### Begin the actual daylight area calculations ### 

    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "For #{self.name}, calculating daylighted areas.")
    
    result = {'toplighted_area' => nil,
              'primary_sidelighted_area' => nil,
              'secondary_sidelighted_area' => nil,
              'total_window_area' => nil,
              'total_skylight_area' => nil
              }
    
    total_window_area = 0
    total_skylight_area = 0
    
    # Make rendering colors to help debug visually
    if draw_daylight_areas_for_debugging
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
    end
    
    # Move the polygon up slightly for viewability in sketchup
    up_translation_flr = OpenStudio::createTranslation(OpenStudio::Vector3d.new(0, 0, 0.05))
    up_translation_top = OpenStudio::createTranslation(OpenStudio::Vector3d.new(0, 0, 0.1))
    up_translation_pri = OpenStudio::createTranslation(OpenStudio::Vector3d.new(0, 0, 0.1))
    up_translation_sec = OpenStudio::createTranslation(OpenStudio::Vector3d.new(0, 0, 0.1))
    
    # Get the space's surface group's transformation
    @space_transformation = self.transformation
    
    # Record a floor in the space for later use
    floor_surface = nil  
    
    # Record all floor polygons
    floor_polygons = []
    floor_z = 0.0
    self.surfaces.each do |surface|
      if surface.surfaceType == "Floor"
        floor_surface = surface
        floor_z = surface.vertices[0].z
        # floor_polygons << surface.vertices
        # Hard-set the z for the floor to zero    
        new_floor_polygon = []
        surface.vertices.each do |vertex|
          new_floor_polygon << OpenStudio::Point3d.new(vertex.x, vertex.y, 0.0)       
        end
        floor_polygons << new_floor_polygon
      end
    end
    
    # Make sure there is one floor surface
    if floor_surface.nil?
      OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Space", "Could not find a floor in space #{self.name.get}, cannot determine daylighted areas.")
      return result
    end
    
    # Make a set of vertices representing each subsurfaces sidelighteding area
    # and fold them all down onto the floor of the self.
    toplit_polygons = []
    pri_sidelit_polygons = []
    sec_sidelit_polygons = []
    self.surfaces.sort.each do |surface|
      if surface.outsideBoundaryCondition == "Outdoors" && surface.surfaceType == "Wall"
        
        # TODO stop skipping non-vertical walls
        surface_normal = surface.outwardNormal
        surface_normal_z = surface_normal.z
        unless surface_normal_z.abs < 0.001 
          if surface.subSurfaces.size > 0
            OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "Cannot currently handle non-vertical walls; skipping windows on #{surface.name} in #{self.name}.")
            next
          end
        end
        
        surface.subSurfaces.sort.each do |sub_surface|
          next unless sub_surface.outsideBoundaryCondition == "Outdoors" && (sub_surface.subSurfaceType == "FixedWindow" || sub_surface.subSurfaceType == "OperableWindow")
          
          #OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "***#{sub_surface.name}***"
          total_window_area += sub_surface.netArea
          
          # Find the head height and sill height of the window
          vertex_heights_above_floor = []
          sub_surface.vertices.each do |vertex|
            vertex_on_floorplane = floor_surface.plane.project(vertex)
            vertex_heights_above_floor << (vertex - vertex_on_floorplane).length
          end
          sill_height_m = vertex_heights_above_floor.min
          head_height_m = vertex_heights_above_floor.max
          #OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "head height = #{head_height_m.round(2)}m, sill height = #{sill_height_m.round(2)}m")
            
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
          #OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "Adding #{extra_width_m.round(2)}m to the width for the sidelighted area.")
          
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
          #OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "min_x_val = #{min_x_val.round(2)}, max_x_val = #{max_x_val.round(2)}")
          
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
            new_z = 0.0

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
            new_z = 0.0

            # Make the new vertex
            new_vertex = OpenStudio::Point3d.new(new_x, new_y, new_z)
            sec_sidelit_sub_polygon << new_vertex     
               
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

          # Put the polygon vertices into counterclockwise order
          pri_sidelit_sub_polygon = pri_sidelit_sub_polygon.reverse
          sec_sidelit_sub_polygon = sec_sidelit_sub_polygon.reverse
      
          # Add these polygons to the list
          pri_sidelit_polygons << pri_sidelit_sub_polygon
          sec_sidelit_polygons << sec_sidelit_sub_polygon
          
        end # Next subsurface
      elsif surface.outsideBoundaryCondition == "Outdoors" && surface.surfaceType == "RoofCeiling"
        
        # TODO stop skipping non-horizontal roofs
        surface_normal = surface.outwardNormal
        straight_upward = OpenStudio::Vector3d.new(0, 0, 1)
        unless surface_normal.to_s == straight_upward.to_s
          if surface.subSurfaces.size > 0
            OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "Cannot currently handle non-horizontal roofs; skipping skylights on #{surface.name} in #{self.name}.")
            OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---Surface #{surface.name} has outward normal of #{surface_normal.to_s.gsub(/\[|\]/,'|')}; up is #{straight_upward.to_s.gsub(/\[|\]/,'|')}.")
            next
          end
        end
        
        surface.subSurfaces.each do |sub_surface|
          next unless sub_surface.outsideBoundaryCondition == "Outdoors" && sub_surface.subSurfaceType == "Skylight"
          
          #OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "***#{sub_surface.name}***")
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
            new_z = 0.0

            # Make the new vertex
            new_vertex = OpenStudio::Point3d.new(new_x, new_y, new_z)
            toplit_sub_polygon << new_vertex
            
          end
          
          # Realign the vertices with space coordinate system
          toplit_sub_polygon = face_transform * toplit_sub_polygon

          # Put the polygon vertices into counterclockwise order
          toplit_sub_polygon = toplit_sub_polygon.reverse

          # Add these polygons to the list
          toplit_polygons << toplit_sub_polygon
          
        end # Next subsurface 
      
      end # End if outdoor wall or roofceiling
    
    end # Next surface

    # Set z=0 for all the polygons so that intersection will work
    toplit_polygons = polygons_set_z(toplit_polygons, 0.0)
    pri_sidelit_polygons = polygons_set_z(pri_sidelit_polygons, 0.0)
    sec_sidelit_polygons = polygons_set_z(sec_sidelit_polygons, 0.0)
    
    # Check the initial polygons
    check_z_zero(floor_polygons, 'floor_polygons', self.name.get)
    check_z_zero(toplit_polygons, 'toplit_polygons', self.name.get)
    check_z_zero(pri_sidelit_polygons, 'pri_sidelit_polygons', self.name.get)
    check_z_zero(sec_sidelit_polygons, 'sec_sidelit_polygons', self.name.get)
    
    # Join, then subtract
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "***Joining polygons***")
 
    # Join toplighted polygons into a single set
    combined_toplit_polygons = join_polygons(toplit_polygons, 0.01, 'toplit_polygons')
    
    # Join primary sidelighted polygons into a single set
    combined_pri_sidelit_polygons = join_polygons(pri_sidelit_polygons, 0.01, 'pri_sidelit_polygons')
    
    # Join secondary sidelighted polygons into a single set
    combined_sec_sidelit_polygons = join_polygons(sec_sidelit_polygons, 0.01, 'sec_sidelit_polygons')
    
    # Join floor polygons into a single set
    combined_floor_polygons = join_polygons(floor_polygons, 0.01, 'floor_polygons')
    
    # Check the joined polygons
    check_z_zero(combined_floor_polygons, 'combined_floor_polygons', self.name.get)
    check_z_zero(combined_toplit_polygons, 'combined_toplit_polygons', self.name.get)
    check_z_zero(combined_pri_sidelit_polygons, 'combined_pri_sidelit_polygons', self.name.get)
    check_z_zero(combined_sec_sidelit_polygons, 'combined_sec_sidelit_polygons', self.name.get)    

    # Make a new surface for each of the resulting polygons to visually inspect it
    # OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "***Making Surfaces to view in SketchUp***")

    # combined_toplit_polygons.each do |polygon|
      # dummy_space = OpenStudio::Model::Space.new(model)
      # polygon = up_translation_top * polygon
      # daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
      # daylt_surf.setConstruction(toplit_construction)
      # daylt_surf.setSpace(dummy_space)
      # daylt_surf.setName("Top")
    # end  
    
    # combined_pri_sidelit_polygons.each do |polygon|
      # dummy_space = OpenStudio::Model::Space.new(model)
      # polygon = up_translation_pri * polygon
      # daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
      # daylt_surf.setConstruction(pri_sidelit_construction)
      # daylt_surf.setSpace(dummy_space)
      # daylt_surf.setName("Pri")    
    # end
    
    # combined_sec_sidelit_polygons.each do |polygon|
      # dummy_space = OpenStudio::Model::Space.new(model)
      # polygon = up_translation_sec * polygon
      # daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
      # daylt_surf.setConstruction(sec_sidelit_construction)
      # daylt_surf.setSpace(dummy_space)
      # daylt_surf.setName("Sec")
    # end

    # combined_floor_polygons.each do |polygon|
      # dummy_space = OpenStudio::Model::Space.new(model)
      # polygon = up_translation_flr * polygon
      # daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
      # daylt_surf.setConstruction(flr_construction)
      # daylt_surf.setSpace(dummy_space)
      # daylt_surf.setName("Flr")
    # end  
    
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "***Subtracting overlapping areas***")

    # Subtract lower-priority daylighting areas from higher priority ones
    pri_minus_top_polygons = a_polygons_minus_b_polygons(combined_pri_sidelit_polygons, combined_toplit_polygons, 'combined_pri_sidelit_polygons', 'combined_toplit_polygons')
    
    sec_minus_top_polygons = a_polygons_minus_b_polygons(combined_sec_sidelit_polygons, combined_toplit_polygons, 'combined_sec_sidelit_polygons', 'combined_toplit_polygons')
    
    sec_minus_top_minus_pri_polygons = a_polygons_minus_b_polygons(sec_minus_top_polygons, combined_pri_sidelit_polygons, 'sec_minus_top_polygons', 'combined_pri_sidelit_polygons')

    # Check the subtracted polygons
    check_z_zero(pri_minus_top_polygons, 'pri_minus_top_polygons', self.name.get)
    check_z_zero(sec_minus_top_polygons, 'sec_minus_top_polygons', self.name.get)
    check_z_zero(sec_minus_top_minus_pri_polygons, 'sec_minus_top_minus_pri_polygons', self.name.get)
      
    # Make a new surface for each of the resulting polygons to visually inspect it.
    # First reset the z so the surfaces show up on the correct plane.
    if draw_daylight_areas_for_debugging

      combined_toplit_polygons_at_floor = polygons_set_z(combined_toplit_polygons, floor_z)
      pri_minus_top_polygons_at_floor = polygons_set_z(pri_minus_top_polygons, floor_z)
      sec_minus_top_minus_pri_polygons_at_floor = polygons_set_z(sec_minus_top_minus_pri_polygons, floor_z)
      combined_floor_polygons_at_floor = polygons_set_z(combined_floor_polygons, floor_z)

      OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "***Making Surfaces to view in SketchUp***")
      dummy_space = OpenStudio::Model::Space.new(model)
      
      combined_toplit_polygons_at_floor.each do |polygon|
        polygon = up_translation_top * polygon
        polygon = @space_transformation * polygon
        daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
        daylt_surf.setConstruction(toplit_construction)
        daylt_surf.setSpace(dummy_space)
        daylt_surf.setName("Top")
      end  

      pri_minus_top_polygons_at_floor.each do |polygon|
        polygon = up_translation_pri * polygon
        polygon = @space_transformation * polygon
        daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
        daylt_surf.setConstruction(pri_sidelit_construction)
        daylt_surf.setSpace(dummy_space)
        daylt_surf.setName("Pri")    
      end     

      sec_minus_top_minus_pri_polygons_at_floor.each do |polygon|
        polygon = up_translation_sec * polygon
        polygon = @space_transformation * polygon
        daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
        daylt_surf.setConstruction(sec_sidelit_construction)
        daylt_surf.setSpace(dummy_space)
        daylt_surf.setName("Sec")
      end     
      
      combined_floor_polygons_at_floor.each do |polygon|
        polygon = up_translation_flr * polygon
        polygon = @space_transformation * polygon
        daylt_surf = OpenStudio::Model::Surface.new(polygon, model)
        daylt_surf.setConstruction(flr_construction)
        daylt_surf.setSpace(dummy_space)
        daylt_surf.setName("Flr")
      end
    end
    
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "***Calculating Daylighted Areas***")

    # Get the total floor area
    total_floor_area_m2 = total_area_of_polygons(combined_floor_polygons)
    total_floor_area_ft2 = OpenStudio.convert(total_floor_area_m2, 'm^2', 'ft^2').get
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "total_floor_area_ft2 = #{total_floor_area_ft2.round(1)}")
    
    # Toplighted area
    toplighted_area_m2 = area_a_polygons_overlap_b_polygons(combined_toplit_polygons, combined_floor_polygons, 'combined_toplit_polygons', 'combined_floor_polygons')
    
    # Primary sidelighted area
    primary_sidelighted_area_m2 = area_a_polygons_overlap_b_polygons(pri_minus_top_polygons, combined_floor_polygons, 'pri_minus_top_polygons', 'combined_floor_polygons')
    
    # Secondary sidelighted area
    secondary_sidelighted_area_m2 = area_a_polygons_overlap_b_polygons(sec_minus_top_minus_pri_polygons, combined_floor_polygons, 'sec_minus_top_minus_pri_polygons', 'combined_floor_polygons')
      
    # Convert to IP for displaying
    toplighted_area_ft2 = OpenStudio.convert(toplighted_area_m2, 'm^2', 'ft^2').get
    primary_sidelighted_area_ft2 = OpenStudio.convert(primary_sidelighted_area_m2, 'm^2', 'ft^2').get
    secondary_sidelighted_area_ft2 = OpenStudio.convert(secondary_sidelighted_area_m2, 'm^2', 'ft^2').get
      
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "toplighted_area_ft2 = #{toplighted_area_ft2.round(1)}")
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "primary_sidelighted_area_ft2 = #{primary_sidelighted_area_ft2.round(1)}")
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "secondary_sidelighted_area_ft2 = #{secondary_sidelighted_area_ft2.round(1)}")    
    
    result['toplighted_area'] = toplighted_area_m2
    result['primary_sidelighted_area'] = primary_sidelighted_area_m2
    result['secondary_sidelighted_area'] = secondary_sidelighted_area_m2
    result['total_window_area'] = total_window_area
    result['total_skylight_area'] = total_skylight_area
    
    return result
    
  end

  # Returns the sidelighting effective aperture
  def sidelightingEffectiveAperture(primary_sidelighted_area)
    
    # sidelighting_effective_aperture = E(window area * window VT) / primary_sidelighted_area
    sidelighting_effective_aperture = 9999
    
    num_sub_surfaces = 0
    
    # Loop through all windows and add up area * VT
    sum_window_area_times_vt = 0
    construction_name_to_vt_map = {}
    self.surfaces.each do |surface|
      next unless surface.outsideBoundaryCondition == "Outdoors" && surface.surfaceType == "Wall"
      surface.subSurfaces.each do |sub_surface|
        next unless sub_surface.outsideBoundaryCondition == "Outdoors" && (sub_surface.subSurfaceType == "FixedWindow" || sub_surface.subSurfaceType == "OperableWindow")
        
        num_sub_surfaces += 1
        
        # Get the area
        area_m2 = sub_surface.netArea
        
        # Get the window construction name
        construction_name = nil
        construction = sub_surface.construction
        if construction.is_initialized
          construction_name = construction.get.name.get.upcase
        else
          OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "For #{self.name}, could not determine construction for #{sub_surface.name}, will not be included in  sidelightingEffectiveAperture calculation.")
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
              OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Model", "VT row ID not found for construction: #{construction_name}, #{sub_surface.name} will not be included in  sidelightingEffectiveAperture calculation.")
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
              vt = nil
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
          OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "For #{self.name}, could not determine VLT for #{construction_name}, will not be included in sidelighting effective aperture caluclation.")
          vt = 0
        end
  
        sum_window_area_times_vt += area_m2 * vt
  
      end
    end
    
    # Calculate the effective aperture
    if sum_window_area_times_vt == 0
      sidelighting_effective_aperture = 9999
      if num_sub_surfaces > 0
        OpenStudio::logFree(OpenStudio::Warn, 'openstudio.standards.Space', "#{self.name} has no windows where VLT could be determined, sidelighting effective aperture will be higher than it should.")
      end
    else
      sidelighting_effective_aperture = sum_window_area_times_vt/primary_sidelighted_area
    end
 
    OpenStudio::logFree(OpenStudio::Debug, 'openstudio.standards.Space', "For #{self.name} sidelighting effective aperture = #{sidelighting_effective_aperture.round(4)}.")
 
    return sidelighting_effective_aperture
    
  end

  # Returns the sidelighting effective aperture
  def skylightEffectiveAperture(toplighted_area)
    
    # skylight_effective_aperture = E(0.85 * skylight area * skylight VT * WF) / toplighted_area
    skylight_effective_aperture = 0.0
    
    num_sub_surfaces = 0
    
    # Assume that well factor (WF) is 0.9 (all wells are less than 2 feet deep)
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "Assuming that all skylight wells are less than 2 feet deep to calculate skylight effective aperture.")
    wf = 0.9
    
    # Loop through all windows and add up area * VT
    sum_85pct_times_skylight_area_times_vt_times_wf = 0
    construction_name_to_vt_map = {}
    self.surfaces.each do |surface|
      next unless surface.outsideBoundaryCondition == "Outdoors" && surface.surfaceType == "RoofCeiling"
      surface.subSurfaces.each do |sub_surface|
        next unless sub_surface.outsideBoundaryCondition == "Outdoors" && sub_surface.subSurfaceType == "Skylight"
        
        num_sub_surfaces += 1
        
        # Get the area
        area_m2 = sub_surface.netArea
        
        # Get the window construction name
        construction_name = nil
        construction = sub_surface.construction
        if construction.is_initialized
          construction_name = construction.get.name.get.upcase
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
              OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Model", "Data not found for query: #{row_query}")
              next
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
              vt = nil
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
          OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "For #{self.name}, could not determine VLT for #{construction_name}, will not be included in skylight effective aperture caluclation.")
          vt = 0
        end

        sum_85pct_times_skylight_area_times_vt_times_wf += 0.85 * area_m2 * vt * wf
  
      end
    end
    
    # Calculate the effective aperture
    if sum_85pct_times_skylight_area_times_vt_times_wf == 0
      skylight_effective_aperture = 9999
      if num_sub_surfaces > 0
        OpenStudio::logFree(OpenStudio::Warn, 'openstudio.standards.Space', "#{self.name} has no skylights where VLT could be determined, skylight effective aperture will be higher than it should.")
      end
    else
      skylight_effective_aperture = sum_85pct_times_skylight_area_times_vt_times_wf/toplighted_area
    end
 
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.standards.Space', "#{self.name} skylight effective aperture = #{skylight_effective_aperture}.")
 
    return skylight_effective_aperture
    
  end
  
  # Adds daylighting controls (sidelighting and toplighting) per the standard
  # remove_existing_controls = true will remove existing controls then add new ones
  # draw_daylight_areas_for_debugging = true will add daylighting 
  # areas added to the model as surfaces.
  # Yellow = toplighted area
  # Red = primary sidelighted area
  # Blue = secondary sidelighted area
  # Light Blue = floor
  def addDaylightingControls(vintage, remove_existing_controls, draw_daylight_areas_for_debugging = false)
  
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "******For #{self.name}, adding daylight controls.")

    # Check for existing daylighting controls
    # and remove if specified in the input
    existing_daylighting_controls = self.daylightingControls
    if existing_daylighting_controls.size > 0
      if remove_existing_controls
        existing_daylighting_controls.each do |dc|
          dc.remove
        end
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, removed #{existing_daylighting_controls.size} existing daylight controls before adding new controls.")
      else
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, daylight controls were already present, no additional controls added.")
        return false
      end
    end

    areas = nil
    
    req_top_ctrl = false
    req_pri_ctrl = false
    req_sec_ctrl = false
    
    # Get the area of the space
    space_area_m2 = self.floorArea
    
    # Get the LPD of the space
    space_lpd_w_per_m2 = self.lightingPowerPerFloorArea
    
    # Determine the type of control required
    case vintage
    when  'DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007'
    
      # Do nothing, no daylighting controls required
      OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, daylighting control not required by this standard.")
      return false
    
    when '90.1-2010'
      
      req_top_ctrl = true
      req_pri_ctrl = true
      
      areas = self.daylighted_areas(vintage, draw_daylight_areas_for_debugging)
      
      # Sidelighting
      # Check if the primary sidelit area < 250 ft2
      if areas['primary_sidelighted_area'] == 0.0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, primary sidelighting control not required because primary sidelighted area = 0ft2 per 9.4.1.4.")
        req_pri_ctrl = false
      elsif areas['primary_sidelighted_area'] < OpenStudio.convert(250, 'ft^2', 'm^2').get
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, primary sidelighting control not required because primary sidelighted area < 250ft2 per 9.4.1.4.")
        req_pri_ctrl = false
      else     
        # Check effective sidelighted aperture
        sidelighted_effective_aperture = self.sidelightingEffectiveAperture(areas['primary_sidelighted_area'])
        if sidelighted_effective_aperture < 0.1
          OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, primary sidelighting control not required because sidelighted effective aperture < 0.1 per 9.4.1.4 Exception b.")
          req_pri_ctrl = false
        else
          # TODO Check the space type
          # if 
            # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, primary sidelighting control not required because space type is retail per 9.4.1.4 Exception c.")
            # req_pri_ctrl = false
          # end
        end
      end
      
      # Toplighting
      # Check if the toplit area < 900 ft2
      if areas['toplighted_area'] == 0.0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, toplighting control not required because toplighted area = 0ft2 per 9.4.1.5.")
        req_top_ctrl = false
      elsif areas['toplighted_area'] < OpenStudio.convert(900, 'ft^2', 'm^2').get
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, toplighting control not required because toplighted area < 900ft2 per 9.4.1.5.")
        req_top_ctrl = false
      else      
        # Check effective sidelighted aperture
        sidelighted_effective_aperture = self.skylightEffectiveAperture(areas['toplighted_area'])
        if sidelighted_effective_aperture < 0.006
          OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, toplighting control not required because skylight effective aperture < 0.006 per 9.4.1.5 Exception b.")
          req_top_ctrl = false
        else
          # TODO Check the climate zone.  Not required in CZ8 where toplit areas < 1500ft2
          # if 
            # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, toplighting control not required because space type is retail per 9.4.1.5 Exception c.")
            # req_top_ctrl = false
          # end
        end
      end
    
    when '90.1-2013'
    
      req_top_ctrl = true
      req_pri_ctrl = true
      req_sec_ctrl = true
      
      areas = self.daylighted_areas(vintage, draw_daylight_areas_for_debugging)
      
      # Primary Sidelighting
      # Check if the primary sidelit area contains less than 150W of lighting
      if areas['primary_sidelighted_area'] == 0.0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, primary sidelighting control not required because primary sidelighted area = 0ft2 per 9.4.1.1(e).")
        req_pri_ctrl = false
      elsif areas['primary_sidelighted_area'] * space_lpd_w_per_m2 < 150.0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, primary sidelighting control not required because less than 150W of lighting are present in the primary daylighted area per 9.4.1.1(e).")
        req_pri_ctrl = false
      else
        # Check the size of the windows
        if areas['total_window_area'] < 20.0
          OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, primary sidelighting control not required because there are less than 20ft2 of window per 9.4.1.1(e) Exception 2.")
          req_pri_ctrl = false
        else      
          # TODO Check the space type
          # if 
            # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, primary sidelighting control not required because space type is retail per 9.4.1.1(e) Exception c.")
            # req_pri_ctrl = false
          # end
        end
      end
      
      # Secondary Sidelighting
      # Check if the primary and secondary sidelit areas contains less than 300W of lighting
      if areas['secondary_sidelighted_area'] == 0.0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, secondary sidelighting control not required because secondary sidelighted area = 0ft2 per 9.4.1.1(e).")
        req_pri_ctrl = false      
      elsif (areas['primary_sidelighted_area'] + areas['secondary_sidelighted_area']) * space_lpd_w_per_m2 < 300
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, secondary sidelighting control not required because less than 300W of lighting are present in the combined primary and secondary daylighted areas per 9.4.1.1(e).")
        req_sec_ctrl = false
      else
        # Check the size of the windows
        if areas['total_window_area'] < 20
          OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, secondary sidelighting control not required because there are less than 20ft2 of window per 9.4.1.1(e) Exception 2.")
          req_sec_ctrl = false
        else      
          # TODO Check the space type
          # if 
            # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, primary sidelighting control not required because space type is retail per 9.4.1.1(e) Exception c.")
            # req_sec_ctrl = false
          # end
        end
      end

      # Toplighting
      # Check if the toplit area contains less than 150W of lighting
      if areas['toplighted_area'] == 0.0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, toplighting control not required because toplighted area = 0ft2 per 9.4.1.1(f).")
        req_pri_ctrl = false 
      elsif areas['toplighted_area'] * space_lpd_w_per_m2 < 150
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, toplighting control not required because less than 150W of lighting are present in the toplighted area per 9.4.1.1(f).")
        req_sec_ctrl = false
      else
        # TODO exception 2 for skylights with VT < 0.4
        # TODO exception 3 for CZ 8 where lighting < 200W
      end

    when 'AssetScore'
    
      # Same as 90.1-2010 but without effective aperture limits
      # to avoid needing to perform run to get VLT for layered windows.
    
      req_top_ctrl = true
      req_pri_ctrl = true
      
      areas = self.daylighted_areas(vintage, draw_daylight_areas_for_debugging)
      
      # Sidelighting
      # Check if the primary sidelit area < 250 ft2
      if areas['primary_sidelighted_area'] == 0.0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, primary sidelighting control not required because primary sidelighted area = 0ft2 per 9.4.1.4.")
        req_pri_ctrl = false
      elsif areas['primary_sidelighted_area'] < OpenStudio.convert(250, 'ft^2', 'm^2').get
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, primary sidelighting control not required because primary sidelighted area < 250ft2 per 9.4.1.4.")
        req_pri_ctrl = false
      end
      
      # Toplighting
      # Check if the toplit area < 900 ft2
      if areas['toplighted_area'] == 0.0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, toplighting control not required because toplighted area = 0ft2 per 9.4.1.5.")
        req_top_ctrl = false
      elsif areas['toplighted_area'] < OpenStudio.convert(900, 'ft^2', 'm^2').get
        OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, toplighting control not required because toplighted area < 900ft2 per 9.4.1.5.")
        req_top_ctrl = false     
      end    
      
    end # End of vintage case statement
    
    # Output the daylight control requirements
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "For #{vintage} #{self.name}, toplighting control required = #{req_top_ctrl}")
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "For #{vintage} #{self.name}, primary sidelighting control required = #{req_pri_ctrl}")
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "For #{vintage} #{self.name}, secondary sidelighting control required = #{req_sec_ctrl}")

    # Stop here if no lighting controls are required.
    # Do not put daylighting control points into the space.
    if !req_top_ctrl && !req_pri_ctrl && !req_sec_ctrl
      OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "For #{vintage} #{self.name}, no daylighting control is required.")
      return false
    end
    
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
    skylights = {}
    self.surfaces.each do |surface|
      next unless surface.outsideBoundaryCondition == "Outdoors" && (surface.surfaceType == "Wall" || surface.surfaceType == "RoofCeiling")
      
      # Skip non-vertical walls and non-horizontal roofs
      straight_upward = OpenStudio::Vector3d.new(0, 0, 1)
      surface_normal = surface.outwardNormal
      if surface.surfaceType == "Wall"
        # TODO stop skipping non-vertical walls
        unless surface_normal.z.abs < 0.001 
          if surface.subSurfaces.size > 0
            OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "Cannot currently handle non-vertical walls; skipping windows on #{surface.name} in #{self.name} for daylight sensor positioning.")
            next
          end
        end
      elsif surface.surfaceType == "RoofCeiling"
        # TODO stop skipping non-horizontal roofs
        unless surface_normal.to_s == straight_upward.to_s
          if surface.subSurfaces.size > 0
            OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "Cannot currently handle non-horizontal roofs; skipping skylights on #{surface.name} in #{self.name} for daylight sensor positioning.")
            OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---Surface #{surface.name} has outward normal of #{surface_normal.to_s.gsub(/\[|\]/,'|')}; up is #{straight_upward.to_s.gsub(/\[|\]/,'|')}.")
            next
          end
        end
      end
      
      # Find the azimuth of the facade
      facade = nil
      group = surface.planarSurfaceGroup
      if group.is_initialized
        group = group.get
        site_transformation = group.buildingTransformation
        site_vertices = site_transformation * surface.vertices
        site_outward_normal = OpenStudio::getOutwardNormal(site_vertices)
        if site_outward_normal.empty?
          OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Space", "Could not compute outward normal for #{surface.name.get}")
          next
        end
        site_outward_normal = site_outward_normal.get
        north = OpenStudio::Vector3d.new(0.0,1.0,0.0)
        if site_outward_normal.x < 0.0
          azimuth = 360.0 - OpenStudio::radToDeg(OpenStudio::getAngle(site_outward_normal, north))
        else
          azimuth = OpenStudio::radToDeg(OpenStudio::getAngle(site_outward_normal, north))
        end
      else
        # The surface is not in a group; should not hit, since
        # called from Space.surfaces
        next
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
      end
      
      # Label the facade as "Up" if it is a skylight
      if surface_normal.to_s == straight_upward.to_s
        facade = "0-Up"
      end
      
      # Loop through all subsurfaces and 
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
        
        # Log the window properties to use when creating daylight sensors
        properties = {:facade => facade, :area_m2 => net_area_m2, :handle => sub_surface.handle, :head_height_m => head_height_m}
        if facade == '0-Up'
          skylights[sub_surface] = properties
        else
          windows[sub_surface] = properties
        end
        
      end #next sub-surface
    end #next surface
  
    # TODO Determine the illuminance setpoint for the controls based on space type
    daylight_stpt_lux = 300
    space_name = self.name.get
    daylight_stpt_lux = nil
    if space_name.match(/post-office/i)# Post Office 500 Lux
      daylight_stpt_lux = 500
    elsif space_name.match(/medical-office/i)# Medical Office 3000 Lux
      daylight_stpt_lux = 3000
    elsif space_name.match(/office/i)# Office 500 Lux
      daylight_stpt_lux = 500
    elsif space_name.match(/education/i)# School 500 Lux
      daylight_stpt_lux = 500
    elsif space_name.match(/retail/i)# Retail 1000 Lux
      daylight_stpt_lux = 1000
    elsif space_name.match(/warehouse/i)# Warehouse 200 Lux
      daylight_stpt_lux = 200
    elsif space_name.match(/hotel/i)# Hotel 300 Lux
      daylight_stpt_lux = 300
    elsif space_name.match(/multifamily/i)# Apartment 200 Lux
      daylight_stpt_lux = 200
    elsif space_name.match(/courthouse/i)# Courthouse 300 Lux
      daylight_stpt_lux = 300
    elsif space_name.match(/library/i)# Library 500 Lux
      daylight_stpt_lux = 500
    elsif space_name.match(/community-center/i)# Community Center 300 Lux
      daylight_stpt_lux = 300
    elsif space_name.match(/senior-center/i)# Senior Center 1000 Lux
      daylight_stpt_lux = 1000
    elsif space_name.match(/city-hall/i)# City Hall 500 Lux
      daylight_stpt_lux = 500
    else
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.model.Space", "Space #{space_name} is an unknown space type, assuming office and 300 Lux daylight setpoint")
      daylight_stpt_lux = 300
    end    
    
    # Get the zone that the space is in
    zone = self.thermalZone
    if zone.empty?
      OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Space", "Space #{self.name.get} has no thermal zone")
    else
      zone = zone.get
    end    
    
    # Sort by priority; first by facade, then by area
    sorted_windows = windows.sort_by { |window, vals| [vals[:facade], vals[:area]] }
    sorted_skylights = skylights.sort_by { |skylight, vals| [vals[:facade], vals[:area]] }
    
    # Report out the sorted skylights for debugging
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "For #{vintage} #{self.name}, Skylights:")
    sorted_skylights.each do |sky, p|
      OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---#{sky.name} #{p[:facade]}, area = #{p[:area_m2].round(2)} m^2")
    end
    
    # Report out the sorted windows for debugging
    OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "For #{vintage} #{self.name}, Windows:")
    sorted_windows.each do |win, p|
      OpenStudio::logFree(OpenStudio::Debug, "openstudio.model.Space", "---#{win.name} #{p[:facade]}, area = #{p[:area_m2].round(2)} m^2")
    end

    # Add the required controls
    sensor_1_frac = 0.0
    sensor_2_frac = 0.0
    sensor_1_window = nil
    sensor_2_window = nil
    
    case vintage
    when  'DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007'
    
      # Do nothing, no daylighting controls required
    
    when '90.1-2010', 'AssetScore'
       
      if req_top_ctrl && req_pri_ctrl
        # Sensor 1 controls toplighted area
        sensor_1_frac = areas['toplighted_area']/space_area_m2
        sensor_1_window = sorted_skylights[0]
        # Sensor 2 controls primary area
        sensor_2_frac = areas['primary_sidelighted_area']/space_area_m2
        sensor_2_window = sorted_windows[0]
      elsif req_top_ctrl && !req_pri_ctrl
        # Sensor 1 controls toplighted area
        sensor_1_frac = areas['toplighted_area']/space_area_m2
        sensor_1_window = sorted_skylights[0]
      elsif !req_top_ctrl && req_pri_ctrl
        if sorted_windows.size == 1
          # Sensor 1 controls the whole primary area
          sensor_1_frac = areas['primary_sidelighted_area']/space_area_m2
          sensor_1_window = sorted_windows[0]
        else
          # Sensor 1 controls half the primary area
          sensor_1_frac = (areas['primary_sidelighted_area']/space_area_m2)/2
          sensor_1_window = sorted_windows[0]
          # Sensor 2 controls the other half of primary area
          sensor_2_frac = (areas['primary_sidelighted_area']/space_area_m2)/2
          sensor_2_window = sorted_windows[1]
        end       
      end
      
    when '90.1-2013'
    
      if req_top_ctrl && req_pri_ctrl && req_sec_ctrl
        # Sensor 1 controls toplighted area
        sensor_1_frac = areas['toplighted_area']/space_area_m2
        sensor_1_window = sorted_skylights[0]
        # Sensor 2 controls primary + secondary area
        sensor_2_frac = (areas['primary_sidelighted_area'] + areas['secondary_sidelighted_area'])/space_area_m2
        sensor_2_window = sorted_windows[0]
      elsif !req_top_ctrl && req_pri_ctrl && req_sec_ctrl
        # Sensor 1 controls primary area
        sensor_1_frac = areas['primary_sidelighted_area']/space_area_m2
        sensor_1_window = sorted_windows[0]        
        # Sensor 2 controls secondary area
        sensor_2_frac = (areas['secondary_sidelighted_area']/space_area_m2)/2
        sensor_2_window = sorted_windows[0]
      elsif req_top_ctrl && !req_pri_ctrl && req_sec_ctrl
        # Sensor 1 controls toplighted area
        sensor_1_frac = areas['toplighted_area']/space_area_m2
        sensor_1_window = sorted_skylights[0]
        # Sensor 2 controls secondary area
        sensor_2_frac = (areas['secondary_sidelighted_area']/space_area_m2)/2
        sensor_2_window = sorted_windows[0]
      elsif req_top_ctrl && !req_pri_ctrl && !req_sec_ctrl
        # Sensor 1 controls toplighted area
        sensor_1_frac = areas['toplighted_area']/space_area_m2
        sensor_1_window = sorted_skylights[0]      
      elsif !req_top_ctrl && req_pri_ctrl && !req_sec_ctrl
        # Sensor 1 controls primary area
        sensor_1_frac = areas['primary_sidelighted_area']/space_area_m2
        sensor_1_window = sorted_windows[0]    
      elsif !req_top_ctrl && !req_pri_ctrl && req_sec_ctrl
        # Sensor 1 controls secondary area
        sensor_1_frac = areas['secondary_sidelighted_area']/space_area_m2
        sensor_1_window = sorted_windows[0]    
      end
    
    end # End of vintage case statement    
    
    # Place the sensors and set control fractions
    # get the zone that the space is in
    zone = self.thermalZone
    if zone.empty?
      OpenStudio::logFree(OpenStudio::Error, "openstudio.model.Space", "Space #{self.name}, cannot determine daylighted areas.")
      return false
    else
      zone = self.thermalZone.get
    end
    
    # Sensors
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, sensor 1 fraction = #{sensor_1_frac.round(2)}.")
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{vintage} #{self.name}, sensor 2 fraction = #{sensor_2_frac.round(2)}.")
    
    # First sensor
    if sensor_1_window
      # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, calculating daylighted areas.")
      # runner.registerInfo("Daylight sensor 1 inside of #{sensor_1_frac.name}")
      sensor_1 = OpenStudio::Model::DaylightingControl.new(model)
      sensor_1.setName("#{self.name} Daylt Sensor 1")
      sensor_1.setSpace(self)
      sensor_1.setIlluminanceSetpoint(daylight_stpt_lux)
      sensor_1.setLightingControlType("Stepped")
      sensor_1.setNumberofSteppedControlSteps(3) #all sensors 3-step per design
      # Place sensor depending on skylight or window
      sensor_vertex = nil
      if sensor_1_window[1][:facade] == '0-Up'
        sub_surface = sensor_1_window[0]
        outward_normal = sub_surface.outwardNormal
        centroid = OpenStudio::getCentroid(sub_surface.vertices).get
        ht_above_flr = OpenStudio::convert(3.0, "ft", "m").get
        outward_normal.setLength(sensor_1_window[1][:head_height_m] - ht_above_flr)
        sensor_vertex = centroid + outward_normal.reverseVector
      else
        sub_surface = sensor_1_window[0]
        window_outward_normal = sub_surface.outwardNormal
        window_centroid = OpenStudio::getCentroid(sub_surface.vertices).get
        window_outward_normal.setLength(sensor_1_window[1][:head_height_m])
        vertex = window_centroid + window_outward_normal.reverseVector
        vertex_on_floorplane = floor_surface.plane.project(vertex)
        floor_outward_normal = floor_surface.outwardNormal
        floor_outward_normal.setLength(OpenStudio::convert(3.0, "ft", "m").get)
        sensor_vertex = vertex_on_floorplane + floor_outward_normal.reverseVector
      end
      sensor_1.setPosition(sensor_vertex)
      #TODO rotate sensor to face window (only needed for glare calcs)
      zone.setPrimaryDaylightingControl(sensor_1)
      zone.setFractionofZoneControlledbyPrimaryDaylightingControl(sensor_1_frac)
    end
    
    # Second sensor
    if sensor_2_window
      # OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Space", "For #{self.name}, calculating daylighted areas.")
      # runner.registerInfo("Daylight sensor 2 inside of #{sensor_2_frac.name}")
      sensor_2 = OpenStudio::Model::DaylightingControl.new(model)
      sensor_2.setName("#{self.name} Daylt Sensor 2")
      sensor_2.setSpace(self)
      sensor_2.setIlluminanceSetpoint(daylight_stpt_lux)
      sensor_2.setLightingControlType("Stepped")
      sensor_2.setNumberofSteppedControlSteps(3) #all sensors 3-step per design
      # Place sensor depending on skylight or window
      sensor_vertex = nil
      if sensor_2_window[1][:facade] == '0-Up'
        sub_surface = sensor_2_window[0]
        outward_normal = sub_surface.outwardNormal
        centroid = OpenStudio::getCentroid(sub_surface.vertices).get
        ht_above_flr = OpenStudio::convert(3.0, "ft", "m").get
        outward_normal.setLength(sensor_2_window[1][:head_height_m] - ht_above_flr)
        sensor_vertex = centroid + outward_normal.reverseVector
      else
        sub_surface = sensor_2_window[0]
        window_outward_normal = sub_surface.outwardNormal
        window_centroid = OpenStudio::getCentroid(sub_surface.vertices).get
        window_outward_normal.setLength(sensor_2_window[1][:head_height_m])
        vertex = window_centroid + window_outward_normal.reverseVector
        vertex_on_floorplane = floor_surface.plane.project(vertex)
        floor_outward_normal = floor_surface.outwardNormal
        floor_outward_normal.setLength(OpenStudio::convert(3.0, "ft", "m").get)
        sensor_vertex = vertex_on_floorplane + floor_outward_normal.reverseVector
      end
      sensor_2.setPosition(sensor_vertex)
      #TODO rotate sensor to face window (only needed for glare calcs)
      zone.setSecondaryDaylightingControl(sensor_2)
      zone.setFractionofZoneControlledbySecondaryDaylightingControl(sensor_2_frac)
    end
    
    return true
    
  end
  
end
