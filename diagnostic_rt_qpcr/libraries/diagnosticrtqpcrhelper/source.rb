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
needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRDebug'
needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRCompositions'

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
  include DiagnosticRTqPCRDebug
  include DiagnosticRTqPCRCompositions

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

  # Adds samples to to collections, provides instructions to tech
  #
  # @param compositions [Array<PCRCompostion>]
  # @param microtiter_plate [MicrotiterPlate]
  # @param column [int]
  def add_samples(compositions:, microtiter_plate:, column: nil)
    compositions.each do |composition|
      layout_group = microtiter_plate.next_empty_group(
        key: TEMPLATE_KEY,
        column: column
      )

      # inspect 'Skipping method single_channel_item_to_collection'
      single_channel_item_to_collection(
        to_collection: microtiter_plate.collection,
        source: composition.template.item,
        volume: composition.template.volume_hash,
        association_map: layout_group.map { |r, c| { to_loc: [r, c] } }
      )

      composition.template.added = true

      microtiter_plate.associate_provenance_group(
        group: layout_group,
        key: TEMPLATE_KEY,
        data: added_component_data(composition: composition)
      )
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

  ########## ITEM METHODS ##########

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

  ########## PROVENANCE METHODS ##########

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

  ################### Provision Plate Methods ################

  # Creates and assigns an output collection for each operation, and fills it
  #   with the output sample according to the provided PlateLayoutGenerator
  #   method
  # @note In debug mode, displays the matrix of each collection
  #
  # @param operations [OperationList]
  # @param object_type [String] the ObjectType of the collection to be made
  # @return [void]
  def provision_plates(operations:)
    operations.each do |op|
      collection = op.output(PLATE).make_collection
      get_and_label_new_plate(collection)

      set_parts(
        collection: collection,
        group_size: op.temporary[:options][:group_size],
        method: op.temporary[:options][:layout_method],
        sample: op.output(PLATE).sample
      )

      inspect op.output(PLATE).collection.matrix if debug
    end
  end

  # Fills a collection with the provided sample according to the provided
  #   PlateLayoutGenerator method
  #
  # @param collection [Collection]
  # @param group_size [Fixnum]
  # @param method [String] a PlateLayoutGenerator method
  # @param sample [Sample] the Sample to add to the collection
  # @return [void]
  def set_parts(collection:, group_size:, method:, sample:)
    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: group_size,
      method: method,
      dimensions: collection.dimensions
    )

    loop do
      index = layout_generator.next
      break unless index.present?

      collection.set(index[0], index[1], sample)
    end
  end

  ############# STRIPWELL METHODS ############
  
  # Adds a stripwell to a microtiter plate
  #
  # @param composition_group [Array<Compositions>] list of compositions that are
  #    all contained in the same stripwell
  # @param microtiter_plate [MicrotiterPlate]
  def add_stripwell(composition_group:, microtiter_plate:, stripwell:)
    layout_group = microtiter_plate.next_empty_group(key: PRIMER_PROBE_MIX_KEY)
    composition_group.zip(layout_group).each do |composition, lyt|
      data = added_component_data(composition: composition)
      microtiter_plate.associate_provenance(index: lyt,
                                            key: PRIMER_PROBE_MIX_KEY,
                                            data: data)
    end
    show_add_stripwell(layout_group: layout_group,
                       stripwell: stripwell,
                       collection: microtiter_plate.collection)
  end

  # Show instructions to place stripwell in rack
  # @param layout_group [Array<[r,c]>]
  # @param stripwell [Collection]
  # @param collection [Collection] the collection of the microtiter plate
  def show_add_stripwell(layout_group:, stripwell:, collection:)
    show_mark_stripwell(stripwell: stripwell)
    show do 
      title 'Add Stripwell to Stripwell Rack'
      note "Please place stripwell #{stripwell.id} in"\
        " stripwell rack #{collection.id} per table below"
      note 'Make sure column 1 of the stripwell lines up with column 1 of the rack'
      table highlight_collection_rc(collection, layout_group){ stripwell.id }
    end
  end

  # Directions to mark a stripwell correctly
  #
  # @param stripwell [Colleciton]
  def show_mark_stripwell(stripwell:)
    show do
      title 'Mark Stripwell'
      note 'Using a felt tip marker please mark'\
        " stripwell #{stripwell.id}"
      note "Mark one end <b>1</b> and the other <b>#{stripwell.dimensions[1]}"
      warning 'Do NOT mark the lids of the stripwell!'
    end
  end
end
