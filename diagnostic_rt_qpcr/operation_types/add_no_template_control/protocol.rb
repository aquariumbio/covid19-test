# typed: false
# frozen_string_literal: true

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/CommonInputOutputNames'
needs 'Standard Libs/Debug'
needs 'Standard Libs/Pipettors'
needs 'Standard Libs/LabwareNames'
needs 'Collection Management/CollectionActions'
needs 'Collection Management/CollectionDisplay'
needs 'Microtiter Plates/PlateLayoutGenerator'
needs 'PCR Libs/PCRComposition'
needs 'Diagnostic RT-qPCR/DataAssociationKeys'
needs 'Microtiter Plates/MicrotiterPlates'

# Protocol for setting up a master mix plate for RT-qPCR
# @note Instructions adapted from the CDC COVID-19 detection protocol
#   https://www.fda.gov/media/134922/download
#
# 12) Prior to moving to the nucleic acid handling area, prepare the
#   No Template Control (NTC) reactions for column #1 in the
#   assay preparation area.
#
# 13) Pipette 5 uL of nuclease-free water into the NTC sample wells
#   (Figure 2, column 1). Securely cap NTC wells before proceeding.
#
# 14) Cover the entire reaction plate and move the reaction plate to
#   the specimen nucleic acid handling area.
#
# @author Devin Strickland <strcklnd@uw.edu>
class Protocol
  # Standard Libs
  include PlanParams
  include CommonInputOutputNames
  include Debug
  include Pipettors
  include LabwareNames

  # Collection Management
  include CollectionActions
  include CollectionDisplay

  # Diagnostic RT-qPCR
  include DataAssociationKeys

  WATER = 'Molecular Grade Water'
  RNA_FREE_WORKSPACE = 'reagent set-up room'
  PLATE = 'PCR Plate'

  ########## DEFAULT PARAMS ##########

  # Default parameters that are applied equally to all operations.
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_job_params
    {}
  end

  # Default parameters that are applied to individual operations.
  #   Can be overridden by:
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_operation_params
    {
      program_name: 'CDC_TaqPath_CG',
      group_size: 3,
      layout_method: 'cdc_sample_layout'
    }
  end

  ########## MAIN ##########

  def main
    setup_test_plates(operations: operations) if debug

    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )
    return {} if operations.errored.any?

    operations.retrieve

    operations.each do |op|
      op.pass(PLATE)
      add_no_template_controls(operation: op)
    end

    operations.store

    {}
  end

  # Add the no template controls to an Operation's putput collection
  #
  # @param operation [Operation]
  # @return [void]
  def add_no_template_controls(operation:)
    # Group_Size and Program name are attributes of the plate
    # and should be associated to the plate from Prepare Master Mix
    # This may not work because group size is different depending on whether
    #   talking about samples or primers
    # group_size = op.input(PLATE).collection.get(GROUP_SIZE_KEY)
    # program_name = op.input(PLATE).collection.get(COMPOSITION_NAME_KEY)

    collection = operation.output(PLATE).collection

    layout_group = add_ntc_data(
      collection: collection,
      group_size: operation.temporary[:options][:group_size],
      method: operation.temporary[:options][:layout_method]
    )

    composition = PCRCompositionFactory.build(
      program_name: operation.temporary[:options][:program_name]
    )

    show_add_ntc(
      collection: collection,
      volume: composition.water.qty_display,
      layout_group: layout_group
    )

    show_result(collection: collection) if debug
    inspect_data_associations(collection: collection) if debug
  end

  # Add metadata for a group of no template control samples, and return the
  #   locations of the group
  #
  # @param collection [Collection]
  # @param group_size [Fixnum]
  # @param method [String]
  # @return [Array<Array<Fixnum>>]
  def add_ntc_data(collection:, group_size:, method:)
    microtiter_plate = MicrotiterPlateFactory.build(
      collection: collection,
      group_size: group_size,
      method: method
    )

    # TODO: Do we want to have an item number for the water?
    microtiter_plate.associate_next_empty_group(
      key: TEMPLATE_KEY,
      data: WATER
    )
  end

  # Instruct technician to add the no template control samples to the plate
  #
  # @param collection [Collection]
  # @param volume [Fixnum]
  # @param layout_group [Array<Array<Fixnum>>]
  # @return [void]
  def show_add_ntc(collection:, volume:, layout_group:)
    show do
      title "Pipet No Template Control (NTC) samples into plate #{collection}"

      note "Pipet #{volume} of #{WATER} into the indicated wells of" \
        " plate #{collection}"
      table highlight_collection_rc(collection, layout_group, check: true)
    end
  end

  ########## DEBUG METHODS ##########

  # Populate all input plates with qPCR Reactions
  #
  # @param operations [OperationList]
  # @return [void]
  def setup_test_plates(operations:)
    operations.each do |op|
      setup_test_plate(collection: op.input(PLATE).collection)
    end
  end

  # Populate a collection with qPCR Reactions
  #
  # @param collection [Collection]
  # @return [void]
  def setup_test_plate(collection:)
    qpcr_reaction = Sample.find_by_name('Test qPCR Reaction')

    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: 24,
      method: :cdc_primer_layout
    )

    loop do
      layout_group = layout_generator.next_group
      break unless layout_group.present?

      layout_group.each do |r, c|
        collection.set(r, c, qpcr_reaction)
        part = collection.part(r, c)
        part.associate(MASTER_MIX_KEY, { foo: 'bar' })
      end
    end

    show_result(collection: collection)
    inspect_data_associations(collection: collection)
  end

  # Show all the non-empty wells of the test plate
  # @todo figure out what you really want to show here
  #
  # @param collection [Collection]
  # @return [void]
  def show_result(collection:)
    show do
      title 'Test Plate Setup'
      table highlight_non_empty(collection)
    end
  end

  # Inspect a subset of the parts and their data associations
  #
  # @param collection [Collection]
  # @return [void]
  def inspect_data_associations(collection:)
    [[0, 0], [0, 3], [0, 8]].each do |r, c|
      part = collection.part(r, c)
      inspect part, "part at #{[r, c]}"
      inspect part.associations, "data at #{[r, c]}"
    end
  end
end