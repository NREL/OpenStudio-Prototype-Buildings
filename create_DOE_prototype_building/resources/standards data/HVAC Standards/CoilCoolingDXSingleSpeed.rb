
# open the class to add methods to return sizing values
class OpenStudio::Model::CoilCoolingDXSingleSpeed


  def setStandardEfficiencyAndCurves(template, hvac_standards)
  
    unitary_acs = hvac_standards["unitary_acs"]
    #curve_biquadratics = hvac_standards["curve_biquadratics"]
    #curve_quadratics = hvac_standards["curve_quadratics"]
    #curve_bicubics = hvac_standards["curve_bicubics"]
  
    # Define the criteria to find the chiller properties
    # in the hvac standards data set.
    search_criteria = {}
    search_criteria["template"] = template
    cooling_type = self.condenserType
    search_criteria["cooling_type"] = cooling_type
    
    # Determine the heating type
    # TODO deal with zone hvac and unitary equipment
    return false if self.airLoopHVAC.empty?
    air_loop = self.airLoopHVAC.get
    heating_type = nil
    if air_loop.supplyComponents("Coil:Heating:Electric".to_IddObjectType).size > 0
      heating_type = "Electric Resistance or None"
    elsif air_loop.supplyComponents("Coil:Heating:Gas".to_IddObjectType).size > 0
      heating_type = "All Other"
    elsif air_loop.supplyComponents("Coil:Heating:Water".to_IddObjectType).size > 0
      heating_type = "All Other"
    elsif air_loop.supplyComponents("Coil:Heating:DX:SingleSpeed".to_IddObjectType).size > 0
      heating_type = "All Other"
    elsif air_loop.supplyComponents("Coil:Heating:Gas:MultiStage".to_IddObjectType).size > 0
      heating_type = "All Other"
    elsif air_loop.supplyComponents("Coil:Heating:Desuperheater".to_IddObjectType).size > 0
      heating_type = "All Other"
    elsif air_loop.supplyComponents("Coil:Heating:WaterToAirHeatPump:EquationFit".to_IddObjectType).size > 0
      heating_type = "All Other"  
    else
      heating_type = "Electric Resistance or None"
    end
    unless heating_type.nil?
      search_criteria["heating_type"] = heating_type
    end
    
    # TODO Standards - add split system vs single package to model
    # For now, assume single package
    subcategory = "Single Package"
    search_criteria["subcategory"] = subcategory

    # Get the coil capacity and convert to Btu/hr
    return false if self.ratedTotalCoolingCapacity.empty?
    capacity_w = self.ratedTotalCoolingCapacity.get
    capacity_btu_per_hr = OpenStudio.convert(capacity_w, "W", "Btu/hr").get
    capacity_kbtu_per_hr = OpenStudio.convert(capacity_w, "W", "kBtu/hr").get
    
    
    ac_props = find_objects(unitary_acs, search_criteria, capacity_btu_per_hr)
    return false if ac_props.nil?
=begin
    # Make the CAPFT curve
    capft_properties = find_objects(curve_biquadratics, {"name"=>ac_props["capft"]})
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
    eirft_properties = find_objects(curve_biquadratics, {"name"=>ac_props["eirft"]})
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
    eirfplr_properties = find_objects(curve_quadratics, {"name"=>ac_props["eirfplr"]})
    if eirfplr_properties
      eirToCorfOfPlr = OpenStudio::Model::CurveQuadratic.new(self.model)
      eirToCorfOfPlr.setName(eirfplr_properties["name"])
      eirToCorfOfPlr.setCoefficient1Constant(eirfplr_properties["coeff_1"])
      eirToCorfOfPlr.setCoefficient2x(eirfplr_properties["coeff_2"])
      eirToCorfOfPlr.setCoefficient3xPOW2(eirfplr_properties["coeff_3"])
      eirToCorfOfPlr.setMinimumValueofx(eirfplr_properties["min_x"])
      eirToCorfOfPlr.setMaximumValueofx(eirfplr_properties["max_x"])
    end
    
    eirfplr_properties = find_objects(curve_bicubics, {"name"=>ac_props["eirfplr"]})
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
=end

    # Get the minimum efficiency standards
    cop = nil
    
    # If specified as SEER
    unless ac_props["minimum_seer"].nil?
      min_seer = ac_props["minimum_seer"]
      cop = seer_to_cop(min_seer)
      self.setName("#{self.name} #{capacity_kbtu_per_hr.round}kBtu/hr #{min_seer}SEER")
      puts "For #{template}: #{self.name}: #{cooling_type} #{heating_type} #{subcategory} Capacity = #{capacity_kbtu_per_hr.round}kBtu/hr; SEER = #{min_seer}"     
    end
    
    # If specified as EER
    unless ac_props["minimum_eer"].nil?
      min_eer = ac_props["minimum_eer"]
      cop = eer_to_cop(min_eer)
      self.setName("#{self.name} #{capacity_kbtu_per_hr.round}kBtu/hr #{min_eer}EER")
      puts "For #{template}: #{self.name}: #{cooling_type} #{heating_type} #{subcategory} Capacity = #{capacity_kbtu_per_hr.round}kBtu/hr; EER = #{min_eer}"
    end

    # Set the efficiency values
    self.setRatedCOP(OpenStudio::OptionalDouble.new(cop))
  
    # Set the performance curves
    #self.setCoolingCapacityFunctionOfTemperature(ccFofT)
    #self.setElectricInputToCoolingOutputRatioFunctionOfTemperature(eirToCorfOfT)
    #self.setElectricInputToCoolingOutputRatioFunctionOfPLR(eirToCorfOfPlr)
    
    
    
    return true

  end

end
