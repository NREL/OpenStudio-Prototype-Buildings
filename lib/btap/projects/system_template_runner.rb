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
require "#{File.dirname(__FILE__)}/btap/btap"
# To change this template, choose Tools | Templates
# and open the template in the editor.

#Store original model so we dont have to reload it everytime.
original_model = BTAP::FileIO::load_osm('C:\osruby\Resources\BasicFiles\5ZoneNoHVAC.osm')

#make a copy of the original that we can modify.
model = BTAP::FileIO::deep_copy(original_model, true)
BTAP::Resources::HVAC::HVACTemplates::ASHRAE90_1::addSys1PTACResidential(model)
BTAP::FileIO::save_osm(model, 'C:\osruby\Resources\A901SystemTemplates\Sys1PTACResidential.osm')

#make a copy of the original that we can modify.
model = BTAP::FileIO::deep_copy(original_model, true)
BTAP::Resources::HVAC::HVACTemplates::ASHRAE90_1::addSys2PTHPResidential(model)
BTAP::FileIO::save_osm(model, 'C:\osruby\Resources\A901SystemTemplates\Sys2PTHPResidential.osm')

#make a copy of the original that we can modify.
model = BTAP::FileIO::deep_copy(original_model, true)
BTAP::Resources::HVAC::HVACTemplates::ASHRAE90_1::addSys3PSZAC(model)
BTAP::FileIO::save_osm(model, 'C:\osruby\Resources\A901SystemTemplates\Sys3PSZAC.osm')

#make a copy of the original that we can modify.
model = BTAP::FileIO::deep_copy(original_model, true)
BTAP::Resources::HVAC::HVACTemplates::ASHRAE90_1::addSys4PSZHP(model)
BTAP::FileIO::save_osm(model, 'C:\osruby\Resources\A901SystemTemplates\Sys4PSZHP.osm')

#make a copy of the original that we can modify.
model = BTAP::FileIO::deep_copy(original_model, true)
BTAP::Resources::HVAC::HVACTemplates::ASHRAE90_1::addSys5PVAVR(model)
BTAP::FileIO::save_osm(model, 'C:\osruby\Resources\A901SystemTemplates\Sys5PVAVR.osm')

#make a copy of the original that we can modify.
model = BTAP::FileIO::deep_copy(original_model, true)
BTAP::Resources::HVAC::HVACTemplates::ASHRAE90_1::addSys6PVAVwPFPBoxes(model)
BTAP::FileIO::save_osm(model, 'C:\osruby\Resources\A901SystemTemplates\Sys6PVAVwPFPBoxes.osm')

#make a copy of the original that we can modify.
model = BTAP::FileIO::deep_copy(original_model, true)
BTAP::Resources::HVAC::HVACTemplates::ASHRAE90_1::addSys7VAVwReheat(model)
BTAP::FileIO::save_osm(model, 'C:\osruby\Resources\A901SystemTemplates\Sys7VAVwReheat.osm')

#make a copy of the original that we can modify.
model = BTAP::FileIO::deep_copy(original_model, true)
BTAP::Resources::HVAC::HVACTemplates::ASHRAE90_1::addSys8VAVwPFPBoxes(model)
BTAP::FileIO::save_osm(model, 'C:\osruby\Resources\A901SystemTemplates\Sys8VAVwPFPBoxess.osm')

#make a copy of the original that we can modify.
model = BTAP::FileIO::deep_copy(original_model, true)
BTAP::Resources::HVAC::HVACTemplates::ASHRAE90_1::addSys9GasFiredWarmAirFurnace(model)
BTAP::FileIO::save_osm(model, 'C:\osruby\Resources\A901SystemTemplates\Sys9GasFiredWarmAirFurnace.osm')

#make a copy of the original that we can modify.
model = BTAP::FileIO::deep_copy(original_model, true)
BTAP::Resources::HVAC::HVACTemplates::ASHRAE90_1::addSys10ElectricWarmAirFurnace(model)
BTAP::FileIO::save_osm(model, 'C:\osruby\Resources\A901SystemTemplates\Sys10ElectricWarmAirFurnace.osm')





## NECB system template methods.
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys1_unitary_ac_baseboard_heating(model,all_zones, "Baseboard::Convective::Electric")
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys1_unitary_ac_baseboard_heating(model,all_zones, "Baseboard::Convective::Water","NaturalGas")
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys2_four_pipe_fan_coil(model, boiler_fuel_type)
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys3_single_zone_packaged_rooftop_unit_with_baseboard_heating( model, is_baseboard, heating_fueltype)
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys4_single_zone_make_up_air_unit_with_baseboard_heating( model, mua_unit_type, baseboard_fueltype)
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys5_two_pipe_fane_coil( model )
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys6_multi_zone_built_up_system_with_baseboard_heating( model , boiler_fuel_type )
#BTAP::Resources::HVAC::HVACTemplates::NECB2011::add_sys7_multi_zone_built_up_system_with_baseboard_heating( model , boiler_fuel_type )



