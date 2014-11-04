
# open the class to add methods to size all HVAC equipment
class OpenStudio::Model::Model

  # Let the model store and access its own template and hvac_standards
  attr_accessor :template
  attr_accessor :hvac_standards
  attr_accessor :runner

  # Load the helper libraries for getting the autosized
  # values for each type of model object.
  require_relative 'FanConstantVolume'
  require_relative 'FanVariableVolume'
  require_relative 'ChillerElectricEIR'
  require_relative 'CoilCoolingDXTwoSpeed'
  require_relative 'CoilCoolingDXSingleSpeed'
  
  def applyHVACEfficiencyStandard
    
    ##### Apply equipment efficiencies
    
    # Fans
    self.getFanVariableVolumes.sort.each {|obj| obj.setStandardEfficiency(self.template, self.hvac_standards)}
    self.getFanConstantVolumes.sort.each {|obj| obj.setStandardEfficiency(self.template, self.hvac_standards)}
  
    # Unitary ACs
    self.getCoilCoolingDXTwoSpeeds.sort.each {|obj| obj.setStandardEfficiencyAndCurves(self.template, self.hvac_standards)}
    self.getCoilCoolingDXSingleSpeeds.sort.each {|obj| obj.setStandardEfficiencyAndCurves(self.template, self.hvac_standards)}
    
    # Unitary HPs
  
    # Chillers
    self.getChillerElectricEIRs.sort.each {|obj| obj.setStandardEfficiencyAndCurves(self.template, self.hvac_standards)}
  
  
  
  end 
  
end  