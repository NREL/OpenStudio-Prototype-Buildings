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

require 'btap/btap'

# Scripts to generate CSV-format data for use in OpenStudi Standards Excel sheet

building_data = BTAP::Compliance::NECB2011::Data::BuildingTypeData
spacetype_data = BTAP::Compliance::NECB2011::Data::SpaceTypeData

def commas(number)
  i = 0
  commastring = ""
  while i < number
    commastring += ","
    i+=1
  end
  return commastring
end

def do_buildingtypes(data)
  meters_to_feet = 3.28084
  sqm_to_sqf = 10.764
  volumetric_flux = 196.9

  data.each { |line |
    print "NECB-CNEB 2011" + ","
    print "NECB-CNEB ClimatZone 4-8" + ","
    print line[0] + "," # building type
    print "WholeBuilding" + "," # space type
    print "255_255_255" + "," # color
    print "NECB-CNEB 2011" + "," # lighting standard
    print line[0] + "," # primary space type
    print "WholeBuilding" + "," # secondary space type
    print commas(3)
    print "," # STD lighting uses a lookup
    print commas(5)
    print line[2] + "," # schedule
    print "NECB-CNEB 2011" + "," # ventilation standard
    print line[0] + "," # primary space type
    print "WholeBuilding" + "," # secondary space type
    print commas(4)
    print ((((1.0/line[3])*1000/sqm_to_sqf)*100).round.to_f/100).to_s + "," # Occupancy in people/1000ft2
    print line[2] + "," # schedule
    print line[2] + "," # schedule
    print (line[10]*volumetric_flux).to_s + "," # Infiltration
    print line[2] + "," # schedule
    print "," # gas equipment
    print commas(35-30-2)
    print line[2] + "," # schedule
    print (line[4]/sqm_to_sqf).to_s + "," # Plug Loads w/m2
    print commas(3)
    print line[2] + "," # schedule
    print line[2] + "," # schedule Thermostats
    print line[2] + "," # schedule
    print commas(6) # service hot water
    print line[2] + "," # schedule
    print commas(6) # exhaust
    print line[2] # schedule
    puts ","

  }
end

def do_ventilation(data,isBuilding)
  data.each { |line |
    primary = get_primary(line[0])
    if primary == "- undefined -"
      next
    end
    secondary = get_secondary(line[0])
    print ","
    print "NECB-CNEB 2011" + ","
    print (isBuilding ? line[0] : primary) + "," # primary space type
    print (isBuilding ? "WholeBuilding" : secondary) + "," # secondary space type
    print ","
    print ","
    print line[7].to_s + ","
    puts ","
  }
end

def do_lighting(data,isBuilding)
  sqm_to_sqf = 10.764

  data.each { |line |
    primary = get_primary(line[0])
    if primary == "- undefined -"
      next
    end
    secondary = get_secondary(line[0])
    print ","
    print "NECB-CNEB 2011" + ","
    print (isBuilding ? line[0] : primary) + "," # primary space type
    print (isBuilding ? "WholeBuilding" : secondary) + "," # secondary space type
    print (line[6]/sqm_to_sqf).to_s + ","
    puts ","
  }
end

def get_primary(name)
  if name.include? " - "
    return name.split(" - ")[0]
  else
    return name
  end
end

def get_secondary(name)
  if name.include? " - "
    return name.split(" - ")[1].capitalize
  else
    return name
  end
end

def do_spacetypes(data)
  sqm_to_sqf = 10.764
  volumetric_flux = 196.9

  data.each { |line |
    primary = get_primary(line[0])
    if primary == "- undefined -"
      next
    end
    secondary = get_secondary(line[0])
    print "NECB-CNEB 2011" + ","
    print "NECB-CNEB ClimatZone 4-8" + ","
    print "," # building type
    print line[0] + "," # space type
    print "255_255_255" + "," # color
    print "NECB-CNEB 2011" + "," # lighting standard
    print primary + "," # primary space type
    print secondary + "," # secondary space type
    print commas(3)
    print "," # print (((line[6]/sqm_to_sqf)*100).round.to_f/100).to_s + "," # STD lighting
    print commas(5)
    print line[2] + "," # schedule
    print "NECB-CNEB 2011" + "," # ventilation standard
    print primary + "," # primary space type
    print secondary + "," # secondary space type
    print commas(4)
    print ((((1.0/line[3])*1000/sqm_to_sqf)*100).round.to_f/100).to_s + "," # Occupancy in people/1000ft2
    print line[2] + "," # schedule
    print line[2] + "," # schedule
    print (line[10]*volumetric_flux).to_s + "," # Infiltration
    print line[2] + "," # schedule
    print "," # gas equipment
    print commas(35-30-2)
    print line[2] + "," # schedule
    print (line[4]/sqm_to_sqf).to_s + "," # Plug Loads w/m2
    print commas(3)
    print line[2] + "," # schedule
    print line[2] + "," # schedule Thermostats
    print line[2] + "," # schedule
    print commas(6) # service hot water
    print line[2] + "," # schedule
    print commas(6) # exhaust
    print line[2] # schedule
    puts ","

  }
end

do_buildingtypes(building_data)
do_ventilation(building_data,true)
do_lighting(building_data,true)
do_spacetypes(spacetype_data)
do_lighting(spacetype_data,false)
do_ventilation(spacetype_data,false)