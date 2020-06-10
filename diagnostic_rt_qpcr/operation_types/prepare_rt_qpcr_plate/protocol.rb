# frozen_string_literal: true

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/CommonInputOutputNames'
needs 'Standard Libs/Debug'
# needs 'Collection Management/CollectionActions'
needs 'Collection Management/CollectionDisplay'
# needs 'Collection Management/CollectionTransfer'
# needs 'Collection Management/CollectionLocation'
# needs 'Collection Management/CollectionData'
needs 'Microtiter Plates/PlateLayoutGenerator'

# Protocol for setting up a plate with extracted RNA samples
#
# @author Devin Strickland <strcklnd@uw.edu>
class Protocol
  include PlanParams
  include Debug
  include CommonInputOutputNames
  # include CollectionActions
  include CollectionDisplay
  # include CollectionTransfer
  # include CollectionLocation
  # include CollectionData

  PLATE = 'PCR Plate'

  ########## DEFAULT PARAMS ##########

  # Default parameters that are applied equally to all operations.
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_job_params
    {
      max_inputs: 24,
      negative_template_control: 'NTC',
      negative_template_location: [0, 0],
      positive_template_control: 'nCoVPC',
      positive_template_location: [0, 11]
    }
  end

  # Default parameters that are applied to individual operations.
  #   Can be overridden by:
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_operation_params
    {}
  end

  ########## MAIN ##########

  def main
    # @job_params = update_all_params(
    #   operations: operations,
    #   default_job_params: default_job_params,
    #   default_operation_params: default_operation_params
    # )
    @job_params = default_job_params
    vaidate(operations: operations)
    return {} if operations.errored.any?

    operations.retrieve.make

    operations.each do |op|
      collection = op.output(PLATE).collection
      layout_generator = PlateLayoutGeneratorFactory.build(group_size: 3)

      remaining_inputs = add_control_samples(
        operation_inputs: op.input_array(TEMPLATE),
        collection: collection,
        layout_generator: layout_generator
      )

      add_diagnostic_samples(
        operation_inputs: remaining_inputs,
        collection: collection,
        layout_generator: layout_generator
      )

      show do
        table highlight_non_empty(collection)
      end
    end

    operations.store

    {}
  end

  def add_control_samples(operation_inputs:, collection:, layout_generator:)
    remaining_inputs = []
    %w[negative_template positive_template].each do |stub|
      name = @job_params["#{stub}_control".to_sym]
      loc = @job_params["#{stub}_location".to_sym]
      these_inputs, remaining_inputs = operation_inputs.partition do |fv|
        fv.sample.name == name
      end

      add_samples(
        operation_inputs: these_inputs,
        collection: collection,
        layout_generator: layout_generator,
        column: loc[1]
      )
    end
    remaining_inputs
  end

  def add_diagnostic_samples(operation_inputs:, collection:, layout_generator:)
    add_samples(
      operation_inputs: operation_inputs,
      collection: collection,
      layout_generator: layout_generator
    )
  end

  def add_samples(operation_inputs:, collection:, layout_generator:, column: nil)
    operation_inputs.each do |fv|
      layout_group = layout_generator.next_group(column: column)
      layout_group.each { |r, c| collection.set(r, c, fv.sample) }
    end
  end

  def vaidate(operations:)
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
end
