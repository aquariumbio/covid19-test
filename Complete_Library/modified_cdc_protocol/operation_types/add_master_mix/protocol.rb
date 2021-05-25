# typed: false
# frozen_string_literal: true

needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'
needs 'Modified CDC Protocol/SetupPCRPlateDebug'
needs 'Microtiter Plates/MicrotiterPlates'
needs 'Standard Libs/Debug'

# Protocol for setting up a plate with extracted RNA samples
#
# @author Devin Strickland <strcklnd@uw.edu>
# @author Cannon Mallory <malloc3@uw.edu>
class Protocol
  include DiagnosticRTqPCRHelper
  include SetupPCRPlateDebug
  include Debug

  REHYDRATION_BUFFER = 'Rehydration Buffer'

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
      program_name: 'Modified_CDC',
      group_size: 12,
      layout_method: 'skip_primer_layout'
    }
  end

  def main
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )
    setup_stripwell_plates(operations: operations) if debug
    set_group_size(operations: operations)

    operations.retrieve

    operations.each do |op|
      op.output(PLATE).set(item: op.input(PLATE).item)
      options = op.temporary[:options]

      op.temporary[:compositions] = build_rehydration_buffer_composition(
        program_name: options[:program_name],
        mm_item: op.input(REHYDRATION_BUFFER).item)

      microtiter_plate = MicrotiterPlateFactory.build(
        collection: op.output(PLATE).collection,
        group_size: options[:group_size],
        method: options[:layout_method]
      )

      add_buffer(compositions: [op.temporary[:compositions]],
                 microtiter_plate: microtiter_plate,
                 group_size: options[:group_size])


    end
    
    operations.each { |op| op.input(REHYDRATION_BUFFER).item.mark_as_deleted }

    operations.store
    
    protocol_survey(operations)
    
    {}

  end
  
  # Sets the group size to the correcrt value if
  # the using the skip layout method
  def set_group_size(operations: operations)
    operations.each do |op|
      if op.temporary[:options][:layout_method].include?('skip')
        op.temporary[:options][:group_size] = op.input(PLATE).collection.parts.length
      end
    end
  end
  


    # Adds samples to to collections, provides instructions to tech
  #
  # @param compositions [Array<PCRCompostion>]
  # @param microtiter_plate [MicrotiterPlate]
  # @param column [int]
  def add_buffer(compositions:, microtiter_plate:, column: nil, group_size:)
    compositions.each do |composition|
      show_fill_reservoir(composition.master_mix.item,
                          unit_volume: composition.master_mix.volume_hash,
                          number_items: group_size,
                          pour: true)
      
      layout_group = microtiter_plate.collection.get_non_empty

      multichannel_item_to_collection(
        to_collection: microtiter_plate.collection,
        source:'Media Reservoir',
        volume:composition.master_mix.volume_hash,
        association_map: layout_group.map { |r, c| { to_loc: [r, c] } }
      )

      composition.master_mix.added = true

      microtiter_plate.associate_provenance_group(
        group: layout_group,
        key: MASTER_MIX_KEY,
        data: added_component_data(composition: composition)
      )
    end
  end

  def build_rehydration_buffer_composition(program_name:, mm_item:)
    composition = PCRCompositionFactory.build(program_name: program_name)
    composition.master_mix.item = mm_item
    composition
  end

end