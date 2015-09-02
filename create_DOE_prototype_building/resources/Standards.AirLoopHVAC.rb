
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
      baseline_motor_eff = fan.standardMinimumMotorEfficiency(template, standards, allowable_fan_bhp)
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

  # Get the total cooling capacity for the air loop
  def totalCoolingCapacity
  
    # Sum the cooling capacity for all cooling components
    # on the airloop, which may be inside of unitary systems.
    total_cooling_capacity_w = 0
    self.supplyComponents.each do |sc|
      # CoilCoolingDXSingleSpeed
      if sc.to_CoilCoolingDXSingleSpeed.is_initialized
        coil = sc.to_CoilCoolingDXSingleSpeed.get
        if coil.ratedTotalCoolingCapacity.is_initialized
          total_cooling_capacity_w += coil.ratedTotalCoolingCapacity.get
        elsif coil.autosizedRatedTotalCoolingCapacity.is_initialized
          total_cooling_capacity_w += coil.autosizedRatedTotalCoolingCapacity.get
        else
          OpenStudio::logFree(OpenStudio::Warn, 'openstudio.standards.AirLoopHVAC', "For #{self.name} capacity of #{coil.name} is not available, total cooling capacity of air loop will be incorrect when applying standard.")
        end
        # CoilCoolingDXTwoSpeed
      elsif sc.to_CoilCoolingDXTwoSpeed.is_initialized  
        coil = sc.to_CoilCoolingDXTwoSpeed.get
        if coil.ratedHighSpeedTotalCoolingCapacity.is_initialized
          total_cooling_capacity_w += coil.ratedHighSpeedTotalCoolingCapacity.get
        elsif coil.autosizedRatedHighSpeedTotalCoolingCapacity.is_initialized
          total_cooling_capacity_w += coil.autosizedRatedHighSpeedTotalCoolingCapacity.get
        else
          OpenStudio::logFree(OpenStudio::Warn, 'openstudio.standards.AirLoopHVAC', "For #{self.name} capacity of #{coil.name} is not available, total cooling capacity of air loop will be incorrect when applying standard.")
        end
        # CoilCoolingWater
      elsif sc.to_CoilCoolingWater.is_initialized
        coil = sc.to_CoilCoolingWater.get
        if coil.autosizedDesignCoilLoad.is_initialized # TODO Change to pull water coil nominal capacity instead of design load
          total_cooling_capacity_w += coil.autosizedDesignCoilLoad.get
        else
          OpenStudio::logFree(OpenStudio::Warn, 'openstudio.standards.AirLoopHVAC', "For #{self.name} capacity of #{coil.name} is not available, total cooling capacity of air loop will be incorrect when applying standard.")
        end
        # TODO Handle all cooling coil types for economizer determination
      elsif sc.to_CoilCoolingDXMultiSpeed.is_initialized ||
          sc.to_CoilCoolingCooledBeam.is_initialized ||
          sc.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized ||
          sc.to_AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.is_initialized ||
          sc.to_AirLoopHVACUnitaryHeatPumpAirToAir.is_initialized ||
          sc.to_AirLoopHVACUnitaryHeatPumpAirToAirMultiSpeed.is_initialized ||
          sc.to_AirLoopHVACUnitarySystem.is_initialized
        OpenStudio::logFree(OpenStudio::Warn, 'openstudio.standards.AirLoopHVAC', "#{self.name} has a cooling coil named #{sc.name}, whose type is not yet covered by economizer checks.")
        # CoilCoolingDXMultiSpeed
        # CoilCoolingCooledBeam
        # CoilCoolingWaterToAirHeatPumpEquationFit
        # AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass
        # AirLoopHVACUnitaryHeatPumpAirToAir	 
        # AirLoopHVACUnitaryHeatPumpAirToAirMultiSpeed	
        # AirLoopHVACUnitarySystem
      end
    end
    
    return total_cooling_capacity_w
  
  end
  
  # Determine whether or not this system
  # is required to have an economizer.
  def isEconomizerRequired(template, climate_zone)
  
    economizer_required = false
    
    # A big number of btu per hr as the minimum requirement
    infinity_btu_per_hr = 999999999999
    minimum_capacity_btu_per_hr = infinity_btu_per_hr
    
    # Determine the minimum capacity that requires an economizer
    case template
    when 'DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007'
      case climate_zone
      when 'ASHRAE 169-2006-1A',
          'ASHRAE 169-2006-1B',
          'ASHRAE 169-2006-2A',
          'ASHRAE 169-2006-3A',
          'ASHRAE 169-2006-4A'
        minimum_capacity_btu_per_hr = infinity_btu_per_hr # No requirement
      when 'ASHRAE 169-2006-2B',
          'ASHRAE 169-2006-5A',
          'ASHRAE 169-2006-6A',
          'ASHRAE 169-2006-7A',
          'ASHRAE 169-2006-7B',
          'ASHRAE 169-2006-8A',
          'ASHRAE 169-2006-8B'
        minimum_capacity_btu_per_hr = 35000
      when 'ASHRAE 169-2006-3B',
          'ASHRAE 169-2006-3C',
          'ASHRAE 169-2006-4B',
          'ASHRAE 169-2006-4C',
          'ASHRAE 169-2006-5B',
          'ASHRAE 169-2006-5C',
          'ASHRAE 169-2006-6B'
        minimum_capacity_btu_per_hr = 65000
      end
    when '90.1-2010', '90.1-2013'
      case climate_zone
      when 'ASHRAE 169-2006-1A',
          'ASHRAE 169-2006-1B'
        minimum_capacity_btu_per_hr = infinity_btu_per_hr # No requirement
      when 'ASHRAE 169-2006-2A',
          'ASHRAE 169-2006-3A',
          'ASHRAE 169-2006-4A',
          'ASHRAE 169-2006-2B',
          'ASHRAE 169-2006-5A',
          'ASHRAE 169-2006-6A',
          'ASHRAE 169-2006-7A',
          'ASHRAE 169-2006-7B',
          'ASHRAE 169-2006-8A',
          'ASHRAE 169-2006-8B',
          'ASHRAE 169-2006-3B',
          'ASHRAE 169-2006-3C',
          'ASHRAE 169-2006-4B',
          'ASHRAE 169-2006-4C',
          'ASHRAE 169-2006-5B',
          'ASHRAE 169-2006-5C',
          'ASHRAE 169-2006-6B'
        minimum_capacity_btu_per_hr = 54000
      end
    when 'NECB 2011'
      minimum_capacity_btu_per_hr =  68243      # NECB requires economizer for cooling cap > 20 kW
    end
  
    # Check whether the system requires an economizer by comparing
    # the system capacity to the minimum capacity.
    minimum_capacity_w = OpenStudio.convert(minimum_capacity_btu_per_hr, "Btu/hr", "W").get
    if self.totalCoolingCapacity >= minimum_capacity_w
      economizer_required = true
    end
    
    return economizer_required
  
  end
  
  # Set the economizer limits per the standard
  def setEconomizerLimits(template, climate_zone)
  
    # EnergyPlus economizer types
    # 'NoEconomizer'
    # 'FixedDryBulb'
    # 'FixedEnthalpy'
    # 'DifferentialDryBulb'
    # 'DifferentialEnthalpy'
    # 'FixedDewPointAndDryBulb'
    # 'ElectronicEnthalpy'
    # 'DifferentialDryBulbAndEnthalpy'  
  
    # Get the OA system and OA controller
    oa_sys = self.airLoopHVACOutdoorAirSystem
    if oa_sys.is_initialized
      oa_sys = oa_sys.get
    else
      return false # No OA system
    end
    oa_control = oa_sys.getControllerOutdoorAir
    economizer_type = oa_control.getEconomizerControlType
    
    # Return false if no economizer is present
    if economizer_type == 'NoEconomizer'
      return false
    end
  
    # Determine the limits according to the type
    drybulb_limit_f = nil
    enthalpy_limit_btu_per_lb = nil
    dewpoint_limit_f = nil
    case template
    when 'DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007'
      case economizer_type
      when 'FixedDryBulb'
        case climate_zone
        when 'ASHRAE 169-2006-1B',
            'ASHRAE 169-2006-2B',
            'ASHRAE 169-2006-3B',
            'ASHRAE 169-2006-3C',
            'ASHRAE 169-2006-4B',
            'ASHRAE 169-2006-4C',
            'ASHRAE 169-2006-5B',
            'ASHRAE 169-2006-5C',
            'ASHRAE 169-2006-6B',
            'ASHRAE 169-2006-7B',
            'ASHRAE 169-2006-8A',
            'ASHRAE 169-2006-8B'
          drybulb_limit_f = 75
        when 'ASHRAE 169-2006-5A',
            'ASHRAE 169-2006-6A',
            'ASHRAE 169-2006-7A'
          drybulb_limit_f = 70
        when 'ASHRAE 169-2006-1A',
            'ASHRAE 169-2006-2A',
            'ASHRAE 169-2006-3A',
            'ASHRAE 169-2006-4A'
          drybulb_limit_f = 65
        end
      when 'FixedEnthalpy'
        enthalpy_limit_btu_per_lb = 28
      when 'FixedDewPointAndDryBulb'
        drybulb_limit_f = 75
        dewpoint_limit_f = 55
      end
    when '90.1-2010', '90.1-2013'
      case economizer_type
      when 'FixedDryBulb'
        case climate_zone
        when 'ASHRAE 169-2006-1B',
            'ASHRAE 169-2006-2B',
            'ASHRAE 169-2006-3B',
            'ASHRAE 169-2006-3C',
            'ASHRAE 169-2006-4B',
            'ASHRAE 169-2006-4C',
            'ASHRAE 169-2006-5B',
            'ASHRAE 169-2006-5C',
            'ASHRAE 169-2006-6B',
            'ASHRAE 169-2006-7A',
            'ASHRAE 169-2006-7B',
            'ASHRAE 169-2006-8A',
            'ASHRAE 169-2006-8B'
          drybulb_limit_f = 75
        when 'ASHRAE 169-2006-5A',
            'ASHRAE 169-2006-6A'
          drybulb_limit_f = 70
        end
      when 'FixedEnthalpy'
        enthalpy_limit_btu_per_lb = 28
      when 'FixedDewPointAndDryBulb'
        drybulb_limit_f = 75
        dewpoint_limit_f = 55
      end
    end 
 
    # Set the limits
    case economizer_type
    when 'FixedDryBulb'
      if drybulb_limit_f
        drybulb_limit_c = OpenStudio.convert(drybulb_limit_f, 'F', 'C').get
        oa_control.setEconomizerMaximumLimitDryBulbTemperature(drybulb_limit_c)
        OpenStudio::logFree(OpenStudio::Info, 'openstudio.standards.AirLoopHVAC', "For #{template} #{climate_zone}:  #{self.name}: Economizer type = #{economizer_type}, dry bulb limit = #{drybulb_limit_f}F")
      end
    when 'FixedEnthalpy'
      if enthalpy_limit_btu_per_lb
        enthalpy_limit_j_per_kg = OpenStudio.convert(enthalpy_limit_btu_per_lb, 'Btu/lb', 'J/kg').get
        oa_control.setEconomizerMaximumLimitEnthalpy(enthalpy_limit_j_per_kg)
        OpenStudio::logFree(OpenStudio::Info, 'openstudio.standards.AirLoopHVAC', "For #{template} #{climate_zone}:  #{self.name}: Economizer type = #{economizer_type}, enthalpy limit = #{enthalpy_limit_btu_per_lb}Btu/lb")
      end
    when 'FixedDewPointAndDryBulb'
      if drybulb_limit_f && dewpoint_limit_f
        drybulb_limit_c = OpenStudio.convert(drybulb_limit_f, 'F', 'C').get
        dewpoint_limit_c = OpenStudio.convert(dewpoint_limit_f, 'F', 'C').get
        oa_control.setEconomizerMaximumLimitDryBulbTemperature(drybulb_limit_c)
        oa_control.setEconomizerMaximumLimitDewpointTemperature(dewpoint_limit_c)
        OpenStudio::logFree(OpenStudio::Info, 'openstudio.standards.AirLoopHVAC', "For #{template} #{climate_zone}:  #{self.name}: Economizer type = #{economizer_type}, dry bulb limit = #{drybulb_limit_f}F, dew-point limit = #{dewpoint_limit_f}F")
      end
    end 

    return true
    
  end

  # For systems required to have an economizer, set the economizer
  # to integrated on non-integrated per the standard.
  def setEconomizerIntegration(template, climate_zone)
  
    # Determine if the system is a VAV system based on the fan
    # which may be inside of a unitary system.
    is_vav = false
    self.supplyComponents.reverse.each do |comp|
      if comp.to_FanVariableVolume.is_initialized
        is_vav = true
      elsif comp.to_AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.is_initialized
        fan = comp.to_AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.get.supplyAirFan
        if fan.to_FanVariableVolume.is_initialized
          is_vav = true
        end
      elsif comp.to_AirLoopHVACUnitarySystem.is_initialized
        fan = comp.to_AirLoopHVACUnitarySystem.get.supplyFan
        if fan.is_initialized
          if fan.get.to_FanVariableVolume.is_initialized
            is_vav = true
          end
        end
      end  
    end

    # Determine the number of zones the system serves
    num_zones_served = self.thermalZones.size
    
    # A big number of btu per hr as the minimum requirement
    infinity_btu_per_hr = 999999999999
    minimum_capacity_btu_per_hr = infinity_btu_per_hr
    
    # Determine if an integrated economizer is required
    integrated_economizer_required = true
    case template
    when 'DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007'    
      minimum_capacity_btu_per_hr = 65000
      minimum_capacity_w = OpenStudio.convert(minimum_capacity_btu_per_hr, "Btu/hr", "W").get
      # 6.5.1.3 Integrated Economizer Control
      # Exception a, DX VAV systems
      if is_vav == true && num_zones_served > 1
        integrated_economizer_required = false
        OpenStudio::logFree(OpenStudio::Info, 'openstudio.standards.AirLoopHVAC', "For #{template} #{climate_zone}:  #{self.name}: non-integrated economizer per 6.5.1.3 exception a, DX VAV system.")
        # Exception b, DX units less than 65,000 Btu/hr
      elsif self.totalCoolingCapacity < minimum_capacity_w
        integrated_economizer_required = false
        OpenStudio::logFree(OpenStudio::Info, 'openstudio.standards.AirLoopHVAC', "For #{template} #{climate_zone}:  #{self.name}: non-integrated economizer per 6.5.1.3 exception b, DX system less than #{minimum_capacity_btu_per_hr}Btu/hr.")
      else
        # Exception c, Systems in climate zones 1,2,3a,4a,5a,5b,6,7,8
        case climate_zone
        when 'ASHRAE 169-2006-1A',
            'ASHRAE 169-2006-1B',
            'ASHRAE 169-2006-2A',
            'ASHRAE 169-2006-2B',
            'ASHRAE 169-2006-3A',
            'ASHRAE 169-2006-4A',
            'ASHRAE 169-2006-5A',
            'ASHRAE 169-2006-5B',
            'ASHRAE 169-2006-6A',
            'ASHRAE 169-2006-6B',
            'ASHRAE 169-2006-7A',
            'ASHRAE 169-2006-7B',
            'ASHRAE 169-2006-8A',
            'ASHRAE 169-2006-8B'
          integrated_economizer_required = false
          OpenStudio::logFree(OpenStudio::Info, 'openstudio.standards.AirLoopHVAC', "For #{template} #{climate_zone}:  #{self.name}: non-integrated economizer per 6.5.1.3 exception c, climate zone #{climate_zone}.")
        when 'ASHRAE 169-2006-3B',
            'ASHRAE 169-2006-3C',
            'ASHRAE 169-2006-4B',
            'ASHRAE 169-2006-4C',
            'ASHRAE 169-2006-5C'
          integrated_economizer_required = true
        end
      end
    when '90.1-2010', '90.1-2013'
      integrated_economizer_required = true
    when 'NECB 2011'
      # this means that compressor allowed to turn on when economizer is open
      # (NoLockout); as per 5.2.2.8(3) 
      integrated_economizer_required = true
    end
  
    # Get the OA system and OA controller
    oa_sys = self.airLoopHVACOutdoorAirSystem
    if oa_sys.is_initialized
      oa_sys = oa_sys.get
    else
      return false # No OA system
    end
    oa_control = oa_sys.getControllerOutdoorAir  
  
    # Apply integrated or non-integrated economizer
    if integrated_economizer_required
      oa_control.setLockoutType('NoLockout')
    else
      oa_control.setLockoutType('LockoutWithCompressor')
    end

    return true
    
  end
  
  # Add economizer per Appendix G baseline
  def addBaselineEconomizer(template, climate_zone)
  
  end
  
  # Check the economizer type.  Returns true if allowable
  # or if the system has no economizer or no OA system.
  def isEconomizerTypeAllowable(template, climate_zone)
  
    # EnergyPlus economizer types
    # 'NoEconomizer'
    # 'FixedDryBulb'
    # 'FixedEnthalpy'
    # 'DifferentialDryBulb'
    # 'DifferentialEnthalpy'
    # 'FixedDewPointAndDryBulb'
    # 'ElectronicEnthalpy'
    # 'DifferentialDryBulbAndEnthalpy'
    
    # Get the OA system and OA controller
    oa_sys = self.airLoopHVACOutdoorAirSystem
    if oa_sys.is_initialized
      oa_sys = oa_sys.get
    else
      return true # No OA system
    end
    oa_control = oa_sys.getControllerOutdoorAir
    economizer_type = oa_control.getEconomizerControlType
    
    # Return true if no economizer is present
    if economizer_type == 'NoEconomizer'
      return true
    end
    
    # Determine the minimum capacity that requires an economizer
    prohibited_types = []
    case template
    when 'DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007'
      case climate_zone
      when 'ASHRAE 169-2006-1B',
          'ASHRAE 169-2006-2B',
          'ASHRAE 169-2006-3B',
          'ASHRAE 169-2006-3C',
          'ASHRAE 169-2006-4B',
          'ASHRAE 169-2006-4C',
          'ASHRAE 169-2006-5B',
          'ASHRAE 169-2006-6B',
          'ASHRAE 169-2006-7A',
          'ASHRAE 169-2006-7B',
          'ASHRAE 169-2006-8A',
          'ASHRAE 169-2006-8B'
        prohibited_types = ['FixedEnthalpy']
      when
        'ASHRAE 169-2006-1A',
          'ASHRAE 169-2006-2A',
          'ASHRAE 169-2006-3A',
          'ASHRAE 169-2006-4A'
        prohibited_types = ['DifferentialDryBulb']
      when 
        'ASHRAE 169-2006-5A',
          'ASHRAE 169-2006-6A',
          prohibited_types = []
      end
    when  '90.1-2010', '90.1-2013'
      case climate_zone
      when 'ASHRAE 169-2006-1B',
          'ASHRAE 169-2006-2B',
          'ASHRAE 169-2006-3B',
          'ASHRAE 169-2006-3C',
          'ASHRAE 169-2006-4B',
          'ASHRAE 169-2006-4C',
          'ASHRAE 169-2006-5B',
          'ASHRAE 169-2006-6B',
          'ASHRAE 169-2006-7A',
          'ASHRAE 169-2006-7B',
          'ASHRAE 169-2006-8A',
          'ASHRAE 169-2006-8B'
        prohibited_types = ['FixedEnthalpy']
      when
        'ASHRAE 169-2006-1A',
          'ASHRAE 169-2006-2A',
          'ASHRAE 169-2006-3A',
          'ASHRAE 169-2006-4A'
        prohibited_types = ['FixedDryBulb', 'DifferentialDryBulb']
      when 
        'ASHRAE 169-2006-5A',
          'ASHRAE 169-2006-6A',
          prohibited_types = []
      end
    end
    
    # Check if the specified type is allowed
    economizer_type_allowed = true
    if prohibited_types.include?(economizer_type)
      economizer_type_allowed = false
    end
    
    return economizer_type_allowed
  
  end
  
  # Check if ERV is required
  def isEnergyRecoveryVentilatorRequired(template, climate_zone)
      
    # ERV Not Applicable for AHUs that serve 
    # parking garage, warehouse, or multifamily
    # if space_types_served_names.include?('PNNL_Asset_Rating_Apartment_Space_Type') ||
    # space_types_served_names.include?('PNNL_Asset_Rating_LowRiseApartment_Space_Type') ||
    # space_types_served_names.include?('PNNL_Asset_Rating_ParkingGarage_Space_Type') ||
    # space_types_served_names.include?('PNNL_Asset_Rating_Warehouse_Space_Type')
    # OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "For #{self.name}, ERV not applicable because it because it serves parking garage, warehouse, or multifamily.")
    # return false
    # end
    
    # ERV Not Applicable for AHUs that have DCV
    # or that have no OA intake.    
    controller_oa = nil
    controller_mv = nil
    oa_system = nil
    if self.airLoopHVACOutdoorAirSystem.is_initialized
      oa_system = self.airLoopHVACOutdoorAirSystem.get
      controller_oa = oa_system.getControllerOutdoorAir      
      controller_mv = controller_oa.controllerMechanicalVentilation
      if controller_mv.demandControlledVentilation == true
        OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "For #{template} #{self.name}, ERV not applicable because DCV enabled.")
        runner.registerInfo()
        return false
      end
    else
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "For #{template} #{self.name}, ERV not applicable because it has no OA intake.")
      return false
    end

    # Get the AHU design supply air flow rate
    dsn_flow_m3_per_s = nil
    if self.designSupplyAirFlowRate.is_initialized
      dsn_flow_m3_per_s = self.designSupplyAirFlowRate.get
    elsif self.autosizedDesignSupplyAirFlowRate.is_initialized
      dsn_flow_m3_per_s = self.autosizedDesignSupplyAirFlowRate.get
    else
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.standards.AirLoopHVAC", "For #{template} #{self.name} design supply air flow rate is not available, cannot apply efficiency standard.")
      return false
    end
    dsn_flow_cfm = OpenStudio.convert(dsn_flow_m3_per_s, 'm^3/s', 'cfm').get
    
    # Get the minimum OA flow rate
    min_oa_flow_m3_per_s = nil
    if controller_oa.minimumOutdoorAirFlowRate.is_initialized
      min_oa_flow_m3_per_s = controller_oa.minimumOutdoorAirFlowRate.get
    elsif controller_oa.autosizedMinimumOutdoorAirFlowRate.is_initialized
      min_oa_flow_m3_per_s = controller_oa.autosizedMinimumOutdoorAirFlowRate.get
    else
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.standards.AirLoopHVAC", "For #{template} #{controller_oa.name} minimum OA flow rate is not available, cannot apply efficiency standard.")
      return false
    end
    min_oa_flow_cfm = OpenStudio.convert(min_oa_flow_m3_per_s, 'm^3/s', 'cfm').get
    
    # Calculate the percent OA at design airflow
    pct_oa = min_oa_flow_m3_per_s/dsn_flow_m3_per_s
    
    case template
    when 'DOE Ref Pre-1980', 'DOE Ref 1980-2004'
      erv_cfm = nil # Not required
    when '90.1-2004', '90.1-2007'
      if pct_oa < 0.7
        erv_cfm = nil
      else
        erv_cfm = 5000
      end
    when '90.1-2010'
      # Table 6.5.6.1
      case climate_zone
      when 'ASHRAE 169-2006-3B', 'ASHRAE 169-2006-3C', 'ASHRAE 169-2006-4B', 'ASHRAE 169-2006-4C', 'ASHRAE 169-2006-5B'
        if pct_oa < 0.3
          erv_cfm = nil
        elsif pct_oa >= 0.3 && pct_oa < 0.4
          erv_cfm = nil
        elsif pct_oa >= 0.4 && pct_oa < 0.5
          erv_cfm = nil
        elsif pct_oa >= 0.5 && pct_oa < 0.6
          erv_cfm = nil
        elsif pct_oa >= 0.6 && pct_oa < 0.7
          erv_cfm = nil
        elsif pct_oa >= 0.7 && pct_oa < 0.8
          erv_cfm = 5000
        elsif pct_oa >= 0.8 
          erv_cfm = 5000
        end
      when 'ASHRAE 169-2006-1B', 'ASHRAE 169-2006-2B', 'ASHRAE 169-2006-5C'
        if pct_oa < 0.3
          erv_cfm = nil
        elsif pct_oa >= 0.3 && pct_oa < 0.4
          erv_cfm = nil
        elsif pct_oa >= 0.4 && pct_oa < 0.5
          erv_cfm = nil
        elsif pct_oa >= 0.5 && pct_oa < 0.6
          erv_cfm = 26000
        elsif pct_oa >= 0.6 && pct_oa < 0.7
          erv_cfm = 12000
        elsif pct_oa >= 0.7 && pct_oa < 0.8
          erv_cfm = 5000
        elsif pct_oa >= 0.8 
          erv_cfm = 4000
        end
      when 'ASHRAE 169-2006-6B'
        if pct_oa < 0.3
          erv_cfm = nil
        elsif pct_oa >= 0.3 && pct_oa < 0.4
          erv_cfm = 11000
        elsif pct_oa >= 0.4 && pct_oa < 0.5
          erv_cfm = 5500
        elsif pct_oa >= 0.5 && pct_oa < 0.6
          erv_cfm = 4500
        elsif pct_oa >= 0.6 && pct_oa < 0.7
          erv_cfm = 3500
        elsif pct_oa >= 0.7 && pct_oa < 0.8
          erv_cfm = 2500
        elsif pct_oa >= 0.8 
          erv_cfm = 1500
        end      
      when 'ASHRAE 169-2006-1A', 'ASHRAE 169-2006-2A', 'ASHRAE 169-2006-3A', 'ASHRAE 169-2006-4A', 'ASHRAE 169-2006-5A', 'ASHRAE 169-2006-6A'
        if pct_oa < 0.3
          erv_cfm = nil
        elsif pct_oa >= 0.3 && pct_oa < 0.4
          erv_cfm = 5500
        elsif pct_oa >= 0.4 && pct_oa < 0.5
          erv_cfm = 4500
        elsif pct_oa >= 0.5 && pct_oa < 0.6
          erv_cfm = 3500
        elsif pct_oa >= 0.6 && pct_oa < 0.7
          erv_cfm = 2000
        elsif pct_oa >= 0.7 && pct_oa < 0.8
          erv_cfm = 1000
        elsif pct_oa >= 0.8 
          erv_cfm = 0
        end   
      when 'ASHRAE 169-2006-7A', 'ASHRAE 169-2006-7B', 'ASHRAE 169-2006-8A', 'ASHRAE 169-2006-8B'
        if pct_oa < 0.3
          erv_cfm = nil
        elsif pct_oa >= 0.3 && pct_oa < 0.4
          erv_cfm = 2500
        elsif pct_oa >= 0.4 && pct_oa < 0.5
          erv_cfm = 1000
        elsif pct_oa >= 0.5 && pct_oa < 0.6
          erv_cfm = 0
        elsif pct_oa >= 0.6 && pct_oa < 0.7
          erv_cfm = 0
        elsif pct_oa >= 0.7 && pct_oa < 0.8
          erv_cfm = 0
        elsif pct_oa >= 0.8 
          erv_cfm = 0
        end      
      end
    when '90.1-2013'
      # Table 6.5.6.1-2
      case climate_zone
      when 'ASHRAE 169-2006-3C'
        erv_cfm = nil
      when 'ASHRAE 169-2006-1B', 'ASHRAE 169-2006-2B', 'ASHRAE 169-2006-3B', 'ASHRAE 169-2006-4C', 'ASHRAE 169-2006-5C'
        if pct_oa < 0.1
          erv_cfm = nil
        elsif pct_oa >= 0.1 && pct_oa < 0.2
          erv_cfm = nil
        elsif pct_oa >= 0.2 && pct_oa < 0.3
          erv_cfm = 19500
        elsif pct_oa >= 0.3 && pct_oa < 0.4
          erv_cfm = 9000
        elsif pct_oa >= 0.4 && pct_oa < 0.5
          erv_cfm = 5000
        elsif pct_oa >= 0.5 && pct_oa < 0.6
          erv_cfm = 4000
        elsif pct_oa >= 0.6 && pct_oa < 0.7
          erv_cfm = 3000
        elsif pct_oa >= 0.7 && pct_oa < 0.8
          erv_cfm = 1500
        elsif pct_oa >= 0.8 
          erv_cfm = 0
        end
      when 'ASHRAE 169-2006-1A', 'ASHRAE 169-2006-2A', 'ASHRAE 169-2006-3A', 'ASHRAE 169-2006-4B',  'ASHRAE 169-2006-5B'
        if pct_oa < 0.1
          erv_cfm = nil
        elsif pct_oa >= 0.1 && pct_oa < 0.2
          erv_cfm = 2500
        elsif pct_oa >= 0.2 && pct_oa < 0.3
          erv_cfm = 2000
        elsif pct_oa >= 0.3 && pct_oa < 0.4
          erv_cfm = 1000
        elsif pct_oa >= 0.4 && pct_oa < 0.5
          erv_cfm = 500
        elsif pct_oa >= 0.5
          erv_cfm = 0
        end
      when 'ASHRAE 169-2006-4A', 'ASHRAE 169-2006-5A', 'ASHRAE 169-2006-6A', 'ASHRAE 169-2006-6B', 'ASHRAE 169-2006-7A', 'ASHRAE 169-2006-7B', 'ASHRAE 169-2006-8A', 'ASHRAE 169-2006-8B'
        if pct_oa < 0.1
          erv_cfm = nil
        elsif pct_oa >= 0.1
          erv_cfm = 0
        end
      end
    when 'NECB 2011'
      # The NECB 2011 requirement is that systems with an exhaust heat content > 150 kW require an HRV
      # The calculation for this is done below, to modify erv_required 
      # erv_cfm set to nil here as placeholder, will lead to erv_required = false
      erv_cfm = nil
    end
    
    # Determine if an ERV is required
    erv_required = nil
    if erv_cfm.nil?
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "For #{template} #{self.name}, ERV not required based on #{(pct_oa*100).round}% OA flow, design flow of #{dsn_flow_cfm.round}cfm, and climate zone #{climate_zone}.")
      erv_required = false 
    elsif dsn_flow_cfm < erv_cfm
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "For #{template} #{self.name}, ERV not required based on #{(pct_oa*100).round}% OA flow, design flow of #{dsn_flow_cfm.round}cfm, and climate zone #{climate_zone}. Does not exceed minimum flow requirement of #{erv_cfm}cfm.")
      erv_required = false 
    else
      OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "For #{template} #{self.name}, ERV required based on #{(pct_oa*100).round}% OA flow, design flow of #{dsn_flow_cfm.round}cfm, and climate zone #{climate_zone}. Exceeds minimum flow requirement of #{erv_cfm}cfm.")
      erv_required = true 
    end
  
    # This code modifies erv_required for NECB 2011
    # Calculation of exhaust heat content and check whether it is > 150 kW
    
    if template == 'NECB 2011'     
      
      # get all zones in the model
      zones = self.thermalZones
      
      # initialize counters
      sum_zone_oa = 0.0
      sum_zoneoaTimesheatDesignT = 0.0
      
      # zone loop
      zones.each do |zone|
        
        # get design heat temperature for each zone; this is equivalent to design exhaust temperature
        zone_sizing = zone.sizingZone
        heatDesignTemp = zone_sizing.zoneHeatingDesignSupplyAirTemperature

        # initialize counter
        zone_oa = 0.0
        # outdoor defined at space level; get OA flow for all spaces within zone
        spaces = zone.spaces
                
        # space loop
        spaces.each do |space|
          if not space.designSpecificationOutdoorAir.empty?             # if empty, don't do anything
            outdoor_air = space.designSpecificationOutdoorAir.get   
            
            # in bTAP, outdoor air specified as outdoor air per person (m3/s/person)
            oa_flow_per_person = outdoor_air.outdoorAirFlowperPerson
            num_people = space.peoplePerFloorArea * space.floorArea
            oa_flow = oa_flow_per_person * num_people     # oa flow for the space
            zone_oa = zone_oa + oa_flow                   # add up oa flow for all spaces to get zone air flow
          end 
          
        end   # space loop
        
        sum_zone_oa = sum_zone_oa + zone_oa              # sum of all zone oa flows to get system oa flow
        sum_zoneoaTimesheatDesignT = sum_zoneoaTimesheatDesignT + (zone_oa * heatDesignTemp)     # calculated to get oa flow weighted average of design exhaust temperature
         
      end   # zone loop
      
      # Calculate average exhaust temperature (oa flow weighted average)
      avg_exhaust_temp = sum_zoneoaTimesheatDesignT / sum_zone_oa              
      
      # for debugging/testing     
