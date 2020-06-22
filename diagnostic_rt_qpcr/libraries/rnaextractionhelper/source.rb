# typed: false
# frozen_string_literal: true

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Units'
needs 'Standard Libs/Debug'
needs 'RNA Extraction Kits/RNAExtractionKits'

# Module for elements that are common to RNA Extraction Protocols
#
# @author Devin Strickland <strcklnd@uw.edu>
module RNAExtractionHelper
  include PlanParams
  include Units
  include Debug
  include RNAExtractionKits

  def sample_volume(operation)
    operation.temporary[:options][:sample_volume]
  end
end
