# Nicholas Long and Andrew Parker
# NREL

# This translator takes the schedule:compact and loads into memory based
# structure, then translates back out to schedule rule sets

#require 'rubygems'
#require 'orderedhash'

ForStruct = Struct.new(:daytypes)
UntilStruct = Struct.new(:timestamp)
ThroughStruct = Struct.new(:startdate)

class ScheduleTranslator
  attr_accessor :os_schedule
  
  def initialize(os_model, os_schedule, type_limits_hash, name_prefix = nil)
    @os_schedule = os_schedule
    @os = os_model
    @sched_name = ""
    @sched_type = ""
    @base_year = 2009 #not used
    @schedule = []
    @name_prefix = name_prefix
    @type_limits_hash = type_limits_hash
  end
  
  def translate()
    sched_objs = []
    
    @sched_name = @os_schedule.getString(0).get
    @sched_name = "#{@name_prefix} #{@sched_name}" unless @name_prefix.nil?
    @sched_type = @os_schedule.getString(1).get
    
    puts "Translating #{@sched_name}"

    i_thru = -1
    i_for = -1
    i_until = -1
    sUntil = ""
    
    (2..@os_schedule.numFields-1).each do |i|
      val = @os_schedule.getString(i).get
      
      # Trap for interpolated schedules
      if val =~ /Interpolate/
        puts "[WARNING] Schedule #{@sched_name} is interpolated.  It will not be translated to .osm"
        return false
      end
      
      if val =~ /through:/i
        i_thru += 1
        i_for = -1
        i_until = -1
        
        str = val.split(":")[1].strip
        if @schedule.size == 0
          @schedule << {:start_date => "01/01", :end_date => str, :for => []}
        else
          @schedule << {:start_date => @schedule[@schedule.size - 1][:end_date], :end_date => str, :for => [] }
        end
        
        next
      end
      
      if val =~ /for[:\s]/i
        i_for += 1
        i_until = -1
        
        arr = val.match(/for[:\s](.*)/i)[0].strip.downcase.split(" ")
        @schedule[i_thru][:for] << {:daytype => arr, :until => []}
        next
      end
      
      if val =~ /until:/i
        i_until += 1
        
        str = val.split(":")[1..2].join(":").strip
        sUntil = str
        
        next
      end
      
      dVal = @os_schedule.getDouble(i).get      
      #puts "thru: #{i_thru} for: #{i_for} until #{i_until}"
      @schedule[i_thru][:for][i_for][:until] << {:timestamp => sUntil, :value => dVal}
    end
    
    #DEBUG spit out the schedule for quick check\
    #puts @schedule.inspect
    # @schedule.each do |sch|
     # puts "#{sch[:start_date]} to #{sch[:end_date]}"
     # sch[:for].each do |fr|
       # puts fr[:daytype]
       # fr[:until].each do |ut|
         # puts "#{ut[:timestamp]} : #{ut[:value]}"
       # end
     # end
    # end
 
    os_schedule_ruleset = OpenStudio::Model::ScheduleRuleset.new(@os)
    os_schedule_ruleset.setName(@sched_name)
    #os_schedule_ruleset.setString(1, @sched_type)
    
    i_rule = 0
    @schedule.each do |sch|
      #create a simple hash to make sure that the schedule covers all days needed
      #and that "allotherdays", can adequately be handled
      coverage = {:mon => false, :tue => false, :wed => false, :thu => false, :fri => false, :sat => false,
                  :sun => false, :sdd => false, :wdd => false, :hol => false}
      sch[:for].each do |fr|
        i_rule += 1
        os_schedule_rule = OpenStudio::Model::ScheduleRule.new(os_schedule_ruleset)
        os_schedule_rule.setName("#{@sched_name} Rule #{i_rule}")
        os_schedule_rule.setApplyMonday(false)
        os_schedule_rule.setApplyTuesday(false)
        os_schedule_rule.setApplyWednesday(false)
        os_schedule_rule.setApplyThursday(false)
        os_schedule_rule.setApplyFriday(false)
        os_schedule_rule.setApplySaturday(false)
        os_schedule_rule.setApplySunday(false)
        
        mody = sch[:start_date].split("/")
        mo = mody[0].to_i
        dy = mody[1].to_i
        osdate_start = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(mo.to_i), dy.to_i)
        if mo != 1 && dy != 1
          osdate_start = osdate_start + OpenStudio::Time.new(1)
        end
        os_schedule_rule.setStartDate(osdate_start)
        mody = sch[:end_date].split("/")
        mo = mody[0].to_i
        dy = mody[1].to_i
        osdate_end = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(mo.to_i), dy.to_i)
        os_schedule_rule.setEndDate(osdate_end)
        
        # create os day model
        # TODO break this out as a method
        if (fr[:daytype].include?("monday")) || (fr[:daytype].include?("alldays")) || (fr[:daytype].include?("weekdays"))
          os_schedule_rule.setApplyMonday(true)
          coverage[:mon] = true
        end
        if (fr[:daytype].include?("tuesday")) || (fr[:daytype].include?("alldays")) || (fr[:daytype].include?("weekdays"))
          os_schedule_rule.setApplyTuesday(true)
          coverage[:tue] = true
        end
        if (fr[:daytype].include?("wednesday")) || (fr[:daytype].include?("alldays")) || (fr[:daytype].include?("weekdays"))
          os_schedule_rule.setApplyWednesday(true)
          coverage[:wed] = true
        end
        if (fr[:daytype].include?("thursday")) || (fr[:daytype].include?("alldays")) || (fr[:daytype].include?("weekdays"))
          os_schedule_rule.setApplyThursday(true)
          coverage[:thu] = true
        end
        if (fr[:daytype].include?("friday")) || (fr[:daytype].include?("alldays")) || (fr[:daytype].include?("weekdays"))
          os_schedule_rule.setApplyFriday(true)
          coverage[:fri] = true
        end
        if (fr[:daytype].include?("saturday")) || (fr[:daytype].include?("alldays"))
          os_schedule_rule.setApplySaturday(true)
          coverage[:sat] = true
        end
        if (fr[:daytype].include?("sunday")) || (fr[:daytype].include?("alldays"))
          os_schedule_rule.setApplySunday(true)
          coverage[:sun] = true
        end
        if (fr[:daytype].include?("allotherdays")) 
          #needs to be a unique rule set
          if !coverage[:mon]
            os_schedule_rule.setApplyMonday(true)
            coverage[:mon] = true
          end
          if !coverage[:tue]
            os_schedule_rule.setApplyTuesday(true)
            coverage[:tue] = true
          end
          if !coverage[:wed]
            os_schedule_rule.setApplyWednesday(true)
            coverage[:wed] = true
          end
          if !coverage[:thu]
            os_schedule_rule.setApplyThursday(true)
            coverage[:thu] = true
          end
          if !coverage[:fri]
            os_schedule_rule.setApplyFriday(true)
            coverage[:fri] = true
          end
          if !coverage[:sat]
            os_schedule_rule.setApplySaturday(true)
            coverage[:sat] = true
          end
          if !coverage[:sun]
            os_schedule_rule.setApplySunday(true)
            coverage[:sun] = true
          end
        end
          
        osday = os_schedule_rule.daySchedule  
        osday.setName("#{@sched_name} Rule #{i_rule} Day Sch")
        #osday.setString(1, @sched_type)
        fr[:until].each do |ut|
          hr = ut[:timestamp].split(":")[0].to_i
          mn = ut[:timestamp].split(":")[1].to_i
          
          ostime = OpenStudio::Time.new(0, hr, mn, 0)
          osday.addValue(ostime, ut[:value])
        end
        
        #set the winter and summer design days
        if (fr[:daytype].include?("winterdesignday")) ||
           (fr[:daytype].include?("allotherdays") && !coverage[:wdd])
          
          # this actually clones osday
          os_schedule_ruleset.setWinterDesignDaySchedule(osday)

          coverage[:wdd] = true
        end
        if (fr[:daytype].include?("summerdesignday")) ||
           (fr[:daytype].include?("allotherdays") && !coverage[:sdd])
           
          # this actually clones osday
          os_schedule_ruleset.setSummerDesignDaySchedule(osday)

          coverage[:sdd] = true
        end
        
        #now check if for some reason that we have alldays for section
        #but the date/time stamp is not in the winter/summer
        if !coverage[:wdd]
          osdate_wdd = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1), 15)
          if fr[:daytype].include?("alldays") && (osdate_start < osdate_wdd) && (osdate_end > osdate_wdd)
            os_schedule_ruleset.setWinterDesignDaySchedule(osday)
            coverage[:wdd] = true
            #puts "[INFO] **** Setting DesignDay based on date, not by actual schedule ****"
          end
        end
        if !coverage[:sdd]
          osdate_wdd = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(7), 15)
          if fr[:daytype].include?("alldays") && (osdate_start < osdate_wdd) && (osdate_end > osdate_wdd)
            os_schedule_ruleset.setSummerDesignDaySchedule(osday)
            coverage[:sdd] = true
            #puts "[INFO] **** Setting DesignDay based on date, not by actual schedule ****"
          end
        end
      end
    end
    
    # Clean up tasks on the naming after all the schedule rule and days are
    # configured
    ostemp = os_schedule_ruleset.winterDesignDaySchedule()
    ostemp.setName("#{@sched_name} Winter Design Day")
    #ostemp.setString(1, @sched_type)
    
    ostemp = os_schedule_ruleset.summerDesignDaySchedule()
    ostemp.setName("#{@sched_name} Summer Design Day")
    #ostemp.setString(1, @sched_type)
    
    ostemp = os_schedule_ruleset.defaultDaySchedule()
    ostemp.setName("#{@sched_name} Default Schedule")
    #ostemp.setString(1, @sched_type)
    
    # Remove rules that don't apply to any days
    os_schedule_ruleset.scheduleRules.each do |sr|
      if !sr.applySunday && !sr.applyMonday && !sr.applyTuesday &&
         !sr.applyWednesday && !sr.applyThursday && !sr.applyFriday &&
         !sr.applySaturday
         sr.daySchedule.remove
         sr.remove
      end
    end
    
    sched_i = 0
    os_schedule_ruleset.scheduleRules.each do |sr|
      sched_i += 1
      sr.setName("#{@sched_name} Rule #{sched_i}")
      sr.daySchedule.setName("#{@sched_name} Rule #{sched_i} Day Schedule")
    end

    # Set the schedule type limits
    type_limits = nil
    case @sched_type.upcase
    when "FRACTION" 
      type_limits = @type_limits_hash["Fraction"]
    when "TEMPERATURE"
      type_limits = @type_limits_hash["Temperature"]
    when "ACTIVITY"
      type_limits = @type_limits_hash["Activity"]
    when "ANY NUMBER"
      type_limits = @type_limits_hash["Activity"]      
    when "ON/OFF"
      type_limits = @type_limits_hash["On Off Operation"]
    when "COMPACT HVAC"
      type_limits = @type_limits_hash["Control Mode"]
    when "COMPACT HVAC ANY NUMBER"
      type_limits = @type_limits_hash["Control Mode"]  
    when "CONTROL TYPE"
      type_limits = @type_limits_hash["Control Mode"]  
    end
    if type_limits.nil?
      puts "*************Could not find type limits of '#{@sched_type}' in the hash."
    else
      os_schedule_ruleset.setScheduleTypeLimits(type_limits)
    end
    
    # If the default profile is never used throughout the year,
    # make the most commonly used rule the default instead.
  
    # Get an array that shows which rule is used on each day in the date range.
    # A value of -1 means that the default profile is used on that day,
    # so if -1 never appears in the list, it isn't used.
    year_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new("January"),1)
    year_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new("December"),31)
    rules_used_each_day = os_schedule_ruleset.getActiveRuleIndices(year_start_date,year_end_date)
    #puts "The schedule covers #{rules_used_each_day.size} days"
    rules_freq = rules_used_each_day.group_by { |n| n }
    #puts rules_freq
    most_freq_rule_index = rules_freq.values.max_by(&:size).first
    puts "rule #{most_freq_rule_index} is used most often, on #{rules_freq[most_freq_rule_index].size} days."
    if not rules_used_each_day.include?(-1)
      puts("#{os_schedule_ruleset.name} does not used the default profile, it will be replaced.")

      # Get times/values from the most commonly used rule then remove that rule.
      rule_vector = os_schedule_ruleset.scheduleRules
      new_default_day_sch = rule_vector.reverse[most_freq_rule_index].daySchedule
      new_default_day_sch_values = new_default_day_sch.values
      new_default_day_sch_times = new_default_day_sch.times
      rule_vector.reverse[most_freq_rule_index].remove
      
      # Reset values in default profile
      default_day_sch = os_schedule_ruleset.defaultDaySchedule
      default_day_sch.clearValues      
      
      # Update values and times for default profile
      for i in 0..(new_default_day_sch_values.size - 1)
        default_day_sch.addValue(new_default_day_sch_times[i],new_default_day_sch_values[i])
      end
    end

    return os_schedule_ruleset
  
  end
  
end
