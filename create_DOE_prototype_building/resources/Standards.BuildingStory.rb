
# open the class to add methods to apply HVAC efficiency standards
class OpenStudio::Model::BuildingStory

  # Determine which of the zones on this story
  # should be served by the primary HVAC system.
  #
  # @todo change the zone load filter to a recursive
  # algorithm that averages all "other spaces" per
  # 90.1.
  def get_primary_thermal_zones()
  
    # Get all the spaces on this story
    spaces = self.spaces
    
    # Get all the thermal zones that serve these spaces
    zones = []
    spaces.each do |space|
      if space.thermalZone.is_initialized
        zones << space.thermalZone.get
      else
        OpenStudio::logFree(OpenStudio::Warn, "openstudio.Standards.BuildingStory", "For #{self.name}, space #{space.name} has no thermal zone, it is not included in the simulation.")
      end
    end
    
    # Get the heating and cooling loads for all the zones
    htg_loads_btu_per_ft2 = []
    clg_loads_btu_per_ft2 = []
    zones.each do |zone|    
      # Get the heating load
      htg_load_w_per_m2 = zone.heatingDesignLoad
      if htg_load_w_per_m2.is_initialized
        htg_load_btu_per_ft2 = OpenStudio.convert(htg_load_w_per_m2.get,'W/m^2','Btu/hr*ft^2').get
        # Don't include zero loads in average
        if htg_load_btu_per_ft2 > 0.0
          htg_loads_btu_per_ft2 << htg_load_btu_per_ft2
        end
      else
        OpenStudio::logFree(OpenStudio::Warn, "openstudio.Standards.BuildingStory", "For #{self.name}, zone #{zone.name}, could not determine the design heating load.")
        next
      end
      # Get the cooling load
      clg_load_w_per_m2 = zone.coolingDesignLoad
      if clg_load_w_per_m2.is_initialized
        clg_load_btu_per_ft2 = OpenStudio.convert(clg_load_w_per_m2.get,'W/m^2','Btu/hr*ft^2').get
        # Don't include zero loads in average
        if clg_load_btu_per_ft2 > 0.0
          clg_loads_btu_per_ft2 << clg_load_btu_per_ft2
        end
      else
        OpenStudio::logFree(OpenStudio::Warn, "openstudio.Standards.BuildingStory", "For #{self.name}, zone #{zone.name}, could not determine the design cooling load.")
        next
      end
    end
    
    # Determine the average heating and cooling loads
    avg_htg_load_btu_per_ft2 = htg_loads_btu_per_ft2.inject(:+)/htg_loads_btu_per_ft2.size
    avg_clg_load_btu_per_ft2 = clg_loads_btu_per_ft2.inject(:+)/clg_loads_btu_per_ft2.size
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.Standards.BuildingStory", "For #{self.name}, average heating = #{avg_htg_load_btu_per_ft2.round} Btu/hr*ft^2, average cooling = #{avg_clg_load_btu_per_ft2.round} Btu/hr*ft^2.")
    
    # Filter out any zones that are +/- 10 Btu/hr*ft^2 from the average
    primary_zones = []
    zones.each do |zone|
      # Get the heating load
      htg_load_btu_per_ft2 = nil
      htg_load_w_per_m2 = zone.heatingDesignLoad
      if htg_load_w_per_m2.is_initialized
        htg_load_btu_per_ft2 = OpenStudio.convert(htg_load_w_per_m2.get,'W/m^2','Btu/hr*ft^2').get
      else
        OpenStudio::logFree(OpenStudio::Warn, "openstudio.Standards.BuildingStory", "For #{self.name}, zone #{zone.name}, could not determine the design heating load.")
        next
      end
      # Get the cooling load
      clg_load_btu_per_ft2 = nil
      clg_load_w_per_m2 = zone.coolingDesignLoad
      if clg_load_w_per_m2.is_initialized
        clg_load_btu_per_ft2 = OpenStudio.convert(clg_load_w_per_m2.get,'W/m^2','Btu/hr*ft^2').get
      else
        OpenStudio::logFree(OpenStudio::Warn, "openstudio.Standards.BuildingStory", "For #{self.name}, zone #{zone.name}, could not determine the design cooling load.")
        next
      end
      # Filter on heating load
      if htg_load_btu_per_ft2 < avg_htg_load_btu_per_ft2 - 10.0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.Standards.BuildingStory", "For #{self.name}, zone #{zone.name}, the heating load of #{htg_load_btu_per_ft2.round} Btu/hr*ft^2 is more than 10 Btu/hr*ft^2 lower than the average of #{avg_htg_load_btu_per_ft2.round} Btu/hr*ft^2, zone will not be attached to the primary system.")
        next
      elsif htg_load_btu_per_ft2 > avg_htg_load_btu_per_ft2 + 10.0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.Standards.BuildingStory", "For #{self.name}, zone #{zone.name}, the heating load of #{htg_load_btu_per_ft2.round} Btu/hr*ft^2 is more than 10 Btu/hr*ft^2 higher than the average of #{avg_htg_load_btu_per_ft2.round} Btu/hr*ft^2, zone will not be attached to the primary system.")
        next
      end
      # Filter on cooling load
      if clg_load_btu_per_ft2 < avg_clg_load_btu_per_ft2 - 10.0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.Standards.BuildingStory", "For #{self.name}, zone #{zone.name}, the cooling load of #{clg_load_btu_per_ft2.round} Btu/hr*ft^2 is more than 10 Btu/hr*ft^2 lower than the average of #{avg_clg_load_btu_per_ft2.round} Btu/hr*ft^2, zone will not be attached to the primary system.")
        next
      elsif clg_load_btu_per_ft2 > avg_clg_load_btu_per_ft2 + 10.0
        OpenStudio::logFree(OpenStudio::Info, "openstudio.Standards.BuildingStory", "For #{self.name}, zone #{zone.name}, the cooling load of #{clg_load_btu_per_ft2.round} Btu/hr*ft^2 is more than 10 Btu/hr*ft^2 higher than the average of #{avg_clg_load_btu_per_ft2.round} Btu/hr*ft^2, zone will not be attached to the primary system.")
        next
      end      
      
      OpenStudio::logFree(OpenStudio::Info, "openstudio.Standards.BuildingStory", "For #{self.name}, zone #{zone.name} heating = #{htg_load_btu_per_ft2.round} Btu/hr*ft^2, cooling = #{clg_load_btu_per_ft2.round} Btu/hr*ft^2.")
      
      # It is a primary zone!
      primary_zones << zone
      
    end
    
    occupied_full_load_hours = {}
    zones.each do |zone|
      OpenStudio::logFree(OpenStudio::Info, "openstudio.Standards.BuildingStory", "#{zone.name}")
      total_persons = 0
      total_person_hours = 0
      zone.spaces.each do |space|
        OpenStudio::logFree(OpenStudio::Info, "openstudio.Standards.BuildingStory", "***#{space.name}")
        # Get all people from either the space
        # or the space type.
        all_people = []
        all_people += space.people
        if space.spaceType.is_initialized
          all_people += space.spaceType.get.people
        end
        all_people.each do |people|
          OpenStudio::logFree(OpenStudio::Info, "openstudio.Standards.BuildingStory", "******#{people.name}")
          # Get the number of people
          num_people = space.numberOfPeople
          total_persons += num_people
          
          # Get the fractional people schedule
          people_sch = people.numberofPeopleSchedule
          full_load_hrs = 0.0
          if people_sch.is_initialized
            if people_sch.get.to_ScheduleRuleset.is_initialized
              people_sch = people_sch.get.to_ScheduleRuleset.get
              full_load_hrs = people_sch.equivalent_full_load_hours
              total_person_hours += num_people * full_load_hrs
            else
              # Can't handle non-ruleset schedules
            end
          else
            
          end
          
          OpenStudio::logFree(OpenStudio::Info, "openstudio.Standards.BuildingStory", "******num_people = #{num_people.round}, full_load_hrs = #{full_load_hrs.round}")
          
        end
      end
      occupied_hours = 0.0
      if total_persons > 0.0
        occupied_hours = total_person_hours/total_persons
      end
      occupied_full_load_hours[zone] = occupied_hours
      
      OpenStudio::logFree(OpenStudio::Info, "openstudio.Standards.BuildingStory", "For #{self.name}, #{zone.name} occupied_full_load_hours = #{occupied_hours.round}")
      
    end
    
    # Determine the average number of person hours
    # per week (assumes an 8760 hr year)
    # avg_person_hrs_per_wk = 
    
    
    # Filter out any zone whose schedule is more than 
    # 
     
    # TODO make sure that the zone doesn't contain
    # spaces on multiple stories.
    
    return primary_zones
  
  end

end
