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

  # Diagnostic RT-qPCR
  include DataAssociationKeys

  WATER = 'Molecular Grade Water'
  WATER_OBJECT_TYPE = 'Reagent Aliquot'
  PLATE = 'PCR Plate'
  PLATE_OBJECT_TYPE = '96-well qPCR Plate'
  PRIMER_MIX = 'Primer/Probe Mix'
  MASTER_MIX_OBJECT_TYPE = 'qPCR Master Mix Stock'
  SPECIMEN = 'Specimen'

  RNA_FREE_WORKSPACE = 'reagent set-up room'

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

  # Instruct technician to do everything necessary to prepare the workspace
  #
  # @return [void]
  def show_prepare_workspace
    show do
      title 'Prepare workspace'

      note "All tasks in this protocol occur in the #{RNA_FREE_WORKSPACE}."
      note 'As you retrieve reagents, place them on ice or in a cold-block.'
    end
  end

  ########## COMPOSITION METHODS ##########

  # Finds a master mix Item in inventory
  #
  # @param sample [Sample] of qPCR Master Mix
  # @return [Item]
  def master_mix_item(sample:)
    get_item(
      sample: sample,
      object_type_name: MASTER_MIX_OBJECT_TYPE
    )
  end

  # Finds a water Item in inventory
  #
  # @return [Item]
  def water_item
    get_item(
      sample: Sample.find_by_name(WATER),
      object_type_name: WATER_OBJECT_TYPE
    )
  end

  # Finds a water Item in inventory for no template control
  #
  # @return [Item]
  def no_template_control_item
    water_item
  end

  # Finds an Item in inventory for the given `Sample` and `ObjectType`
  # @todo replace with a back-end method such as `Sample.in`
  #
  # @param sample [Sample]
  # @param object_type_name [String]
  # @return [Item]
  def get_item(sample:, object_type_name:)
    Item.with_sample(sample: sample)
        .where(object_type: ObjectType.find_by_name(object_type_name))
        .reject(&:deleted?)
        .first
  end

  # Retrieve `Item`s required for the protocol based on what's in
  #   the compositions that are attached to the operations
  #
  # @param operations [OperationList]
  # @return [void]
  def retrieve_by_compositions(operations:)
    compositions = operations.map { |op| op.temporary[:compositions] }.flatten
    items = compositions.map(&:items).flatten.compact.uniq
    items = items.sort_by(&:object_type_id)
    take(items, interactive: true)
  end

  # Build the data structure that documents the provenance of a
  #   master mix
  #
  # @param primer_mix [Item]
  # @param composition [PCRComposition]
  # @return [Hash] a data structure that documents the provenance of a
  #   master mix
  def added_component_data(composition:)
    composition.added_components.map { |component| serialize(component) }
  end

  # Reduce a `ReactionComponent` (part of a `PCRComposition`) to a simplified
  #   serialized representation that is compatible with `PartProvenance`
  #
  # @param component [ReactionComponent]
  # @return [Hash]
  def serialize(component)
    {
      name: component.input_name,
      id: component.item.id,
      volume: component.volume_hash
    }
  end

  # Add provenance metadata to a stock item and aliquots made from that stock
  #
  # @param stock_item [Item] the source item for the aliquot operation
  # @param aliquot_items [Array<Item>] the aliqouts made in the operation
  # @return [void]
  def add_aliquot_provenance(stock_item:, aliquot_items:)
    from_map = AssociationMap.new(stock_item)
    to_maps = aliquot_items.map { |a| [a, AssociationMap.new(a)] }

    to_maps.each do |aliquot_item, to_map|
      add_provenance(
        from: stock_item, from_map: from_map,
        to: aliquot_item, to_map: to_map
      )
      from_map.save
      to_map.save
    end
  end

  def add_one_to_one_provenance(from_item:, to_item:)
    from_map = AssociationMap.new(from_item)
    to_map = AssociationMap.new(to_item)

    add_provenance(
      from: from_item, from_map: from_map,
      to: to_item, to_map: to_map
    )
    from_map.save
    to_map.save
  end
end
