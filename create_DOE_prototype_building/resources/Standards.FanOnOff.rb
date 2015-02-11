
# open the class to add methods to return sizing values
class OpenStudio::Model::FanOnOff

  # Sets the fan motor efficiency based on the standard
  def setStandardEfficiency(template, hvac_standards)
    
    motors = hvac_standards["motors"]
    
    # Get the max flow rate from the fan.
    maximum_flow_rate_m3_per_s = nil
    if self.maximumFlowRate.is_initialized
      maximum_flow_rate_m3_per_s = self.maximumFlowRate.get
    elsif self.autosizedMaximumFlowRate.is_initialized
      maximum_flow_rate_m3_per_s = self.autosizedMaximumFlowRate.get
    else
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.hvac_standards.FanOnOff", "For #{self.name} max flow rate is not available, cannot apply efficiency standard.")
      return false
    end
    
    # Convert max flow rate to cfm
    maximum_flow_rate_cfm = OpenStudio.convert(maximum_flow_rate_m3_per_s, "m^3/s", "cfm").get
    
    # Get the pressure rise from the fan
    pressure_rise_pa = self.pressureRise
    pressure_rise_in_h2o = OpenStudio.convert(pressure_rise_pa, "Pa","inH_{2}O").get
    
    # Assume that the fan efficiency is 65% based on
    #TODO need reference
    fan_eff = 0.65
    
    # Calculate the Brake Horsepower
    brake_hp = (pressure_rise_in_h2o * maximum_flow_rate_cfm)/(fan_eff * 6356) 
    allowed_hp = brake_hp * 1.1 # Per PNNL document #TODO add reference

    # Find the motor that meets these size criteria
    search_criteria = {
    "template" => template,
    "number_of_poles" => 4.0,
    "type" => "Open Drip-Proof",
    }
    
    motor_properties = find_object(motors, search_criteria, allowed_hp)
  
    # Get the nominal motor efficiency
    motor_eff = motor_properties["nominal_full_load_efficiency"]
  
    # Calculate the total fan efficiency
    total_fan_eff = fan_eff * motor_eff
    
    # Set the total fan efficiency and the motor efficiency
    self.setFanEfficiency(total_fan_eff)
    self.setMotorEfficiency(motor_eff)
    
    # Set the fan efficiency ration function of speed ratio curve to a
    # flat number per the IDFs.  Not sure how this invalid input affects
    # the simulation, but it is in the Prototype IDF files.
    # TODO check if this is just for small office or every building type
    #fan_eff_curve = self.fanEfficiencyRatioFunctionofSpeedRatioCurve
    #fan_eff_curve = fan_eff_curve.to_CurveCubic.get
    #fan_eff_curve.setCoefficient1Constant(total_fan_eff)
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.hvac_standards.FanOnOff", "For #{template}: #{self.name}: allowed_hp = #{allowed_hp.round(1)}HP; motor eff = #{motor_eff*100}%; total fan eff = #{(total_fan_eff*100).round}%")
    
    return true
    
  end
  
end
