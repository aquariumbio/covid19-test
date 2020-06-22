# typed: false
# frozen_string_literal: true

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/CommonInputOutputNames'
needs 'Standard Libs/Debug'
needs 'Standard Libs/Pipettors'
needs 'Standard Libs/LabwareNames'
needs 'Collection Management/CollectionActions'
needs 'Collection Management/CollectionDisplay'
# needs 'Collection Management/CollectionTransfer'
# needs 'Collection Management/CollectionLocation'
# needs 'Collection Management/CollectionData'
needs 'Microtiter Plates/PlateLayoutGenerator'

# Module for elements that are common throughout Diagnostic RT qPCR
#
# @author Devin Strickland <strcklnd@uw.edu>
module DiagnosticRTqPCRHelper
  # Standard Libs
  include Units
  include PlanParams
  include CommonInputOutputNames
  include Debug
  include Pipettors
  include LabwareNames

  # Collection Management
  include CollectionActions
  include CollectionDisplay
  # include CollectionTransfer
  # include CollectionLocation
  # include CollectionData

  WATER = 'Molecular Grade Water'
  RNA_FREE_WORKSPACE = 'reagent set-up room'
  PLATE = 'PCR Plate'
  PRIMER_MIX = 'Primer/Probe Mix'
end
