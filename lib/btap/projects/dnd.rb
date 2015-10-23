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
require 'btap/btap'



class DND

  
  def initialize()
    @counter = 0
    @vintage_name =
      [
      [1, "Vintage 1" ,"Constructed post-2004"],
      [2, "Vintage 2","Constructed 1980-2004"],
      [3, "Vintage 3", "Constructed 1960-1980"],
      [4, "Vintage 4", "Constructed Pre-1960" ]
    ]


    @vintages = [1]#,2,3,4]
    @buildings = [
      #["19","Fire Hall"]#, # 1.3 minutes
      #      ["34","Offices"], # 4 minutes
            ["58","Fitness & Rec. - Multi-gym"] # 5 minutes
      #      ["119","Retail Bldgs"], # 1m
      #      ["120","Offices"], # 6m
      #      ["231","Sleeping barracks"], # 36s
      #      ["260","Sleeping barracks"], # 35s
      #      ["362","Fitness & Rec. - Pool"], # 4m49s
      #      ["414","Motel Type Residences"] # 7m49s
      #      ["358","Workshops"] # fixed
      #      ["152","Workshops"] # fixed 1m44s
      #      ["56_v4","Offices"] # fixed 8 min (must review
      #      ["604","Hangers"] broken
      #      ["607", "Hangers"] broken
      #      ["239", "Warehouses (Storage Bldgs)"]
      #      [111, "University Dormitory Type"
    ]





    #infilitration rates m3/s/m2 vintage 1,2,3,4
    @infil_rates = Hash[
      "Training Bldgs",                 [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Warehouses (Sheds)",             [ 0.00030, 0.00045,0.00075,0.00080 ],
      "Recreational / Club Bldgs",      [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Storage Bldgs",                  [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Workshops",                      [ 0.00030, 0.00045,0.00075,0.00080 ],
      "Communications & Control",       [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Misc. Bldgs < 100m2",            [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Hangars",                        [ 0.00030, 0.00045,0.00075,0.00080 ],
      "Air Terminal",                   [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Training Bldgs",                 [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Warehouses (Storage Bldgs)",     [ 0.00030, 0.00045,0.00075,0.00080 ],
      "Motel Type Residences",          [ 0.00020, 0.00035,0.00050,0.00070 ],
      "University Dormitory Type",      [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Sleeping barracks",              [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Fitness & Rec. - Multi-gym",     [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Fitness & Rec. - Arena",	        [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Fitness & Rec. - Pool",	        [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Offices",                        [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Food Services",                  [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Infrastructure",                 [ 0.00030, 0.00045,0.00075,0.00080 ],
      "Workshops",                      [ 0.00030, 0.00045,0.00075,0.00080 ],
      "Medical Facilities",             [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Retail Bldgs",                   [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Religious Bldgs",                [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Control Tower"  ,                [ 0.00020, 0.00035,0.00050,0.00070 ],
      "Fire Hall",                      [ 0.00030, 0.00045,0.00075,0.00080 ],
      "Museum",                         [ 0.00020, 0.00035,0.00050,0.00070 ]
    ]



    #Glazing properties using ASHRAE Fundamentals window IDs 22,7,5,and 23
    #Each set is conductance, TSol, TVis, UpgradeCost/M2
    @glazing_properties = [
      [ "G0",   [2.74,0.65,0.73, 0.00], [3.01,0.70,0.78, 0.00], [4.12,0.70,0.78, 0.00], [4.12,0.70,0.78, 0.00],   ],
      [ "G1",   [2.06,0.65,0.73, 0.00], [2.06,0.65,0.73, 0.00], [2.06,0.65,0.73, 0.00], [2.06,0.65,0.73, 0.00] ]
    ]

    #Concrete Wall rsi values and upgrade cost per square meter.(MUST reverse!!!!
    @wall_conc_array_rsi =
      [
      ["W0",    [2.82 , 0.0],             [2.11, 0.0],              [1.40, 0.0],                [(0.88), 0.0] ],
      ["W1",    [(2.82 + 1.32), 279.87],  [(2.11 + 1.32), 279.87],	[(1.40 + 1.32), 279.87],	  [(0.88 + 1.4),  62.43] ],
      ["W2",    [(2.82 + 1.32), 318.62],  [(2.11 + 1.32), 318.62],	[(1.40 + 1.32), 318.62],    [(0.88 + 2.0), 286.33] ],
      ["W3",    [(2.82 + 2.00), 286.33],  [(2.11 + 2.00), 286.33],  [(1.40 + 2.00),  286.66],	  "nil" ]
    ]
    @wall_metal_array_rsi =
      [
      ["W0",    [(2.82), 0.0],            [(2.11), 0.0],            [(1.40), 0.0],            [(0.88), 0.0] ],
      ["W1",    [(2.82 + 2.00), 258.34],  [(2.11 + 2.00), 258.34],  [( 1.40 + 2.00), 258.34], [1.4, 62.43] ],
      ["W2",    "nil",                    "nil",                    "nil",                    [2.0, 275.57 ] ],
      ["W3",    "nil",                    "nil",                    "nil",                    "nil"]
    ]

    @roof_deck_array_rsi =
      [
      ["R0",  [(3.52), 0.0],            [(1.76), 0.0],              [(0.70), 0.00],           [(0.70), 0.0] ], 
      ["R1",  [(3.52 + 1.76), 210.47],  [(1.76 + 1.76), 210.55],    [(0.70 + 2.64), 329.39],  [(0.70 + 2.64), 194.40] ], 
      ["R2",  [(3.52 + 3.87), 185.07],  [(1.76 + 3.87), 159.31],    [(0.70 + 3.87), 133.69],  [(0.70 + 3.87), 133.69] ],
      ["R3",  "nil",                    [(1.76 + 2.11), 314.53],    [(0.70 + 2.64), 186.44]   [(0.70 + 4.58), 299.25] ]
    ]

    @roof_metal_array_rsi =
      [
      ["R0",  [(2.81), 0.0],             [(2.81), 0.0],            [(1.05), 0.0],              [ (0.70), 0.0] ] ,
      ["R1",  [(2.81 + 1.76) , 134.77],  [(2.81 + 2.64 ),155.44 ], [(1.05 + 2.64 ), 237.24 ],  [ (0.70 + 2.64), 237.24 ] ],
      ["R2",  [(2.81 + 1.40) , 149.62],  [(2.81 + 1.40 ),149.62 ], [(1.05 + 3.70 ), 106.14 ],  [ (0.70 + 3.70), 237.24 ] ], 
      ["R3",  "nil",                     [(2.81 + 1.40 ),329.17 ], [(1.05 + 2.87 ), 175.89 ],  [ (0.70 + 3.87), 133.69 ] ]
    ]

    @construction_types =
      [
      #      ["M", @wall_metal_array_rsi, @roof_metal_array_rsi ],
      ["C", @wall_conc_array_rsi,  @roof_metal_array_rsi] #As per Mike for Trenton.
    ]

    @COP_ecms = [
      ["COP_default", "default", 0.00],
      ["COP_3.5", [3.5], 0.00]
    ]



    @lighting_ecms = [
      ["lights_0",  [1.00,0.0]],
      ["lights_1",  [0.70, 0.0]]

    ]

    @plug_loads_ecms = [
      ["plugs_0",  [1.00,     0.0]],
      ["plugs_1",  [0.80,     0.0]],
      ["plugs_2",  [0.70,     0.0]]
    ]

    @dcv_ecms = [
      ["dcv_default", [ "default"    ,0.0]],
      ["dcv_off" , [false     ,0.0]],
      ["dcv_on" , [true     ,0.0]]

    ]

    @infiltration_ecm = [
      ["inf_default", [ "default"    ,0.0]],
      ["inf_0_20",    [ 0.20    ,0.0]]
    ]
    
    
    



    #ERV input order.
    #            autosizeNominalSupplyAirFlowRate = true,
    #            setNominalSupplyAirFlowRate = nil,
    #            setHeatExchangerType = 'Plate', # 'Rotary' or 'Plate'
    #            setSensibleEffectivenessat100CoolingAirFlow = 0.76,
    #            setSensibleEffectivenessat75CoolingAirFlow  = 0.81,
    #            setLatentEffectiveness100Cooling = 0.68,
    #            setLatentEffectiveness75Cooling = 0.73,
    #            setSensibleEffectiveness100Heating = 0.76,
    #            setSensibleEffectiveness75Heating = 0.81,
    #            setLatentEffectiveness100Heating = 0.68,
    #            setLatentEffectiveness75Heating = 0.73,
    #            setSupplyAirOutletTemperatureControl = true,
    #            setFrostControlType = 'None', # 'None', 'ExhaustAirRecirculation','ExhaustOnly','MinimumExhaustTemperature'
    #            setThresholdTemperature  = 1.7,
    #            setInitialDefrostTimeFraction = 0,
    #            nominal_electric_power = nil,
    #            setEconomizerLockout = true
    @erv_ecms = [
      ["erv_default",  'default', 0.0 ],
      ["erv_plate",   [ true, nil, 'Plate',0.76, 0.81, 0.68, 0.73, 0.76, 0.81, 0.68, 0.73, true, 'None', 1.7, 0, nil, true],0.0],
      ["erv_rotary" , [ true, nil, 'Rotary',0.76, 0.81, 0.68, 0.73, 0.76, 0.81, 0.68, 0.73, true, 'None', 1.7, 0, nil, true],0.0]
    ]

    # Economizer input order.
    #          setEconomizerControlType = "FixedDryBulb",
    #          setEconomizerControlActionType = "ModulateFlow",
    #          setEconomizerMaximumLimitDryBulbTemperature = 28.0,
    #          setEconomizerMaximumLimitEnthalpy = 64000,
    #          setEconomizerMaximumLimitDewpointTemperature = 0.0,
    #          setEconomizerMinimumLimitDryBulbTemperature = -100.0
    #        )
    @economizer_ecms = [
      ["econ_default",  'default', 0.0],
      ["econ_fixedDB" , ["FixedDryBulb", "ModulateFlow", 19.0,64000, 0.0, -100.0], 0.0]

    ]

    #Max temp for heating, min temp for cooling.. Costing information.
    @temperature_setpoint_ecms = [
      ["temp_set_point_default", ['default'],[0.0]],
      ["temp_set_point_18_24",    [ 18.0    ,24.0], [0.0]]

    ]


    #create array of output variables strings from E+
    @output_variable_array =
      [
      "Facility Total Electric Demand Power",
      "Water Heater Gas Rate",
      "Facility Total HVAC Electric Demand Power",
      "Facility Total Electric Demand Power",
      "Plant Supply Side Heating Demand Rate",
      "Heating Coil Gas Rate",
      "Cooling Coil Electric Power",
      "Boiler Gas Rate",
      "Heating Coil Air Heating Rate",
      "Cooling Coil Total Cooling Rate",
      "Water Heater Heating Rate",
      "Zone Air Temperature",
      "Baseboard Air Inlet Temperature",
      "Baseboard Air Outlet Temperature",
      "Baseboard Water Inlet Temperature",
      "Baseboard Water Outlet Temperature",
      "Boiler Inlet Temperature",
      "Boiler Outlet Temperature",
      "Plant Supply Side Inlet Temperature",
      "Plant Supply Side Outlet Temperature",
      "People Radiant Heating Rate",
      "People Sensible Heating Rate",
      "People Latent Gain Rate",
      "People Total Heating Rate",
      "Lights Total Heating Rate",
      "Electric Equipment Total Heating Rate",
      "Other Equipment Total Heating Rate",
      "District Heating Hot Water Rate",
      "District Heating Rate",
      "Air System Outdoor Air Flow Fraction",
      "Air System Outdoor Air Minimum Flow Fraction",
      "Air System Fan Electric Energy"
    ]


  end



  ########ECMs######################

  #	(Done)  Wall retrofits
  #	(Done)  Roof retrofits
  #	(Done)  Lighting reduction (30%)
  #	(Done)  Plug loads reduction ( 20%/30%)
  #	(Done)  Demand Control Ventilation
  #	(Done)  Windows upgrade
  #	(Done - Testing)     Infiltration 0.6 ACH to 0.27 ACH
  #	(?-Should we do this?)     Reduce heating temperature setpoint (Occupied 20C; Unoccupied 18C)
  #	(Done)     ECM: Sensible HRV (70% effectiveness) on main air handling unit
  #	(Mike)  Solar thermal new
  #	(MIke)  Fixed DB Economizer on air handling units (19C upper temperature limit)
  #	(Mike)  Solar wall
  #	(Mike)  Hot Water Reset from 82C



  def dnd_common_ecms(building,osm_file_path, epw_weather_file, output_folder)

    FileUtils.mkdir_p(output_folder)

    #Header Flag
    header_printed = false

    #Create file to write characteristics of each simulation file.
    index_file_path = "#{output_folder}/#{building}_index.csv"
    File.delete(index_file_path) if File.exist?(index_file_path)
    index_file = File.new( index_file_path,'a')

    #load baseline model, set weather file.
    base_model = BTAP::FileIO::load_osm(osm_file_path)
    BTAP::Site::set_weather_file( base_model, epw_weather_file )

    #Set E+ hourly output.
    BTAP::Reports::clear_output_variables(base_model)
    BTAP::Reports::set_output_variables(base_model,"Hourly", @output_variable_array)

    #Save prototype locally
    BTAP::FileIO::save_osm(base_model, "#{output_folder}/\{#{building}_baseline\}.osm")

    #Create new model library.
    library = BTAP::FileIO::load_osm("C:/OSRuby/Resources/DOEArchetypes/blank.osm", "blank")
    #Need to add constructions sets from old model library.
    construction_lib = BTAP::FileIO::load_osm("C:/OSRuby/Resources/DND/Trenton/TrentonConstructionsLibrary.osm")
  
    
    #HVAC / Loads Study
    #iterate through vintages
    @vintages.each do |vintage|

      #iterate through @construction_types
      @construction_types.each do |construction_type|

        #Wall ECMs: iterate through wall retrofits
        construction_type[1].each do |wall_retrofit|

          create_variant(
            base_model,
            construction_lib,
            vintage ,
            construction_type,
            wall_retrofit,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            header_printed,
            library,
            building,
            output_folder,
            index_file
          )
        
        end
        #iterate through roof retrofits
        construction_type[2].each do |roof_retrofit|
          create_variant(
            base_model,
            construction_lib,
            vintage ,
            construction_type,
            nil,
            roof_retrofit,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            header_printed,
            library,
            building,
            output_folder,
            index_file
          )


        end
        #iterate through glazing retrofits
        [@glazing_properties[0]].each do |glazing_retrofit|
          create_variant(
            base_model,
            construction_lib,
            vintage ,
            construction_type,
            nil,
            nil,
            glazing_retrofit,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            header_printed,
            library,
            building,
            output_folder,
            index_file
          )
        end
        #lighting ECMs
        @lighting_ecms.each do |lighting_scale_factor|
          create_variant(
            base_model,
            construction_lib,
            vintage ,
            construction_type,
            nil,
            nil,
            nil,
            lighting_scale_factor,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            header_printed,
            library,
            building,
            output_folder,
            index_file
          )
        end
        #Plug ECMs
        @plug_loads_ecms.each do |plug_scale_factor|
          create_variant(
            base_model,
            construction_lib,
            vintage ,
            construction_type,
            nil,
            nil,
            nil,
            nil,
            plug_scale_factor,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            header_printed,
            library,
            building,
            output_folder,
            index_file
          )
        end
        #DCV ECMs
        @dcv_ecms.each do |enable_dcv|
          create_variant(
            base_model,
            construction_lib,
            vintage ,
            construction_type,
            nil,
            nil,
            nil,
            nil,
            nil,
            enable_dcv,
            nil,
            nil,
            nil,
            nil,
            nil,
            header_printed,
            library,
            building,
            output_folder,
            index_file
          )
        end
        #infiltration
        @infiltration_ecm.each do |infiltration_info|
          create_variant(
            base_model,
            construction_lib,
            vintage ,
            construction_type,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            infiltration_info,
            nil,
            nil,
            nil,
            nil,
            header_printed,
            library,
            building,
            output_folder,
            index_file
          )
        end
        # ERV ecms
        @erv_ecms.each do |erv_info|
          create_variant(
            base_model,
            construction_lib,
            vintage ,
            construction_type,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            erv_info,
            nil,
            nil,
            nil,
            header_printed,
            library,
            building,
            output_folder,
            index_file
          )
        end
        #Economizer ecms
        @economizer_ecms.each do |economizer_info|
          create_variant(
            base_model,
            construction_lib,
            vintage ,
            construction_type,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            economizer_info,
            nil,
            nil,
            header_printed,
            library,
            building,
            output_folder,
            index_file
          )
        end
        @temperature_setpoint_ecms.each do |temp_reduction_info|
          create_variant(
            base_model,
            construction_lib,
            vintage ,
            construction_type,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            temp_reduction_info,
            nil,
            header_printed,
            library,
            building,
            output_folder,
            index_file
          )
        end
        @COP_ecms.each do  |cop_info|
          create_variant(
            base_model,
            construction_lib,
            vintage ,
            construction_type,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            cop_info,
            header_printed,
            library,
            building,
            output_folder,
            index_file
          )
        end
        GC.start
      end
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
  
    #    #HVAC / Loads Study
    #    #iterate through vintages
    #    @vintages.each do |vintage|
    #
    #      #iterate through @construction_types
    #      @construction_types.each do |construction_type|
    #
    #        #Wall ECMs: iterate through wall retrofits
    #        [construction_type[1][0]].each do |wall_retrofit|
    #
    #          #iterate through roof retrofits
    #          [construction_type[2][0]].each do |roof_retrofit|
    #
    #            #iterate through glazing retrofits
    #            [@glazing_properties[0]].each do |glazing_retrofit|
    #
    #              #lighting ECMs
    #              @lighting_ecms.each do |lighting_scale_factor|
    #
    #                #Plug ECMs
    #                @plug_loads_ecms.each do |plug_scale_factor|
    #
    #                  #DCV ECMs
    #                  @dcv_ecms.each do |enable_dcv|
    #
    #                    #infiltration
    #                    infiltration_info = @infiltration_ecm[0]
    #
    #                    # ERV ecms
    #                    @erv_ecms.each do |erv_info|
    #
    #                      #Economizer ecms
    #                      @economizer_ecms.each do |economizer_info|
    #
    #                        @temperature_setpoint_ecms.each do |temp_reduction_info|
    #
    #                          @COP_ecms.each do  |cop_info|
    #
    #                            create_variant(
    #                              base_model,
    #                              construction_lib,
    #                              vintage ,
    #                              construction_type,
    #                              wall_retrofit,
    #                              roof_retrofit,
    #                              glazing_retrofit,
    #                              lighting_scale_factor,
    #                              plug_scale_factor,
    #                              enable_dcv,
    #                              infiltration_info,
    #                              erv_info,
    #                              economizer_info,
    #                              temp_reduction_info,
    #                              cop_info,
    #                              header_printed,
    #                              library,
    #                              building,
    #                              output_folder,
    #                              index_file
    #                            )
    #                            GC.start
    #                          end
    #                        end
    #                      end
    #                    end
    #                  end
    #                end
    #              end
    #            end
    #          end
    #        end
    #      end
    #    end
    #
    #    #Envelope and infiltration Study
    #    #iterate through vintages
    #    @vintages.each do |vintage|
    #
    #      #iterate through @construction_types
    #      @construction_types.each do |construction_type|
    #
    #        #Wall ECMs: iterate through wall retrofits
    #        construction_type[1].each do |wall_retrofit|
    #
    #          #iterate through roof retrofits
    #          construction_type[2].each do |roof_retrofit|
    #
    #            #iterate through glazing retrofits
    #            @glazing_properties.each do |glazing_retrofit|
    #
    #              #lighting ECMs
    #              lighting_scale_factor = @lighting_ecms[0]
    #
    #              #Plug ECMs
    #              plug_scale_factor = @plug_loads_ecms[0]
    #
    #              #DCV ECMs
    #              enable_dcv = @dcv_ecms[0]
    #
    #              #infiltration rates
    #              @infiltration_ecm.each do |infiltration_info|
    #
    #                erv_info = @erv_ecms[0]
    #
    #                economizer_info = @economizer_ecms[0]
    #
    #                temp_reduction_info = @temperature_setpoint_ecms[0]
    #
    #                cop_info = @COP_ecms[0]
    #
    #                create_variant(
    #                  base_model,
    #                  construction_lib,
    #                  vintage ,
    #                  construction_type,
    #                  wall_retrofit,
    #                  roof_retrofit,
    #                  glazing_retrofit,
    #                  lighting_scale_factor,
    #                  plug_scale_factor,
    #                  enable_dcv,
    #                  infiltration_info,
    #                  erv_info,
    #                  economizer_info,
    #                  temp_reduction_info,
    #                  cop_info,
    #                  header_printed,
    #                  library,
    #                  building,
    #                  output_folder,
    #                  index_file
    #                )
    #                GC.start
    #              end
    #            end
    #          end
    #        end
    #      end
    #    end
    #
  
  
    #    BTAP::FileIO::save_osm(library, "C:/OSRuby/Resources/DND/Trenton/test.osm")
    #    index_file.close
    #
    #    ##Load files into Run manager and simulate all of them
    #    process_manager = BTAP::SimManager::ProcessManager.new(output_folder)
    #    process_manager.simulate_all_files_in_folder(output_folder)
    #
    #    #process Results
    #    BTAP::FileIO::get_all_annual_results_from_runmanger( output_folder )
    #    BTAP::FileIO::convert_all_eso_to_csv(output_folder)

  end



  def create_variant(
      base_model,
      construction_lib,
      vintage ,
      construction_type,
      wall_retrofit,
      roof_retrofit,
      glazing_retrofit,
      lighting_scale_factor,
      plug_scale_factor,
      enable_dcv,
      infiltration_info,
      erv_info,
      economizer_info,
      temp_reduction_info,
      cop_info,
      header_printed,
      library,
      building,
      output_folder,
      index_file
    )

    #Create Vintage base model.
    #Create baseline model using default values.
    wall_retrofit = construction_type[1][0] if wall_retrofit.nil?
    roof_retrofit = construction_type[2][0] if roof_retrofit.nil?
    glazing_retrofit = @glazing_properties[0] if glazing_retrofit.nil?
    lighting_scale_factor = @lighting_ecms[0] if lighting_scale_factor.nil?
    plug_scale_factor = @plug_loads_ecms[0] if plug_scale_factor.nil?
    enable_dcv = @dcv_ecms[0] if enable_dcv.nil?
    infiltration_info = @infiltration_ecm[0] if infiltration_info.nil?
    erv_info = @erv_ecms[0] if erv_info.nil?
    economizer_info = @economizer_ecms[0] if economizer_info.nil?
    temp_reduction_info = @temperature_setpoint_ecms[0] if temp_reduction_info.nil?
    cop_info = @COP_ecms[0] if cop_info.nil?

    #Set construction data struct for surface types.
    glazing_ecm_info  = glazing_retrofit[ vintage ]
    ext_wall_ecm_info = wall_retrofit[ vintage ]
    ext_roof_ecm_info = roof_retrofit[ vintage ]
    #ground surface conductance is fixed at 1.8
    ground_cond  = [1.8,0.0]
    #Check if any of the struct are nil...if so skip this iteration.
    return nil if ext_wall_ecm_info == "nil" or ext_roof_ecm_info == "nil" or glazing_ecm_info == "nil" or  ground_cond == "nil"

    #get construction set by type and vintage.. I/O expensive so doing it here.
    vintage_construction_set = construction_lib.getDefaultConstructionSetByName("#{ construction_type[0] }#{ vintage }").get

    #make fresh copy of base_model.
    constructions_model = BTAP::FileIO::deep_copy( base_model )
    #Remove all existing constructions from model.
    BTAP::Resources::Envelope::remove_all_envelope_information( constructions_model )

    #Construct name for construction set.
    construction_id = "#{construction_type[0]}-#{vintage}-#{wall_retrofit[0]}-#{roof_retrofit[0]}-#{glazing_retrofit[0]}"

    new_construction_set =vintage_construction_set.clone(library).to_DefaultConstructionSet.get
    #Set conductances to needed values in construction set if possible.
    BTAP::Resources::Envelope::ConstructionSets::customize_default_surface_construction_set_rsi!(
      library,
      construction_id,
      new_construction_set,
      1.0 / ext_wall_ecm_info[0], 1.0 / ext_roof_ecm_info[0], 1.0 / ext_roof_ecm_info[0],
      1.0 / ground_cond[0], 1.0 / ground_cond[0], 1.0 / ground_cond[0],
      glazing_ecm_info[0], glazing_ecm_info[1] ,  glazing_ecm_info[2],
      glazing_ecm_info[0], glazing_ecm_info[1] ,  glazing_ecm_info[2]
    )

    #Define costs
    BTAP::Resources::Envelope::ConstructionSets::customize_default_surface_construction_set_costs(new_construction_set,
      ext_wall_ecm_info[1],
      ext_roof_ecm_info[1],
      ext_roof_ecm_info[1],
      ground_cond[1],
      ground_cond[1],
      ground_cond[1],
      glazing_ecm_info[3],
      glazing_ecm_info[3],
      0.0, #doors
      0.0, #glass doors
      0.0, #overhead doors
      0.0, #skylight
      0.0, #tubular_daylight_dome_cost =
      0.0 #tubular_daylight_diffuser_cost
    )

    #Save to library.
    new_construction_set.setAttribute("name",construction_id)
    constructions_model.building.get.setDefaultConstructionSet( new_construction_set.clone( constructions_model ).to_DefaultConstructionSet.get )

    #Give adiabatic surfaces a construction. Does not matter what. This is a bug in Openstudio that leave these surfaces unassigned by the default construction set.
    all_adiabatic_surfaces = BTAP::Geometry::Surfaces::filter_by_boundary_condition(constructions_model.getSurfaces, "Adiabatic")
    BTAP::Geometry::Surfaces::set_surfaces_construction( all_adiabatic_surfaces, constructions_model.building.get.defaultConstructionSet.get.defaultInteriorSurfaceConstructions.get.wallConstruction.get)

    #Enforce Vintage infiltration.
    BTAP::Resources::SpaceLoads::ScaleLoads::set_inflitration_magnitude( constructions_model,
      0.0, #setDesignFlowRate,
      0.0, #setFlowperSpaceFloorArea,
      @infil_rates[building[1]][ vintage - 1 ], #setFlowperExteriorSurfaceArea
      0.0  #setAirChangesperHour
    )
    puts "setting infiltration rate based on building and vintage type #{@infil_rates[building[1]][ vintage - 1 ]}"

    #Lighting ECM
    BTAP::Resources::SpaceLoads::ScaleLoads::scale_lighting_loads(constructions_model, lighting_scale_factor[1][0])

    #Electrical ECM
    BTAP::Resources::SpaceLoads::ScaleLoads::scale_electrical_loads(constructions_model, plug_scale_factor[1][0])

    #DCV ECM
    BTAP::Resources::HVAC::enable_demand_control_ventilation(constructions_model,enable_dcv[1][0]) unless "default" == enable_dcv[1][0]

    #Infiltration ECM...Don't change if default is set.
    if "default" != infiltration_info[1][0]
      BTAP::Resources::SpaceLoads::ScaleLoads::set_inflitration_magnitude( constructions_model,
        0.0, #setDesignFlowRate,
        0.0, #setFlowperSpaceFloorArea,
        infiltration_info[1][0], #setFlowperExteriorSurfaceArea,
        0.0  #setAirChangesperHour
      )
    end

    #ERV ECM
    unless 'default' == erv_info[1]
      BTAP::Resources::HVAC::enable_erv(
        constructions_model,
        erv_info[1][0],
        erv_info[1][1],
        erv_info[1][2], # 'Rotary' or 'Plate'
        erv_info[1][3],
        erv_info[1][4],
        erv_info[1][5],
        erv_info[1][6],
        erv_info[1][7],
        erv_info[1][8],
        erv_info[1][9],
        erv_info[1][10],
        erv_info[1][11],
        erv_info[1][12], # 'None', 'ExhaustAirRecirculation','ExhaustOnly','MinimumExhaustTemperature'
        erv_info[1][13],
        erv_info[1][14],
        erv_info[1][15],
        erv_info[1][16]
      )
    end

    #Economizer ECM
    unless 'default' == economizer_info[1]
      BTAP::Resources::HVAC::enable_economizer(
        constructions_model,
        economizer_info[1][0],
        economizer_info[1][1],
        economizer_info[1][2],
        economizer_info[1][3],
        economizer_info[1][4],
        economizer_info[1][5]
      )
    end

    #Temperature Reduction
    unless 'default' == temp_reduction_info[1][0]
      constructions_model.getThermostatSetpointDualSetpoints.each do |dual_setpoint|
        BTAP::Resources::Schedules::apply_schedule_minimum(temp_reduction_info[1][1], dual_setpoint.getCoolingSchedule.get) unless dual_setpoint.getCoolingSchedule.empty? or temp_reduction_info[1][1].nil?
        BTAP::Resources::Schedules::apply_schedule_maximum(temp_reduction_info[1][0], dual_setpoint.getHeatingSchedule.get) unless dual_setpoint.getHeatingSchedule.empty? or temp_reduction_info[1][0].nil?
      end
    end

    #DX Coil COP ECMs
    unless 'default' == cop_info[1]
      constructions_model.getCoilCoolingDXSingleSpeeds.each do |cooling_coil|
        cooling_coil.setRatedCOP( OpenStudio::OptionalDouble.new( cop_info[1][0] ))
      end
      constructions_model.getCoilCoolingDXTwoSpeeds.each do |cooling_coil|
        cooling_coil.setRatedHighSpeedCOP( OpenStudio::OptionalDouble.new( cop_info[1][0] ) )
        cooling_coil.setRatedLowSpeedCOP( OpenStudio::OptionalDouble.new( cop_info[1][0] ))
      end
    end

    #set name variant
    puts run_name_string = "#{building[0]}-#{building[1]}-#{construction_type[0]}-#{vintage}-#{wall_retrofit[0]}-#{roof_retrofit[0]}-#{glazing_retrofit[0]}-#{lighting_scale_factor[0]}-#{plug_scale_factor[0]}-#{enable_dcv[0]}-#{erv_info[0]}-#{economizer_info[0]}-#{temp_reduction_info[0]}-#{cop_info[0]}"
    BTAP::FileIO::set_name(constructions_model, run_name_string)
    BTAP::FileIO::save_osm(constructions_model, "#{output_folder}/\{#{run_name_string}\}.osm")
    #Add characteristics to table that will be exported to csv file later.
    simulation_characteristics_array = Array.new()
    simulation_characteristics_array.push( [ building,"Building Number","" ])
    simulation_characteristics_array.push( [ "#{run_name_string}.osm","OSM File","" ])
    simulation_characteristics_array.push( [ construction_type[0],"Construction Type","" ])
    simulation_characteristics_array.push( [ vintage,"Vintage","" ])
    simulation_characteristics_array.push( [ wall_retrofit[0],"Wall Retrofit","" ])
    simulation_characteristics_array.push( [ roof_retrofit[0] ,"Roof Retrofit","" ])
    simulation_characteristics_array.push( [ glazing_retrofit[0],"Glazing Retrofit","" ])
    simulation_characteristics_array.push( [ lighting_scale_factor[1][0],"Lighting Scale Factor Retrofit","ratio" ])
    simulation_characteristics_array.push( [ plug_scale_factor[1][0],"Plug Load Scale Factor Retrofit","ratio" ])
    simulation_characteristics_array.push( [ enable_dcv[1][0],"DCV Enabled?","bool" ])
    simulation_characteristics_array.push( [ erv_info[0],"ERV","" ])
    simulation_characteristics_array.push( [ economizer_info[0],"Economizer","" ])
    simulation_characteristics_array.push( [ temp_reduction_info[0],"Setpoint Reduction Heating / Cooling","" ])
    simulation_characteristics_array.push( [ cop_info[0],"Cooling COP","" ])

    array = simulation_characteristics_array
    #If header has not been printed...print it.
    if header_printed == false
      header_printed = true
      header = ""
      array.each do |value|
        header = header + "#{value[1]} #{value[2]},"
      end
      index_file.puts(header)
    end

    #Print row data.
    row_data = ""
    array.each do |value|
      row_data = row_data + "#{value[0]},"
    end
    index_file.puts(row_data)
    puts @counter = @counter + 1
  end

  def create_models(prototype_folder, output_folder, weather_file )
    @buildings.each do |building|
      self.dnd_common_ecms( building,
        "#{prototype_folder}/\{#{ building[0] }_baseline\}.osm",
        weather_file,
        output_folder
      )
    end
  end
end


dnd = DND.new()
dnd.create_models(
  "C:/osruby/Resources/DND/models/prototypes/",
  "F:/phylroy",
  "C:/osruby/weather_files/CAN_ON_Trenton.716210_CWEC/CAN_ON_Trenton.716210_CWEC.epw" )

#Only after you manually run the files in the Runmanager app get the results.
#BTAP::FileIO::get_all_annual_results_from_runmanger( "F:/phylroy")
#BTAP::FileIO::convert_all_eso_to_csv("F:/phylroy")
