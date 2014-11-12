
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
  require_relative 'HeatExchangerAirToAirSensibleAndLatent'
  
  def applyPrototypeHVACAssumptions
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started applying prototype HVAC assumptions.")
    
    ##### Apply equipment efficiencies
    
    # Fans
    self.getFanConstantVolumes.sort.each {|obj| obj.setPrototypeFanPressureRise}
    self.getFanVariableVolumes.sort.each {|obj| obj.setPrototypeFanPressureRise}

    # Heat Exchangers
    self.getHeatExchangerAirToAirSensibleAndLatents.sort.each {|obj| obj.setPrototypeNominalElectricPower}
    
    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished applying prototype HVAC assumptions.")
    
  end 
  
end  