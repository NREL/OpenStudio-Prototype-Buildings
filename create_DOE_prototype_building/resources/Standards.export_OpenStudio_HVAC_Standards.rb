# This script reads OpenStudio_HVAC_Standards.xlsx
# and creates a JSON file containing all the information

require 'rubygems'
require 'json'
require 'rubyXL'

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
      seed
    end
  end
  
end

begin

  # Path to the xlsx file
  xlsx_path = "#{Dir.pwd}/OpenStudio_HVAC_Standards.xlsx"

  # List of columns that are boolean
  # (rubyXL returns 0 or 1, will translate to true/false)
  bool_cols = []
  bool_cols << 'hx'  
  
  # Open workbook
  workbook = RubyXL::Parser.parse(xlsx_path)

  standards_data = {}
  workbook.worksheets.each do |worksheet|
    #puts worksheet.methods.sort
    sheet_name = worksheet.sheet_name.snake_case
    puts "Exporting #{sheet_name}"
    
    # All spreadsheets must have headers in row 3
    # and data from roworksheet 4 onward.
    header_row = 2 # Base 0

    # Get all data
    all_data = worksheet.extract_data
    
    # Get the header row data
    header_data = all_data[header_row]

    # Format the headers and parse out units (in parentheses)
    headers = []
    header_data.each do |header_string|
      break if header_string.nil?
      header = {}
      header["name"] = header_string.gsub(/\(.*\)/,'').strip.snake_case
      header_unit_parens = header_string.scan(/\(.*\)/)[0]
      if header_unit_parens.nil?
        header["units"] = nil
      else
        header["units"] = header_unit_parens.gsub(/\(|\)/,'').strip
      end
      headers << header
    end
    puts "--found #{headers.size} columns"
    
    # Loop through all rows and export
    # data for the row to a hash.
    objs = []
    for i in (header_row + 1)..(all_data.size - 1)
      row = all_data[i]     
      obj = {}
      all_null = true
      for j in 0..headers.size - 1
        val = row[j]
        if !val.nil?
          all_null = false
        end
        # Convert specified columns to boolean
        if bool_cols.include?(headers[j]['name'])
          if val == 1
            val = true
          elsif val == 0
            val = false
          else
            val = nil
          end
        end
        obj[headers[j]["name"]] = val
        # Skip recording units for unitless values
        next if headers[j]["units"].nil?
        #obj["#{headers[j]["name"]}_units"] = headers[j]["units"]
      end
      
      # Skip recording empty rows
      next if all_null == true
      
        # Store the array of objects
        # special cases for some types
        if sheet_name == 'schedules'
          new_obj = {}
          new_obj['name'] = obj['name']
          items = []
          obj.each do |key, val|
            # Skip the key
            next if key == 'name'
            # Put materials into an array,
            # record other fields normally
            if key.include?('hr')
              # Skip blank hourly values
              next if val.nil?
              items << val
            else
              new_obj[key] = val
            end
          end
          new_obj['values'] = items
          objs << new_obj
        else
          objs << obj
        end

    end
    
    # Report how many objects were found
    puts "--found #{objs.size} rows"
    
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


end
