# typed: false
# frozen_string_literal: true

needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'
needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRDebug'
needs 'Diagnostic RT-qPCR/DataAssociationKeys'
needs 'PCR Libs/PCRComposition'
needs 'Microtiter Plates/MicrotiterPlate'
needs 'Collection Management/CollectionTransfer'

# Protocol for setting up a plate with extracted RNA samples
#
# @author Devin Strickland <strcklnd@uw.edu>
# @author Cannon Mallory <malloc3@uw.edu>
class Protocol
  include DiagnosticRTqPCRHelper
  include DiagnosticRTqPCRDebug
  include MicrotiterPlates
  include CollectionTransfer
  include DataAssociationKeys

  METHOD = :cdc_sample_layout

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
      positive_template_location: [0, 11]
    }
  end

  def main
    #========= Setup Job ==========#
    setup_test(operations) if debug
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )

    #========= Validation =========#
    validate(operations: operations)
    return {} if operations.errored.any?

    #====== General Warnings =====#
    rnase_warning
    safety_warning

    operations.retrieve.make

    #====== Core Operation ======#
    operations.each do |op|
      op.pass(PLATE)
      output_collection = op.output(PLATE).collection
      group_size = output_collection.get(:group_size)
      program_name = output_collection.get(:program_name)

      microtiter_plate = MicrotiterPlateFactory.build(
        collection: output_collection,
        group_size: group_size,
        method: METHOD
      )

      composition = PCRCompositionFactory.build(
        program_name: program_name
      )
      volume = { qty: composition.template.qty,
                 units: composition.template.units }

      remaining_inputs = add_control_samples(
        operation_inputs: op.input_array(TEMPLATE),
        microtiter_plate: microtiter_plate,
        volume: volume,
        operation_parameters: op.temporary[:options]
      )

      add_diagnostic_samples(
        operation_inputs: remaining_inputs,
        microtiter_plate: microtiter_plate,
        volume: volume
      )

      seal_plate(output_collection)
      show_result(collection: output_collection) if debug
    end

    operations.store

    {}
  end

  # Provides instructions and handling for addition of control
  # samples.  Returns all inputs that are NOT control inputs
  #
  # @param operation_inputs [Array<item>]
  # @param collection [Collection]
  # @param layout_generator [LayoutGenerator]
  # @param volume [{aty: int, unit: string}]
  # @return operation_inputs [Array<item>]
  def add_control_samples(operation_inputs:, microtiter_plate:,
                          volume:, operation_parameters:)
    %w[negative_template positive_template].each do |stub|
      name = operation_parameters["#{stub}_control".to_sym]
      loc = operation_parameters["#{stub}_location".to_sym]

      next unless name.present? && loc.present?

      control_inputs, operation_inputs = operation_inputs.partition do |fv|
        fv.sample.name == name
      end

      add_samples(
        operation_inputs: control_inputs,
        microtiter_plate: microtiter_plate,
        volume: volume,
        column: loc[1]
      )

      # negative control samples need to be covered after addition
      next unless stub.include?('negative')

      seal_plate(collection, rc_list: get_rna_samples(collection))
    end
    operation_inputs
  end

  # Provides instructions to add diagnostic samples to collection
  #
  # @param operation_inputs [Array<items>]
  # @param collection [Collection]
  # @param layout_generator [LayoutGenerator]
  # @param volume [{aty: int, unit: string}]
  def add_diagnostic_samples(operation_inputs:, microtiter_plate:,
                            volume:)
    add_samples(
      operation_inputs: operation_inputs,
      microtiter_plate: microtiter_plate,
      volume: volume
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
