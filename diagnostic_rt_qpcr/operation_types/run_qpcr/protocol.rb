# frozen_string_literal: true

needs 'PCR Libs/PCRComposition'
needs 'PCR Libs/PCRProgram'
needs 'Thermocyclers/Thermocyclers'
needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'
needs 'Standard Libs/UploadHelper'
needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'
needs 'Diagnostic RT-qPCR/DataAssociationkeys'

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
      program_name: 'CDC_TaqPath_CG',
      qpcr: true
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

    running_thermocyclers = start_thermocyclers(paired_ops)

    get_data(running_thermocyclers: running_thermocyclers)
    
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
        title 'Spin Down' + ' Plates'.pluralize(paired_ops.length)
        note 'Spin down the following' + ' plate'.pluralize(paired_ops.length)
        paired_ops.each do |op|
          note op.input(PLATE).collection.id.to_s
        end
      end
  end

  def get_data(running_thermocyclers:)
    running_thermocyclers.each do |op, thermocycler|
      go_to_thermocycler(thermocycler_name: op.get(THERMOCYCLER_KEY)['name'])
      export_measurements(thermocycler: thermocycler)

      associate_measurement(file_name: op.get(RAW_QPCR_DATA_KEY),
                            plate: op.input(PLATE).collection)
    end
  end

  def start_thermocyclers(paired_ops)
    composition = PCRCompositionFactory.build(
      program_name: @job_params[:program_name]
    )
    program = PCRProgramFactory.build(
      program_name: @job_params[:program_name]
    )

    running_thermocyclers = []
    paired_ops.each do |op|
      plate = op.input(PLATE).collection

      file_name = experiment_filename(plate)

      thermo_type = op.get(THERMOCYCLER_KEY)

      op.associate(RAW_QPCR_DATA_KEY, file_name)

      thermocycler = ThermocyclerFactory.build(
        model: thermo_type['model']
      )

      go_to_thermocycler(thermocycler_name: thermo_type['name'], plate: plate)

      set_up_program(
        thermocycler: thermocycler,
        program: program,
        composition: composition,
        qpcr: @job_params[:qpcr]
      )

      load_plate_and_start_run(
        thermocycler: thermocycler,
        items: plate,
        experiment_filename: file_name
      )
      running_thermocyclers.push([op, thermocycler])
    end
    running_thermocyclers
  end

  def associate_measurement(file_name:, plate:)
    file = uploadData(file_name, 1, 4)
    plate.associate(RAW_QPCR_DATA_KEY, file)
  end

  def go_to_thermocycler(thermocycler_name:, plate: nil)
    show do
      title 'Go to Thermocycler'
      note "Take the #{plate.object_type.name} <b>#{plate.id}</b>"\
           " to Thermocycler #{thermocycler_name}" unless plate.nil?
      note "Complete the next few steps at Thermocycler #{thermocycler_name}"
    end
  end

  def get_available_thermocyclers
    thermocyclers = find_thermocyclers
    available_key = 'available'
    response = show do
      title 'Check Available Thermocyclers'
      note 'Please check which thermocyclers are currently available'
      thermocyclers.each { |thermo|
        select [ available_key, 'unavailable' ], var: thermo['name'], label: "Thermocycler #{thermo['name']}", default: 1 }
    end
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

  def pair_ops_and_thermocyclers(thermocyclers, ops)
    paired_ops = []
    ops.each do |op|
      thermocyclers.each do |thermo|
        next unless thermo['model'] == op.temporary[:options][:thermocycler_model]

        op.associate(THERMOCYCLER_KEY, thermo)
        thermocyclers.delete(thermo)
        paired_ops.push(op)
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
  def experiment_filename(plate)
    date = DateTime.now.strftime('%Y-%m-%d')
    "#{date}_Job_#{job.id}_#{plate.id}"
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
