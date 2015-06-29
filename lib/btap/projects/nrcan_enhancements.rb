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

# To change this template, choose Tools | Templates
# and open the template in the editor.
$LOAD_PATH << BTAP::OS_RUBY_PATH + "\\lib\\"

#

class NC
  def self.getmodel
    return OpenStudio::Plugin.model_manager.model_interface.openstudio_model
  end

  def self.list_climate_files
    Dir["C:/EnergyPlusV7-2-0/WeatherData/*.epw"].each { |file| puts file}
    return nil
  end

  def self.climate_file(index)

  end
end
#  NRCanHelper::list_climate_files

require 'model'
require 'surface'
require 'sub_surface'
require 'thermal_zone'
require 'space'
require 'process_manager'
require 'schedule_names'
require 'thermostat_names'
require 'necb2011'
require 'weather_file'
require 'construction'
#
#
#puts "nrcan loaded"