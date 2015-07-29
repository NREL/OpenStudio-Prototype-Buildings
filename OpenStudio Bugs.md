# Bugs found when calibrating the OSM
## WaterHeater:Mixed:
### water_heater.setAmbientTemperatureIndicator("Zone") doesn't work
### Fixed: it should be water_heater.setAmbientTemperatureIndicator("ThermalZone")

## WaterHeaterMixed:
### Object added and can be found in the osm file, but did not output to the IDF file
### [It seems the WaterHeater:Mixed has to be included in a plant loop](https://github.com/NREL/OpenStudio/issues/1675)

## Missing Refrigeration:CompressorRack object
### Fixed: This object is purposefully not in OpenStudio. Have to build a detailed refrigeration system.  

## OpenStudio::Model::RefrigerationCase
### setRefrigeratedCaseRestockingSchedule don't work

## Economizer maximum OA percentage assumption:
### Need to separate the DOAS system with other systems

## Fan efficiency assumption: 
### Need to separate the Fan Coil fan with AHU Fans

## Missing ZoneMixing object

## Space.addDaylightingControls 
### Error info: undefined method 'substract' for OpenStudio::Module;
### Fixed: update the OpenStuio to 1.8

## Missing ZoneVentilation:WindandStackOpenArea

## Minimum outdoor air fraction (PNNL set use hard sizing). 

## Basement Walls: SurfaceProperty:OtherSideCoefficients is used, but SurfaceProperty:OtherSideCoefficients is not support by OpenStudio yet.  
### Currently, set the outdoor boundary condition to "Ground"

## EMS used in Boiler:HotWater Normalized Boiler Efficiency Curve Name (The curve value is calculated by EMS). 
### Need to check the EMS code and seek the solution.

## AirloopHVAC AvailabilityManager
### In Prototype buildings, the  AvailabilityManagerAssignmentList for the AirLoopHVAC:OutdoorAirSystem and the AirloopHVAC are the same (both AvailabilityManager:NightCycle). 
### In current OSM (i.e. VAV system), the AirloopHVAC is AvailabilityManager:NightCycle, but the AirloopHVAC:OutdoorAirSystem is  AvailabilityManager:Scheduled. 
### How to change the AvailabilityManagerAssignmentList for the AirLoopHVAC:OutdoorAirSystem?

## Controller:MechanicalVentilation
### By default, each Controller:OutdoorAir has a Controller:MechanicalVentilation in OpenStudio model. 
### The large hotel model don't have Controller:MechanicalVentilation. 
### How to remove the Controller:MechanicalVentilation from Controller:OutdoorAir?

## Controller:MechanicalVentilation
### Controller:MechanicalVentilation.setControllerMechanicalVentilation don't work. 
### I set the schedule to "Always off", and checked the final.osm. 
### The final.osm has the right information. However, the final IDF output is the same as the "Minimum Outdoor Air Schedule Name" of the Controller:OutdoorAir



