# typed: false
# frozen_string_literal: true

needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'
needs 'PCR Libs/PCRComposition'
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
  include DiagnosticRTqPCRHelper

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

    prepare_materials(operations: operations)

    operations.each do |op|
      op.pass(PLATE)
      add_no_template_controls(operation: op)
    end

    operations.store

    {}
  end

  # Prepare workspace and materials
  #
  # @todo Make this handle master mix or enzyme with separate
  #   buffer dynamically
  # @param operations [OperationList]
  # @return [void]
  def prepare_materials(operations:)
    show_prepare_workspace
    build_compositions(operations: operations)
    retrieve_by_compositions(operations: operations)
  end

  # Initialize all `PCRComposition`s for each operation
  #
  # @param operations [OperationList]
  # @return [void]
  def build_compositions(operations:)
    operations.each do |operation|
      composition = build_composition(
        program_name: operation.temporary[:options][:program_name]
      )
      operation.temporary[:compositions] = [composition]
    end
  end

  # Initialize a `PCRComposition` for the given program
  #
  # @param program_name [String]
  # @return [PCRComposition]
  def build_composition(program_name:)
    composition = PCRCompositionFactory.build(program_name: program_name)
    composition.template.item = no_template_control_item
    composition
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
    composition = operation.temporary[:compositions].first

    microtiter_plate = MicrotiterPlateFactory.build(
      collection: collection,
      group_size: operation.temporary[:options][:group_size],
      method: operation.temporary[:options][:layout_method]
    )

    layout_group = microtiter_plate.next_empty_group(key: TEMPLATE_KEY)

    show_add_ntc(
      collection: collection,
      volume: composition.water.qty_display,
      layout_group: layout_group
    )

    composition.template.added = true

    microtiter_plate.associate_provenance_group(
      group: layout_group,
      key: TEMPLATE_KEY,
      data: added_component_data(composition: composition)
    )

    show_result(collection: collection) if debug
    inspect_data_associations(collection: collection) if debug
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
        part.associate(MASTER_MIX_KEY, 'added')
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