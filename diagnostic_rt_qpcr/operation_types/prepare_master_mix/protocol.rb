# typed: false
# frozen_string_literal: true

needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'
needs 'Microtiter Plates/MicrotiterPlates'
needs 'PCR Libs/PCRComposition'

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
      group_size: 24,
      program_name: 'CDC_TaqPath_CG',
      layout_method: 'cdc_primer_layout'
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

    provision_plates(
      operations: operations,
      object_type: PLATE_OBJECT_TYPE
    )

    prepare_materials(operations: operations)

    assemble_master_mix_plates(operations: operations)

    operations.store

    inspect_data_associations(operation: operations.first) if debug

    {}
  end

  # Creates and assigns an output collection for each operation, and fills it
  #   with the output sample according to the provided PlateLayoutGenerator
  #   method
  # @note In debug mode, displays the matrix of each collection
  #
  # @param operations [OperationList]
  # @param object_type [String] the ObjectType of the collection to be made
  # @return [void]
  def provision_plates(operations:, object_type:)
    operations.each do |op|
      collection = make_new_plate(object_type, label_plate: true)
      op.output(PLATE).set(collection: collection)

      set_parts(
        collection: collection,
        group_size: op.temporary[:options][:group_size],
        method: op.temporary[:options][:layout_method],
        sample: op.output(PLATE).sample
      )

      inspect op.output(PLATE).collection.matrix if debug
    end
  end

  # Fills a collection with the provided sample according to the provided
  #   PlateLayoutGenerator method
  #
  # @param collection [Collection]
  # @param group_size [Fixnum]
  # @param method [String] a PlateLayoutGenerator method
  # @param sample [Sample] the Sample to add to the collection
  # @return [void]
  def set_parts(collection:, group_size:, method:, sample:)
    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: group_size,
      method: method
    )

    loop do
      index = layout_generator.next
      break unless index.present?

      collection.set(index[0], index[1], sample)
    end
  end

  # Prepare workspace and materials
  #
  # @todo Make this handle master mix or enzyme with separate
  #   buffer dynamically
  # @param operations [OperationList]
  # @return [void]
  def prepare_materials(operations:)
    show_prepare_workspace
    build_master_mix_compositions(operations: operations)
    retrieve_by_compositions(operations: operations)
    show_mix_and_spin_reagents
  end

  # Assembles a master mix plate for each operation
  #
  # @param operations [OperationList]
  # @return [void]
  def assemble_master_mix_plates(operations:)
    operations.each { |op| assemble_master_mix_plate(operation: op) }
  end

  # Assembles a master mix plate for an operation
  # @todo this isn't very efficient for multiple operations that all make the
  #   same plate
  # @todo refactor to take collection and compositions as arguments, not
  #   operation
  #
  # @param operation [Operation]
  # @return [void]
  def assemble_master_mix_plate(operation:)
    compositions = operation.temporary[:compositions]
    pp_labels = compositions.map { |c| c.primer_probe_mix.sample.name }
    show_label_mmix_tubes(labels: pp_labels)

    group_size = operation.temporary[:options][:group_size]
    program_name = operation.temporary[:options][:program_name]

    output_collection = operation.output(PLATE).collection
    output_collection.associate(GROUP_SIZE_KEY, group_size)
    output_collection.associate(COMPOSITION_NAME_KEY, program_name)

    make_master_mixes(
      compositions: compositions,
      sample_number: sample_number_with_excess(sample_number: group_size)
    )

    microtiter_plate = MicrotiterPlateFactory.build(
      collection: output_collection,
      group_size: group_size,
      method: :cdc_primer_layout
    )

    pipet_master_mixes(
      compositions: compositions,
      microtiter_plate: microtiter_plate
    )
  end

  # Makes large volume master mixes to be distributed among wells
  # @todo Make this address each composition in full
  #
  # @param compositions [Array<PCRComposition>]
  # @param sample_number [Fixnum] the number samples for each primer
  # @return [void]
  def make_master_mixes(compositions:, sample_number:)
    show_make_master_mixes(
      compositions: compositions,
      sample_number: sample_number
    )
  end

  # Distribute each master mix among wells on the plate
  #
  # @param compositions [Array<PCRComposition>]
  # @param microtiter_plate [MicrotiterPlate]
  # @return [void]
  def pipet_master_mixes(compositions:, microtiter_plate:)
    compositions.each do |composition|
      pipet_master_mix(
        composition: composition,
        microtiter_plate: microtiter_plate
      )
    end
  end

  # Pipet the master mixes to individual wells
  #
  # @param composition [PCRComposition]
  # @param microtiter_plate [MicrotiterPlate]
  # @return [void]
  def pipet_master_mix(composition:, microtiter_plate:)
    data = added_component_data(composition: composition)
    layout_group = microtiter_plate.associate_provenance_next_empty_group(
      key: MASTER_MIX_KEY,
      data: data
    )

    show_pipet_mmix(
      primer_mix_name: composition.primer_probe_mix.sample.name,
      volume: composition.sum_added_components(0),
      collection: microtiter_plate.collection,
      layout_group: layout_group
    )
  end

  ########## DATA METHODS ##########

  # Compute the number of 'extra' master mixes to make to account for
  #   pipetting error
  #
  # @param sample_number [Fixnum]
  # @return [Fixnum]
  def sample_number_with_excess(sample_number:)
    sample_number < 15 ? sample_number + 1 : sample_number + 2
  end

  ########## SHOW METHODS ##########

  # Instruct technician to mix the incoming reagents and spin down the tubes
  #
  # @return [void]
  def show_mix_and_spin_reagents
    show do
      title 'Mix and spin down reagents'

      note 'Mix buffer, enzyme, and primer/probes by inversion 5 times.'
      note 'Centrifuge reagents and primers/probes for 5 seconds to collect' \
        ' contents at the bottom of the tube.'
      note 'Place the tubes on ice or in a cold-block.'
    end
  end

  # Instruct technician to label the tubes that will contain the master mixes
  #
  # @param labels [Array<String>]
  # @return [void]
  def show_label_mmix_tubes(labels:)
    n = labels.length
    labels = labels.map { |label| "<b>#{label}</b>" }
    show do
      title 'Label master mix tubes'

      note "Take out #{n} #{TUBE_MICROFUGE.pluralize(n)}"
      note "Write #{labels.to_sentence} on the tops of each tube"
    end
  end

  # Instruct technician to make large volume master mixes to be
  #   distributed among wells
  #
  # @param compositions [Array<PCRComposition>]
  # @param sample_number [Fixnum]
  # @return [void]
  def show_make_master_mixes(compositions:, sample_number:)
    show do
      title 'Pipet master mix components'

      note 'Pipet the following components into each labeled master mix tube'
      table master_mix_table(
        compositions: compositions,
        sample_number: sample_number
      )
      separator

      note 'Pipet the primer/probe mixes into each corresponding' \
        ' master mix tube'
      table primer_probe_table(
        compositions: compositions,
        sample_number: sample_number
      )
    end
  end

  # Instruct technician to pipet a master mix into the plate
  #
  # @param primer_mix_name [String]
  # @param volume [Numeric]
  # @param collection [Collection]
  # @param layout_group [Array<Fixnum>]
  # @return [void]
  def show_pipet_mmix(primer_mix_name:, volume:, collection:, layout_group:)
    show do
      title "Pipet #{primer_mix_name} master mix into plate"

      note "Pipet #{volume} #{MICROLITERS} of #{primer_mix_name}" \
        " master mix into the plate #{collection}"
      table highlight_collection_rc(collection, layout_group, check: false)
    end
  end

  ########## TABLE METHODS ##########

  # Build table for volumes of master mix components
  #
  # @param compositions [Array<PCRComposition>]
  # @param sample_number [Fixnum]
  # @return [Array<Array>] a 2D array formatted for the `table` method in Krill
  def master_mix_table(compositions:, sample_number:)
    # This is a hack because otherwise only the first composition gets
    #   marked as added
    compositions.each do |composition|
      composition.master_mix.added = true
      composition.water.added = true
    end

    composition = compositions.first
    header = [
      'Component',
      composition.master_mix.sample.name,
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
  # @param compositions [Array<PCRComposition>]
  # @param sample_number [Fixnum]
  # @return [Array<Array>] a 2D array formatted for the `table` method in Krill
  def primer_probe_table(compositions:, sample_number:)
    table = [[
      compositions.first.primer_probe_mix.display_name,
      'Item',
      "Volume (#{MICROLITERS})"
    ]]
    compositions.each do |composition|
      pp_mix = composition.primer_probe_mix
      row = [
        pp_mix.sample.name,
        pp_mix.item.to_s,
        pp_mix.add_in_table(sample_number)
      ]
      table.append(row)
    end
    table
  end

  private

  def inspect_data_associations(operation:)
    collection = operation.output(PLATE).collection
    [[0, 0], [1, 3], [2, 8]].each do |r, c|
      part = collection.part(r, c)
      inspect part, "part at #{[r, c]}"
      inspect part.associations, "data at #{[r, c]}"
    end
  end
end
