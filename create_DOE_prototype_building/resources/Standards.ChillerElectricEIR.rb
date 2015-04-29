
# open the class to add methods to return sizing values
class OpenStudio::Model::ChillerElectricEIR

  def setStandardEfficiencyAndCurves(template, hvac_standards)
  
    chillers = hvac_standards['chillers']
    curve_biquadratics = hvac_standards['curve_biquadratics']
    curve_quadratics = hvac_standards['curve_quadratics']
    curve_bicubics = hvac_standards['curve_bicubics']
  
    # Define the criteria to find the chiller properties
    # in the hvac standards data set.
    search_criteria = {}
    search_criteria['template'] = template
    cooling_type = self.condenserType
    search_criteria['cooling_type'] = cooling_type
    
    # TODO Standards replace this with a mechanism to store this
    # data in the chiller object itself.
    # For now, retrieve the condenser type from the name
    name = self.name.get
    condenser_type = nil
    compressor_type = nil
    if name.include?('AirCooled')
      if name.include?('WithCondenser')
        condenser_type = 'WithCondenser'
      elsif name.include?('WithoutCondenser')
        condenser_type = 'WithoutCondenser'
      end
    elsif name.include('WaterCooled')
      if name.include?('Reciprocating')
        compressor_type = 'Reciprocating'
      elsif name.include?('Rotary Screw')
        compressor_type = 'Rotary Screw'
      elsif  name.include?('Scroll')
        compressor_type = 'Scroll'
      end
    end
    unless condenser_type.nil?
      search_criteria['condenser_type'] = condenser_type
    end
    unless compressor_type.nil?
      search_criteria["compressor_type"] = compressor_type
    end
    
    # Get the chiller capacity
    capacity_w = nil
    if self.referenceCapacity.is_initialized
      capacity_w = self.referenceCapacity.get
    elsif self.autosizedReferenceCapacity.is_initialized
      capacity_w = self.autosizedReferenceCapacity.get
    else
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.hvac_standards.ChillerElectricEIR", "For #{self.name} capacity is not available, cannot apply efficiency standard.")
      successfully_set_all_properties = false
      return successfully_set_all_properties
    end
 
    # Convert capacity to tons
    capacity_tons = OpenStudio.convert(capacity_w, "W", "ton").get

    # Get the chiller minimum efficiency
    kw_per_ton = nil
    cop = nil
    chlr_props = find_object(chillers, search_criteria, capacity_tons)
    if chlr_props
      kw_per_ton = chlr_props["minimum_full_load_efficiency"]
      cop = kw_per_ton_to_cop(kw_per_ton)
    else
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.hvac_standards.ChillerElectricEIR", "For #{self.name}, cannot find minimum full load eff, will not be set.")
      successfully_set_all_properties = false
    end
    
    # Make the CAPFT curve
    cool_cap_ft = self.model.add_curve(chlr_props['capft'], hvac_standards)
    if cool_cap_ft
      self.setCoolingCapacityFunctionOfTemperature(cool_cap_ft)
    else
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.hvac_standards.ChillerElectricEIR", "For #{self.name}, cannot find cool_cap_ft curve, will not be set.")
      successfully_set_all_properties = false
    end    
    
    # Make the EIRFT curve
    cool_eir_ft = self.model.add_curve(chlr_props['eirft'], hvac_standards)
    if cool_eir_ft
      self.setElectricInputToCoolingOutputRatioFunctionOfTemperature(cool_eir_ft)  
    else
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.hvac_standards.ChillerElectricEIR", "For #{self.name}, cannot find cool_eir_ft curve, will not be set.")
      successfully_set_all_properties = false
    end    
    
    # Make the EIRFPLR curve
    # which may be either a CurveBicubic or a CurveQuadratic based on chiller type
    cool_plf_fplr = self.model.add_curve(chlr_props['eirfplr'], hvac_standards)
    if cool_plf_fplr
      self.setElectricInputToCoolingOutputRatioFunctionOfPLR(cool_plf_fplr)
    else
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.hvac_standards.ChillerElectricEIR", "For #{self.name}, cannot find cool_plf_fplr curve, will not be set.")
      successfully_set_all_properties = false
    end     

    # Set the efficiency value
    kw_per_ton = chlr_props['minimum_full_load_efficiency']
    cop = kw_per_ton_to_cop(kw_per_ton)
    self.setReferenceCOP(cop)

    # Append the name with size and kw/ton
    self.setName("#{name} #{capacity_tons.round}tons #{kw_per_ton.round(1)}kW/ton")
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.ChillerElectricEIR', "For #{template}: #{self.name}: #{cooling_type} #{condenser_type} #{compressor_type} Capacity = #{capacity_tons.round}tons; COP = #{cop.round(1)} (#{kw_per_ton.round(1)}kW/ton)")
    
    return successfully_set_all_properties

  end
  
end
