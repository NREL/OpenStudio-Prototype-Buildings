
# open the class to add methods to return sizing values
class OpenStudio::Model::CoilCoolingDXSingleSpeed


  def setStandardEfficiencyAndCurves(template, hvac_standards)
  
    unitary_acs = hvac_standards['unitary_acs']
    curve_biquadratics = hvac_standards['curve_biquadratics']
    curve_quadratics = hvac_standards['curve_quadratics']
    curve_bicubics = hvac_standards['curve_bicubics']
    curve_cubics = hvac_standards['curve_cubics']
  
    # Define the criteria to find the chiller properties
    # in the hvac standards data set.
    search_criteria = {}
    search_criteria['template'] = template
    cooling_type = self.condenserType
    search_criteria['cooling_type'] = cooling_type
    
    # Determine the heating type
    # TODO deal with zone hvac and unitary equipment
    return false if self.airLoopHVAC.empty?
    air_loop = self.airLoopHVAC.get
    heating_type = nil
    if air_loop.supplyComponents('Coil:Heating:Electric'.to_IddObjectType).size > 0
      heating_type = 'Electric Resistance or None'
    elsif air_loop.supplyComponents('Coil:Heating:Gas'.to_IddObjectType).size > 0
      heating_type = 'All Other'
    elsif air_loop.supplyComponents('Coil:Heating:Water'.to_IddObjectType).size > 0
      heating_type = 'All Other'
    elsif air_loop.supplyComponents('Coil:Heating:DX:SingleSpeed'.to_IddObjectType).size > 0
      heating_type = 'All Other'
    elsif air_loop.supplyComponents('Coil:Heating:Gas:MultiStage'.to_IddObjectType).size > 0
      heating_type = 'All Other'
    elsif air_loop.supplyComponents('Coil:Heating:Desuperheater'.to_IddObjectType).size > 0
      heating_type = 'All Other'
    elsif air_loop.supplyComponents('Coil:Heating:WaterToAirHeatPump:EquationFit'.to_IddObjectType).size > 0
      heating_type = 'All Other'
    else
      heating_type = 'Electric Resistance or None'
    end
    unless heating_type.nil?
      search_criteria['heating_type'] = heating_type
    end
    
    # TODO Standards - add split system vs single package to model
    # For now, assume single package
    subcategory = 'Single Package'
    search_criteria['subcategory'] = subcategory

    # Get the coil capacity and convert to Btu/hr
    return false if self.ratedTotalCoolingCapacity.empty?
    capacity_w = self.ratedTotalCoolingCapacity.get
    capacity_btu_per_hr = OpenStudio.convert(capacity_w, 'W', 'Btu/hr').get
    capacity_kbtu_per_hr = OpenStudio.convert(capacity_w, 'W', 'kBtu/hr').get
    
    ac_props = find_object(unitary_acs, search_criteria, capacity_btu_per_hr)
    return false if ac_props.nil?

    # Make the COOL-CAP-FT curve
    cool_cap_ft_data = find_object(curve_biquadratics, {'name'=>ac_props['cool_cap_ft']})
    return false if cool_cap_ft_data.nil?
    cool_cap_ft = OpenStudio::Model::CurveBiquadratic.new(self.model)
    self.setTotalCoolingCapacityFunctionOfTemperatureCurve(cool_cap_ft)
    cool_cap_ft.setName(cool_cap_ft_data['name'])
    cool_cap_ft.setCoefficient1Constant(cool_cap_ft_data['coeff_1'])
    cool_cap_ft.setCoefficient2x(cool_cap_ft_data['coeff_2'])
    cool_cap_ft.setCoefficient3xPOW2(cool_cap_ft_data['coeff_3'])
    cool_cap_ft.setCoefficient4y(cool_cap_ft_data['coeff_4'])
    cool_cap_ft.setCoefficient5yPOW2(cool_cap_ft_data['coeff_5'])
    cool_cap_ft.setCoefficient6xTIMESY(cool_cap_ft_data['coeff_6'])
    cool_cap_ft.setMinimumValueofx(cool_cap_ft_data['min_x'])
    cool_cap_ft.setMaximumValueofx(cool_cap_ft_data['max_x'])
    cool_cap_ft.setMinimumValueofy(cool_cap_ft_data['min_y'])
    cool_cap_ft.setMaximumValueofy(cool_cap_ft_data['max_y'])

    # Make the COOL-CAP-FFLOW curve
    cool_cap_fflow_data = find_object(curve_cubics, {'name'=>ac_props['cool_cap_fflow']})
    return false if cool_cap_fflow_data.nil?
    cool_cap_fflow = OpenStudio::Model::CurveCubic.new(self.model)
    self.setTotalCoolingCapacityFunctionOfFlowFractionCurve(cool_cap_fflow)
    cool_cap_fflow.setName(cool_cap_fflow_data['name'])
    cool_cap_fflow.setCoefficient1Constant(cool_cap_fflow_data['coeff_1'])
    cool_cap_fflow.setCoefficient2x(cool_cap_fflow_data['coeff_2'])
    cool_cap_fflow.setCoefficient3xPOW2(cool_cap_fflow_data['coeff_3'])
    cool_cap_fflow.setCoefficient4xPOW3(cool_cap_fflow_data['coeff_4'])
    cool_cap_fflow.setMinimumValueofx(cool_cap_fflow_data['min_x'])
    cool_cap_fflow.setMaximumValueofx(cool_cap_fflow_data['max_x'])
    
    # Make the COOL-EIR-FT curve
    cool_eir_ft_data = find_object(curve_biquadratics, {'name'=>ac_props['cool_eir_ft']})
    return false if cool_eir_ft_data.nil?
    cool_eir_ft = OpenStudio::Model::CurveBiquadratic.new(self.model)
    self.setEnergyInputRatioFunctionOfTemperatureCurve(cool_eir_ft)
    cool_eir_ft.setName(cool_eir_ft_data['name'])
    cool_eir_ft.setCoefficient1Constant(cool_eir_ft_data['coeff_1'])
    cool_eir_ft.setCoefficient2x(cool_eir_ft_data['coeff_2'])
    cool_eir_ft.setCoefficient3xPOW2(cool_eir_ft_data['coeff_3'])
    cool_eir_ft.setCoefficient4y(cool_eir_ft_data['coeff_4'])
    cool_eir_ft.setCoefficient5yPOW2(cool_eir_ft_data['coeff_5'])
    cool_eir_ft.setCoefficient6xTIMESY(cool_eir_ft_data['coeff_6'])
    cool_eir_ft.setMinimumValueofx(cool_eir_ft_data['min_x'])
    cool_eir_ft.setMaximumValueofx(cool_eir_ft_data['max_x'])
    cool_eir_ft.setMinimumValueofy(cool_eir_ft_data['min_y'])
    cool_eir_ft.setMaximumValueofy(cool_eir_ft_data['max_y'])
    
    # Make the COOL-EIR-FFLOW curve
    cool_eir_fflow_data = find_object(curve_cubics, {'name'=>ac_props['cool_eir_fflow']})
    return false if cool_eir_fflow_data.nil?
    cool_eir_fflow = OpenStudio::Model::CurveCubic.new(self.model)
    self.setEnergyInputRatioFunctionOfFlowFractionCurve(cool_eir_fflow)
    cool_eir_fflow.setName(cool_eir_fflow_data['name'])
    cool_eir_fflow.setCoefficient1Constant(cool_eir_fflow_data['coeff_1'])
    cool_eir_fflow.setCoefficient2x(cool_eir_fflow_data['coeff_2'])
    cool_eir_fflow.setCoefficient3xPOW2(cool_eir_fflow_data['coeff_3'])
    cool_eir_fflow.setCoefficient4xPOW3(cool_eir_fflow_data['coeff_4'])
    cool_eir_fflow.setMinimumValueofx(cool_eir_fflow_data['min_x'])
    cool_eir_fflow.setMaximumValueofx(cool_eir_fflow_data['max_x'])
    
    # Make the COOL-PLF-FPLR curve
    cool_plf_fplr_data = find_object(curve_quadratics, {'name'=>ac_props['cool_plf_fplr']})
    return false if cool_plf_fplr_data.nil?
    cool_plf_fplr = OpenStudio::Model::CurveQuadratic.new(self.model)
    self.setPartLoadFractionCorrelationCurve(cool_plf_fplr)
    cool_plf_fplr.setName(cool_plf_fplr_data['name'])
    cool_plf_fplr.setCoefficient1Constant(cool_plf_fplr_data['coeff_1'])
    cool_plf_fplr.setCoefficient2x(cool_plf_fplr_data['coeff_2'])
    cool_plf_fplr.setCoefficient3xPOW2(cool_plf_fplr_data['coeff_3'])
    cool_plf_fplr.setMinimumValueofx(cool_plf_fplr_data['min_x'])
    cool_plf_fplr.setMaximumValueofx(cool_plf_fplr_data['max_x'])
    
    # Get the minimum efficiency standards
    cop = nil
    
    # If specified as SEER
    unless ac_props['minimum_seer'].nil?
      min_seer = ac_props['minimum_seer']
      cop = seer_to_cop(min_seer)
      self.setName("#{self.name} #{capacity_kbtu_per_hr.round}kBtu/hr #{min_seer}SEER")
      OpenStudio::logFree(OpenStudio::Info, 'openstudio.hvac_standards.CoilCoolingDXSingleSpeed',  "For #{template}: #{self.name}: #{cooling_type} #{heating_type} #{subcategory} Capacity = #{capacity_kbtu_per_hr.round}kBtu/hr; SEER = #{min_seer}")
    end
    
    # If specified as EER
    unless ac_props['minimum_eer'].nil?
      min_eer = ac_props['minimum_eer']
      cop = eer_to_cop(min_eer)
      self.setName("#{self.name} #{capacity_kbtu_per_hr.round}kBtu/hr #{min_eer}EER")
      OpenStudio::logFree(OpenStudio::Info, 'openstudio.hvac_standards.CoilCoolingDXSingleSpeed', "For #{template}: #{self.name}: #{cooling_type} #{heating_type} #{subcategory} Capacity = #{capacity_kbtu_per_hr.round}kBtu/hr; EER = #{min_eer}")
    end

    # Set the efficiency values
    self.setRatedCOP(OpenStudio::OptionalDouble.new(cop))
    
    return true

  end

end
