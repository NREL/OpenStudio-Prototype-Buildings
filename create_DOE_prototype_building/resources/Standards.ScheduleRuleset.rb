
# open the class to add methods to apply HVAC efficiency standards
class OpenStudio::Model::ScheduleRuleset

  # Determine the equivalent full load hours
  # for a given schedule for the entire year.
  # 1 Full load hr = 1 hr at 100% 
  # ,or 4 hrs at 25%, or 10 hrs at 10%, etc.
  #
  # @note Credit: Matt Leach, NORESCO
  def equivalent_full_load_hours()
  
    if model.yearDescription.is_initialized
      year_description = model.yearDescription.get
      # puts "Year description:"
      # puts year_description
      year = year_description.assumedYear
      puts "Assumed year = #{year_description.assumedYear}"
      year_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new("January"),1,year)
      year_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new("December"),31,year)
    else
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.Standards.ScheduleRuleset", "For #{self.name}, Year description is not specified in this model, cannot correctly determine equivalent full load hours.")
      return false
    end
    
    # Define the start and end date
    # year_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new("January"),1)
    # year_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new("December"),31)

    # Get the ordered list of all the day schedules
    # that are used by this schedule ruleset
    day_schs = self.getDaySchedules(year_start_date, year_end_date)
    puts "*******************************"
    puts "Day Schedules:"
    day_schs.uniq.each do |day_sch|
      puts day_sch.name.get.to_s
    end
    puts "*******************************"
    
    # Get a 365-value array of which schedule is used on each day of the year,
    day_schs_used_each_day = self.getActiveRuleIndices(year_start_date, year_end_date)

    # puts "Schedule day key by day:"
    # puts day_schs_used_each_day
    
    puts "Number of days accounted for:"
    puts day_schs_used_each_day.length
    puts "*******************************"
    
    # Create a map that shows how many days each schedule is used
    day_sch_freq = day_schs_used_each_day.group_by { |n| n }
    # puts "Grouped schedule days:"
    # puts day_sch_freq
    
    # Build a hash that maps schedule day index to schedule day
    schedule_index_to_day = {}
    for i in 0..(day_schs.length-1)
      schedule_index_to_day[day_schs_used_each_day[i]] = day_schs[i]
    end
    
    puts "Schedule Index to Day Mapping:"
    schedule_index_to_day.keys.each do |index|
      puts "Index #{index} maps to #{schedule_index_to_day[index].name}"
    
    end
    puts "*******************************"
    
    # Loop through each of the schedules that is used, figure out the
    # full load hours for that day, then multiply this by the number
    # of days that day schedule applies and add this to the total.
    annual_flh = 0
    default_day_sch = self.defaultDaySchedule
    day_sch_freq.each do |freq|
      #puts freq.inspect
      #exit

      # puts "Schedule Index = #{freq[0]}"
      sch_index = freq[0]
      number_of_days_sch_used = freq[1].size

      # Get the day schedule at this index
      day_sch = nil
      if sch_index == -1 # If index = -1, this day uses the default day schedule (not a rule)
        day_sch = default_day_sch
        puts "*******************************"
        puts "Calculating hours for Default Day Schedule: #{default_day_sch.name}"
      else
        puts "*******************************"
        day_sch = schedule_index_to_day[sch_index]
        puts "Calculating hours for #{day_sch.name}"
      end

      # Determine the full load hours for just one day
      daily_flh = 0
      # puts "Values:"
      # puts day_sch.values
      # puts "Times:"
      # puts day_sch.times
      
      values = day_sch.values
      times = day_sch.times
      
      previous_time_decimal = 0
      for i in 0..(times.length - 1)
        time_days = times[i].days
        time_hours = times[i].hours
        time_minutes = times[i].minutes
        time_seconds = times[i].seconds
        time_decimal = (time_days*24) + time_hours + (time_minutes/60) + (time_seconds/3600)
        duration_of_value = time_decimal - previous_time_decimal
        puts "Duration of value #{values[i]} is #{duration_of_value} hours"
        daily_flh += values[i]*duration_of_value
        previous_time_decimal = time_decimal
      end
      
      # day_sch.values.each do |val|
        # daily_flh += val
      # end

      puts "#{day_sch.name} has #{daily_flh.round(2)} hours per day"
      puts "Number of days #{day_sch.name} is used = #{number_of_days_sch_used}"
      puts "*******************************"
      
      # Warn if the daily flh is more than 24,
      # which would indicate that this isn't a 
      # fractional schedule.
      if daily_flh > 24
        return 0
      end

      # Multiply the daily flh by the number
      # of days this schedule is used per year
      # and add this to the overall total
      annual_flh += daily_flh * number_of_days_sch_used

    end

    return annual_flh

  end

end
