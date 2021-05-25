# frozen_string_literal: true

needs 'RNA Extraction Kits/TestRNAExtractionKit'
needs 'RNA Extraction Kits/QIAampDSPViralRNAMiniKit'
needs 'RNA Extraction Kits/QiagenRNeasyMiniKit'

# Module for enumerating supported RNA extraction kits
#
# @author Devin Strickland <strcklnd@uw.edu>
module SupportedRNAExtractionKits
  # Extend the module with the correct methods based on the kit name
  #
  # @param name [String] the name of the kit
  # @return [void]
  def set_kit(name:)
    case name
    when TestRNAExtractionKit::NAME
      extend TestRNAExtractionKit
    when QIAampDSPViralRNAMiniKit::NAME
      extend QIAampDSPViralRNAMiniKit
    when QiagenRNeasyMiniKit::NAME
      extend QiagenRNeasyMiniKit
    else
      raise ProtocolError, "Unrecognized RNA Extraction Kit: #{name}"
    end
  end
end
