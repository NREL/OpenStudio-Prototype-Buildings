
# open the class to add methods to apply HVAC efficiency standards
class OpenStudio::Model::Model

  # Load the helper libraries for getting the autosized
  # values for each type of model object.
  require_relative 'FanConstantVolume'
  require_relative 'FanVariableVolume'
  require_relative 'ChillerElectricEIR'
  require_relative 'CoilCoolingDXTwoSpeed'
  require_relative 'CoilCoolingDXSingleSpeed'
  
  def applyHVACEfficiencyStandard
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started applying HVAC efficiency standards.")
    
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
  
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished applying HVAC efficiency standards.")
  
  end 
  
end  