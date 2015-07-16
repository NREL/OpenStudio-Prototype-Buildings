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

## Online Documentation
Documentation for the latest code is available online #TODO put code on rubydoc.info

## Local Documentation
This code uses [YARD](http://yardoc.org/) to create documentation.  To generate a local html copy of the documentation on your computer:

1. Prerequisite - Make sure you have `rake` and `yard` installed on your computer (`gem install rake`, `gem install yard`)
2. Open a command prompt in the root directory aka `/OpenStudio-Prototype-Buildings`
3. run `rake yard`.  This will create the models, run them, and compare the simulation results to the results stored in `legacy_idf_results.json`.  The simulations will all be run and stored in: `/create_DOE_prototype_building/tests/build`.  This `/build` directory should not be committed to the repository.
4. In the root directory you will now see a folder called `/doc`
5. Click the file `_index.html` to browse the documentation

## Testing
The OpenStudio models that are created by this Measure have been run and the results have been compared per-end-use and per-fuel-type to the results of the original Prototype and Reference IDF files.  Results agree within XX% (TODO: Reasonable tolerance?).  You can run the tests yourself by following these steps:

### Run the IDFs of the original Prototype and Reference buildings
1. Install OpenStudio and Ruby using [these instructions](http://nrel.github.io/OpenStudio-user-documentation/getting_started/getting_started/#installation-instructions)
2. Modify `run_legacy_idf_files.rb` to specify the building types/vintages/climate zones you want to run.
3. Open a command prompt in the `/regression test` directory
4. run `ruby run_legacy_idf_files.rb` to run the simulations. Note: this will take a long time.
4. After the simulations are complete, run `ruby store_legacy_idf_results.rb`.  This will store the simulation results in a file called `legacy_idf_results.json`, which is in the `/create_DOE_prototype_building/tests` directory.

### Run the OpenStudio Measure and compare results to legacy IDF files
1. Open a command prompt in the `/create_DOE_prototype_building/tests` directory.
2. Modify `create_DOE_prototype_building_Test.rb`to specify the building types/vintages/climate zones you want to run.  You can turn a test off by changing the name of the test from `test_blah_blah` to `dont_test_blah_blah`.
3. run `ruby create_DOE_prototype_building_Test.rb`.  This will create the models, run them, and compare the simulation results to the results stored in `legacy_idf_results.json`.  The simulations will all be run and stored in: `/create_DOE_prototype_building/tests/build`.  This `/build` directory should not be committed to the repository.

## Structure of Code

### /regression test
This directory contains IDFs of the original Prototype and Reference buildings, which are used for testing purposes.

### /create DOE prototype building
This directory is the Measure itself.  Everything under this directory helps the measure run.

#### /resources
This directory contains libraries of methods to build up the prototype building, run sizing runs, apply standards, etc.  It must be a flat directory because of the design of BCL, which will be used to distribute the final Measure.  Because of this limitation, the purpose of each file is defined by the file prefix instead of a subdirectory.  The meaning of each file prefix is as follows:

##### /resources/Geometry.*
These files contain the 3D building geometry used as a starting point for the model.

##### /resources/HVACSizing.*
These files extend OpenStudio classes to enable a Measure to run a sizing run and pull autosized component values back into the model.  This library also gives each model object access to it's individual values once a sizing run has been performed.

##### /resources/OpenStudio_*.xlsx/json
These JSON files are libraries of Standards information that the Measure pulls information like HVAC efficiency values, default performance curves, etc. from.  The input mechanism is the spreadsheet of the same name, and there is file called `Standards.export_OpenStudio_HVAC_Standards.rb` that is run to export the spreadsheet to JSON format.  The `OpenStudio_Standards.json` comes from the [openstudio-standards](https://github.com/NREL/openstudio-standards) repository.  Eventually, the information from `OpenStudio_HVAC_Standards` will be moved into this same repository.

##### /resources/Prototype.*
These files extends OpenStudio classes to build up the prototype buildings using assumptions that are not governed by any standard.  For example, the configuration of the HVAC systems, assumptions for fan pressure drops, etc.

##### /resources/Standards.*
These files extend OpenStudio classes to enable them to modify their inputs to meet a specific standard.  For example, the Chiller:Electric:EIR object gets a method that sets its COP and performance curves based on the standard, the capacity, and the compressor type.  These methods rely on the information in `OpenStudio_Standards.json` and `OpenStudio_HVAC_Standards.json`.

##### /resources/USA...*
The *.epw, *.ddy, and *.stat files contain weather information for the representative city for each of the ASHRAE climate zones.d

##### /resources/Weather.*
These files extend the OpenStudio classes to allow a model to import design days, pull water mains temperature from the .stat file, and assign the correct weather file to the model.

#### /tests
This directory contains the simulation results from the legacy IDF files, as well as test fixtures which will run the Measure, create the models, and then compare the model results against the legacy IDF files.

## Adding a New Building Type
1. Run Prototype.strip_model to get the geometry-only .osm
2. In Measure.rb, add the building type name to the arguments
3. Create the Prototype.building_name file
  - Add the define_space_type_map method
  - Add the define_hvac_system_map method
  - Add the add_hvac method, which might include adding to/changing Prototype.hvac_systems.rb
4. Add a test for this building type to tests/create_DOE_prototype_buildings_Test.rb
5. Run the test, look at results, iterate

