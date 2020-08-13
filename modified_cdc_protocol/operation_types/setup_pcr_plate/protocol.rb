# typed: false
# frozen_string_literal: true

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'
needs 'Standard Libs/Pipettors'
needs 'Standard Libs/Units'
needs 'Standard Libs/AssociationManagement'
needs 'Standard Libs/LabwareNames'
needs 'Standard Libs/ItemActions'
needs 'Collection Management/CollectionActions'
needs 'Microtiter Plates/MicrotiterPlates'
needs 'Microtiter Plates/PlateLayoutGenerator'
needs 'PCR Libs/PCRComposition'
needs 'Modified CDC Protocol/SetupPCRPlateDebug'
needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'

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
  include ItemActions
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
      group_size: 8,
      sample_names: ['RP', '2019-nCoVPC_N1', '2019-nCoVPC_N2'],
      object_type: '8 Well Stripwell'
    }
  end

  def default_job_params
    {
    }
  end

  def main
    setup_test(operations, default_operation_params[:object_type]) if debug
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )

    provision_plates(
      operations: operations
    )

    create_microtiter_plates(operations: operations)
    build_stripwell_primer_probe_compositions(operations: operations)

    if operations.errored.any?
      error_operations
      return {}
    end

    all_inputs = get_all_composition_stripwells(operations: operations).flatten

    show_prepare_workspace

    retrieve_materials(all_inputs)

    set_locations(all_inputs, 'Bench')

    get_lot_number(all_inputs)

    assemble_primer_probe_plates(operations: operations)
    
    all_inputs.map{ |item| item.mark_as_deleted }

    operations.store

    protocol_survey(operations)

    {}
  end

  def error_operations
    operations.each { |op| op.set_status_recursively('pending') }
    operations.store
    show do
      title 'Job Failed'
      note 'There are not enough primer probes in inventory.  Please talk with the lab manager'
    end
  end

  #======== record lot numbers ======#

  def get_all_composition_stripwells(operations:)
    all_stripwells = []
    operations.each do |op|
      all_stripwells.push(get_composition_stripwells(operation: op))
    end
    all_stripwells
  end

  def get_composition_stripwells(operation:)
    stripwells = []
    operation.temporary[:compositions].each do |comp|
      stripwells.push(Collection.find(comp.primer_probe_mix.item.containing_collection.id))
    end
    stripwells.uniq
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
    operations.each do |op|
      add_compositions(compositions: op.temporary[:compositions],
                       microtiter_plate: op.temporary[:microtiter_plate])
    end
  end
  
  # Creates microtiter plate for each operation and
  # associates it to temporary associations under :microtiter_plate
  #
  # @param operations [OperationList]
  def create_microtiter_plates(operations:)
    operations.each do |operation|
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
      operation.temporary[:microtiter_plate] = microtiter_plate
    end
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