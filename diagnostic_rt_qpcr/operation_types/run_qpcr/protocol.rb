# frozen_string_literal: true

needs 'PCR Libs/PCRComposition'
needs 'PCR Libs/PCRProgram'
needs 'Thermocyclers/Thermocyclers'
needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'
needs 'Standard Libs/UploadHelper'
needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'
needs 'Diagnostic RT-qPCR/DataAssociationkeys'
needs 'Tube Rack/TubeRack'
needs 'Tube Rack/TubeRackHelper'

# Protocol for loading samples into a qPCR thermocycler and running it
#
# @author Devin Strickland <strcklnd@uw.edu>
# @todo Decide whether this is actually qPCR specific
class Protocol
  include ThermocyclerHelper
  include PlanParams
  include Debug
  include UploadHelper
  include DiagnosticRTqPCRHelper
  include TubeRackHelper

  THERMOCYCLER_KEY = 'thermocycler'.to_sym

  ########## DEFAULT PARAMS ##########

  # Default parameters that are applied equally to all operations.
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_job_params
    {
    }
  end

  # Default parameters that are applied to individual operations.
  #   Can be overridden by:
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_operation_params
    {
      thermocycler_model: TestThermocycler::MODEL,
      program_name: 'CDC_TaqPath_CG',
      qpcr: true
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

    paired_ops = pair_ops_and_thermocyclers(get_available_thermocyclers, operations)

    remove_unpaired_operations(operations)

    return {} if paired_ops.empty?

    paired_ops.make

    # TODO this errors
    # paired_ops.retrieve
    
    retrieve_materials(paired_ops.map { |op| op.input(PLATE).collection } )
    
    spin_down_plates(paired_ops)
    
    flick_to_remove_bubbles(paired_ops)

    start_thermocyclers(paired_ops)

    get_data(paired_ops)
    
    protocol_survey(operations)
    
    workflow_survey(operations)

    {}
  end
  
  def flick_to_remove_bubbles(paired_ops)
    show do
      title 'Examine for Bubbles'
      note 'Examine all wells in plates for bubbles'
      note 'If there are bubbles gently remove stripwell and flick plate until bubbles are gone'
      note 'INSERT GIF'
      note 'Plates:'
      paired_ops.each do |op|
        note op.input(PLATE).collection.id.to_s
      end
    end
  end
  
  def spin_down_plates(paired_ops)
      show do
        title 'Spin Down Plate'
        note 'Spin down the following plate'
        paired_ops.each do |op|
          note op.input(PLATE).collection.id.to_s
        end
      end
  end

  def get_data(paired_ops)
    paired_ops.each do |op|
      thermocycler = op.temporary[:thermocycler]
      go_to_thermocycler(thermocycler_name: op.get(THERMOCYCLER_KEY)['name'])
      export_measurements(thermocycler: thermocycler)

      associate_measurement(file_name: op.get(RAW_QPCR_DATA_KEY),
                            plate: op.input(PLATE).collection)
    end
  end

  def start_thermocyclers(paired_ops)
    running_thermocyclers = []

    paired_ops.group_by(&:plan).each do |plan, ops|
      composition = PCRCompositionFactory.build(
        program_name: ops.first.temporary[:options][:program_name]
      )

      program = PCRProgramFactory.build(
        program_name: ops.first.temporary[:options][:program_name]
      )

      thermo_type = ops.first.get(THERMOCYCLER_KEY)
      
      file_name = experiment_filename(plan)
      
      ops.each { |op| op.associate(RAW_QPCR_DATA_KEY, file_name) }
      
      thermocycler = ThermocyclerFactory.build(
        model: thermo_type['model']
      )
      
      ops.each { |op| op.temporary[:thermocycler] = thermocycler }
      
      thermocycler_dimensions = thermocycler.params[:dimensions]
      
      go_to_thermocycler(thermocycler_name: thermo_type['name'], plates: ops.map{ |op| op.input(PLATE).collection })
      
      set_up_program(
        thermocycler: thermocycler,
        program: program,
        composition: composition,
        qpcr: ops.first.temporary[:options][:program_name]
      )
      
      if ops.length == 1
        load_plate_and_start_run(
          thermocycler: thermocycler,
          items: ops.first.input(PLATE).collection,
          experiment_filename: file_name
        )
      else
        load_stripwells_and_start_run(
          thermocycler: thermocycler,
          ops: ops,
          experiment_filename: file_name
        )
      end
      
      ops.each { |op| running_thermocyclers.push([op, thermocycler]) }
      
      running_thermocyclers
      
    end
  end
  
  def load_stripwells_and_start_run(thermocycler:, ops:, experiment_filename: nil)
    thermocycler_dimensions = thermocycler.params[:dimensions]
    thermocycler_rack = TubeRack.new(thermocycler_dimensions[0], thermocycler_dimensions[1], name: 'Thermocycler')
    rotate = thermocycler_dimensions != ops.first.input(PLATE).collection.dimensions
    
    
    show do
      title "Start Run on #{thermocycler.model} Thermocycler"
      note thermocycler.open_lid
      image thermocycler.open_lid_image
    end
    
    ops.each do |op|
      collection = op.input(PLATE).collection
      part_by_row = collection.get_non_empty.group_by { |loc| loc[0] }
      part_by_row.each do |_row, from_row|
        full_to_row = rotate ? thermocycler_rack.next_empty_column : thermocycler_rack.next_empty_row
        to_row = full_to_row[0, from_row.length]
        to_row.each { |loc| thermocycler_rack.set('Occupied', loc[0], loc[1]) }
        to_row_rcx = []
        from_row.zip(to_row).each do |from_loc, to_loc|
          collection.part(from_loc[0], from_loc[1]).associate('thermocycler_well_location', to_loc)
          to_row_rcx.push(to_loc.push(from_loc[1]))
        end
        numerator = (0...(from_row.length + 1)).to_a
        show do
          title "Add Stripwell to #{thermocycler.model}"
          note 'Move Stripwell to thermocycler'
          warning 'Make sure to keep the proper orientation'
          separator
          
          note "From Plate #{collection.id}"
          table highlight_collection_rc(collection, from_row) { |r,c| c }
          note "To thermocycler #{thermocycler.model}"
          table highlight_tube_rack_rcx(thermocycler_rack, to_row_rcx)
        end
      end
    end
    
    show do
      title 'Close and Start Thermocycler'
      note thermocycler.close_lid
      image thermocycler.close_lid_image
      separator

      note thermocycler.start_run
      if experiment_filename.present?
        note thermocycler.save_experiment_file(filename: experiment_filename)
      end
    end
  end

  def associate_measurement(file_name:, plate:)
    file = uploadData(file_name, 1, 4)
    plate.associate(RAW_QPCR_DATA_KEY, file)
  end

  def go_to_thermocycler(thermocycler_name:, plates: nil)
    show do
      title 'Go to Thermocycler'
      if plates
        note "Take plates to #{thermocycler_name}"
        plates.each do |plate|
          note "#{plate.object_type.name} <b>#{plate.id}</b>"
        end
      end
      note "Complete the next few steps at Thermocycler #{thermocycler_name}"
    end
  end

  def get_available_thermocyclers
    thermocyclers = find_thermocyclers
    available_key = 'available'
    response = show {
      title 'Check Available Thermocyclers'
      note 'Please check which thermocyclers are currently available'
      thermocyclers.each { |thermo|
        select [ available_key, 'unavailable' ], var: thermo['name'], label: "Thermocycler #{thermo['name']}", default: 1
      }
    }
    available_thermo = []
    thermocyclers.map do |thermo|
      next unless response[thermo['name'].to_sym].to_s == available_key || debug
      available_thermo.push(thermo)
    end
    available_thermo
  end

  def find_thermocyclers
    Parameter.where(key: 'thermocycler').map { |thr| JSON.parse(thr.value) }
  end

  def remove_unpaired_operations(ops)
    ops_to_remove = []
    ops.each do |op|
      if op.get(THERMOCYCLER_KEY).nil?
        op.error(:unavailablethermocycler, 'No thermocyclers were available')
        op.status = 'pending'
        op.save
        ops_to_remove.push(op)
      end
    end
    error_op_warning(ops_to_remove) unless ops_to_remove.empty?
  end

  def error_op_warning(ops_to_remove)
    show do
      title 'Thermocyclers Unavailable'
      note 'There are not enough available thermocyclers for this job'
      note 'Please ensure the following plates remain in the freezer until a thermocycler is available'
      ops_to_remove.each do |op|
        note "#{op.input(PLATE).collection.id} at #{op.input(PLATE).collection.location}"
      end
    end
  end
    
  # TODO: Assumes that if the operations are in the same job that they will fit onto one thermocycler
  # Not a totally valid assumtion but for now it will do.
  def pair_ops_and_thermocyclers(thermocyclers, ops)
    paired_ops = []
    ops.group_by(&:plan).each do |_plan, ops|
      thermocyclers.each do |thermo|
        next unless thermo['model'] == ops.first.temporary[:options][:thermocycler_model]
        
        ops.each do |op|
            op.associate(THERMOCYCLER_KEY, thermo)
            paired_ops.push(op)
        end
        thermocyclers.delete(thermo)
        break
      end
    end
    paired_ops.extend(OperationList)
  end

  class UnavailableThermocycler < ProtocolError; end

  ########## NAMING METHODS ##########

  # Constructs a name for the experiment file.
  #
  # @return [String]
  def experiment_filename(plan)
    date = DateTime.now.strftime('%Y-%m-%d')
    "#{date}_Job_#{job.id}_#{plan.id}"
  end

  # Gets the currently active `Job`
  #
  # @return [Job]
  def job
    operation_ids = operations.map(&:id)
    ja_ids = JobAssociation.where(operation_id: operation_ids).map(&:job_id).uniq
    jobs = Job.find(ja_ids).select(&:active?)
    raise ProtocolError, 'Cannot resolve the current Job' if jobs.length > 1

    jobs.last
  end
end
