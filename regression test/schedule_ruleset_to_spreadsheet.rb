
require 'openstudio'

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

model = safe_load_model("C:/GitRepos/OpenStudio-Prototype-Buildings/create_DOE_prototype_building/resources/standards data/Master_Schedules.osm")

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

all_rows = []
model.getScheduleRulesets.each do |sch_ruleset|
  
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
  if sch_name.include?("Infil")
    category = "Infiltration"
  elsif sch_name.include?("ClgSetp") || sch_name.include?("HtgSetp")
    category = "Thermostat Setpoint"
  elsif sch_name.include?("Occ")
    category = "Occupancy" 
  elsif sch_name.include?("Light")
    category = "Lighting"  
  elsif sch_name.include?("Equip")
    category = "Equipment"    
  elsif sch_name.include?("Activity")
    category = "Activity" 
  elsif sch_name.include?("Clothing")
    category = "Clothing"
  elsif sch_name.include?("Swh")
    category = "Service Water Heating"    
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
  row["start_date"] = year_start_date
  row["end_date"] = year_end_date
  row["type"] = vals[0]
  row["vals"] = vals[1]
  sch_rows << row
  
  # Winter Design Day
  if sch_ruleset.isWinterDesignDayScheduleDefaulted == false
    row = {}
    row["name"] = sch_name
    row["category"] = category
    row["units"] = units
    row["day_types"] = ["WntrDsn"]
    vals = get_hr_vals(sch_ruleset.winterDesignDaySchedule, units)
    row["start_date"] = year_start_date
    row["end_date"] = year_end_date    
    row["type"] = vals[0]
    row["vals"] = vals[1]
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
    row["start_date"] = year_start_date
    row["end_date"] = year_end_date
    row["type"] = vals[0]
    row["vals"] = vals[1]
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
    row["start_date"] = rule.startDate.get
    row["end_date"] = rule.endDate.get
    row["type"] = vals[0]
    row["vals"] = vals[1]
    sch_rows << row    
  end 

  all_rows << sch_rows
  
end

File.open("#{Dir.pwd}/OpenStudioSchedules.csv", 'w') do |file|  
  all_rows.each do |sch_rows|
    sch_rows.each do |sr|
      sr["day_types"] = sr["day_types"].join('|')
      line = "#{sr["name"]},#{sr["category"]},#{sr["units"]},#{sr["day_types"]},#{sr["start_date"]},#{sr["end_date"]},#{sr["type"]},#{sr["vals"].join(',')}"
      puts line
      file.puts line
    end
  end
end

puts "There are #{all_rows.size} schedules in the library"





