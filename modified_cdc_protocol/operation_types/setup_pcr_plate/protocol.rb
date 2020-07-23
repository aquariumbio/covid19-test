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

PLATE = 'PCR Plate'
LOT_NUM_KEY = 'Lot Number'


class Protocol
  # Standard Libs
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

  RP_COMPOSITION_KEY = 'rp_composition'.to_sym
  N1_COMPOSITION_KEY = 'n1_composition'.to_sym
  N2_COMPOSITION_KEY = 'n2_composition'.to_sym

  def default_operation_params
    {
      program_name: 'Modified_CDC',
      layout_method: 'modified_primer_layout_two',
      group_size: 8 #not needed for the modified CDC protocol
    }
  end

  def default_job_params
    {
    }
  end

  def main
    debug_method = setup_test(operations) if debug
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )
    if debug
      operations.each do |op|
        op.temporary[:options][:layout_method] = debug_method
      end
    end


    provision_plates(
      operations: operations
    )

    operations.retrieve

    record_lot_numbers(operations: operations)

    prepare_materials(operations: operations)

    sort_compositions(operations: operations)

    assemble_master_mix_plates(operations: operations)

    operations.store

    {}
  end

  #======= provision plates =======#

  # Creates and assigns an output collection for each operation, and fills it
  #   with the output sample according to the provided PlateLayoutGenerator
  #   method
  # @note In debug mode, displays the matrix of each collection
  #
  # @param operations [OperationList]
  # @param object_type [String] the ObjectType of the collection to be made
  # @return [void]
  def provision_plates(operations:)
    operations.each do |op|
      collection = op.output(PLATE).make_collection
      get_and_label_new_plate(collection)

      set_parts(
        collection: collection,
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
  def set_parts(collection:, method:, sample:)
    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: 3, # arbitrary since modified methods don't use group size
      method: method,
      dimensions: collection.dimensions
    )

    loop do
      index = layout_generator.next
      break unless index.present?

      collection.set(index[0], index[1], sample)
    end
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
      stripwell_list.each do |strip_well|
        get('number',
            var: "#{LOT_NUM_KEY}#{strip_well.id}",
            label: 'Lot Number',
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
    stripwell_list.each do |strip_well|
      lot_number = responses.get_response("#{LOT_NUM_KEY}#{strip_well.id}")
      strip_well.associate(LOT_NUM_KEY, lot_number)
    end
  end

  #===== sort compositions =====#

  # Sorts the compositions into groups based on their name
  # needed to make sure that the correct primer/probe set is added in
  # the right row
  #
  # @param operation [OperationList]
  def sort_compositions(operations: operations)
    operations.each { |op| sort_rp_n1_n2_compositions(operation: op) }
  end
  
  # Sorts the compositions into groups based on their name
  # needed to make sure that the correct primer/probe set is added in
  # the right row
  #
  # @param operation [Array<Compositions>]
  def sort_rp_n1_n2_compositions(operation:)
    compositions = operation.temporary[:compositions]
    rp = []
    n1 = []
    n2 = []
    compositions.each_with_index do |composition, idx|
      name = composition.primer_probe_mix.item.sample.name.downcase
      case
      when name.include?('rp')
        rp.push(composition)
      when name.include?('n1')
        n1.push(composition)
      when name.include?('n2')
        n2.push(composition)
      end
    end
    operation.temporary[RP_COMPOSITION_KEY] = rp
    operation.temporary[N1_COMPOSITION_KEY] = n1
    operation.temporary[N2_COMPOSITION_KEY] = n2
  end



  #====== prepare materials ======#

  # Prepare workspace and materials
  #
  # @todo Make this handle master mix or enzyme with separate
  #   buffer dynamically
  # @param operations [OperationList]
  # @return [void]
  def prepare_materials(operations:)
    show_prepare_workspace
    build_stripwell_master_mix_compositions(operations: operations)
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
    get_composition_keys(method).each do |composition_key|
      compositions = operation.temporary[composition_key]
      add_stripwells(
        compositions: compositions,
        microtiter_plate: microtiter_plate)
    end
  end

  # Adds list of stripwells to microtiter plate
  #
  # @param compositions [Array<Composition>]
  # @param microtiter_plate [MicrotiterPlate]
  def add_stripwells(compositions:, microtiter_plate:)
    stripwell_groups = compositions.group_by do |comp| 
      comp.primer_probe_mix.item.containing_collection
    end
    stripwell_groups.each do |composition_group|
      stripwell = Collection.find(stripwell.id) # TODO need to cast to collection
      add_stripwell(composition_group: composition_group,
                    microtiter_plate: microtiter_plate)
    end
  end

  # Adds a stripwell to a microtiter plate
  #
  # @param composition_group [Array<Compositions>] list of compositions that are
  #    all contained in the same stipwell
  # @param microtiter_plate [MicrotiterPlate]
  def add_stripwell(composition_group:, microtiter_plate:)
    layout_group = microtiter_plate.next_empty_group(key: MASTER_MIX_KEY)
    composition_group.zip(layout_group).each do |composition, lyt|
      data = added_component_data(composition: composition)
      microtiter_plate.associate_provenance(index: lyt,
                                            key: PRIMER_PROBE_MIX_KEY,
                                            data: data)
    end
    strpwll = composition_group.first.primer_probe_mix.item.containing_collection
    show_add_stripwell(layout_group: layout_group,
                       stripwell: strpwll,
                       collection: microtiter_plate.collection)
  end

  # Show instructions to place stripwell in rack
  # @param layout_group [Array<[r,c]>]
  # @param stripwell [Collection]
  # @param collection [Collection] the collection of the microtiter plate
  def show_add_stripwell(layout_group:, stripwell:, collection:)
    show_mark_stripwell(stripwell: stripwell)
    show do 
      title 'Add Stripwell to Stripwell Rack'
      note "Please place stripwell #{stripwell.id} in"\
        " stripwell rack #{collection.id} per table below"
      note 'Make sure column 1 of the stripwell lines up with column 1 of the rack'
      table highlight_collection_rc(collection, layout_group){ stripwell.id }
    end
  end

  # Directions to mark a stripwell correctly
  #
  # @param stripwell [Colleciton]
  def show_mark_stripwell(stripwell:)
    show do
      title 'Mark Stripwell'
      note 'Using a felt tip marker please mark'\
        " stripwell #{stripwell.id}"
      note "Mark one end <b>1</b> and the other <b>#{stripwell.dimensions[1]}"
      warning 'Do NOT mark the lids of the stripwell!'
    end
  end

  # Returns an array of keys determined from the method type
  #
  # @param method [string] the method used in microtiter plate
  # @return [Array<[Symbols]>] symbols are determined from constants
  def get_composition_keys(method)
    if method == 'modified_primer_layout_two'
      return [RP_COMPOSITION_KEY, N1_COMPOSITION_KEY]
    elsif method == 'modified_primer_layout_one'
      return [N2_COMPOSITION_KEY]
    end
    raise 'No valid method detected'
  end
end
