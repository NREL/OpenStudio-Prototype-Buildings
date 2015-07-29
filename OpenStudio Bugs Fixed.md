# Bugs found when calibrating the OSM
## WaterHeater:Mixed:
### water_heater.setAmbientTemperatureIndicator("Zone") doesn't work
### Fixed: it should be water_heater.setAmbientTemperatureIndicator("ThermalZone")

## WaterHeaterMixed:
### Object added and can be found in the osm file, but did not output to the IDF file
### [It seems the WaterHeater:Mixed has to be included in a plant loop](https://github.com/NREL/OpenStudio/issues/1675)

## Missing Refrigeration:CompressorRack object
### Fixed: This object is purposefully not in OpenStudio. Have to build a detailed refrigeration system.  

## Space.addDaylightingControls 
### Error info: undefined method 'substract' for OpenStudio::Module;
### Fixed: update the OpenStuio to 1.8
