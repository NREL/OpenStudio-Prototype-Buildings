
# open the class to add methods to return sizing values
class OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent

  def setPrototypeNominalElectricPower
  
    # Get the nominal supply air flow rate
    supply_air_flow_m3_per_s = nil
    if self.nominalSupplyAirFlowRate.is_initialized
      supply_air_flow_m3_per_s = self.nominalSupplyAirFlowRate.get
    elsif self.autosizedNominalSupplyAirFlowRate.is_initialized
      supply_air_flow_m3_per_s = self.autosizedNominalSupplyAirFlowRate.get
    else
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.prototype.HeatExchangerAirToAirSensibleAndLatent", "For #{self.name} nominal flow rate is not available, cannot apply prototype assumptions.")
      return false
    end

    # Convert the flow rate to cfm
    supply_air_flow_cfm = OpenStudio.convert(supply_air_flow_m3_per_s, "m^3/s", "cfm").get
  
    # Calculate the motor power for the rotatry wheel per:
    # Power (W) = (Nominal Supply Air Flow Rate (CFM) * 0.3386) + 49.5
    power = (supply_air_flow_cfm * 0.3386) + 49.5
    
    # Set the power for the HX
    self.setNominalElectricPower(power)

    return true

  end

end
  