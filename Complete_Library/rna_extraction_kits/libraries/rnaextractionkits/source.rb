# frozen_string_literal: true

needs 'RNA Extraction Kits/SupportedRNAExtractionKits'

# Module for switching among several different RNA extraction kits
#
# @author Devin Strickland <strcklnd@uw.edu>
module RNAExtractionKits
  include SupportedRNAExtractionKits

  # Run the protocol defined by the kit
  #
  # @note if `sample_volume` is provided, then all samples will be run
  #   using that volume of sample
  # @note if `sample_volume` is not provided, but `operations` are, then
  #   the protocol will look for sample_volumes assigned to the `Operations`
  # @note if neither `sample_volume` nor `operations` are provided, then
  #   all samples will be run using `DEFAULT_SAMPLE_VOLUME`
  # @param operations [OperationList] the operations to run
  # @param sample_volume [Hash] the volume as a Hash in the format
  #   `{ qty: 140, units: MICROLITERS }`
  # @return [void]
  def run_rna_extraction_kit(operations: [], sample_volume: nil, expert: false)
    prepare_materials

    notes_on_handling unless expert

    if sample_volume
      lyse_samples_constant_volume(sample_volume: sample_volume, expert: expert)
    elsif operations.present?
      lyse_samples_variable_volume(operations: operations, expert: expert)
    else
      lyse_samples_constant_volume(expert: expert)
    end

    bind_rna(
      operations: operations,
      sample_volume: sample_volume,
      expert: expert
    )

    wash_rna(operations: operations, expert: expert)

    elute_rna(operations: operations, expert: expert)
  end
end
