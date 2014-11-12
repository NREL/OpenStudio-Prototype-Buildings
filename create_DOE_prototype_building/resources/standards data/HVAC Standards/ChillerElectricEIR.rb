
# open the class to add methods to return sizing values
class OpenStudio::Model::ChillerElectricEIR

  def setStandardEfficiencyAndCurves(template, hvac_standards)
  
    chillers = hvac_standards["chillers"]
    curve_biquadratics = hvac_standards["curve_biquadratics"]
    curve_quadratics = hvac_standards["curve_quadratics"]
    curve_bicubics = hvac_standards["curve_bicubics"]
  
    # Define the criteria to find the chiller properties
    # in the hvac standards data set.
    search_criteria = {}
    search_criteria["template"] = template
    cooling_type = self.condenserType
    search_criteria["cooling_type"] = cooling_type
    
    # TODO Standards replace this with a mechanism to store this
    # data in the chiller object itself.
    # For now, retrieve the condenser type from the name
    name = self.name.get
    condenser_type = nil
    compressor_type = nil
    if name.include?("AirCooled")
      if name.include?("WithCondenser")
        condenser_type = "WithCondenser"
      elsif name.include?("WithoutCondenser")
        condenser_type = "WithoutCondenser"
      end
    elsif name.include("WaterCooled")
      if name.include?("Reciprocating")
        compressor_type = "Reciprocating"
      elsif name.include?("Rotary Screw")
        compressor_type = "Rotary Screw"
      elsif  name.include?("Scroll")
        compressor_type = "Scroll"
      end
    end
    unless condenser_type.nil?
      search_criteria["condenser_type"] = condenser_type
    end
    unless compressor_type.nil?
      search_criteria["compressor_type"] = compressor_type
    end    
    
    # Get the chiller capacity
    return false if self.referenceCapacity.empty?
    capacity_w = self.referenceCapacity.get
    capacity_tons = OpenStudio.convert(capacity_w, "W", "ton").get

    chlr_props = find_object(chillers, search_criteria, capacity_tons)
    return false if chlr_props.nil?

    # Make the CAPFT curve
    capft_properties = find_object(curve_biquadratics, {"name"=>chlr_props["capft"]})
    return false if capft_properties.nil?
    ccFofT = self.coolingCapacityFunctionOfTemperature
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
    eirft_properties = find_object(curve_biquadratics, {"name"=>chlr_props["eirft"]})
    return false if eirft_properties.nil?
    eirToCorfOfT = self.electricInputToCoolingOutputRatioFunctionOfTemperature
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
    eirfplr_properties = find_object(curve_quadratics, {"name"=>chlr_props["eirfplr"]})
    if eirfplr_properties
      eirToCorfOfPlr = OpenStudio::Model::CurveQuadratic.new(self.model)
      eirToCorfOfPlr.setName(eirfplr_properties["name"])
      eirToCorfOfPlr.setCoefficient1Constant(eirfplr_properties["coeff_1"])
      eirToCorfOfPlr.setCoefficient2x(eirfplr_properties["coeff_2"])
      eirToCorfOfPlr.setCoefficient3xPOW2(eirfplr_properties["coeff_3"])
      eirToCorfOfPlr.setMinimumValueofx(eirfplr_properties["min_x"])
      eirToCorfOfPlr.setMaximumValueofx(eirfplr_properties["max_x"])
    end
    
    eirfplr_properties = find_object(curve_bicubics, {"name"=>chlr_props["eirfplr"]})
    if eirfplr_properties
      eirToCorfOfPlr = OpenStudio::Model::CurveBicubic.new(self.model)
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

    # Set the efficiency value
    cop = chlr_props["minimum_cop"]
    self.setReferenceCOP(cop)
    
    # Set the performance curves
    self.setCoolingCapacityFunctionOfTemperature(ccFofT)
    self.setElectricInputToCoolingOutputRatioFunctionOfTemperature(eirToCorfOfT)
    self.setElectricInputToCoolingOutputRatioFunctionOfPLR(eirToCorfOfPlr)
    
    # Append the name with size and kw/ton
    kw_per_ton = cop_to_kw_per_ton(cop)
    chiller.setName("#{name} #{capacity_tons.round}tons #{kw_per_ton.round(1)}kW/ton")
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.ChillerElectricEIR", "For #{template}: #{self.name}: #{cooling_type} #{condenser_type} #{compressor_type} Capacity = #{capacity_tons.round}tons; COP = #{cop} (#{kw_per_ton.round(1)}kW/ton)")
    
    return true

  end
  
end
