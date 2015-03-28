#Error Reduction Process
Going through this process in a systematic manner is the fastest way to reduce error between the legacy and osm models.  Don't skip around; troubleshooting the HVAC doesn't make sense until you know that the loads are correct.  Running the legacy IDF files so that you have the .html files makes this comparison easier.

## 1. External Loads
1. Check the size of the building surfaces in "Envelope Summary"
2. Check the R-values of constructions in "Envelope Summary"
3. Check the infiltration rates in "Outdoor Air Summary"
4. Check the infiltration schedules in "Outdoor Air Summary"

## 2. Internal Loads
1. Check the lighting loads in "Lighting Summary"
2. Check the lighting schedules in "Lighting Summary"
3. Check the equipment loads
4. Check the equipment schedules
5. Check the people density in "Outdoor Air Summary"
6. Check the people schedules in "Outdoor Air Summary"

## 3. Ventilation
1. Check the ventilation rates in "Outdoor Air Summary"
2. Check the Sizing:System and Sizing:Zone objects
3. Check the minimum flow fields in the terminals
4. Check the nightcycle and economizer settings