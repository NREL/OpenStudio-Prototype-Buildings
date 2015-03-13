
# open the class to add methods to return sizing values
class OpenStudio::Model::AirLoopHVAC

  # Determine the fan power limitation pressure drop adjustment
  # Per Table 6.5.3.1.1B
  def fanPowerLimitationPressureDropAdjustmentBrakeHorsepower(template = "ASHRAE 90.1-2007")
  
   # Get design supply air flow rate (whether autosized or hard-sized)
    dsn_air_flow_m3_per_s = 0
    dsn_air_flow_cfm = 0
    if self.autosizedDesignSupplyAirFlowRate.is_initialized
      dsn_air_flow_m3_per_s = self.autosizedDesignSupplyAirFlowRate.get
      dsn_air_flow_cfm = OpenStudio.convert(dsn_air_flow_m3_per_s, "m^3/s", "cfm").get
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "* #{dsn_air_flow_cfm.round} cfm = Autosized Design Supply Air Flow Rate.")
    else
      dsn_air_flow_m3_per_s = self.designSupplyAirFlowRate.get
      dsn_air_flow_cfm = OpenStudio.convert(dsn_air_flow_m3_per_s, "m^3/s", "cfm").get
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "* #{dsn_air_flow_cfm.round} cfm = Hard sized Design Supply Air Flow Rate.")
    end  
  
    # TODO determine the presence of MERV filters and other stuff
    # in Table 6.5.3.1.1B
    # perhaps need to extend AirLoopHVAC data model
    has_fully_ducted_return_and_or_exhaust_air_systems = false
    
    # Calculate Fan Power Limitation Pressure Drop Adjustment (in wc)
    fan_pwr_adjustment_in_wc = 0
    
    # Fully ducted return and/or exhaust air systems
    if has_fully_ducted_return_and_or_exhaust_air_systems
      adj_in_wc = 0.5
      fan_pwr_adjustment_in_wc += adj_in_wc
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC","--Added #{adj_in_wc} in wc for Fully ducted return and/or exhaust air systems")
    end
    
    # Convert the pressure drop adjustment to brake horsepower (bhp)
    # assuming that all supply air passes through all devices
    fan_pwr_adjustment_bhp = fan_pwr_adjustment_in_wc * dsn_air_flow_cfm / 4131
    OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC","#{self.name} - #{(fan_pwr_adjustment_bhp)} bhp = Fan Power Limitation Pressure Drop Adjustment")
 
    return fan_pwr_adjustment_bhp
 
  end

  # Determine the allowable fan system brake horsepower
  # Per Table 6.5.3.1.1A
  def allowableSystemBrakeHorsepower(template = "ASHRAE 90.1-2007")
  
   # Get design supply air flow rate (whether autosized or hard-sized)
    dsn_air_flow_m3_per_s = 0
    dsn_air_flow_cfm = 0
    if self.autosizedDesignSupplyAirFlowRate.is_initialized
      dsn_air_flow_m3_per_s = self.autosizedDesignSupplyAirFlowRate.get
      dsn_air_flow_cfm = OpenStudio.convert(dsn_air_flow_m3_per_s, "m^3/s", "cfm").get
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "* #{dsn_air_flow_cfm.round} cfm = Autosized Design Supply Air Flow Rate.")
    else
      dsn_air_flow_m3_per_s = self.designSupplyAirFlowRate.get
      dsn_air_flow_cfm = OpenStudio.convert(dsn_air_flow_m3_per_s, "m^3/s", "cfm").get
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "* #{dsn_air_flow_cfm.round} cfm = Hard sized Design Supply Air Flow Rate.")
    end

    # Get the fan limitation pressure drop adjustment bhp
    fan_pwr_adjustment_bhp = self.fanPowerLimitationPressureDropAdjustmentBrakeHorsepower
    
    # Determine the number of zones the system serves
    num_zones_served = self.thermalZones.size
    
    # Get the supply air fan and determine whether VAV or CAV system.
    # Assume that supply air fan is fan closest to the demand outlet node.
    # The fan may be inside of a piece of unitary equipment.
    fan_pwr_limit_type = nil
    self.supplyComponents.reverse.each do |comp|
      if comp.to_FanConstantVolume.is_initialized || comp.to_FanOnOff.is_initialized
        fan_pwr_limit_type = "constant volume"
      elsif comp.to_FanConstantVolume.is_initialized
        fan_pwr_limit_type = "variable volume"
      elsif comp.to_AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.is_initialized
        fan = comp.to_AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.get.supplyAirFan
        if fan.to_FanConstantVolume.is_initialized || comp.to_FanOnOff.is_initialized
          fan_pwr_limit_type = "constant volume"
        elsif fan.to_FanConstantVolume.is_initialized
          fan_pwr_limit_type = "variable volume"
        end
      elsif comp.to_AirLoopHVACUnitarySystem.is_initialized
        fan = comp.to_AirLoopHVACUnitarySystem.get.supplyFan
        if fan.to_FanConstantVolume.is_initialized || comp.to_FanOnOff.is_initialized
          fan_pwr_limit_type = "constant volume"
        elsif fan.to_FanConstantVolume.is_initialized
          fan_pwr_limit_type = "variable volume"
        end
      end  
    end
    
    # For 90.1-2010, single-zone VAV systems use the 
    # constant volume limitation per 6.5.3.1.1
    if template == "ASHRAE 90.1-2010" && fan_pwr_limit_type = "variable volume" && num_zones_served == 1
      fan_pwr_limit_type = "constant volume"
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC","#{self.name} - Using the constant volume limitation because single-zone VAV system.")
    end
    
    # Calculate the Allowable Fan System brake horsepower per Table G3.1.2.9
    allowable_fan_bhp = 0
    if fan_pwr_limit_type == "constant volume"
      allowable_fan_bhp = dsn_air_flow_cfm * 0.0013 + fan_pwr_adjustment_bhp
    elsif fan_pwr_limit_type == "variable volume"
      allowable_fan_bhp = dsn_air_flow_cfm * 0.00094 + fan_pwr_adjustment_bhp
    end
    OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC","#{self.name} - #{(allowable_fan_bhp).round(2)} bhp = Allowable brake horsepower.")
    
    return allowable_fan_bhp

  end

  # Get all of the supply, return, exhaust, and relief fans on this system.
  def supplyReturnExhaustReliefFans() 
    
    # Fans on the supply side of the airloop directly, or inside of unitary equipment.
    fans = []
    sup_and_oa_comps = self.supplyComponents
    sup_and_oa_comps += self.oaComponents
    sup_and_oa_comps.each do |comp|
      if comp.to_FanConstantVolume.is_initialized || comp.to_FanVariableVolume.is_initialized
        fans << comp
      elsif comp.to_AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.is_initialized
        sup_fan = comp.to_AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.get.supplyAirFan
        if sup_fan.to_FanConstantVolume.is_initialized
          fans << sup_fan.to_FanConstantVolume.get
        elsif sup_fan.to_FanOnOff.is_initialized
          fans << sup_fan.to_FanOnOff.get
        end
      elsif comp.to_AirLoopHVACUnitarySystem.is_initialized
        sup_fan = comp.to_AirLoopHVACUnitarySystem.get.supplyFan
        if sup_fan.to_FanConstantVolume.is_initialized
          fans << sup_fan.to_FanConstantVolume.get
        elsif sup_fan.to_FanOnOff.is_initialized
          fans << sup_fan.to_FanOnOff.get
        elsif sup_fan.to_FanVariableVolume.is_initialized
          fans << sup_fan.to_FanVariableVolume.get  
        end      
      end
    end 
    
    return fans
    
  end
  
  # Determine the total brake horsepower of the fans on the system
  # with or without the fans inside of fan powered terminals.
  def systemFanBrakeHorsepower(include_terminal_fans = true, template = "ASHRAE 90.1-2007")

    # TODO get the template from the parent model itself?
    # Or not because maybe you want to see the difference between two standards?
    OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC","#{self.name} - Determining #{template} allowable system fan power.")
  
    # Get all fans
    fans = []
    # Supply, exhaust, relief, and return fans
    fans += self.supplyReturnExhaustReliefFans
    
    # Fans inside of fan-powered terminals
    if include_terminal_fans
      self.demandComponents.each do |comp|
        if comp.to_AirTerminalSingleDuctSeriesPIUReheat.is_initialized
          term_fan = comp.to_AirTerminalSingleDuctSeriesPIUReheat.get.supplyAirFan
          if term_fan.to_FanConstantVolume.is_initialized
            fans << term_fan.to_FanConstantVolume.get
          end
        elsif comp.to_AirTerminalSingleDuctParallelPIUReheat.is_initialized
          term_fan = comp.to_AirTerminalSingleDuctParallelPIUReheat.get.fan
          if term_fan.to_FanConstantVolume.is_initialized
            fans << term_fan.to_FanConstantVolume.get
          end     
        end
      end
    end
    
    # Loop through all fans on the system and
    # sum up their brake horsepower values.
    sys_fan_bhp = 0
    fans.sort.each do |fan|
      sys_fan_bhp += fan.brakeHorsepower
    end
    
    return sys_fan_bhp
   
  end 
  
  # Set the fan pressure rises that will result in
  # the system hitting the baseline allowable fan power
  def setBaselineFanPressureRise(template = "ASHRAE 90.1-2007")

    OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "#{self.name} - Setting #{template} baseline fan power.")
  
    # Get the total system bhp from the proposed system, including terminal fans
    proposed_sys_bhp = self.systemFanBrakeHorsepower(true)
  
    # Get the allowable fan brake horsepower
    allowable_fan_bhp = self.allowableSystemBrakeHorsepower(template)

    # Get the fan power limitation from proposed system
    fan_pwr_adjustment_bhp = self.fanPowerLimitationPressureDropAdjustmentBrakeHorsepower
    
    # Subtract the fan power adjustment
    allowable_fan_bhp = allowable_fan_bhp - fan_pwr_adjustment_bhp
    
    # Get all fans
    fans = self.supplyReturnExhaustReliefFans    
    
    # TODO improve description
    # Loop through the fans, changing the pressure rise
    # until the fan bhp is the same percentage of the baseline allowable bhp
    # as it was on the proposed system.
    fans.each do |fan|
    
      OpenStudio::logFree(OpenStudio::Info, "#{fan.name}")
    
      # Get the bhp of the fan on the proposed system
      proposed_fan_bhp = fan.brakeHorsepower
      
      # Get the bhp of the fan on the proposed system
      proposed_fan_bhp_frac = proposed_fan_bhp / proposed_sys_bhp
      
      # Determine the target bhp of the fan on the baseline system
      baseline_fan_bhp = proposed_fan_bhp_frac * allowable_fan_bhp
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "* #{(baseline_fan_bhp).round(1)} bhp = Baseline fan brake horsepower.")
      
      # Set the baseline impeller eff of the fan, 
      # preserving the proposed motor eff.
      baseline_impeller_eff = fan.baselineImpellerEfficiency(template)
      fan.changeImpellerEfficiency(baseline_impeller_eff)
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "* #{(baseline_impeller_eff * 100).round(1)}% = Baseline fan impeller efficiency.")
      
      # Set the baseline motor efficiency for the specified bhp
      baseline_motor_eff = fan.standardMinimumMotorEfficiency(template, hvac_standards, allowable_fan_bhp)
      fan.changeMotorEfficiency(baseline_motor_eff)
      
      # Get design supply air flow rate (whether autosized or hard-sized)
      dsn_air_flow_m3_per_s = 0
      if fan.autosizedDesignSupplyAirFlowRate.is_initialized
        dsn_air_flow_m3_per_s = fan.autosizedDesignSupplyAirFlowRate.get
        dsn_air_flow_cfm = OpenStudio.convert(dsn_air_flow_m3_per_s, "m^3/s", "cfm").get
        OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "* #{dsn_air_flow_cfm.round} cfm = Autosized Design Supply Air Flow Rate.")
      else
        dsn_air_flow_m3_per_s = fan.designSupplyAirFlowRate.get
        dsn_air_flow_cfm = OpenStudio.convert(dsn_air_flow_m3_per_s, "m^3/s", "cfm").get
        OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "* #{dsn_air_flow_cfm.round} cfm = User entered Design Supply Air Flow Rate.")
      end
      
      # Determine the fan pressure rise that will result in the target bhp
      # pressure_rise_pa = fan_bhp * 746 / fan_motor_eff * fan_total_eff / dsn_air_flow_m3_per_s
      baseline_pressure_rise_pa = baseline_fan_bhp * 746 / fan.motorEfficiency * fan.fanEfficiency / dsn_air_flow_m3_per_s
      baseline_pressure_rise_in_wc = OpenStudio.convert(fan_pressure_rise_pa, "Pa", "inH_{2}O",).get
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "* #{(fan_pressure_rise_in_wc).round(2)} in w.c. = Pressure drop to achieve allowable fan power.")

      # Calculate the bhp of the fan to make sure it matches
      calc_bhp = fan.brakeHorsepower
      if ((calc_bhp - baseline_fan_bhp) / baseline_fan_bhp).abs > 0.02
        OpenStudio::logFree(OpenStudio::Error, "openstudio.standards.AirLoopHVAC", "#{fan.name} baseline fan bhp supposed to be #{baseline_fan_bhp}, but is #{calc_bhp}.")
      end

    end
    
    # Calculate the total bhp of the system to make sure it matches the goal
    calc_sys_bhp = self.systemFanBrakeHorsepower(false)
    if ((calc_sys_bhp - allowable_fan_bhp) / allowable_fan_bhp).abs > 0.02
      OpenStudio::logFree(OpenStudio::Error, "openstudio.standards.AirLoopHVAC", "#{self.name} baseline system bhp supposed to be #{allowable_fan_bhp}, but is #{calc_sys_bhp}.")
    end

  end
 
end
