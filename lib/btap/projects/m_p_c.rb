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
# To change this template, choose Tools | Templates
# and open the template in the editor.

require "#{File.dirname(__FILE__)}/../lib/btap"

BTAP::Compliance::NECB2011::create_necb_libraries()


#basefile = '../../Resources/MPC/prototypes/elephant_hvac_hydronic_cooling.osm'
#output = 'E:/MPC-HVAC/montreal'
#weatherfile = '../../weather_files/CAN_PQ_Montreal.Intl.AP.716270_CWEC.epw'
#BTAP::MPC::MPC.new(
#  basefile,
#  weatherfile,
#  output  )
#
#BTAP::SimManager::simulate_all_files_in_folder(output) 
#BTAP::FileIO::convert_all_eso_to_csv(output, output)
