# Purpose
This repository contains an [OpenStudio Measure](http://nrel.github.io/OpenStudio-user-documentation/measures/about_measures/) which generates the [DOE Commercial Prototype Building Models](http://www.energycodes.gov/commercial-prototype-building-models) and [DOE Commercial Reference Buildings](http://energy.gov/eere/buildings/commercial-reference-buildings) energy models in OpenStudio (.osm) format.  The goal of this work is to enable anyone to easily create large-scale analyses using these models as the starting point.

## Why OpenStudio?
OpenStudio is a software development kit for energy modeling.  Energy models created in the OpenStudio format (.osm) can easily be manipulated by other [OpenStudio Measures](http://nrel.github.io/OpenStudio-user-documentation/measures/about_measures/).  Once a user has the DOE Prototype and Reference Buildings available in .osm format, they can use Measures to make changes to the buildings to determine their impact.

## Vintages
The DOE Reference Buildings cover 3 vintages:

- Pre-1980
- 1980-2004
- New Construction (90.1-2004)*

The DOE Prototype Buildings cover 4 vintages:

- 90.1-2004
- 90.1-2007
- 90.1-2010
- 90.1-2013

This Measure covers 6 vintages:

- Pre-1980
- 1980-2004
- 90.1-2004*
- 90.1-2007
- 90.1-2010
- 90.1-2013

*90.1-2004 is covered by both vintages.  This Measure used the DOE Prototype Buildings as the starting point for 90.1-2004.

## Testing
The OpenStudio models that are created by this Measure have been run and the results have been compared per-end-use and per-fuel-type to the results of the original Prototype and Reference IDF files.  Results agree within XX% (TODO: Reasonable tolerance?).  You can run the tests yourself by following these steps:

### Run the IDFs of the original Prototype and Reference buildings
1. Install OpenStudio and Ruby using [these instructions](http://nrel.github.io/OpenStudio-user-documentation/getting_started/getting_started/#installation-instructions)
2. Modify `run_legacy_idf_files.rb` to specify the building types/vintages/climate zones you want to run.
3. Open a command prompt in the `/regression test` directory
4. run `ruby run_legacy_idf_files.rb` to run the simulations. Note: this will take a long time.
4. After the simulations are complete, run `ruby store_legacy_idf_results.rb1`.  This will store the simulation results in a file called `legacy_idf_results.json`.  Copy this file into the `/create_DOE_prototype_building/tests` directory.

### Run the OpenStudio Measure and compare results to legacy IDF files
1. Open a command prompt in the `/create_DOE_prototype_building/tests` directory.
2. Modify `create_DOE_prototype_building_Test.rb`to specify the building types/vintages/climate zones you want to run.  You can turn a test off by changing the name of the test from `test_blah_blah` to `dont_test_blah_blah`.
3. run `ruby create_DOE_prototype_building_Test.rb`.  This will create the models, run them, and compare the simulation results to the results stored in `legacy_idf_results.json`.  The simulations will all be run and stored in: `/create_DOE_prototype_building/tests/build`.  This `/build` directory should not be committed to the repository.

## Structure of Code
### /regression test
This directory contains IDFs of the original Prototype and Reference buildings, which are used for testing purposes.

### /create DOE prototype building
This directory is the Measure itself.  Everything under this directory helps the measure run.

#### /resources/hvac sizing
This is a library that extends OpenStudio classes to enable a Measure to run a sizing run and pull autosized component values back into the Measure.

#### /resources/prototype
This is a library that extends OpenStudio classes to build up the prototype buildings using assumptions that are not governed by any standard.  For example, the configuration of the HVAC systems.

#### /resources/standards data
This is a library that extends OpenStudio classes to modify model objects and settings per a specific standard.  For example, a chiller gets a method that sets its COP and performance curves based on the standard, the capacity, and the compressor type.

#### /resources/weather data
This directory contains the weather files for each of the representative locations for each of the climate zones covered.


#### /tests
This directory contains the simulation results from the legacy IDF files, as well as test fixtures which will run the Measure, create the models, and then compare the model results against the legacy IDF files.
