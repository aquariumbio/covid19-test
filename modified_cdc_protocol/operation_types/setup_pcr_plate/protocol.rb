# typed: false
# frozen_string_literal: true

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'
needs 'Standard Libs/Pipettors'
needs 'Standard Libs/Units'
needs 'Standard Libs/AssociationManagement'
needs 'Standard Libs/LabwareNames'
needs 'Collection Management/CollectionActions'
needs 'Microtiter Plates/MicrotiterPlates'
needs 'Microtiter Plates/PlateLayoutGenerator'
needs 'PCR Libs/PCRComposition'
needs 'Modified CDC Protocol/SetupPCRPlateDebug'
needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'
needs 'Diagnostic RT-qPCR/DataAssociationKeys'

# TODO Will alternate all primer probe sample types.
# does not keep to rigid structure (e.g working down RP, N1, N2)
# The order depends on the order that stripwells are listed in the
# input array.

class Protocol
  include PlanParams
  include Debug
  include Pipettors
  include Units
  include LabwareNames
  include AssociationManagement
  include SetupPCRPlateDebug
  include CollectionActions
  include MicrotiterPlates
  include DiagnosticRTqPCRHelper
  include DataAssociationKeys


  def default_operation_params
    {
      program_name: 'Modified_CDC',
      layout_method: 'modified_primer_layout',
      group_size: 8
    }
  end

  def default_job_params
    {
    }
  end

  def main
    setup_test(operations) if debug
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )
    

    provision_plates(
      operations: operations
    )

    operations.retrieve

    record_lot_numbers(operations: operations)

    show_prepare_workspace

    build_stripwell_master_mix_compositions(operations: operations)

    assemble_primer_probe_plates(operations: operations)

    operations.store

    {}
  end

  #======== record lot numbers ======#

  # Handles associations and directions to get and record stripwell lot numbers
  #
  # @param operations [OperationList]
  def record_lot_numbers(operations:)
    operations.each do |op|
      get_lot_number(op.input_array(PRIMER_PROBE_MIX).map { |fv| fv.collection })
    end
  end

  # Gets tech to read and record lot numbers of stripwells
  #
  # @param stripwell_list [Array<collection>]
  def get_lot_number(stripwell_list)
    responses = show do
      title 'Record Primer Probe Lot Number'
      note 'Please add the primer probe lot number below'
      stripwell_list.each do |stripwell|
        get('number',
            var: "#{LOT_NUM_KEY}#{stripwell.id}",
            label: "Stripwell #{stripwell.id} Lot Number",
            default: 0)
      end
    end
    associate_lot_numbers(stripwell_list, responses)
  end

  # Adds data associations to stripwells
  # May need to associate it to something else.  But for now its to the stripwell
  #
  # @param stripwell_list [Array<collection>]
  # @param responses [Array<strings>]
  def associate_lot_numbers(stripwell_list, responses)
    stripwell_list.each do |stripwell|
      lot_number = responses.get_response("#{LOT_NUM_KEY}#{stripwell.id}")
      stripwell.associate(LOT_NUM_KEY, lot_number)
    end
  end

  #====== assemble primer_probe plates ======#

  # Assembles the primer probe stripwells in the 96 well rack
  #
  # @param operations [Array<Operations>] 
  def assemble_primer_probe_plates(operations:)
    operations.each { |op| assemble_primer_probe_plate(operation: op) }
  end

  # Assembles the primer probe stripwells in the 96 well rack
  #
  # @param operation [Operation]
  def assemble_primer_probe_plate(operation:)
    method = operation.temporary[:options][:layout_method]
    group_size = operation.temporary[:options][:group_size]
    program_name = operation.temporary[:options][:program_name]

    output_collection = operation.output(PLATE).collection
    output_collection.associate(PRIMER_GROUP_SIZE_KEY, group_size)
    output_collection.associate(COMPOSITION_NAME_KEY, program_name)
    output_collection.associate(PRIMER_METHOD_KEY, method)

    microtiter_plate = MicrotiterPlateFactory.build(
      collection: output_collection,
      group_size: group_size,
      method: method
    )
    add_compositions(compositions: operation.temporary[:compositions],
                   microtiter_plate: microtiter_plate)
  end

  # Adds list of stripwells to microtiter plate
  #
  # @param compositions [Array<Composition>]
  # @param microtiter_plate [MicrotiterPlate]
  def add_compositions(compositions:, microtiter_plate:)
    stripwell_groups = compositions.group_by do |comp| 
      Collection.find(comp.primer_probe_mix.item.containing_collection.id)
    end

    sample_groups = stripwell_groups.keys.group_by do |stripwell|
      stripwell.parts.first.sample.name
    end

    sample_groups.values.transpose.each do |stripwells|
      stripwells.each_with_index do |stripwell, idx|
        add_stripwell(composition_group: stripwell_groups[stripwell],
                      microtiter_plate: microtiter_plate,
                      stripwell: stripwell)
      end
    end
  end
end