#      puts "average exhaust temp = #{avg_exhaust_temp}"
#      puts "sum_zone_oa = #{sum_zone_oa}"
       
      # Get January winter design temperature
      # get model weather file name
      weather_file = BTAP::Environment::WeatherFile.new(self.model.weatherFile.get.path.get)
      
      # get winter(heating) design temp stored in array
      # Note that the NECB 2011 specifies using the 2.5% january design temperature
      # The outdoor temperature used here is the 0.4% heating design temperature of the coldest month, available in stat file
      outdoor_temp = weather_file.heating_design_info[1]
      
#      for debugging/testing
#      puts "outdoor design temp = #{outdoor_temp}"            
           
      # Calculate exhaust heat content
      exhaust_heat_content = 0.00123 * sum_zone_oa * 1000.0 * (avg_exhaust_temp - outdoor_temp)
      
      # for debugging/testing
#      puts "exhaust heat content = #{exhaust_heat_content}"
      
      
      # Modify erv_required based on exhaust heat content
      if ( exhaust_heat_content > 150.0 ) then
        erv_required = true
        OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "For #{template} #{self.name}, ERV required based on exhaust heat content.") 
      else
        erv_required = false
        OpenStudio::logFree(OpenStudio::Info, "openstudio.standards.AirLoopHVAC", "For #{template} #{self.name}, ERV not required based on exhaust heat content.") 
      end
       
      
      
    end   # of NECB 2011 condition
    
    # for debugging/testing
#    puts "erv_required = #{erv_required}"   
    
    return erv_required
  
  end  
   
end
