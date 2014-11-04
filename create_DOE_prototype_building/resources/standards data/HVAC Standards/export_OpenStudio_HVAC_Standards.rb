#this script reads the prototype_hvac.xlsx spreadsheet
#and creates a JSON file containing all the information

require 'rubygems'
require 'json'
require 'openstudio'
require 'win32ole'

class Hash
  def sort_by_key(recursive = false, &block)
    self.keys.sort(&block).reduce({}) do |seed, key|
      seed[key] = self[key]
      if recursive && seed[key].is_a?(Hash)
        seed[key] = seed[key].sort_by_key(true, &block)
      end
      seed
    end
  end
end

def getNumRows(worksheet, column, begin_row)
  # find number of rows
  max_row = 12000
  end_row = begin_row
  data = worksheet.range("#{column}#{begin_row}:#{column}#{max_row}").value
  data.each do |row|
    if row[0].nil?
      end_row -= 1
      break
    end
    end_row += 1
  end
  return end_row
end

# Read the PrototypeInputs tab and put into a Hash
def getPrototypeInputs(workbook)
  # compound key for this sheet is [prototype_inputs]

  #specify worksheet
  worksheet = workbook.worksheets("PrototypeInputs")
  begin_column = "A"
  end_column = "K"
  begin_row = 4
  end_row = getNumRows(worksheet, begin_column, begin_row)
  
  # Specify data range
  data = worksheet.range("#{begin_column}#{begin_row}:#{end_column}#{end_row}").value

  # Define the columns where the data live in the spreadsheet
  template_col = 0
  climate_col = 1
  building_type_col = 2
  chw_pumping_type_col = 3
  chiller_cooling_type_col = 4
  chller_condenser_type_col = 5
  chiller_compressor_type_col = 6
  chiller_capacity_guess_col = 7
  unitary_ac_cooling_type_col = 8
  unitary_ac_heating_type_col = 9
  hx_col = 10
  
  # Create an array of Prototype Inputs
  prototype_inputs = []

  # Loop through all the prototype inputs and put them into a hash
  data.each do |row|
    prototype_input = {}
    
    # Basic Info
    prototype_input["template"] = row[template_col]
    prototype_input["climate_zone"] = row[climate_col]
    prototype_input["building_type"] = row[building_type_col]

    # Chilled water system inputs
    prototype_input["chw_pumping_type"] = row[chw_pumping_type_col]
    prototype_input["chiller_cooling_type"] = row[chiller_cooling_type_col]
    prototype_input["chller_condenser_type"] = row[chller_condenser_type_col]
    prototype_input["chiller_compressor_type"] = row[chiller_compressor_type_col]
    prototype_input["chiller_capacity_guess"] = row[chiller_capacity_guess_col]

    # Unitary AC inputs
    prototype_input["unitary_ac_cooling_type"] = row[unitary_ac_cooling_type_col]
    prototype_input["unitary_ac_heating_type"] = row[unitary_ac_heating_type_col]
    
    # HX inputs
    prototype_input["hx"] = row[hx_col]
    
    prototype_inputs << prototype_input
  
  end
  
  return prototype_inputs
end

# Read the Chiller tab and put into a Hash
def getChillers(workbook)
  # compound key for this sheet is [chillers]

  #specify worksheet
  worksheet = workbook.worksheets("Chillers")
  begin_column = "A"
  end_column = "K"
  begin_row = 4
  end_row = getNumRows(worksheet, begin_column, begin_row)
  
  #specify data range
  data = worksheet.range("#{begin_column}#{begin_row}:#{end_column}#{end_row}").value

  #define the columns where the data live in the spreadsheet
  template_col = 0
  cooling_type_col = 1
  condenser_type_col = 2
  compressor_type_col = 3
  minimum_capacity_col = 4
  maximum_capacity_col = 5
  minimum_cop_col = 6
  minimum_iplv_col = 7
  capft_col = 8
  eirft_col = 9
  eirfplr_col = 10
  
  # Create an array of Chillers
  chillers = []

  # Loop through all the Chiller inputs and put them into a hash
  data.each do |row|
    chiller = {}
    
    # Basic Info
    chiller["template"] = row[template_col]
    
    # Chiller Properties
    chiller["cooling_type"] = row[cooling_type_col]
    chiller["condenser_type"] = row[condenser_type_col]
    chiller["compressor_type"] = row[compressor_type_col]
    chiller["minimum_capacity"] = row[minimum_capacity_col]
    chiller["maximum_capacity"] = row[maximum_capacity_col]
    chiller["minimum_cop"] = row[minimum_cop_col]
    chiller["minimum_iplv"] = row[minimum_iplv_col]
    chiller["capft"] = row[capft_col]
    chiller["eirft"] = row[eirft_col]
    chiller["eirfplr"] = row[eirfplr_col]
    
    chillers << chiller
  
  end
  
  return chillers
