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

require "#{File.dirname(__FILE__)}/../lib/btap"
# To change this template, choose Tools | Templates
# and open the template in the editor.

#Load OSM file change path as necessary.

model = BTAP::FileIO::load_osm('C:\osruby\Resources\BasicFiles\5ZoneNoHVAC.osm')

#add_sys1_unitary_ac_baseboard_heating(model,heating_coil_type,baseboard_type,boiler_fueltype)
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys1_unitary_ac_baseboard_heating(model,"Hot Water","Hot Water","NaturalGas")
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys1_unitary_ac_baseboard_heating(model,"Hot Water","Hot Water","Electricity")
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys1_unitary_ac_baseboard_heating(model,"Hot Water","Hot Water","PropaneGas")
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys1_unitary_ac_baseboard_heating(model,"Hot Water","Electric","NaturalGas")
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys1_unitary_ac_baseboard_heating(model,"Electric","Electric","NaturalGas")
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys1_unitary_ac_baseboard_heating(model,"Electric","Hot Water","NaturalGas")
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys1_unitary_ac_baseboard_heating(model,"Gas","Hot Water","NaturalGas")
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys1_unitary_ac_baseboard_heating(model,"Gas","Electric","NaturalGas")

#BTAP::Resources::HVAC::HVACTemplates::ASHRAE90_1::addSys3PSZAC(model)

#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys2_four_pipe_fan_coil(model, "NaturalGas")

#add_sys3_single_zone_packaged_rooftop_unit_with_baseboard_heating( model, heating_coil_type, baseboard_type, boiler_fueltype)
BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys3_single_zone_packaged_rooftop_unit_with_baseboard_heating(model, "Electric", "Hot Water", "PropaneGas")

#save file.
#BTAP::FileIO::save_osm(model, 'C:/osruby/Resources/BasicFiles/necbsys2-test.osm')
#BTAP::FileIO::save_osm(model, 'C:/osruby/Resources/BasicFiles/ashrae-pzac.osm')
BTAP::FileIO::save_osm(model, 'C:/osruby/Resources/BasicFiles/necbsys3-test.osm')





