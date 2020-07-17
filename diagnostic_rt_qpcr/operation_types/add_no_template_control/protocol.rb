# typed: false
# frozen_string_literal: true

needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'
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
    setup_test_plates(operations: operations, method: :master_mix) if debug

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
    build_ntc_compositions(operations: operations)
    retrieve_by_compositions(operations: operations)
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
end