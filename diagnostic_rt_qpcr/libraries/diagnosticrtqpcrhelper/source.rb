# typed: false
# frozen_string_literal: true

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/CommonInputOutputNames'
needs 'Standard Libs/Debug'
needs 'Standard Libs/Pipettors'
needs 'Standard Libs/LabwareNames'
needs 'Collection Management/CollectionActions'
needs 'Collection Management/CollectionDisplay'
needs 'Collection Management/CollectionTransfer'
needs 'Diagnostic RT-qPCR/DataAssociationKeys'

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
  include CollectionTransfer

  #Diagnostic RT-qPCR
  include DataAssociationKeys

  WATER = 'Molecular Grade Water'
  RNA_FREE_WORKSPACE = 'reagent set-up room'
  PLATE = 'PCR Plate'
  PRIMER_MIX = 'Primer/Probe Mix'
  TEMPLATE = 'Template'

  def rnase_warning
    show do
      title 'RNase degrades RNA'
      note 'RNA is prone to degradation by RNase present in our eyes, skin, and breath.'
      note 'Avoid opening tubes outside the Biosafety Cabinet (BSC).'
      bullet 'Change gloves whenever you suspect potential RNAse contamination'
    end
  end

  def safety_warning
    show do
      title 'Review Safety Warnings'
      note '<b>Always</b> pay attention to orange warning blocks throughout the protocol.'
      warning '<b>INFECTIOUS MATERIALS</b>'
      note 'You will be working with infectious materials.'
      note 'Do <b>ALL</b> work in a biosafety cabinet (BSC).'
      note '<b>PPE is required</b>'
      check 'Put on lab coat.'
      check 'Put on 2 layers of gloves.'
      bullet 'Make sure to use tight gloves. Tight gloves reduce the chance of the gloves getting caught on the tubes when closing their lids.'
      bullet 'Change outer layer of gloves after handling infectious sample and before touching surfaces outside of the BSC (such as a refrigerator door handle).'
    end
  end

  # TODO: Think about how to switch this to row-wise addition.
  # Adds samples to to collections, provides instructions to tech
  #
  # @param operation_inputs [Array<items>]
  # @param collection [Collection]
  # @param layout_generator [LayoutGenerator]
  # @param volume [{aty: int, unit: string}]
  # @param column [int]
  def add_samples(operation_inputs:, microtiter_plate:,
                  volume:, column: nil)
    operation_inputs.each do |fv|
      item = fv.item
      layout_group = microtiter_plate.associate_next_empty_group(
        key: TEMPLATE_KEY,
        data: { item: item.id, volume: volume },
        column: column
      )

      association_map = []
      layout_group.each { |r, c| association_map.push({ to_loc: [r, c] }) }
      single_channel_item_to_collection(to_collection: microtiter_plate.collection,
                                        source: item,
                                        volume: volume,
                                        association_map: association_map)
    end
  end

end
