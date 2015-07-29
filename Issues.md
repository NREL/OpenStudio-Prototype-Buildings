#### 4.OpenStudio::Model::RefrigerationCase
setRefrigeratedCaseRestockingSchedule don't work

#### 5. Economizer assumption: Need to separate the DOAS system with other systems

#### 6. Fan efficiency assumption: Need to separate the Fan Coil fan with AHU Fans

#### 7. Missing ZoneMixing object

#### 8. Missing ZoneVentilation:WindandStackOpenArea

#### 10. Minimum outdoor air fraction (PNNL set use hard sizing). 

#### 11. Basement Walls: SurfaceProperty:OtherSideCoefficients is used, but SurfaceProperty:OtherSideCoefficients is not support by OpenStudio yet.  
Currently, set the outdoor bundary condition to "Ground"

#### 12. EMS used in Boiler:HotWater Normalized Boiler Efficiency Curve Name (The curve value is calculated by EMS). Need to check the EMS code and seek the solution.


#### 13. In Prototype buildings, the  AvailabilityManagerAssignmentList for the AirLoopHVAC:OutdoorAirSystem and the AirloopHVAC are the same (both AvailabilityManager:NightCycle). In current OSM (i.e. VAV system), the AirloopHVAC is AvailabilityManager:NightCycle, but the AirloopHVAC:OutdoorAirSystem is  AvailabilityManager:Scheduled. How to change the AvailabilityManagerAssignmentList for the AirLoopHVAC:OutdoorAirSystem?


#### 14. By default, each Controller:OutdoorAir has a Controller:MechanicalVentilation in OpenStudio model. The large hotel model don't have Controller:MechanicalVentilation. How to remove the Controller:MechanicalVentilation from Controller:OutdoorAir?


#### 15. Bug: Controller:MechanicalVentilation.setControllerMechanicalVentilation don't work. I set the schedule to "Always off", and checked the final.osm. The final.osm has the right information. However, the final IDF output is the same as the "Minimum Outdoor Air Schedule Name" of the Controller:OutdoorAir

#### 16. Bug: SetpointManagerScheduled.addToNode(air_loop.supplyOutletNode) not working


#### 1.Bugs found when calibrating the OSM
WaterHeater:Mixed:
water_heater.setAmbientTemperatureIndicator("Zone") doesn't work  
Fixed: it should be water_heater.setAmbientTemperatureIndicator("ThermalZone")

#### 2.WaterHeaterMixed:
Object added and can be found in the osm file, but did not output to the IDF file  
Fixed: The WaterHeater:Mixed has to be included in a plant loop

#### 3.Missing Refrigeration:CompressorRack object
Fixed: This object is purposefully not in OpenStudio. Have to build a detailed refrigeration system.  

#### 9. Bugs in Space.addDaylightingControls; Error info: undefined method 'substract' for OpenStudio::Module; in Standards.Space.rb function a_polygons_minus_b_polygons(a_polygons, b_polygons, a_name, b_name) line 138: a_minus_b_polygons = OpenStudio.subtract(a_polygon, b_polygons, 0.01)  
Fixed: update the OpenStuio to 1.8