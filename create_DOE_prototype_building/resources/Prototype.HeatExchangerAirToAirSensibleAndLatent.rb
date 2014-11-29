
# open the class to add methods to return sizing values
class OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent

  def setPrototypeNominalElectricPower
  
    # Skip HXs that haven't been hard-sized yet
    return false if self.nominalSupplyAirFlowRate.empty?
    
    # Get the nominal supply air flow rate
    supply_air_flow_m3_per_s = self.nominalSupplyAirFlowRate.get
    supply_air_flow_cfm = OpenStudio.convert(supply_air_flow_m3_per_s, "m^3/s", "cfm").get
    
    # Calculate the motor power for the rotatry wheel per:
    # Power (W) = (Nominal Supply Air Flow Rate (CFM) * 0.3386) + 49.5
    power = (supply_air_flow_cfm * 0.3386) + 49.5
    
    # Set the power for the HX
    self.setNominalElectricPower(power)

    return true

  end

end
  