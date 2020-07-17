# frozen_string_literal: true

needs 'PCR Libs/PCRComposition'
needs 'PCR Libs/PCRProgram'
needs 'Thermocyclers/Thermocyclers'
needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'
needs 'Standard Libs/UploadHelper'
needs 'Diagnostic RT-qPCR/DataAssociationKeys'

# Protocol for loading samples into a qPCR thermocycler and running it
#
# @author Devin Strickland <strcklnd@uw.edu>
# @todo Decide whether this is actually qPCR specific
class Protocol
  include ThermocyclerHelper
  include PlanParams
  include Debug
  include UploadHelper
  include DataAssociationKeys

  INPUT_REACTIONS = 'qPCR Reactions'

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

    available_thermocyclers = get_available_thermocyclers

    remove_unavailable_operations(available_thermocyclers)

    return {} if operations.empty?

    operations.retrieve.make

    composition = PCRCompositionFactory.build(
      program_name: @job_params[:program_name]
    )
    program = PCRProgramFactory.build(
      program_name: @job_params[:program_name],
      volume: composition.volume
    )

    running_thermocyclers = start_thermocyclers(program: program,
                                                composition: composition)

    get_data(running_thermocyclers: running_thermocyclers)

    operations.store

    {}
  end

  def get_data(running_thermocyclers:)
    running_thermocyclers.each do |op, thermocycler|
      go_to_thermocycler(thermocycler_name: op.get(THERMOCYCLER_KEY)['name'])
      export_measurements(thermocycler: thermocycler)

      associate_measurement(file_name: op.get(RAW_QPCR_DATA_KEY),
                            plate: op.input(INPUT_REACTIONS).collection)
    end
  end

  def start_thermocyclers(program:, composition:)
    running_thermocyclers = []
    operations.each do |op|
      plate = op.input(INPUT_REACTIONS).item

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
    file = upload_data(file_name, 1, 4)
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
      thermocyclers.each_with_index do |thermo|
        select([available_key, 'unavailable'],
               var: thermo['name'].to_s,
               label: "Thermocycler #{thermo['name']}")
      end
    end
    available_thermo = []
    thermocyclers.map do |thermo|
      next unless response[thermo['name'].to_s] == available_key || debug

      available_thermo.push(thermo)
    end
    available_thermo
  end

  def find_thermocyclers
    Parameter.where(key: 'thermocycler').map { |thr| JSON.parse(thr.value) }
  end

  def remove_unavailable_operations(available_thermocyclers)
    ops_to_remove = find_unavailable_ops(available_thermocyclers)
    operations.reject! { |op| ops_to_remove.include?(op) }
    error_op_warning(ops_to_remove)
    ops_to_remove.each do |op|
      op.error(:unavailablethermocycler, 'No thermocyclers were available')
      op.set_status_recursively('pending')
    end
  end

  def error_op_warning(ops_to_remove)
    show do
      title 'Thermocyclers Unavailable'
      note 'There are not enough available thermocyclers for this job'
      warning 'The following plates were removed from this job'
      ops_to_remove.each do |op|
        note op.input(INPUT_REACTIONS).collection.id.to_s
      end
    end
  end

  def find_unavailable_ops(thermocyclers)
    ops_to_remove = []
    operations.each do |op|
      available = false
      thermocyclers.each do |thermo|
        next unless thermo['model'] == op.temporary[:options][:thermocycler_model] || true

        op.associate(THERMOCYCLER_KEY, thermo)
        thermocyclers.delete(thermo)
        available = true
        break
      end
      ops_to_remove.push(op) unless available 
    end
    ops_to_remove
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
