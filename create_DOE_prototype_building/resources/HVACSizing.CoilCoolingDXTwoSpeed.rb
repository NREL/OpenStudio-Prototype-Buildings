
# open the class to add methods to return sizing values
class OpenStudio::Model::CoilCoolingDXTwoSpeed

  # Sets all auto-sizeable fields to autosize
  def autosize
    OpenStudio::logFree(OpenStudio::Warn, "openstudio.sizing.CoilCoolingDXTwoSpeed", ".autosize not yet implemented for #{self.iddObject.type.valueDescription}.")
  end

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    rated_high_speed_air_flow_rate = self.autosizedRatedHighSpeedAirFlowRate
    if rated_high_speed_air_flow_rate.is_initialized
      self.setRatedHighSpeedAirFlowRate(rated_high_speed_air_flow_rate) 
    end

    rated_high_speed_total_cooling_capacity = self.autosizedRatedHighSpeedTotalCoolingCapacity
    if rated_high_speed_total_cooling_capacity.is_initialized
      self.setRatedHighSpeedTotalCoolingCapacity(rated_high_speed_total_cooling_capacity) 
    end    

    rated_high_speed_sensible_heat_ratio = self.autosizedRatedHighSpeedSensibleHeatRatio
    if rated_high_speed_sensible_heat_ratio.is_initialized
      self.setRatedHighSpeedSensibleHeatRatio(rated_high_speed_sensible_heat_ratio) 
    end     
    
    rated_low_speed_air_flow_rate = self.autosizedRatedLowSpeedAirFlowRate
    if rated_low_speed_air_flow_rate.is_initialized
      self.setRatedLowSpeedAirFlowRate(rated_low_speed_air_flow_rate) 
    end  

    rated_low_speed_total_cooling_capacity = self.autosizedRatedLowSpeedTotalCoolingCapacity
    if rated_low_speed_total_cooling_capacity.is_initialized
      self.setRatedLowSpeedTotalCoolingCapacity(rated_low_speed_total_cooling_capacity) 
    end  
      
  end

  # returns the autosized rated high speed air flow rate as an optional double
  def autosizedRatedHighSpeedAirFlowRate

    return self.model.getAutosizedValue(self, 'Design Size Rated High Speed Air Flow Rate', 'm3/s')   
    
  end

  # returns the autosized rated high speed total cooling capacity as an optional double
  def autosizedRatedHighSpeedTotalCoolingCapacity

    return self.model.getAutosizedValue(self, 'Design Size Rated High Speed Total Cooling Capacity (gross)', 'W')
    
  end
  
  # returns the autosized rated high speed sensible heat ratio as an optional double
  def autosizedRatedHighSpeedSensibleHeatRatio

    return self.model.getAutosizedValue(self, 'Design Size Rated High Speed Sensible Heat Ratio', '')
    
  end

  # returns the autosized rated low speed air flow rate as an optional double
  def autosizedRatedLowSpeedAirFlowRate

    return self.model.getAutosizedValue(self, 'Design Size Rated Low Speed Air Flow Rate', 'm3/s')
    
  end

  # returns the autosized rated low speed total cooling capacity as an optional double
  def autosizedRatedLowSpeedTotalCoolingCapacity

    return self.model.getAutosizedValue(self, 'Design Size Rated Low Speed Total Cooling Capacity (gross)', 'W')
    
  end


end
