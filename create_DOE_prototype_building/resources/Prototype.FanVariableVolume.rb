
# open the class to add methods to return sizing values
class OpenStudio::Model::FanVariableVolume

  # Sets the fan pressure rise based on the Prototype buildings inputs
  # which are governed by the flow rate coming through the fan
  # and whether the fan lives inside a unit heater, PTAC, etc.
  def setPrototypeFanPressureRise
    
    # Get the max flow rate from the fan.
    maximum_flow_rate_m3_per_s = nil
    if self.maximumFlowRate.is_initialized
      maximum_flow_rate_m3_per_s = self.maximumFlowRate.get
    elsif self.autosizedMaximumFlowRate.is_initialized
      maximum_flow_rate_m3_per_s = self.autosizedMaximumFlowRate.get
    else
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.prototype.FanVariableVolume", "For #{self.name} max flow rate is not available, cannot apply prototype assumptions.")
      return false
    end
    
    # Convert max flow rate to cfm
    maximum_flow_rate_cfm = OpenStudio.convert(maximum_flow_rate_m3_per_s, 'm^3/s', 'cfm').get
    
    # Pressure rise will be determined based on the 
    # following logic.
    pressure_rise_in_h2o = 0.0
    
    # If the fan lives inside of a zone hvac equipment
    if self.containingZoneHVACComponent.is_initialized
      zone_hvac = self.ZoneHVACComponent.get
      if zone_hvac.to_ZoneHVACPackagedTerminalAirConditioner.is_initialized
        pressure_rise_in_h2o = 1.33
      elsif zone_hvac.to_ZoneHVACFourPipeFanCoil.is_initialized
        pressure_rise_in_h2o = 1.33
      elsif zone_hvac.to_ZoneHVACUnitHeater.is_initialized
        pressure_rise_in_h2o = 0.2
      else # This type of fan should not exist in the prototype models
        return false
      end
    end
    
    # If the fan lives on an airloop
    if self.airLoopHVAC.is_initialized
      if maximum_flow_rate_cfm < 4648
        pressure_rise_in_h2o = 4.0
      elsif maximum_flow_rate_cfm >= 4648 && maximum_flow_rate_cfm < 20000
        pressure_rise_in_h2o = 6.32
      else # Over 20,000 cfm
        pressure_rise_in_h2o = 5.58
      end
    end
    
    # Set the fan pressure rise
    pressure_rise_pa = OpenStudio.convert(pressure_rise_in_h2o, 'inH_{2}O','Pa').get
    self.setPressureRise(pressure_rise_pa)  
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.FanVariableVolume', "For Prototype: #{self.name}: #{maximum_flow_rate_cfm.round}cfm; Pressure Rise = #{pressure_rise_in_h2o}in w.c.")
    
    return true
    
  end

end