end

# Read the Chiller tab and put into a Hash
def getUnitaryACs(workbook)
  # compound key for this sheet is [unitary_acs]

  #specify worksheet
  worksheet = workbook.worksheets("UnitaryAC")
  begin_column = "A"
  end_column = "K"
  begin_row = 4
  end_row = getNumRows(worksheet, begin_column, begin_row)
  
  #specify data range
  data = worksheet.range("#{begin_column}#{begin_row}:#{end_column}#{end_row}").value

  #define the columns where the data live in the spreadsheet
  template_col = 0
  cooling_type_col = 1
  heating_type_col = 2
  subcategory_col = 3
  minimum_capacity_col = 4
  maximum_capacity_col = 5
  minimum_seer_col = 6
  minimum_eer_col = 7
  minimum_iplv_col = 8
  
  # Create an array of unitary_acs
  unitary_acs = []

  # Loop through all the unitary_ac inputs and put them into a hash
  data.each do |row|
    unitary_ac = {}
    
    # Basic Info
    unitary_ac["template"] = row[template_col]
    
    # unitary_ac Properties
    unitary_ac["cooling_type"] = row[cooling_type_col]
    unitary_ac["heating_type"] = row[heating_type_col]
    unitary_ac["subcategory"] = row[subcategory_col]
    unitary_ac["minimum_capacity"] = row[minimum_capacity_col]
    unitary_ac["maximum_capacity"] = row[maximum_capacity_col]
    unitary_ac["minimum_seer"] = row[minimum_seer_col]
    unitary_ac["minimum_eer"] = row[minimum_eer_col]
    unitary_ac["minimum_iplv"] = row[minimum_iplv_col]
    
    unitary_acs << unitary_ac
  
  end
  
  return unitary_acs
end

# Read the CurveBiquadratic tab and put into a Hash
def getCurveBiquadratics(workbook)
  # compound key for this sheet is [curve_biquadratics]

  #specify worksheet
  worksheet = workbook.worksheets("CurveBiquadratic")
  begin_column = "A"
  end_column = "L"
  begin_row = 4
  end_row = getNumRows(worksheet, begin_column, begin_row)
  
  #specify data range
  data = worksheet.range("#{begin_column}#{begin_row}:#{end_column}#{end_row}").value

  #define the columns where the data live in the spreadsheet
  name_col = 0
  coeff_1_col = 1
  coeff_2_col = 2
  coeff_3_col = 3
  coeff_4_col = 4
  coeff_5_col = 5
  coeff_6_col = 6
  min_x_col = 7
  max_x_col = 8
  min_y_col = 9
  max_y_col = 10
  notes_col = 11
  
  # Create an array of Chillers
  curves = []
  
  # Loop through all the Chiller inputs and put them into a hash
  data.each do |row|
    curve = {}
    
    # Basic Info
    curve["name"] = row[name_col]
    
    # Curve Coefficients
    curve["coeff_1"] = row[coeff_1_col]
    curve["coeff_2"] = row[coeff_2_col]
    curve["coeff_3"] = row[coeff_3_col]
    curve["coeff_4"] = row[coeff_4_col]
    curve["coeff_5"] = row[coeff_5_col]
    curve["coeff_6"] = row[coeff_6_col]
    curve["min_x"] = row[min_x_col]
    curve["max_x"] = row[max_x_col]
    curve["min_y"] = row[min_y_col]
    curve["max_y"] = row[max_y_col]
    curve["notes"] = row[notes_col]
    
    curves << curve
  
  end
  
  return curves
end

# Read the CurveBiquadratic tab and put into a Hash
def getCurveQuadratics(workbook)
  # compound key for this sheet is [curve_biquadratics]

  #specify worksheet
  worksheet = workbook.worksheets("CurveQuadratic")
  begin_column = "A"
  end_column = "L"
  begin_row = 4
  end_row = getNumRows(worksheet, begin_column, begin_row)
  
  #specify data range
  data = worksheet.range("#{begin_column}#{begin_row}:#{end_column}#{end_row}").value

  #define the columns where the data live in the spreadsheet
  name_col = 0
  coeff_1_col = 1
  coeff_2_col = 2
  coeff_3_col = 3
  min_x_col = 4
  max_x_col = 5
  notes_col = 6
  
  # Create an array of Chillers
  curves = []
  
  # Loop through all the Chiller inputs and put them into a hash
  data.each do |row|
    curve = {}
    
    # Basic Info
    curve["name"] = row[name_col]
    
    # Curve Coefficients
    curve["coeff_1"] = row[coeff_1_col]
    curve["coeff_2"] = row[coeff_2_col]
    curve["coeff_3"] = row[coeff_3_col]
    curve["min_x"] = row[min_x_col]
    curve["max_x"] = row[max_x_col]
    curve["notes"] = row[notes_col]
    
    curves << curve
  
  end
  
  return curves
