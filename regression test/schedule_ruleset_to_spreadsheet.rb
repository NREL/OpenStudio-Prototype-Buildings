# Andrew Parker
# NREL

require 'openstudio'
require 'profile'

#load a model into OS & version translates, exiting and erroring if a problem is found
def safe_load_model(model_path_string)  
  model_path = OpenStudio::Path.new(model_path_string)
  if OpenStudio::exists(model_path)
    versionTranslator = OpenStudio::OSVersion::VersionTranslator.new 
    model = versionTranslator.loadModel(model_path)
    if model.empty?
      puts "Version translation failed for #{model_path_string}"
      exit
    else
      model = model.get
    end
  else
    puts "#{model_path_string} couldn't be found"
    exit
  end
  return model
end

model_paths = []
model_paths << "C:/GitRepos/OpenStudio-Prototype-Buildings/create_DOE_prototype_building/resources/standards data/Master_Schedules.osm"
model_paths << "C:/GitRepos/OpenStudio-Prototype-Buildings/regression test/Prototype_Schedule_Library.osm"


def get_hr_vals(day_sch,unit_type)
  type = "Hourly"
  vals = []
  (1..24).each do |hr|
    time = OpenStudio::Time.new(0, hr, 0, 0)
    val = day_sch.getValue(time)
    
    # Convert from C to F if necessary
    if unit_type == "Temperature"
      val = OpenStudio.convert(val, "C", "F").get
    end
    
    # Round
    if val < 5
      val = val.round(2)
    else
      val = val.round
    end
    
    vals << day_sch.getValue(time)
  end
  
  if vals.uniq.size == 1
    type = "Constant"
    vals = vals.uniq
  end
  
  return [type,vals]
  
end

