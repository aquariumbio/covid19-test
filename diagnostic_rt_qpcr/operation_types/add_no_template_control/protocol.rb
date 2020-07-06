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
      sample_group_size: 3
    }
  end

  ########## MAIN ##########

  def main
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )
    return {} if operations.errored.any?

    update_operation_params(
      operations: operations,
      default_operation_params: default_operation_params
    )

    operations.retrieve.make

    add_no_template_controls(operations: operations)

    operations.store

    {}
  end

  # Group_Size and Program name are attributes of the plate
  # and should be associated to the plate from Prepare Master Mix
  def add_no_template_controls(operations:)
    operations.each do |op|
      group_size = op.input(PLATE).collection.get(GROUP_SIZE_KEY)
      program_name = op.input(PLATE).collection.get(COMPOSITION_NAME_KEY)

      if debug
        group_size = 3
        program_name = 'CDC_TaqPath_CG'
      end

      layout_generator = PlateLayoutGeneratorFactory.build(
        group_size: group_size # op.temporary[:options][:sample_group_size]
      )
      layout_group = layout_generator.next_group
      composition = PCRCompositionFactory.build(
        program_name: program_name # op.temporary[:options][:program_name]
      )
      volume = composition.water.qty_display
      collection = op.output(PLATE).collection

      show do
        title "Pipet No Template Control (NTC) samples into plate #{collection}"

        note "Pipet #{volume} of #{WATER} into the indicated wells of" \
          " plate #{collection}"
        table highlight_collection_rc(collection, layout_group, check: true)
      end
    end
  end

end
