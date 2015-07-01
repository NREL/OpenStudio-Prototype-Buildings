# Bugs found when calibrating the OSM
## WaterHeater:Mixed:
### water_heater.setAmbientTemperatureIndicator("Zone") doesn't work
### fixed: it should be water_heater.setAmbientTemperatureIndicator("ThermalZone")

## WaterHeaterMixed:
### Object added and can be found in the osm file, but did not output to the IDF file
### It seems the WaterHeater:Mixed has to be included in a plant loop


