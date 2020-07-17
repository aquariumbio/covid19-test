# typed: false
# frozen_string_literal: true

needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'
needs 'Microtiter Plates/MicrotiterPlates'

# Protocol for setting up a plate with extracted RNA samples
#
# @author Devin Strickland <strcklnd@uw.edu>
# @author Cannon Mallory <malloc3@uw.edu>
class Protocol
  include DiagnosticRTqPCRHelper

  CONTROL_TYPE_STUBS = %w[negative_template positive_template].freeze

  # Default parameters that are applied equally to all operations.
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_job_params
    {
      max_inputs: 24
    }
  end

  # Default parameters that are applied to individual operations.
  #   Can be overridden by:
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_operation_params
    {
      negative_template_control: nil,
      negative_template_location: nil,
      positive_template_control: 'Test nCoVPC',
      positive_template_location: [0, 11],
      program_name: 'CDC_TaqPath_CG',
      group_size: 3,
      layout_method: 'cdc_sample_layout'
    }
  end

  def main
    setup_test_plates(operations: operations) if debug
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )

    validate(operations: operations)
    return {} if operations.errored.any?

    prepare_materials(operations: operations)
    # operations.make

    operations.each do |op|
      op.pass(PLATE)
      add_all_samples(operation: op)
    end

    operations.store

    {}
  end

  def add_all_samples(operation:)
    collection = operation.output(PLATE).collection
    remaining_compositions = operation.temporary[:compositions].dup
    operation_parameters = operation.temporary[:options]

    microtiter_plate = MicrotiterPlateFactory.build(
      collection: collection,
      group_size: operation_parameters[:group_size],
      method: operation_parameters[:layout_method]
    )

    remaining_compositions = add_control_samples(
      compositions: remaining_compositions,
      microtiter_plate: microtiter_plate,
      operation_parameters: operation_parameters
    )

    add_diagnostic_samples(
      compositions: remaining_compositions,
      microtiter_plate: microtiter_plate
    )

    seal_plate(collection)
    show_result(collection: collection) if debug
  end

  # Prepare workspace and materials
  #
  # @todo Make this handle master mix or enzyme with separate
  #   buffer dynamically
  # @param operations [OperationList]
  # @return [void]
  def prepare_materials(operations:)
    rnase_warning
    safety_warning
    build_template_compositions(operations: operations)
    retrieve_by_compositions(operations: operations)
  end

  # Provides instructions and handling for addition of control
  # samples.  Returns all inputs that are NOT control inputs
  #
  # @param compositions [Array<PCRCompostion>]
  # @param microtiter_plate [MicrotiterPlate]
  # @param operation_parameters [Hash]
  # @return operation_inputs [Array<item>]
  def add_control_samples(compositions:, microtiter_plate:,
                          operation_parameters:)
    remaining_compositions = []
    CONTROL_TYPE_STUBS.each do |stub|
      name = operation_parameters["#{stub}_control".to_sym]
      loc = operation_parameters["#{stub}_location".to_sym]

      next unless name.present? && loc.present?

      compositions, remaining_compositions = compositions.partition do |c|
        c.template.sample.name == name
      end

      add_samples(
        compositions: compositions,
        microtiter_plate: microtiter_plate,
        column: loc[1]
      )

      # negative control samples need to be covered after addition
      next unless stub.include?('negative')

      seal_plate(collection, rc_list: get_rna_samples(collection))
    end
    remaining_compositions
  end

  # Provides instructions to add diagnostic samples to collection
  #
  # @param compositions [Array<PCRCompostion>]
  # @param microtiter_plate [MicrotiterPlate]
  def add_diagnostic_samples(compositions:, microtiter_plate:)
    add_samples(
      compositions: compositions,
      microtiter_plate: microtiter_plate
    )
  end

  # validates operations and ensures that they are formatted as expected
  #
  # @param operations [OperationList]
  def validate(operations:)
    operations.each do |op|
      if op.input_array(TEMPLATE).length > @job_params[:max_inputs]
        raise IncompatibleInputsError, "Too many inputs for Operation #{op.id}"
      end
    end
  rescue IncompatibleInputsError => e
    error_operations(operations: operations, err: e)
  end

  # Say you're quitting due to an error and error all the operations
  #
  def error_operations(operations:, err:)
    show do
      title 'Incompatible Inputs Detected'
      warning err.message
    end

    operations.each { |op| op.error(:incompatible_inputs, err.message) }
  end

  class IncompatibleInputsError < ProtocolError; end
  class NoAvailableWells < ProtocolError; end
end
