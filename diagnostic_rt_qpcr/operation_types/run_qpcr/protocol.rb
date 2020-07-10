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

  ########## DEFAULT PARAMS ##########

  # Default parameters that are applied equally to all operations.
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_job_params
    {
      thermocycler_model: TestThermocycler::MODEL,
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
    {}
  end

  ########## MAIN ##########

  def main
    setup_test_options(operations: operations) if debug

    @job_params = update_job_params(
      operations: operations,
      default_job_params: default_job_params
    )
    return {} if operations.errored.any?

    operations.retrieve.make

    available_thermocyclers = Parameter.where(key: 'thermocycler').map do |thermo|
      JSON.parse(thermo.value)
    end

    inspect available_thermocyclers.length.to_s

    operations.each_slice(available_thermocyclers.length).each do |ops_list|

      composition = PCRCompositionFactory.build(
        program_name: @job_params[:program_name]
      )
      program = PCRProgramFactory.build(
        program_name: @job_params[:program_name],
        volume: composition.volume
      )

      available_thermocyclers.zip(ops_list).each_with_index do |thermo_type, op, idx|
        break if op.nil?

        plate = op.input(INPUT_REACTIONS).item

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
          experiment_filename: experiment_filename
        )

        export_measurements(thermocycler: thermocycler)

        associate_measurement(file_name: experiment_filename, plate: plate)
      end

    end

    operations.store

    {}
  end

  def associate_measurement(file_name:, plate:)
    file = upload_data(file_name, 1, 4)
    plate.associate(RAW_QPCR_DATA_KEY, file)
  end

  def go_to_thermocycler(thermocycler_name:, plate:)
    show do
      title 'Go to Thermocycler'
      note "Take #{plate.object_type.name} <b>#{plate.id}</b>"\
           "to Thermocycler #{thermocycler_name}"
      note "Complete the next few steps at Thermocycler #{thermocycler_name}"
    end
  end

  ########## NAMING METHODS ##########

  # Constructs a name for the experiment file.
  #
  # @return [String]
  def experiment_filename
    date = DateTime.now.strftime('%Y-%m-%d')
    "#{date}_Job_#{job.id}"
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
