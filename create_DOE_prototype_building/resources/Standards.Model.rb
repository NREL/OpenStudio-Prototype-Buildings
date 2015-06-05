
# open the class to add methods to apply HVAC efficiency standards
class OpenStudio::Model::Model

  # Load the helper libraries for getting the autosized
  # values for each type of model object.
  require_relative 'Standards.FanConstantVolume'
  require_relative 'Standards.FanVariableVolume'
  require_relative 'Standards.FanOnOff'
  require_relative 'Standards.ChillerElectricEIR'
  require_relative 'Standards.CoilCoolingDXTwoSpeed'
  require_relative 'Standards.CoilCoolingDXSingleSpeed'
  require_relative 'Standards.BoilerHotWater'
  require_relative 'Standards.AirLoopHVAC'
  require_relative 'Standards.WaterHeaterMixed'
  require_relative 'Standards.Space'
  require_relative 'Standards.Construction'
  
  def applyHVACEfficiencyStandard
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started applying HVAC efficiency standards.')
    
    ##### Apply equipment efficiencies
    
    # Fans
    self.getFanVariableVolumes.sort.each {|obj| obj.setStandardEfficiency(self.template, self.hvac_standards)}
    self.getFanConstantVolumes.sort.each {|obj| obj.setStandardEfficiency(self.template, self.hvac_standards)}
    self.getFanOnOffs.sort.each {|obj| obj.setStandardEfficiency(self.template, self.hvac_standards)}
  
    # Unitary ACs
    self.getCoilCoolingDXTwoSpeeds.sort.each {|obj| obj.setStandardEfficiencyAndCurves(self.template, self.hvac_standards)}
    self.getCoilCoolingDXSingleSpeeds.sort.each {|obj| obj.setStandardEfficiencyAndCurves(self.template, self.hvac_standards)}
    
    # Unitary HPs
  
    # Chillers
    self.getChillerElectricEIRs.sort.each {|obj| obj.setStandardEfficiencyAndCurves(self.template, self.hvac_standards)}
  
    # Boilers
    self.getBoilerHotWaters.sort.each {|obj| obj.setStandardEfficiencyAndCurves(self.template, self.hvac_standards)}
  
    # Water Heaters
    self.getWaterHeaterMixeds.sort.each {|obj| obj.setStandardEfficiency(self.template, self.hvac_standards)}
  
    # Economizers
    self.getAirLoopHVACs.sort.each {|obj| obj.setEconomizerLimits(self.template, self.climate_zone)}
    self.getAirLoopHVACs.sort.each {|obj| obj.setEconomizerIntegration(self.template, self.climate_zone)}
  
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished applying HVAC efficiency standards.')
  
  end
  
  def addDaylightingControls
    
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started adding daylighting controls.')
    
    # Add daylighting controls to each space
    self.getSpaces.sort.each do |space|
      added = space.addDaylightingControls(self.template, false, false)
    end
  
    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished adding daylighting controls.')
  
  end
  
end
