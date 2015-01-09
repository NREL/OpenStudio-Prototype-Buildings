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
#model_paths << "C:/GitRepos/OpenStudio-Prototype-Buildings/create_DOE_prototype_building/resources/standards data/Master_Schedules.osm"
#model_paths << "C:/GitRepos/OpenStudio-Prototype-Buildings/regression test/Prototype_Schedule_Library.osm"
model_paths << "C:/Users/dgoldwas/Documents/GitHub/OpenStudio-Prototype-Buildings/regression test/Prototype_Schedule_Library.osm"

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

def get_half_hr_vals(day_sch,unit_type,hoo_start,hoo_finish)
  type = "formula"
  floor = nil
  ceiling = nil
  vals = []
  time_val_hash = {}

  # get ceiling and floor
  # todo - run through in reverse and create a hash of unique time/value pairs
  (1..48).each do |i|

    # alter to go through backwards
    i = 48.5 - i

    hr =  (i/2).truncate
    if (i/2) == (i/2).truncate then min = 0 else min = 30 end

    time = OpenStudio::Time.new(0, hr, min, 0)
    val = day_sch.getValue(time)

    # Convert from C to F if necessary
    if unit_type == "Temperature"
      val = OpenStudio.convert(val, "C", "F").get
    end

    # populate hash
    time_val_hash[hr + min/60.0] = val # just want double for time, not openstudio time

    # set ceiling and floor
    if ceiling.nil? or ceiling < val
      ceiling = val
    end
    if floor.nil? or floor > val
      floor = val
    end
  end

  # populate vals
  val_old = nil # this is from previous datapoint going backwards
  time_val_hash.each do |time,val|

    # if value is same as previous then skip until there is a new value
    next if val == val_old

    # adjust value relative to floor or ceiling
    if ceiling - val < val - floor
      if ceiling > 0
        adj_val_in = (val/ceiling).round(2)
      else
        adj_val_in = 0
      end
      val_in_string = "opp_val*#{adj_val_in}"
    else
      if ceiling > 0
        adj_val_in = (val/floor).round(2)
      else
        adj_val_in = 0
      end
      val_in_string = "non_opp_val*#{adj_val_in}"
    end

    time_string = time # todo - update this to use hours of operation to create formula relative opp_range or non_opp_range. Don't use mutliplier so times say exactly on 30min.

    # turn value into formula
    if val_old.nil?
      vals << "[#{time_string};#{val_in_string}]" # should only hit this the first time
    else
      if ceiling - val < val - floor
        if ceiling > 0
          adj_val_out = (val/ceiling).round(2)
        else
          adj_val_out = 0
        end
        val_out_string = "opp_val*#{adj_val_in}"
      else
        if floor > 0
          adj_val_out = (val/floor).round(2)
        else
          adj_val_out = 0
        end
        val_out_string = "non_opp_val*#{adj_val_out}"
      end
      vals << "[#{time_string};#{val_in_string};#{val_out_string}]"
    end

    # set val_out for next item to use
    val_old = val

  end

  return [type,vals,ceiling,floor]

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

    # Determine the name and hoo for the schedule
    array = nil
    if sch_name.include?("ApartmentMidRise")
      array = ["MidriseApartment",8,18]
    elsif sch_name.include?("Hospital")
      array = ["Hospital",4,22]
    elsif sch_name.include?("HotelLarge")
      array = ["LargeHotel",6,22]
    elsif sch_name.include?("HotelSmall")
      array = ["SmallHotel",6,22]
    elsif sch_name.include?("OfficeMedium")
      array = ["OfficeMedium",8,17]
    elsif sch_name.include?("OfficeSmall")
      array = ["OfficeSmall",8,17]
    elsif sch_name.include?("OfficeLarge")
      array = ["OfficeLarge",8,17]
    elsif sch_name.include?("OutPatientHealthCare")
      array = ["Outpatient",4,22]
    elsif sch_name.include?("RestaurantFastFood")
      array = ["QuickServiceRestaurant",7,23]
    elsif sch_name.include?("RestaurantSitDown")
      array = ["FullServiceRestaurant",7,23]
    elsif sch_name.include?("RetailStandalone")
      array = ["Retail",7,21]
    elsif sch_name.include?("RetailStripmall")
      array = ["StripMall",6,22]
    elsif sch_name.include?("SchoolPrimary")
      array = ["PrimarySchool",8,16]
    elsif sch_name.include?("SchoolSecondary")
      array = ["SecondarySchool",0,0]
    elsif sch_name.include?("Warehouse")
      array = ["Warehouse",7,17]
    else
      array = ["Unknown",8,17]
    end
    building_type = array[0]
    hoo_start = array[1]
    hoo_finish = array[2]

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
    vals = get_half_hr_vals(sch_ruleset.defaultDaySchedule, units,hoo_start,hoo_finish)
    row["data"] = {}
    row["data"]["start_date"] = year_start_date
    row["data"]["end_date"] = year_end_date
    row["data"]["opp_value"] = vals[2]
    row["data"]["non_opp_value"] = vals[3]
    row["data"]["type"] = vals[0]
    row["data"]["vals"] = vals[1].reverse
    sch_rows << row
    
    # Winter Design Day
    if sch_ruleset.isWinterDesignDayScheduleDefaulted == false
      row = {}
      row["name"] = sch_name
      row["category"] = category
      row["units"] = units
      row["day_types"] = ["WntrDsn"]
      vals = get_half_hr_vals(sch_ruleset.defaultDaySchedule, units,hoo_start,hoo_finish)
      row["data"] = {}
      row["data"]["start_date"] = year_start_date
      row["data"]["end_date"] = year_end_date
      row["data"]["opp_value"] = vals[2]
      row["data"]["non_opp_value"] = vals[3]
      row["data"]["type"] = vals[0]
      row["data"]["vals"] = vals[1].reverse
      sch_rows << row    
    end
    
    # Summer Design Day
    if sch_ruleset.isSummerDesignDayScheduleDefaulted == false
      row = {}
      row["name"] = sch_name
      row["category"] = category
      row["units"] = units
      row["day_types"] = ["SmrDsn"]
      vals = get_half_hr_vals(sch_ruleset.defaultDaySchedule, units,hoo_start,hoo_finish)
      row["data"] = {}
      row["data"]["start_date"] = year_start_date
      row["data"]["end_date"] = year_end_date
      row["data"]["opp_value"] = vals[2]
      row["data"]["non_opp_value"] = vals[3]
      row["data"]["type"] = vals[0]
      row["data"]["vals"] = vals[1].reverse
      sch_rows << row    
    end

    # Schedule rules
    sch_ruleset.scheduleRules.each do |rule|
      row = {}
      row["name"] = sch_name
      row["building_type"] = building_type
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
      vals = get_half_hr_vals(sch_ruleset.defaultDaySchedule, units,hoo_start,hoo_finish)
      row["data"] = {}
      row["data"]["start_date"] = "#{rule.startDate.get.monthOfYear.value}/#{rule.startDate.get.dayOfMonth}"
      row["data"]["end_date"] = "#{rule.endDate.get.monthOfYear.value}/#{rule.endDate.get.dayOfMonth}"
      row["data"]["opp_value"] = vals[2]
      row["data"]["non_opp_value"] = vals[3]
      row["data"]["type"] = vals[0]
      row["data"]["vals"] = vals[1].reverse
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
      line = "#{csr["name"]},#{csr["building_type"]},#{csr["category"]},#{csr["units"]},#{csr["day_types"].join('|')},#{csr["data"]["start_date"]},#{csr["data"]["end_date"]},#{csr["data"]["opp_value"]},#{csr["data"]["non_opp_value"]},#{csr["data"]["type"]},#{csr["data"]["vals"].join(',')}"
      puts line
      file.puts line
    end
    
  end
end

puts "There are #{all_schs.size} schedules in the library"
