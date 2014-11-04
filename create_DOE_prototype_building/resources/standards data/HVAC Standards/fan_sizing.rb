
# A helper method to set the fan pressure drops
# based on their air flows.
def set_fan_pressure_rises(model)
   
  # Load the helper libraries for getting the autosized
  # values for each type of model object.
  require_relative 'Model'
  require_relative 'FanConstantVolume'
  require_relative 'FanVariableVolume'
  
  # Get the autosized values and 
  # put them back into the model.
  apply_sizes_success = model.setFanPressureRise
  # if apply_sizes_success
    # @runner.registerInfo("Successfully applied component sizing values.")
  # else
    # @runner.registerInfo("Failed to apply component sizing values.")
  # end
  
  return true

end

# A helper method to set the fan pressure drops
# based on their air flows.
def set_fan_motor_efficiencies(model, motors, template)
   
  # Load the helper libraries for getting the autosized
  # values for each type of model object.
  require_relative 'Model'
  require_relative 'FanConstantVolume'
  require_relative 'FanVariableVolume'

  apply_sizes_success = model.setFanMotorEfficiency(motors, template)
  # if apply_sizes_success
    # @runner.registerInfo("Successfully applied component sizing values.")
  # else
    # @runner.registerInfo("Failed to apply component sizing values.")
  # end
  
  return true

end
