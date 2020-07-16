# frozen_string_literal: true

needs 'RNA Extraction Kits/RNAExtractionHelper'
needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'

# Extract RNA Protocol
#
# @author Devin Strickland <strcklnd@uw.edu>
class Protocol
  include RNAExtractionHelper
  include DiagnosticRTqPCRHelper

  ########## DEFAULT PARAMS ##########

  # Default parameters that are applied equally to all operations.
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_job_params
    {
      rna_extraction_kit: QiagenRNeasyMiniKit::NAME
    }
  end

  # Default parameters that are applied to individual operations.
  #   Can be overridden by:
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_operation_params
    {
      sample_volume: { qty: 300, units: MICROLITERS }
    }
  end

  ########## MAIN ##########

  def main
    setup_test_options(operations: operations) if debug
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )
    return {} if operations.errored.any?

    operations.retrieve.make

    set_kit(name: @job_params[:rna_extraction_kit])

    sample_volumes = operations.map { |op| sample_volume(op) }
    if sample_volumes.uniq.length == 1
      run_rna_extraction_kit(
        operations: operations,
        sample_volume: sample_volumes.first
      )
    else
      run_rna_extraction_kit(
        operations: operations,
        use_operations: true
      )
    end

    add_specimen_provenance(operations: operations)

    operations.store

    {}
  end

  # Add provenance to SPECIMEN inputs and outputs of operations
  #
  # @param operations [OperationList]
  # @return [void]
  def add_specimen_provenance(operations:)
    operations.each do |op|
      add_one_to_one_provenance(
        from_item: op.input(SPECIMEN).item,
        to_item: op.output(SPECIMEN).item
      )
    end
    return unless debug

    inspect(operations.last.input(SPECIMEN).item.associations, 'input')
    inspect(operations.last.output(SPECIMEN).item.associations, 'output')
  end
end
