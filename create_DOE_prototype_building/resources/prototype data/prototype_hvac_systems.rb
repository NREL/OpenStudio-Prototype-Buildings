
# open the class to add methods to size all HVAC equipment
class OpenStudio::Model::Model

  def add_hw_loop(prototype_input, hvac_standards)

    #hot water loop
    hot_water_loop = OpenStudio::Model::PlantLoop.new(self)
    hot_water_loop.setName("Hot Water Loop")

    #hot water loop controls
    hw_temp_f = 180 #HW setpoint 180F 
    hw_delta_t_r = 20 #20F delta-T    
    hw_temp_c = OpenStudio.convert(hw_temp_f,"F","C").get
    hw_delta_t_k = OpenStudio.convert(hw_delta_t_r,"R","K").get
    hw_temp_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    hw_temp_sch.setName("Hot Water Loop Temp - #{hw_temp_f}F")
    hw_temp_sch.defaultDaySchedule().setName("Hot Water Loop Temp - #{hw_temp_f}F Default")
    hw_temp_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),hw_temp_c)
    hw_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(self,hw_temp_sch)    
    hw_stpt_manager.addToNode(hot_water_loop.supplyOutletNode)
    sizing_plant = hot_water_loop.sizingPlant
    sizing_plant.setLoopType("Heating")
    sizing_plant.setDesignLoopExitTemperature(hw_temp_c)
    sizing_plant.setLoopDesignTemperatureDifference(hw_delta_t_k)         
    
    #hot water pump
    hw_pump = OpenStudio::Model::PumpVariableSpeed.new(self)
    hw_pump.setName("Hot Water Loop Pump")
    hw_pump_head_ft_h2o = 60.0
    hw_pump_head_press_pa = OpenStudio.convert(hw_pump_head_ft_h2o, "ftH_{2}O","Pa").get
    hw_pump.setRatedPumpHead(hw_pump_head_press_pa)
    hw_pump.setMotorEfficiency(0.9)
    hw_pump.setFractionofMotorInefficienciestoFluidStream(0)
    hw_pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
    hw_pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
    hw_pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
    hw_pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
    hw_pump.setPumpControlType("Intermittent")
    hw_pump.addToNode(hot_water_loop.supplyInletNode)
    
    #boiler
    boiler = OpenStudio::Model::BoilerHotWater.new(self)
    boiler.setName("Hot Water Loop Boiler")
    boiler.setFuelType("NaturalGas")
    boiler.setDesignWaterOutletTemperature(hw_temp_c)
    boiler.setNominalThermalEfficiency(0.78)
    boiler.setBoilerFlowMode("LeavingSetpointModulated")
    hot_water_loop.addSupplyBranchForComponent(boiler)   
    
    #hot water loop pipes
    boiler_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
    hot_water_loop.addSupplyBranchForComponent(boiler_bypass_pipe)
    coil_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
    hot_water_loop.addDemandBranchForComponent(coil_bypass_pipe)
    supply_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
    supply_outlet_pipe.addToNode(hot_water_loop.supplyOutletNode)    
    demand_inlet_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
    demand_inlet_pipe.addToNode(hot_water_loop.demandInletNode) 
    demand_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
    demand_outlet_pipe.addToNode(hot_water_loop.demandOutletNode) 

    return hot_water_loop
    
  end  

  def add_chw_loop(prototype_input, hvac_standards)
    
    chillers = hvac_standards["chillers"]
    
    # Chilled water loop
    chilled_water_loop = OpenStudio::Model::PlantLoop.new(self)
    chilled_water_loop.setName("Chilled Water Loop")

    # Chilled water loop controls
    chw_temp_f = 44 #CHW setpoint 44F 
    chw_delta_t_r = 12 #12F delta-T    
    chw_temp_c = OpenStudio.convert(chw_temp_f,"F","C").get
    chw_delta_t_k = OpenStudio.convert(chw_delta_t_r,"R","K").get
    chw_temp_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    chw_temp_sch.setName("Chilled Water Loop Temp - #{chw_temp_f}F")
    chw_temp_sch.defaultDaySchedule().setName("Chilled Water Loop Temp - #{chw_temp_f}F Default")
    chw_temp_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),chw_temp_c)
    chw_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(self,chw_temp_sch)    
    chw_stpt_manager.addToNode(chilled_water_loop.supplyOutletNode)
    sizing_plant = chilled_water_loop.sizingPlant
    sizing_plant.setLoopType("Cooling")
    sizing_plant.setDesignLoopExitTemperature(chw_temp_c)
    sizing_plant.setLoopDesignTemperatureDifference(chw_delta_t_k)         
    
    puts prototype_input["chw_pumping_type"]
    
    # Chilled water pumps
    if prototype_input["chw_pumping_type"] == "const_pri"
      # Primary chilled water pump
      pri_chw_pump = OpenStudio::Model::PumpVariableSpeed.new(self)
      pri_chw_pump.setName("Chilled Water Loop Pump")
      pri_chw_pump_head_ft_h2o = 60.0
      pri_chw_pump_head_press_pa = OpenStudio.convert(pri_chw_pump_head_ft_h2o, "ftH_{2}O","Pa").get
      pri_chw_pump.setRatedPumpHead(pri_chw_pump_head_press_pa)
      pri_chw_pump.setMotorEfficiency(0.9)
      # Flat pump curve makes it behave as a constant speed pump
      pri_chw_pump.setFractionofMotorInefficienciestoFluidStream(0)
      pri_chw_pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
      pri_chw_pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
      pri_chw_pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
      pri_chw_pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
      pri_chw_pump.setPumpControlType("Intermittent")
      pri_chw_pump.addToNode(chilled_water_loop.supplyInletNode)   
    elsif prototype_input["chw_pumping_type"] == "const_pri_var_sec" 
      # Primary chilled water pump
      pri_chw_pump = OpenStudio::Model::PumpVariableSpeed.new(self)
      pri_chw_pump.setName("Chilled Water Loop Primary Pump")
      pri_chw_pump_head_ft_h2o = 15
      pri_chw_pump_head_press_pa = OpenStudio.convert(pri_chw_pump_head_ft_h2o, "ftH_{2}O","Pa").get
      pri_chw_pump.setRatedPumpHead(pri_chw_pump_head_press_pa)
      pri_chw_pump.setMotorEfficiency(0.9)
      # Flat pump curve makes it behave as a constant speed pump
      pri_chw_pump.setFractionofMotorInefficienciestoFluidStream(0)
      pri_chw_pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
      pri_chw_pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
      pri_chw_pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
      pri_chw_pump.setCoefficient4ofthePartLoadPerformanceCurve(0)    
      pri_chw_pump.setPumpControlType("Intermittent")
      pri_chw_pump.addToNode(chilled_water_loop.supplyInletNode) 
      # Secondary chilled water pump
      sec_chw_pump = OpenStudio::Model::PumpVariableSpeed.new(self)
      sec_chw_pump.setName("Chilled Water Loop Secondary Pump")
      sec_chw_pump_head_ft_h2o = 45
      sec_chw_pump_head_press_pa = OpenStudio.convert(sec_chw_pump_head_ft_h2o, "ftH_{2}O","Pa").get
      sec_chw_pump.setRatedPumpHead(sec_chw_pump_head_press_pa)
      sec_chw_pump.setMotorEfficiency(0.9)
      # Curve makes it perform like variable speed pump
      sec_chw_pump.setFractionofMotorInefficienciestoFluidStream(0)
      sec_chw_pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
      sec_chw_pump.setCoefficient2ofthePartLoadPerformanceCurve(0.0205)
      sec_chw_pump.setCoefficient3ofthePartLoadPerformanceCurve(0.4101)
      sec_chw_pump.setCoefficient4ofthePartLoadPerformanceCurve(0.5753)    
      sec_chw_pump.setPumpControlType("Intermittent")
      sec_chw_pump.addToNode(chilled_water_loop.demandInletNode) 
      # Change the chilled water loop to have a two-way common pipes
      chilled_water_loop.setCommonPipeSimulation("CommonPipe")
    else
      
    end
    
    # Find the initial Chiller properties based on initial inputs
    search_criteria = {
      "cooling_type" => prototype_input["chiller_cooling_type"],
      "condenser_type" => prototype_input["chller_condenser_type"],
      "compressor_type" => prototype_input["chiller_compressor_type"],
    }
    
    chiller_properties = find_objects(chillers, search_criteria, prototype_input["chiller_capacity_guess"])
    
    # Make the correct type of chiller based these properties
    chiller = add_chiller(self, chiller_properties)
    chiller.setReferenceLeavingChilledWaterTemperature(chw_temp_c)
    ref_cond_wtr_temp_f = 95
    ref_cond_wtr_temp_c = OpenStudio.convert(ref_cond_wtr_temp_f,"F","C").get
    chiller.setReferenceEnteringCondenserFluidTemperature(ref_cond_wtr_temp_c)
    chiller.setMinimumPartLoadRatio(0.15)
    chiller.setMaximumPartLoadRatio(1.0)
    chiller.setOptimumPartLoadRatio(0.8)
    chiller.setMinimumUnloadingRatio(0.15)
    chiller.setCondenserType("AirCooled")
    chiller.setLeavingChilledWaterLowerTemperatureLimit(OpenStudio.convert(36,"F","C").get)
    chiller.setChillerFlowMode("VariableFlow")
    chilled_water_loop.addSupplyBranchForComponent(chiller)  
    
    #chilled water loop pipes
    chiller_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
    chilled_water_loop.addSupplyBranchForComponent(chiller_bypass_pipe)
    coil_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
    chilled_water_loop.addDemandBranchForComponent(coil_bypass_pipe)
    supply_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
    supply_outlet_pipe.addToNode(chilled_water_loop.supplyOutletNode)    
    demand_inlet_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
    demand_inlet_pipe.addToNode(chilled_water_loop.demandInletNode) 
    demand_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
    demand_outlet_pipe.addToNode(chilled_water_loop.demandOutletNode)

    return chilled_water_loop

  end

  def add_vav(prototype_input, hvac_standards, hot_water_loop, chilled_water_loop, thermal_zones)

    hw_temp_f = 180 #HW setpoint 180F 
    hw_delta_t_r = 20 #20F delta-T    
    hw_temp_c = OpenStudio.convert(hw_temp_f,"F","C").get
    hw_delta_t_k = OpenStudio.convert(hw_delta_t_r,"R","K").get

    #hvac operation schedule
    # HVACOperationSchd,On/Off,
    # Through: 12/31,
    # For: Weekdays SummerDesignDay,Until: 06:00,0.0,Until: 22:00,1.0,Until: 24:00,0.0,
    # For: Saturday WinterDesignDay,Until: 06:00,0.0,Until: 18:00,1.0,Until: 24:00,0.0,
    # For: AllOtherDays,Until: 24:00,0.0    
    #weekdays and summer design days
    hvac_op_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    hvac_op_sch.setName("HVAC Operation Schedule")
    hvac_op_sch.defaultDaySchedule.setName("HVAC Operation Schedule Weekdays") 
    hvac_op_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,6,0,0), 0.0)
    hvac_op_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,22,0,0), 1.0)
    hvac_op_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
    hvac_op_sch.setSummerDesignDaySchedule(hvac_op_sch.defaultDaySchedule)
    #saturdays and winter design days
    saturday_rule = OpenStudio::Model::ScheduleRule.new(hvac_op_sch)
    saturday_rule.setName("HVAC Operation Schedule Saturday Rule")
    saturday_rule.setApplySaturday(true)   
    saturday = saturday_rule.daySchedule  
    saturday.setName("HVAC Operation Schedule Saturday")
    saturday.addValue(OpenStudio::Time.new(0,6,0,0), 0.0)
    saturday.addValue(OpenStudio::Time.new(0,18,0,0), 1.0)
    saturday.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
    hvac_op_sch.setWinterDesignDaySchedule(saturday)
    #sundays
    sunday_rule = OpenStudio::Model::ScheduleRule.new(hvac_op_sch)
    sunday_rule.setName("HVAC Operation Schedule Sunday Rule")
    sunday_rule.setApplySunday(true)   
    sunday = sunday_rule.daySchedule  
    sunday.setName("HVAC Operation Schedule Sunday")
    sunday.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
    
    #motorized oa damper schedule
    # MinOA_MotorizedDamper_Sched,Fraction,
    # Through: 12/31,
    # For: Weekdays SummerDesignDay,Until: 07:00,0.0,Until: 22:00,1.0,Until: 24:00,0.0,
    # For: Saturday WinterDesignDay,Until: 07:00,0.0,Until: 18:00,1.0,Until: 24:00,0.0,
    # For: AllOtherDays,Until: 24:00,0.0
    #weekdays and summer design days
    motorized_oa_damper_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    motorized_oa_damper_sch.setName("Motorized OA Damper Schedule")
    motorized_oa_damper_sch.defaultDaySchedule.setName("Motorized OA Damper Schedule Weekdays") 
    motorized_oa_damper_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,7,0,0), 0.0)
    motorized_oa_damper_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,22,0,0), 1.0)
    motorized_oa_damper_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
    motorized_oa_damper_sch.setSummerDesignDaySchedule(motorized_oa_damper_sch.defaultDaySchedule)
    #saturdays and winter design days
    saturday_rule = OpenStudio::Model::ScheduleRule.new(motorized_oa_damper_sch)
    saturday_rule.setName("Motorized OA Damper Schedule Saturday Rule")
    saturday_rule.setApplySaturday(true)   
    saturday = saturday_rule.daySchedule  
    saturday.setName("Motorized OA Damper Schedule Saturday")
    saturday.addValue(OpenStudio::Time.new(0,7,0,0), 0.0)
    saturday.addValue(OpenStudio::Time.new(0,18,0,0), 1.0)
    saturday.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
    motorized_oa_damper_sch.setWinterDesignDaySchedule(saturday)
    #sundays
    sunday_rule = OpenStudio::Model::ScheduleRule.new(motorized_oa_damper_sch)
    sunday_rule.setName("Motorized OA Damper Schedule Sunday Rule")
    sunday_rule.setApplySunday(true)   
    sunday = sunday_rule.daySchedule  
    sunday.setName("Motorized OA Damper Schedule Sunday")
    sunday.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)    
    
    #control temps used across all air handlers
    clg_sa_temp_f = 55 # Central deck clg temp 55F 
    prehtg_sa_temp_f = 44.6 # Preheat to 44.6F
    htg_sa_temp_f = 55 # Central deck htg temp 55F
    rht_sa_temp_f = 104 # VAV box reheat to 104F
    
    clg_sa_temp_c = OpenStudio.convert(clg_sa_temp_f,"F","C").get
    prehtg_sa_temp_c = OpenStudio.convert(prehtg_sa_temp_f,"F","C").get
    htg_sa_temp_c = OpenStudio.convert(htg_sa_temp_f,"F","C").get
    rht_sa_temp_c = OpenStudio.convert(rht_sa_temp_f,"F","C").get
    
    sa_temp_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    sa_temp_sch.setName("Supply Air Temp - #{clg_sa_temp_f}F")
    sa_temp_sch.defaultDaySchedule().setName("Supply Air Temp - #{clg_sa_temp_f}F Default")
    sa_temp_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),clg_sa_temp_c)

    #air handler
    air_loop = OpenStudio::Model::AirLoopHVAC.new(self)
    air_loop.setName("#{thermal_zones.size} Zone VAV")
    air_loop.setAvailabilitySchedule(hvac_op_sch)
    
    #air handler controls
    hw_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(self,sa_temp_sch)    
    hw_stpt_manager.addToNode(air_loop.supplyOutletNode)
    sizing_system = air_loop.sizingSystem()
    sizing_system.setSizingOption("Coincident")
    sizing_system.setAllOutdoorAirinCooling(false)
    sizing_system.setAllOutdoorAirinHeating(false)
    sizing_system.setSystemOutdoorAirMethod("VentilationRateProcedure")
    air_loop.setNightCycleControlType("CyleOnAny")
    
    #fan
    fan = OpenStudio::Model::FanVariableVolume.new(self,self.alwaysOnDiscreteSchedule)
    fan.setName("#{thermal_zones.size} Zone VAV Fan")
    fan.setFanEfficiency(0.6045)
    fan.setMotorEfficiency(0.93)
    fan_static_pressure_in_h2o = 5.58
    fan_static_pressure_pa = OpenStudio.convert(fan_static_pressure_in_h2o, "inH_{2}O","Pa").get
    fan.setPressureRise(fan_static_pressure_pa)
    fan.addToNode(air_loop.supplyInletNode)
    
    #cooling coil
    clg_coil = OpenStudio::Model::CoilCoolingWater.new(self,self.alwaysOnDiscreteSchedule)
    clg_coil.setName("#{thermal_zones.size} Zone VAV Clg Coil")
    clg_coil.addToNode(air_loop.supplyInletNode)
    chilled_water_loop.addDemandBranchForComponent(clg_coil)
    
    #heating coil
    htg_coil = OpenStudio::Model::CoilHeatingWater.new(self,model.alwaysOnDiscreteSchedule)
    htg_coil.setName("#{thermal_zones.size} Zone VAV Main Htg Coil")
    htg_coil.setRatedInletWaterTemperature(hw_temp_c)
    htg_coil.setRatedInletAirTemperature(prehtg_sa_temp_c)
    htg_coil.setRatedOutletWaterTemperature(hw_temp_c - hw_delta_t_k)
    htg_coil.setRatedOutletAirTemperature(htg_sa_temp_c)
    htg_coil.addToNode(air_loop.supplyInletNode)
    hot_water_loop.addDemandBranchForComponent(htg_coil)
    
    #outdoor air intake system
    oa_intake_controller = OpenStudio::Model::ControllerOutdoorAir.new(self)
    oa_intake = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(self, oa_intake_controller)    
    oa_intake.setName("#{thermal_zones.size} Zone VAV OA Sys")
    oa_intake_controller.setEconomizerControlType("NoEconomizer")
    oa_intake_controller.setMinimumLimitType("FixedMinimum")
    oa_intake_controller.setMinimumOutdoorAirSchedule(motorized_oa_damper_sch)
    oa_intake.addToNode(air_loop.supplyInletNode)

    #heat exchanger on oa system
    heat_exchanger = OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent.new(self)
    heat_exchanger.setName("#{thermal_zones.size} Zone VAV HX")
    heat_exchanger.setHeatExchangerType("Rotary")
    heat_exchanger.setSensibleEffectivenessat100CoolingAirFlow(0.7)
    heat_exchanger.setSensibleEffectivenessat75CoolingAirFlow(0.6)
    heat_exchanger.setLatentEffectivenessat100CoolingAirFlow(0.7)
    heat_exchanger.setLatentEffectivenessat75CoolingAirFlow(0.6)
    heat_exchanger.setSensibleEffectivenessat100HeatingAirFlow(0.75)
    heat_exchanger.setSensibleEffectivenessat75HeatingAirFlow(0.6)
    heat_exchanger.setLatentEffectivenessat100HeatingAirFlow(0.75)
    heat_exchanger.setLatentEffectivenessat75HeatingAirFlow(0.6)
    heat_exchanger.setNominalElectricPower(6240.0734)
    heat_exchanger.setEconomizerLockout(true)
    heat_exchanger.setSupplyAirOutletTemperatureControl(false)

    oa_node = oa_intake.outboardOANode
    if oa_node.is_initialized
      heat_exchanger.addToNode(oa_node.get)
    else
      puts("No outdoor air node found, can not add heat exchanger")
      return false
    end
    
    #hook the VAV system to each zone
    thermal_zones.each do |zone|
    
      #reheat coil
      rht_coil = OpenStudio::Model::CoilHeatingWater.new(self,model.alwaysOnDiscreteSchedule)
      rht_coil.setName("#{zone.name} Rht Coil")
      rht_coil.setRatedInletWaterTemperature(hw_temp_c)
      rht_coil.setRatedInletAirTemperature(htg_sa_temp_c)
      rht_coil.setRatedOutletWaterTemperature(hw_temp_c - hw_delta_t_k)
      rht_coil.setRatedOutletAirTemperature(rht_sa_temp_c)
      hot_water_loop.addDemandBranchForComponent(rht_coil)        
      
      #vav terminal
      terminal = OpenStudio::Model::AirTerminalSingleDuctVAVReheat.new(self,model.alwaysOnDiscreteSchedule,rht_coil)
      terminal.setName("#{zone.name} VAV Term")
      terminal.setZoneMinimumAirFlowMethod("Constant")
      terminal.setConstantMinimumAirFlowFraction(0.3)
      terminal.setDamperHeatingAction("Normal")
      air_loop.addBranchForZone(zone,terminal.to_StraightComponent)
    
    end

    return true

  end

  def add_psz_ac(prototype_input, hvac_standards, thermal_zones)

    #hvac operation schedule
    # HVACOperationSchd,On/Off,
    # Through: 12/31,
    # For: Weekdays SummerDesignDay,Until: 06:00,0.0,Until: 22:00,1.0,Until: 24:00,0.0,
    # For: Saturday WinterDesignDay,Until: 06:00,0.0,Until: 18:00,1.0,Until: 24:00,0.0,
    # For: AllOtherDays,Until: 24:00,0.0    
    #weekdays and summer design days
    hvac_op_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    hvac_op_sch.setName("HVAC Operation Schedule")
    hvac_op_sch.defaultDaySchedule.setName("HVAC Operation Schedule Weekdays") 
    hvac_op_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,6,0,0), 0.0)
    hvac_op_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,22,0,0), 1.0)
    hvac_op_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
    hvac_op_sch.setSummerDesignDaySchedule(hvac_op_sch.defaultDaySchedule)
    #saturdays and winter design days
    saturday_rule = OpenStudio::Model::ScheduleRule.new(hvac_op_sch)
    saturday_rule.setName("HVAC Operation Schedule Saturday Rule")
    saturday_rule.setApplySaturday(true)   
    saturday = saturday_rule.daySchedule  
    saturday.setName("HVAC Operation Schedule Saturday")
    saturday.addValue(OpenStudio::Time.new(0,6,0,0), 0.0)
    saturday.addValue(OpenStudio::Time.new(0,18,0,0), 1.0)
    saturday.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
    hvac_op_sch.setWinterDesignDaySchedule(saturday)
    #sundays
    sunday_rule = OpenStudio::Model::ScheduleRule.new(hvac_op_sch)
    sunday_rule.setName("HVAC Operation Schedule Sunday Rule")
    sunday_rule.setApplySunday(true)   
    sunday = sunday_rule.daySchedule  
    sunday.setName("HVAC Operation Schedule Sunday")
    sunday.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
    
    # Motorized OA damper schedule min OA schedule
    # MinOA_MotorizedDamper_Sched,Fraction,
    # Through: 12/31,
    # For: Weekdays SummerDesignDay,Until: 07:00,0.0,Until: 22:00,1.0,Until: 24:00,0.0,
    # For: Saturday WinterDesignDay,Until: 07:00,0.0,Until: 18:00,1.0,Until: 24:00,0.0,
    # For: AllOtherDays,Until: 24:00,0.0
    #weekdays and summer design days
    motorized_oa_damper_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    motorized_oa_damper_sch.setName("Motorized OA Damper Schedule")
    motorized_oa_damper_sch.defaultDaySchedule.setName("Motorized OA Damper Schedule Weekdays") 
    motorized_oa_damper_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,7,0,0), 0.0)
    motorized_oa_damper_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,22,0,0), 1.0)
    motorized_oa_damper_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
    motorized_oa_damper_sch.setSummerDesignDaySchedule(motorized_oa_damper_sch.defaultDaySchedule)
    #saturdays and winter design days
    saturday_rule = OpenStudio::Model::ScheduleRule.new(motorized_oa_damper_sch)
    saturday_rule.setName("Motorized OA Damper Schedule Saturday Rule")
    saturday_rule.setApplySaturday(true)   
    saturday = saturday_rule.daySchedule  
    saturday.setName("Motorized OA Damper Schedule Saturday")
    saturday.addValue(OpenStudio::Time.new(0,7,0,0), 0.0)
    saturday.addValue(OpenStudio::Time.new(0,18,0,0), 1.0)
    saturday.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
    motorized_oa_damper_sch.setWinterDesignDaySchedule(saturday)
    #sundays
    sunday_rule = OpenStudio::Model::ScheduleRule.new(motorized_oa_damper_sch)
    sunday_rule.setName("Motorized OA Damper Schedule Sunday Rule")
    sunday_rule.setApplySunday(true)   
    sunday = sunday_rule.daySchedule  
    sunday.setName("Motorized OA Damper Schedule Sunday")
    sunday.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)    

    # Make a PSZ-AC for each zone
    thermal_zones.each do |zone|
      
      air_loop = OpenStudio::Model::AirLoopHVAC.new(self)
      air_loop.setName("#{zone.name} PSZ-AC")
      air_loop.setAvailabilitySchedule(hvac_op_sch)
      
      # When an air_loop is contructed, its constructor creates a sizing:system object
      # the default sizing:system contstructor makes a system:sizing object 
      # appropriate for a multizone VAV system
      # this systems is a constant volume system with no VAV terminals, 
      # and therfore needs different default settings
      air_loop_sizing = air_loop.sizingSystem # TODO units
      air_loop_sizing.setTypeofLoadtoSizeOn("Sensible")
      air_loop_sizing.autosizeDesignOutdoorAirFlowRate
      air_loop_sizing.setMinimumSystemAirFlowRatio(1.0)
      air_loop_sizing.setPreheatDesignTemperature(7.0)
      air_loop_sizing.setPreheatDesignHumidityRatio(0.008)
      air_loop_sizing.setPrecoolDesignTemperature(12.8)
      air_loop_sizing.setPrecoolDesignHumidityRatio(0.008)
      air_loop_sizing.setCentralCoolingDesignSupplyAirTemperature(12.8)
      air_loop_sizing.setCentralHeatingDesignSupplyAirTemperature(40.0)
      air_loop_sizing.setSizingOption("Coincident")
      air_loop_sizing.setAllOutdoorAirinCooling(false)
      air_loop_sizing.setAllOutdoorAirinHeating(false)
      air_loop_sizing.setCentralCoolingDesignSupplyAirHumidityRatio(0.0085)
      air_loop_sizing.setCentralHeatingDesignSupplyAirHumidityRatio(0.0080)
      air_loop_sizing.setCoolingDesignAirFlowMethod("DesignDay")
      air_loop_sizing.setCoolingDesignAirFlowRate(0.0)
      air_loop_sizing.setHeatingDesignAirFlowMethod("DesignDay")
      air_loop_sizing.setHeatingDesignAirFlowRate(0.0)
      air_loop_sizing.setSystemOutdoorAirMethod("ZoneSum")

      fan = OpenStudio::Model::FanConstantVolume.new(self,self.alwaysOnDiscreteSchedule)
      fan.setName("#{zone.name} PSZ-AC Fan")
      fan_static_pressure_in_h2o = 2.5    
      fan_static_pressure_pa = OpenStudio.convert(fan_static_pressure_in_h2o, "inH_{2}O","Pa").get
      fan.setPressureRise(fan_static_pressure_pa)  
      fan.setFanEfficiency(0.54)
      fan.setMotorEfficiency(0.90)
      
      htg_coil = nil
      supplemental_htg_coil = nil
      if prototype_input["unitary_ac_heating_type"] == "Gas"
        htg_coil = OpenStudio::Model::CoilHeatingGas.new(self,self.alwaysOnDiscreteSchedule)
        htg_coil.setName("#{zone.name} PSZ-AC Gas Htg Coil")
      elsif prototype_input["unitary_ac_heating_type"] == "Single Speed Heat Pump"
        htg_cap_f_of_temp = OpenStudio::Model::CurveCubic.new(self)
        htg_cap_f_of_temp.setCoefficient1Constant(0.758746)
        htg_cap_f_of_temp.setCoefficient2x(0.027626)
        htg_cap_f_of_temp.setCoefficient3xPOW2(0.000148716)
        htg_cap_f_of_temp.setCoefficient4xPOW3(0.0000034992)
        htg_cap_f_of_temp.setMinimumValueofx(-20.0)
        htg_cap_f_of_temp.setMaximumValueofx(20.0)

        htg_cap_f_of_flow = OpenStudio::Model::CurveCubic.new(self)
        htg_cap_f_of_flow.setCoefficient1Constant(0.84)
        htg_cap_f_of_flow.setCoefficient2x(0.16)
        htg_cap_f_of_flow.setCoefficient3xPOW2(0.0)
        htg_cap_f_of_flow.setCoefficient4xPOW3(0.0)
        htg_cap_f_of_flow.setMinimumValueofx(0.5)
        htg_cap_f_of_flow.setMaximumValueofx(1.5)

        htg_energy_input_ratio_f_of_temp = OpenStudio::Model::CurveCubic.new(self)
        htg_energy_input_ratio_f_of_temp.setCoefficient1Constant(1.19248)
        htg_energy_input_ratio_f_of_temp.setCoefficient2x(-0.0300438)
        htg_energy_input_ratio_f_of_temp.setCoefficient3xPOW2(0.00103745)
        htg_energy_input_ratio_f_of_temp.setCoefficient4xPOW3(-0.000023328)
        htg_energy_input_ratio_f_of_temp.setMinimumValueofx(-20.0)
        htg_energy_input_ratio_f_of_temp.setMaximumValueofx(20.0)

        htg_energy_input_ratio_f_of_flow = OpenStudio::Model::CurveQuadratic.new(self)
        htg_energy_input_ratio_f_of_flow.setCoefficient1Constant(1.3824)
        htg_energy_input_ratio_f_of_flow.setCoefficient2x(-0.4336)
        htg_energy_input_ratio_f_of_flow.setCoefficient3xPOW2(0.0512)
        htg_energy_input_ratio_f_of_flow.setMinimumValueofx(0.0)
        htg_energy_input_ratio_f_of_flow.setMaximumValueofx(1.0)

        htg_part_load_fraction = OpenStudio::Model::CurveQuadratic.new(self)
        htg_part_load_fraction.setCoefficient1Constant(0.85)
        htg_part_load_fraction.setCoefficient2x(0.15)
        htg_part_load_fraction.setCoefficient3xPOW2(0.0)
        htg_part_load_fraction.setMinimumValueofx(0.0)
        htg_part_load_fraction.setMaximumValueofx(1.0)

        htg_coil = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(self,
                                                                  self.alwaysOnDiscreteSchedule,
                                                                  htg_cap_f_of_temp,
                                                                  htg_cap_f_of_flow,
                                                                  htg_energy_input_ratio_f_of_temp,
                                                                  htg_energy_input_ratio_f_of_flow,
                                                                  htg_part_load_fraction) 

        clg_coil.setName("#{zone.name} PSZ-AC HP Htg Coil")                                                          
                                                                  
        supplemental_htg_coil = OpenStudio::Model::CoilHeatingElectric.new(self,self.alwaysOnDiscreteSchedule)
        supplemental_htg_coil.setName("#{zone.name} PSZ-AC Elec Backup Htg Coil")
        
      end
      
      clg_coil = nil
      if prototype_input["unitary_ac_cooling_type"] == "Two Speed DX AC"
      
        clg_cap_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(self)
        clg_cap_f_of_temp.setCoefficient1Constant(0.42415)
        clg_cap_f_of_temp.setCoefficient2x(0.04426)
        clg_cap_f_of_temp.setCoefficient3xPOW2(-0.00042)
        clg_cap_f_of_temp.setCoefficient4y(0.00333)
        clg_cap_f_of_temp.setCoefficient5yPOW2(-0.00008)
        clg_cap_f_of_temp.setCoefficient6xTIMESY(-0.00021)
        clg_cap_f_of_temp.setMinimumValueofx(17.0)
        clg_cap_f_of_temp.setMaximumValueofx(22.0)
        clg_cap_f_of_temp.setMinimumValueofy(13.0)
        clg_cap_f_of_temp.setMaximumValueofy(46.0)

        clg_cap_f_of_flow = OpenStudio::Model::CurveQuadratic.new(self)
        clg_cap_f_of_flow.setCoefficient1Constant(0.77136)
        clg_cap_f_of_flow.setCoefficient2x(0.34053)
        clg_cap_f_of_flow.setCoefficient3xPOW2(-0.11088)
        clg_cap_f_of_flow.setMinimumValueofx(0.75918)
        clg_cap_f_of_flow.setMaximumValueofx(1.13877)

        clg_energy_input_ratio_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(self)
        clg_energy_input_ratio_f_of_temp.setCoefficient1Constant(1.23649)
        clg_energy_input_ratio_f_of_temp.setCoefficient2x(-0.02431)
        clg_energy_input_ratio_f_of_temp.setCoefficient3xPOW2(0.00057)
        clg_energy_input_ratio_f_of_temp.setCoefficient4y(-0.01434)
        clg_energy_input_ratio_f_of_temp.setCoefficient5yPOW2(0.00063)
        clg_energy_input_ratio_f_of_temp.setCoefficient6xTIMESY(-0.00038)
        clg_energy_input_ratio_f_of_temp.setMinimumValueofx(17.0)
        clg_energy_input_ratio_f_of_temp.setMaximumValueofx(22.0)
        clg_energy_input_ratio_f_of_temp.setMinimumValueofy(13.0)
        clg_energy_input_ratio_f_of_temp.setMaximumValueofy(46.0)

        clg_energy_input_ratio_f_of_flow = OpenStudio::Model::CurveQuadratic.new(self)
        clg_energy_input_ratio_f_of_flow.setCoefficient1Constant(1.20550)
        clg_energy_input_ratio_f_of_flow.setCoefficient2x(-0.32953)
        clg_energy_input_ratio_f_of_flow.setCoefficient3xPOW2(0.12308)
        clg_energy_input_ratio_f_of_flow.setMinimumValueofx(0.75918)
        clg_energy_input_ratio_f_of_flow.setMaximumValueofx(1.13877)

        clg_part_load_ratio = OpenStudio::Model::CurveQuadratic.new(self)
        clg_part_load_ratio.setCoefficient1Constant(0.77100)
        clg_part_load_ratio.setCoefficient2x(0.22900)
        clg_part_load_ratio.setCoefficient3xPOW2(0.0)
        clg_part_load_ratio.setMinimumValueofx(0.0)
        clg_part_load_ratio.setMaximumValueofx(1.0)

        clg_cap_f_of_temp_low_spd = OpenStudio::Model::CurveBiquadratic.new(self)
        clg_cap_f_of_temp_low_spd.setCoefficient1Constant(0.42415)
        clg_cap_f_of_temp_low_spd.setCoefficient2x(0.04426)
        clg_cap_f_of_temp_low_spd.setCoefficient3xPOW2(-0.00042)
        clg_cap_f_of_temp_low_spd.setCoefficient4y(0.00333)
        clg_cap_f_of_temp_low_spd.setCoefficient5yPOW2(-0.00008)
        clg_cap_f_of_temp_low_spd.setCoefficient6xTIMESY(-0.00021)
        clg_cap_f_of_temp_low_spd.setMinimumValueofx(17.0)
        clg_cap_f_of_temp_low_spd.setMaximumValueofx(22.0)
        clg_cap_f_of_temp_low_spd.setMinimumValueofy(13.0)
        clg_cap_f_of_temp_low_spd.setMaximumValueofy(46.0)

        clg_energy_input_ratio_f_of_temp_low_spd = OpenStudio::Model::CurveBiquadratic.new(self)
        clg_energy_input_ratio_f_of_temp_low_spd.setCoefficient1Constant(1.23649)
        clg_energy_input_ratio_f_of_temp_low_spd.setCoefficient2x(-0.02431)
        clg_energy_input_ratio_f_of_temp_low_spd.setCoefficient3xPOW2(0.00057)
        clg_energy_input_ratio_f_of_temp_low_spd.setCoefficient4y(-0.01434)
        clg_energy_input_ratio_f_of_temp_low_spd.setCoefficient5yPOW2(0.00063)
        clg_energy_input_ratio_f_of_temp_low_spd.setCoefficient6xTIMESY(-0.00038)
        clg_energy_input_ratio_f_of_temp_low_spd.setMinimumValueofx(17.0)
        clg_energy_input_ratio_f_of_temp_low_spd.setMaximumValueofx(22.0)
        clg_energy_input_ratio_f_of_temp_low_spd.setMinimumValueofy(13.0)
        clg_energy_input_ratio_f_of_temp_low_spd.setMaximumValueofy(46.0)

        clg_coil = OpenStudio::Model::CoilCoolingDXTwoSpeed.new(self,
                                                        self.alwaysOnDiscreteSchedule,
                                                        clg_cap_f_of_temp,
                                                        clg_cap_f_of_flow,
                                                        clg_energy_input_ratio_f_of_temp,
                                                        clg_energy_input_ratio_f_of_flow,
                                                        clg_part_load_ratio, 
                                                        clg_cap_f_of_temp_low_spd,
                                                        clg_energy_input_ratio_f_of_temp_low_spd)

        clg_coil.setName("#{zone.name} PSZ-AC 2spd DX AC Clg Coil")
        clg_coil.setRatedLowSpeedSensibleHeatRatio(OpenStudio::OptionalDouble.new(0.69))
        clg_coil.setBasinHeaterCapacity(10)
        clg_coil.setBasinHeaterSetpointTemperature(2.0)
      
      elsif prototype_input["unitary_ac_cooling_type"] == "Single Speed DX AC"
      
        clg_cap_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(self)
        clg_cap_f_of_temp.setCoefficient1Constant(0.9712123)
        clg_cap_f_of_temp.setCoefficient2x(-0.015275502)
        clg_cap_f_of_temp.setCoefficient3xPOW2(0.0014434524)
        clg_cap_f_of_temp.setCoefficient4y(-0.00039321)
        clg_cap_f_of_temp.setCoefficient5yPOW2(-0.0000068364)
        clg_cap_f_of_temp.setCoefficient6xTIMESY(-0.0002905956)
        clg_cap_f_of_temp.setMinimumValueofx(-100.0)
        clg_cap_f_of_temp.setMaximumValueofx(100.0)
        clg_cap_f_of_temp.setMinimumValueofy(-100.0)
        clg_cap_f_of_temp.setMaximumValueofy(100.0)

        clg_cap_f_of_flow = OpenStudio::Model::CurveQuadratic.new(self)
        clg_cap_f_of_flow.setCoefficient1Constant(1.0)
        clg_cap_f_of_flow.setCoefficient2x(0.0)
        clg_cap_f_of_flow.setCoefficient3xPOW2(0.0)
        clg_cap_f_of_flow.setMinimumValueofx(-100.0)
        clg_cap_f_of_flow.setMaximumValueofx(100.0)

        clg_energy_input_ratio_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(self)
        clg_energy_input_ratio_f_of_temp.setCoefficient1Constant(0.28687133)
        clg_energy_input_ratio_f_of_temp.setCoefficient2x(0.023902164)
        clg_energy_input_ratio_f_of_temp.setCoefficient3xPOW2(-0.000810648)
        clg_energy_input_ratio_f_of_temp.setCoefficient4y(0.013458546)
        clg_energy_input_ratio_f_of_temp.setCoefficient5yPOW2(0.0003389364)
        clg_energy_input_ratio_f_of_temp.setCoefficient6xTIMESY(-0.0004870044)
        clg_energy_input_ratio_f_of_temp.setMinimumValueofx(-100.0)
        clg_energy_input_ratio_f_of_temp.setMaximumValueofx(100.0)
        clg_energy_input_ratio_f_of_temp.setMinimumValueofy(-100.0)
        clg_energy_input_ratio_f_of_temp.setMaximumValueofy(100.0)

        clg_energy_input_ratio_f_of_flow = OpenStudio::Model::CurveQuadratic.new(self)
        clg_energy_input_ratio_f_of_flow.setCoefficient1Constant(1.0)
        clg_energy_input_ratio_f_of_flow.setCoefficient2x(0.0)
        clg_energy_input_ratio_f_of_flow.setCoefficient3xPOW2(0.0)
        clg_energy_input_ratio_f_of_flow.setMinimumValueofx(-100.0)
        clg_energy_input_ratio_f_of_flow.setMaximumValueofx(100.0)

        clg_part_load_ratio = OpenStudio::Model::CurveQuadratic.new(self)
        clg_part_load_ratio.setCoefficient1Constant(0.90949556)
        clg_part_load_ratio.setCoefficient2x(0.09864773)
        clg_part_load_ratio.setCoefficient3xPOW2(-0.00819488)
        clg_part_load_ratio.setMinimumValueofx(0.0)
        clg_part_load_ratio.setMaximumValueofx(1.0)
        clg_part_load_ratio.setMinimumCurveOutput(0.7)
        clg_part_load_ratio.setMaximumCurveOutput(1.0)

        clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(self,
                                                        self.alwaysOnDiscreteSchedule,
                                                        clg_cap_f_of_temp,
                                                        clg_cap_f_of_flow,
                                                        clg_energy_input_ratio_f_of_temp,
                                                        clg_energy_input_ratio_f_of_flow,
                                                        clg_part_load_ratio)

        clg_coil.setName("#{zone.name} PSZ-AC 1spd DX AC Clg Coil")
      
      elsif prototype_input["unitary_ac_cooling_type"] == "Single Speed Heat Pump"
      
        clg_cap_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(self)
        clg_cap_f_of_temp.setCoefficient1Constant(0.766956)
        clg_cap_f_of_temp.setCoefficient2x(0.0107756)
        clg_cap_f_of_temp.setCoefficient3xPOW2(-0.0000414703)
        clg_cap_f_of_temp.setCoefficient4y(0.00134961)
        clg_cap_f_of_temp.setCoefficient5yPOW2(-0.000261144)
        clg_cap_f_of_temp.setCoefficient6xTIMESY(0.000457488)
        clg_cap_f_of_temp.setMinimumValueofx(12.78)
        clg_cap_f_of_temp.setMaximumValueofx(23.89)
        clg_cap_f_of_temp.setMinimumValueofy(21.1)
        clg_cap_f_of_temp.setMaximumValueofy(46.1)

        clg_cap_f_of_flow = OpenStudio::Model::CurveQuadratic.new(self)
        clg_cap_f_of_flow.setCoefficient1Constant(0.8)
        clg_cap_f_of_flow.setCoefficient2x(0.2)
        clg_cap_f_of_flow.setCoefficient3xPOW2(0.0)
        clg_cap_f_of_flow.setMinimumValueofx(0.5)
        clg_cap_f_of_flow.setMaximumValueofx(1.5)

        clg_energy_input_ratio_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(self)
        clg_energy_input_ratio_f_of_temp.setCoefficient1Constant(0.297145)
        clg_energy_input_ratio_f_of_temp.setCoefficient2x(0.0430933)
        clg_energy_input_ratio_f_of_temp.setCoefficient3xPOW2(-0.000748766)
        clg_energy_input_ratio_f_of_temp.setCoefficient4y(0.00597727)
        clg_energy_input_ratio_f_of_temp.setCoefficient5yPOW2(0.000482112)
        clg_energy_input_ratio_f_of_temp.setCoefficient6xTIMESY(-0.000956448)
        clg_energy_input_ratio_f_of_temp.setMinimumValueofx(12.78)
        clg_energy_input_ratio_f_of_temp.setMaximumValueofx(23.89)
        clg_energy_input_ratio_f_of_temp.setMinimumValueofy(21.1)
        clg_energy_input_ratio_f_of_temp.setMaximumValueofy(46.1)

        clg_energy_input_ratio_f_of_flow = OpenStudio::Model::CurveQuadratic.new(self)
        clg_energy_input_ratio_f_of_flow.setCoefficient1Constant(1.156)
        clg_energy_input_ratio_f_of_flow.setCoefficient2x(-0.1816)
        clg_energy_input_ratio_f_of_flow.setCoefficient3xPOW2(0.0256)
        clg_energy_input_ratio_f_of_flow.setMinimumValueofx(0.5)
        clg_energy_input_ratio_f_of_flow.setMaximumValueofx(1.5)

        clg_part_load_ratio = OpenStudio::Model::CurveQuadratic.new(self)
        clg_part_load_ratio.setCoefficient1Constant(0.85)
        clg_part_load_ratio.setCoefficient2x(0.15)
        clg_part_load_ratio.setCoefficient3xPOW2(0.0)
        clg_part_load_ratio.setMinimumValueofx(0.0)
        clg_part_load_ratio.setMaximumValueofx(1.0)

        clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(self,
                                                        self.alwaysOnDiscreteSchedule,
                                                        clg_cap_f_of_temp,
                                                        clg_cap_f_of_flow,
                                                        clg_energy_input_ratio_f_of_temp,
                                                        clg_energy_input_ratio_f_of_flow,
                                                        clg_part_load_ratio)

        clg_coil.setName("#{zone.name} PSZ-AC 1spd DX HP Clg Coil")
        clg_coil.setRatedLowSpeedSensibleHeatRatio(OpenStudio::OptionalDouble.new(0.69))
        clg_coil.setBasinHeaterCapacity(10)
        clg_coil.setBasinHeaterSetpointTemperature(2.0)
      
      end
      
        
      oa_controller = OpenStudio::Model::ControllerOutdoorAir.new(self)
      oa_controller.setMinimumOutdoorAirSchedule(motorized_oa_damper_sch)
      
      oa_system = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(self,oa_controller)
      oa_system.setName("#{zone.name} PSZ-AC OA Sys")

      #heat exchanger on oa system
      if prototype_input["hx"] == true
        heat_exchanger = OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent.new(self)
        heat_exchanger.setName("#{zone.name} PSZ-AC HX")
        heat_exchanger.setHeatExchangerType("Rotary")
        heat_exchanger.setSensibleEffectivenessat100CoolingAirFlow(0.7)
        heat_exchanger.setSensibleEffectivenessat75CoolingAirFlow(0.6)
        heat_exchanger.setLatentEffectivenessat100CoolingAirFlow(0.7)
        heat_exchanger.setLatentEffectivenessat75CoolingAirFlow(0.6)
        heat_exchanger.setSensibleEffectivenessat100HeatingAirFlow(0.75)
        heat_exchanger.setSensibleEffectivenessat75HeatingAirFlow(0.6)
        heat_exchanger.setLatentEffectivenessat100HeatingAirFlow(0.75)
        heat_exchanger.setLatentEffectivenessat75HeatingAirFlow(0.6)
        heat_exchanger.setNominalElectricPower(2210.5647)
        heat_exchanger.setEconomizerLockout(true)
        heat_exchanger.setSupplyAirOutletTemperatureControl(false)
        oa_node = oa_system.outboardOANode
        if oa_node.is_initialized
          heat_exchanger.addToNode(oa_node.get)
        else
          puts("No outdoor air node found, can not add heat exchanger")
          return false
        end
      end
      
      # Add the components to the air loop
      # in order from closest to zone to furthest from zone
      supply_inlet_node = air_loop.supplyInletNode
      fan.addToNode(supply_inlet_node)
      unless supplemental_htg_coil.nil?
        supplemental_htg_coil.addToNode(supply_inlet_node)
      end
      
      unless htg_coil.nil?
        htg_coil.addToNode(supply_inlet_node)      
      end
      
      unless htg_coil.nil?
        clg_coil.addToNode(supply_inlet_node)
      end
      
      oa_system.addToNode(supply_inlet_node)
      
      # Add a setpoint manager single zone reheat to control the
      # supply air temperature based on the needs of this zone
      setpoint_mgr_single_zone_reheat = OpenStudio::Model::SetpointManagerSingleZoneReheat.new(self)
      setpoint_mgr_single_zone_reheat.setControlZone(zone)
      setpoint_mgr_single_zone_reheat.setMinimumSupplyAirTemperature(OpenStudio.convert(50,"F","C").get)
      setpoint_mgr_single_zone_reheat.setMaximumSupplyAirTemperature(OpenStudio.convert(122,"F","C").get)
      
      setpoint_mgr_single_zone_reheat.addToNode(air_loop.supplyOutletNode)
      air_loop.setNightCycleControlType("CycleOnAny")
      
      # Create a diffuser and attach the zone/diffuser pair to the air loop
      diffuser = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(self,self.alwaysOnDiscreteSchedule)
      diffuser.setName("#{zone.name} PSZ-AC Diffuser")
      air_loop.addBranchForZone(zone,diffuser.to_StraightComponent)      

    end

    return true

  end

  def add_chiller(hvac_standards, chlr_props)
    
    curve_biquadratics = hvac_standards["curve_biquadratics"]
    curve_quadratics = hvac_standards["curve_quadratics"]
    curve_bicubics = hvac_standards["curve_bicubics"]
  
    # Make the CAPFT curve
    capft_properties = find_objects(curve_biquadratics, {"name"=>chlr_props["capft"]})
    ccFofT = OpenStudio::Model::CurveBiquadratic.new(self)
    ccFofT.setName(capft_properties["name"])
    ccFofT.setCoefficient1Constant(capft_properties["coeff_1"])
    ccFofT.setCoefficient2x(capft_properties["coeff_2"])
    ccFofT.setCoefficient3xPOW2(capft_properties["coeff_3"])
    ccFofT.setCoefficient4y(capft_properties["coeff_4"])
    ccFofT.setCoefficient5yPOW2(capft_properties["coeff_5"])
    ccFofT.setCoefficient6xTIMESY(capft_properties["coeff_6"])
    ccFofT.setMinimumValueofx(capft_properties["min_x"])
    ccFofT.setMaximumValueofx(capft_properties["max_x"])
    ccFofT.setMinimumValueofy(capft_properties["min_y"])
    ccFofT.setMaximumValueofy(capft_properties["max_y"])

    # Make the EIRFT curve
    eirft_properties = find_objects(curve_biquadratics, {"name"=>chlr_props["eirft"]})
    eirToCorfOfT = OpenStudio::Model::CurveBiquadratic.new(self)
    eirToCorfOfT.setName(eirft_properties["name"])
    eirToCorfOfT.setCoefficient1Constant(eirft_properties["coeff_1"])
    eirToCorfOfT.setCoefficient2x(eirft_properties["coeff_2"])
    eirToCorfOfT.setCoefficient3xPOW2(eirft_properties["coeff_3"])
    eirToCorfOfT.setCoefficient4y(eirft_properties["coeff_4"])
    eirToCorfOfT.setCoefficient5yPOW2(eirft_properties["coeff_5"])
    eirToCorfOfT.setCoefficient6xTIMESY(eirft_properties["coeff_6"])
    eirToCorfOfT.setMinimumValueofx(eirft_properties["min_x"])
    eirToCorfOfT.setMaximumValueofx(eirft_properties["max_x"])
    eirToCorfOfT.setMinimumValueofy(eirft_properties["min_y"])
    eirToCorfOfT.setMaximumValueofy(eirft_properties["max_y"])

    # Make the EIRFPLR curve
    # which may be either a CurveBicubic or a CurveQuadratic based on chiller type
    eirToCorfOfPlr = nil
    eirfplr_properties = find_objects(curve_quadratics, {"name"=>chlr_props["eirfplr"]})
    if eirfplr_properties
      eirToCorfOfPlr = OpenStudio::Model::CurveQuadratic.new(self)
      eirToCorfOfPlr.setName(eirfplr_properties["name"])
      eirToCorfOfPlr.setCoefficient1Constant(eirfplr_properties["coeff_1"])
      eirToCorfOfPlr.setCoefficient2x(eirfplr_properties["coeff_2"])
      eirToCorfOfPlr.setCoefficient3xPOW2(eirfplr_properties["coeff_3"])
      eirToCorfOfPlr.setMinimumValueofx(eirfplr_properties["min_x"])
      eirToCorfOfPlr.setMaximumValueofx(eirfplr_properties["max_x"])
    end
    
    eirfplr_properties = find_objects(curve_bicubics, {"name"=>chlr_props["eirfplr"]})
    if eirfplr_properties
      eirToCorfOfPlr = OpenStudio::Model::CurveBicubic.new(self)
      eirToCorfOfPlr.setName(eirft_properties["name"])
      eirToCorfOfPlr.setCoefficient1Constant(eirfplr_properties["coeff_1"])
      eirToCorfOfPlr.setCoefficient2x(eirfplr_properties["coeff_2"])
      eirToCorfOfPlr.setCoefficient3xPOW2(eirfplr_properties["coeff_3"])
      eirToCorfOfPlr.setCoefficient4y(eirfplr_properties["coeff_4"])
      eirToCorfOfPlr.setCoefficient5yPOW2(eirfplr_properties["coeff_5"])
      eirToCorfOfPlr.setCoefficient6xTIMESY(eirfplr_properties["coeff_6"])
      eirToCorfOfPlr.setCoefficient7xPOW3 (eirfplr_properties["coeff_7"])
      eirToCorfOfPlr.setCoefficient8yPOW3 (eirfplr_properties["coeff_8"])
      eirToCorfOfPlr.setCoefficient9xPOW2TIMESY(eirfplr_properties["coeff_9"])
      eirToCorfOfPlr.setCoefficient10xTIMESYPOW2 (eirfplr_properties["coeff_10"])
      eirToCorfOfPlr.setMinimumValueofx(eirft_properties["min_x"])
      eirToCorfOfPlr.setMaximumValueofx(eirft_properties["max_x"])
      eirToCorfOfPlr.setMinimumValueofy(eirft_properties["min_y"])
      eirToCorfOfPlr.setMaximumValueofy(eirft_properties["max_y"])
    end  

    chiller = OpenStudio::Model::ChillerElectricEIR.new(self,ccFofT,eirToCorfOfT,eirToCorfOfPlr)
    chiller.setName("#{chlr_props["template"]} #{chlr_props["cooling_type"]} #{chlr_props["condenser_type"]} #{chlr_props["compressor_type"]} Chiller")
    chiller.setReferenceCOP(chlr_props["minimum_cop"])
    
    return chiller

  end

end
