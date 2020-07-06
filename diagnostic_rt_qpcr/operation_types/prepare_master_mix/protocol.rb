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
# 1) In the reagent set-up room clean hood, place rRT-PCR buffer, enzyme,
#     and primer/probes on ice or cold-block. Keep cold during preparation
#     and use.
#
# 2) Mix buffer, enzyme, and primer/probes by inversion 5 times.
#
# 3) Centrifuge reagents and primers/probes for 5 seconds to collect
#     contents at the bottom of the tube, and then place the tube in
#     a cold rack.
#
# 4) Label one 1.5 mL microcentrifuge tube for each primer/probe set.
#
# 5) Determine the number of reactions (N) to set up per assay.
#   It is necessary to make excess reaction mix for the NTC, nCoVPC,
#   HSC (if included in the RT-PCR run), and RP reactions and for pipetting
#   error. Use the following guide to determine N:
#     - If number of samples (n) including controls equals 1 through 14,
#       then N = n + 1
#     - If number of samples (n) including controls is 15 or greater,
#       then N = n + 2
#
# 7) For each primer/probe set, calculate the amount of each reagent
#   to be added for each reaction mixture (N = # of reactions).
#
# 8) Dispense reagents into each respective labeled 1.5 mL microcentrifuge
#   tube. After addition of the reagents, mix reaction mixtures by
#   pipetting up and down. Do not vortex.
#
# 9) Centrifuge for 5 seconds to collect contents at the bottom of
#   the tube, and then place the tube in a cold rack.
#
# 10) Set up reaction strip tubes or plates in a 96-well cooler rack.
#
# 11) Dispense 15 uL of each master mix into the appropriate wells going
#   across the row
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
  PRIMER_MIX = 'Primer/Probe Mix'

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
      number_of_reactions: 24,
      group_size: 3,
      program_name: 'CDC_TaqPath_CG'
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

    provision_plates(
      operations: operations,
      object_type: '96-well qPCR Plate'
    )

    prepare_materials(operations: operations)

    prepare_master_mixes(operations: operations)

    operations.store

    {}
  end

  # @todo make this responsive to the designated object_type for the operation
  def provision_plates(operations:, object_type:)
    operations.each do |op|
      collection = make_new_plate(object_type, label_plate: true)
      op.output(PLATE).set collection: collection
      inspect op.output(PLATE).collection.matrix if debug
    end
  end

  # Prepare workspace and materials
  #
  # @todo Make this handle master mix or enzyme with separate buffer dynamically
  # @param operations [OperationList]
  def prepare_materials(operations:)
    prepare_workspace
    operations.retrieve
    mix_and_spin_down_reagents
  end

  def prepare_master_mixes(operations:)
    operations.each { |op| prepare_master_mix(operation: op) }
  end

  def prepare_master_mix(operation:)
    primer_mixes = operation.input_array(PRIMER_MIX).map(&:item)
    output_collection = operation.output(PLATE).collection

    label_master_mix_tubes(labels: primer_mixes.map { |item| item.sample.name })

    group_size = operation.temporary[:options][:group_size]
    program_name = operation.temporary[:options][:program_name]
    composition = PCRCompositionFactory.build(
      program_name: program_name
    )

    output_collection.associate(COMPOSITION_NAME_KEY, program_name)
    output_collection.associate(GROUP_SIZE_KEY, group_size)

    pipet_master_mix_components(
      primer_mixes: primer_mixes,
      composition: composition,
      sample_number: sample_number_with_excess(sample_number: group_size)
    )

    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: group_size,
      method: :primer_layout
    )
    primer_mixes.each do |primer_mix|
      pipet_master_mix(
        primer_mix: primer_mix,
        volume: composition.sum_added_components,
        layout_group: layout_generator.next_group,
        collection: output_collection
      )
    end

    # test_layout_generator(layout_generator) if debug
  end

  def sample_number_with_excess(sample_number:)
    sample_number < 15 ? sample_number + 1 : sample_number + 2
  end

  ########## SHOW METHODS ##########

  def prepare_workspace
    show do
      title 'Prepare workspace'

      note "All tasks in this protocol occur in the #{RNA_FREE_WORKSPACE}."
      note 'As you retrieve reagents, place them on ice or in a cold-block.'
    end
  end

  def mix_and_spin_down_reagents
    show do
      title 'Mix and spin down reagents'

      note 'Mix buffer, enzyme, and primer/probes by inversion 5 times.'
      note 'Centrifuge reagents and primers/probes for 5 seconds to collect' \
        'contents at the bottom of the tube.'
      note 'Place the tubes on ice or in a cold-block.'
    end
  end

  def label_master_mix_tubes(labels:)
    n = labels.length
    labels = labels.map { |label| "<b>#{label}</b>" }
    show do
      title 'Label master mix tubes'

      note "Take out #{n} #{TUBE_MICROFUGE.pluralize(n)}"
      note "Write #{labels.to_sentence} on the tops of each tube"
    end
  end

  def pipet_master_mix_components(primer_mixes:, composition:, sample_number:)
    show do
      title 'Pipet master mix components'

      note 'Pipet the following components into each labeled master mix tube'
      table master_mix_table(
        composition: composition,
        sample_number: sample_number
      )
      separator

      note 'Pipet the primer/probe mixes into each corresponding' \
        ' master mix tube'
      table primer_probe_table(
        primer_mixes: primer_mixes,
        composition: composition,
        sample_number: sample_number
      )
    end
  end

  # Build table for volumes of master mix components
  #
  # @param composition [PCRComposition]
  # @param sample_number [Fixnum]
  # @return [Array<Array>] a 2D array formatted for the `table` method in Krill
  def master_mix_table(composition:, sample_number:)
    header = [
      'Component',
      composition.master_mix.display_name,
      composition.water.display_name
    ]
    row = [
      "Volume (#{MICROLITERS})",
      composition.master_mix.add_in_table(sample_number),
      composition.water.add_in_table(sample_number)
    ]
    [header, row].transpose
  end

  # Build table for volumes of master mix components
  #
  # @param composition [PCRComposition]
  # @param sample_number [Fixnum]
  # @return [Array<Array>] a 2D array formatted for the `table` method in Krill
  def primer_probe_table(primer_mixes:, composition:, sample_number:)
    table = [[
      composition.primer_probe_mix.display_name,
      'Item',
      "Volume (#{MICROLITERS})"
    ]]
    primer_mixes.each do |primer_mix|
      row = [
        primer_mix.sample.name,
        primer_mix.to_s,
        composition.primer_probe_mix.add_in_table(sample_number)
      ]
      table.append(row)
    end
    table
  end

  def pipet_master_mix(primer_mix:, volume:, layout_group:, collection:)
    show do
      title "Pipet #{primer_mix.sample.name} master mix into plate"

      note "Pipet #{volume} #{MICROLITERS} of #{primer_mix.sample.name}" \
        " master mix into the plate #{collection}"
      table highlight_collection_rc(collection, layout_group, check: false)
    end
  end

  ########## TEST METHODS ##########

  # @todo this doesn't work because next_group is destructive
  def test_layout_generator(layout_generator)
    3.times do |i|
      inspect layout_generator.next_group.to_s, "Layout group #{i + 1}"
    end
  end
end