end

# Read the CurveBiquadratic tab and put into a Hash
def getCurveBicubics(workbook)
  # compound key for this sheet is [curve_biquadratics]

  #specify worksheet
  worksheet = workbook.worksheets("CurveBicubic")
  begin_column = "A"
  end_column = "L"
  begin_row = 4
  end_row = getNumRows(worksheet, begin_column, begin_row)
  
  #specify data range
  data = worksheet.range("#{begin_column}#{begin_row}:#{end_column}#{end_row}").value

  #define the columns where the data live in the spreadsheet
  name_col = 0
  coeff_1_col = 1
  coeff_2_col = 2
  coeff_3_col = 3
  coeff_4_col = 4
  coeff_5_col = 5
  coeff_6_col = 6
  coeff_7_col = 7
  coeff_8_col = 8
  coeff_9_col = 9
  coeff_10_col = 10
  min_x_col = 11
  max_x_col = 12
  min_y_col = 13
  max_y_col = 14
  notes_col = 15
  
  # Create an array of Chillers
  curves = []
  
  # Loop through all the Chiller inputs and put them into a hash
  data.each do |row|
    curve = {}
    
    # Basic Info
    curve["name"] = row[name_col]
    
    # Curve Coefficients
    curve["coeff_1"] = row[coeff_1_col]
    curve["coeff_2"] = row[coeff_2_col]
    curve["coeff_3"] = row[coeff_3_col]
    curve["coeff_4"] = row[coeff_4_col]
    curve["coeff_5"] = row[coeff_5_col]
    curve["coeff_6"] = row[coeff_6_col]
    curve["coeff_7"] = row[coeff_7_col]
    curve["coeff_8"] = row[coeff_8_col]
    curve["coeff_9"] = row[coeff_9_col]
    curve["coeff_10"] = row[coeff_10_col]
    curve["min_x"] = row[min_x_col]
    curve["max_x"] = row[max_x_col]
    curve["min_y"] = row[min_y_col]
    curve["max_y"] = row[max_y_col]
    curve["notes"] = row[notes_col]
    
    curves << curve
  
  end
  
  return curves
end

# Read the CurveBiquadratic tab and put into a Hash
def getMotors(workbook)
  # compound key for this sheet is [motors]

  #specify worksheet
  worksheet = workbook.worksheets("Motors")
  begin_column = "A"
  end_column = "L"
  begin_row = 4
  end_row = getNumRows(worksheet, begin_column, begin_row)
  
  #specify data range
  data = worksheet.range("#{begin_column}#{begin_row}:#{end_column}#{end_row}").value

  #define the columns where the data live in the spreadsheet
  template_col = 0
  number_of_poles_col = 1
  type_col = 2
  minimum_capacity_col = 3
  maximum_capacity_col = 4
  nominal_full_load_efficiency_col = 5
  notes_col = 6
  
  # Create an array of Motors
  motors = []
  
  # Loop through all the Chiller inputs and put them into a hash
  data.each do |row|
    motor = {}
    
    # motor Coefficients
    motor["template"] = row[template_col]
    motor["number_of_poles"] = row[number_of_poles_col]
    motor["type"] = row[type_col]
    motor["minimum_capacity"] = row[minimum_capacity_col]
    motor["maximum_capacity"] = row[maximum_capacity_col]
    motor["nominal_full_load_efficiency"] = row[nominal_full_load_efficiency_col]
    motor["notes"] = row[notes_col]
    
    motors << motor
  
  end
  
  return motors
end

#load in the space types
#path to the space types xl file
xlsx_path = "#{Dir.pwd}/OpenStudio_HVAC_Standards.xlsx"
#enable Excel
xl = WIN32OLE::new('Excel.Application')
#open workbook
wb = xl.workbooks.open(xlsx_path)

begin

  prototype_input_data = Hash.new
  prototype_input_data["prototype_inputs"] = getPrototypeInputs(wb)
  prototype_input_data["chillers"] = getChillers(wb)
  prototype_input_data["curve_biquadratics"] = getCurveBiquadratics(wb)
  prototype_input_data["curve_quadratics"] = getCurveQuadratics(wb)
  prototype_input_data["curve_bicubics"] = getCurveBicubics(wb)
  prototype_input_data["motors"] = getMotors(wb)
  prototype_input_data["unitary_acs"] = getUnitaryACs(wb)
  
  sorted_standards = prototype_input_data.sort_by_key(true) {|x,y| x.to_s <=> y.to_s}

  # Write the hash to a JSON file
  File.open("#{Dir.pwd}/OpenStudio_HVAC_Standards.json", 'w') do |file|
    file << JSON::pretty_generate(sorted_standards)
  end
  puts "Successfully generated OpenStudio_HVAC_Standards.json"

ensure

  #close workbook
  wb.Close(1)
  #quit Excel
  xl.Quit

end









  