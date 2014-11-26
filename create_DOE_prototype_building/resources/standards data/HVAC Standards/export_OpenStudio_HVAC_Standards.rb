# This script reads OpenStudio_HVAC_Standards.xlsx
# and creates a JSON file containing all the information

require 'rubygems'
require 'json'
require 'win32ole'

class String

  def snake_case
    self.downcase.gsub(' ','_')
  end

end

class Hash
  
  def sort_by_key(recursive = false, &block)
    self.keys.sort(&block).reduce({}) do |seed, key|
      seed[key] = self[key]
      if recursive && seed[key].is_a?(Hash)
        seed[key] = seed[key].sort_by_key(true, &block)
      end
      return seed
    end
  end
  
end

def getNumRoworksheet(worksheet, column, begin_row)
  # find number of roworksheet
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

begin

  # Path to the xlsx file
  xlsx_path = "#{Dir.pwd}/OpenStudio_HVAC_Standards.xlsx"
  # Enable Excel
  xl = WIN32OLE::new('Excel.Application')
  # Open workbook
  workbook = xl.workbooks.open(xlsx_path)

  standards_data = {}
  workbook.worksheets.each do |worksheet|
    
    sheet_name = worksheet.name.snake_case
    puts "Exporting #{sheet_name}"
    
    # All spreadsheets must have headers in row 3
    # and data from roworksheet 4 onward.
    header_row = 3
    begin_column = "A"
    end_column = "ZZ"
    begin_data_row = 4
    end_data_row = getNumRoworksheet(worksheet, begin_column, begin_data_row)
    
    # Get the headers
    header_data = worksheet.range("#{begin_column}#{header_row}:#{end_column}#{header_row}").value[0]

    # Rename the headers and parse out units
    headers = []
    header_data.each do |header_string|
      break if header_string.nil?
      # TODO parse out header units
      #
      header = {}
      header["name"] = header_string.gsub(/\(.*\)/,'').strip.snake_case  
      headers << header
    end
    puts "--found #{headers.size} columns"
    
    # Get the data
    data = worksheet.range("#{begin_column}#{begin_data_row}:#{end_column}#{end_data_row}").value
    puts "--found #{data.size} rows"

    # Loop through all rows and export
    # data for the row to a hash.
    objs = []
    data.each do |row|
      obj = {}
      for i in 0..headers.size - 1
        val = row[i]
        # Don't store nil values in the JSON
        # next if val.nil?
        obj[headers[i]["name"]] = val
      end
      objs << obj
    end
    
    # Save this hash 
    standards_data[sheet_name] = objs

  end

  # Sort the standard data so it can be diffed easily
  sorted_standards_data = standards_data.sort_by_key(true) {|x,y| x.to_s <=> y.to_s}

  # Write the hash to a JSON file
  File.open("#{Dir.pwd}/OpenStudio_HVAC_Standards.json", 'w') do |file|
    file << JSON::pretty_generate(sorted_standards_data)
  end
  puts "Successfully generated OpenStudio_HVAC_Standards.json"
  
ensure

  # Close workbook
  workbook.Close(1)
  # Quit Excel
  xl.Quit

end