all_schs = []
model_paths.each do |model_path|
  model = safe_load_model(model_path)
  model.getScheduleRulesets.sort.each do |sch_ruleset|
    
    sch_rows = []
    # Make a spreadsheet line for each rule  
    # Name	                    Category	            Units	    Day Types	                Type	  Start Date	End Date	Hr 1	Hr 2
    # SmallOffice BLDG_SWH_SCH	Service Water Heating	Fraction	Default, SmrDsn, WntrDsn	Hourly	1-Jan	      31-Dec	  0%	0%
    
    # Day Type choices: Default, Wkdy, Wknd, Mon, Tue, Wed, Thu, Fri, Sat, Sun, WntrDsn, SmrDsn, Hol
    
    sch_name = sch_ruleset.name.get
    year_start_date = "1/1"
    year_end_date = "12/31"
    
    # Determine the category from the name
    category = "Unknown"
    uc_sch_name = sch_name.upcase
    if uc_sch_name.include?("INFIL")
      category = "Infiltration"
    elsif uc_sch_name.include?("CLGSETP") || 
          uc_sch_name.include?("HTGSETP") ||
          uc_sch_name.include?("CLGSP") ||
          uc_sch_name.include?("HTGSP")
      category = "Thermostat Setpoint"
    elsif uc_sch_name.include?("OCC")
      category = "Occupancy" 
    elsif uc_sch_name.include?("LIGHT")
      category = "Lighting"  
    elsif uc_sch_name.include?("EQUIP") ||
          uc_sch_name.include?("EQP") ||
          uc_sch_name.include?("LAUNDRY") ||
          uc_sch_name.include?("KITCHEN")
      category = "Equipment"    
    elsif uc_sch_name.include?("ACTIVITY")
      category = "Activity" 
    elsif uc_sch_name.include?("CLOTHING")
      category = "Clothing"
    elsif uc_sch_name.include?("SWH") ||
          uc_sch_name.include?("SHW")
      category = "Service Water Heating"    
    elsif uc_sch_name.include?("ELEV")
      category = "Elevator"  
    elsif uc_sch_name.include?("EXH")
      category = "Exhaust"  
    elsif uc_sch_name.include?("DAMPER") ||
          uc_sch_name.include?("OA")
      category = "OA Air"  
    elsif uc_sch_name.include?("OPERATION")
      category = "Operation"
    end  
      
    # Determine the schedule type from the type limits
    sch_day_types_limits = sch_ruleset.scheduleTypeLimits
    units = "Unknown"
    if sch_day_types_limits.is_initialized
      units = sch_day_types_limits.get.unitType
    end

    # Default day
    row = {}
    row["name"] = sch_name
    row["category"] = category
    row["units"] = units
    day_types = ["Default"]
    day_types << "WntrDsn" if sch_ruleset.isWinterDesignDayScheduleDefaulted == true
    day_types << "SmrDsn" if sch_ruleset.isSummerDesignDayScheduleDefaulted == true
    row["day_types"] = day_types
    vals = get_hr_vals(sch_ruleset.defaultDaySchedule, units)
    row["data"] = {}
    row["data"]["start_date"] = year_start_date
    row["data"]["end_date"] = year_end_date
    row["data"]["type"] = vals[0]
    row["data"]["vals"] = vals[1]
    sch_rows << row
    
    # Winter Design Day
    if sch_ruleset.isWinterDesignDayScheduleDefaulted == false
      row = {}
      row["name"] = sch_name
      row["category"] = category
      row["units"] = units
      row["day_types"] = ["WntrDsn"]
      vals = get_hr_vals(sch_ruleset.winterDesignDaySchedule, units)
      row["data"] = {}
      row["data"]["start_date"] = year_start_date
      row["data"]["end_date"] = year_end_date    
      row["data"]["type"] = vals[0]
      row["data"]["vals"] = vals[1]
      sch_rows << row    
    end
    
    # Summer Design Day
    if sch_ruleset.isSummerDesignDayScheduleDefaulted == false
      row = {}
      row["name"] = sch_name
      row["category"] = category
      row["units"] = units
      row["day_types"] = ["SmrDsn"]
      vals = get_hr_vals(sch_ruleset.summerDesignDaySchedule, units)
      row["data"] = {}
      row["data"]["start_date"] = year_start_date
      row["data"]["end_date"] = year_end_date
      row["data"]["type"] = vals[0]
      row["data"]["vals"] = vals[1]
      sch_rows << row    
    end

    # Schedule rules
    sch_ruleset.scheduleRules.each do |rule|
      row = {}
      row["name"] = sch_name
      row["category"] = category
      row["units"] = units
      day_types = []
      if rule.applySaturday && rule.applySunday
        day_types << "Wknd"
      else
        day_types << "Sat" if rule.applySaturday
        day_types << "Sun" if rule.applySunday      
      end
      if rule.applyMonday && rule.applyTuesday && rule.applyWednesday && rule.applyThursday && rule.applyFriday
        day_types << "Wkdy"
      else
        day_types << "Mon" if rule.applyMonday
        day_types << "Tue" if rule.applyTuesday 
        day_types << "Wed" if rule.applyWednesday 
        day_types << "Thu" if rule.applyThursday 
        day_types << "Fri" if rule.applyFriday     
      end      
      row["day_types"] = day_types
      vals = get_hr_vals(rule.daySchedule, units)
      row["data"] = {}
      row["data"]["start_date"] = "#{rule.startDate.get.monthOfYear.value}/#{rule.startDate.get.dayOfMonth}"
      row["data"]["end_date"] = "#{rule.endDate.get.monthOfYear.value}/#{rule.endDate.get.dayOfMonth}"
      row["data"]["type"] = vals[0]
      row["data"]["vals"] = vals[1]
      sch_rows << row    
    end 

    all_schs << sch_rows
    
  end

end

File.open("#{Dir.pwd}/OpenStudioSchedules.csv", 'w') do |file|  
  all_schs.each do |sch_rows|
    
    puts ""
    puts sch_rows
    
    # Collapse rows (rules) that have the same data (date/time/values) 
    # but different day_types as a previous row into that row.
    collapsed_srs = []
    sch_rows.each do |sr|
      
      # Always store the first row.
      if collapsed_srs.size == 0
        collapsed_srs << sr
      end
      
      # For all subsequent rows, only store the row
      # if it can't be collapsed into one of the existing rows.
      was_combined = false
      collapsed_srs.each do |csr|
        if sr["data"] == csr["data"]
          puts "***combined"
          puts "--existing-#{csr}"
          puts "---plus----#{sr}"
          sr["day_types"].each do |dt|
            if !csr["day_types"].include?(dt)
              csr["day_types"] << dt
            end
          end
          puts "---equals--#{csr}"
          was_combined = true
        end
      end
      
      # Only store rows that weren't combined
      if was_combined == false
        collapsed_srs << sr
      end
      
    end
     
    # Put the collapsed rows into the file  
    collapsed_srs.each do |csr|
      line = "#{csr["name"]},#{csr["category"]},#{csr["units"]},#{csr["day_types"].join('|')},#{csr["data"]["start_date"]},#{csr["data"]["end_date"]},#{csr["data"]["type"]},#{csr["data"]["vals"].join(',')}"
      puts line
      file.puts line
    end
    
  end
end

puts "There are #{all_schs.size} schedules in the library"
