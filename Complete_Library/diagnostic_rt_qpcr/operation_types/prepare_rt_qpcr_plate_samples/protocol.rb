needs 'Diagnostic RT-qPCR/PreparePCRPlate_Lib'
class Protocol
    include PreparePCRPlate_Lib
  def main
      run_protocol(operations: operations) 
      
      {}
  end
end