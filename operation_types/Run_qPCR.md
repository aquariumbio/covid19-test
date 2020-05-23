# Run qPCR

Documentation here. Start with a paragraph, not a heading or title, as in most views, the title will be supplied by the view.
### Inputs


- **qPCR Reactions** [P]  
  - <a href='#' onclick='easy_select("Sample Types", "qPCR Reaction")'>qPCR Reaction</a> / <a href='#' onclick='easy_select("Containers", "96-well qPCR Reaction")'>96-well qPCR Reaction</a>

### Parameters

- **Options** 

### Outputs


- **qPCR Reactions** [P]  
  - <a href='#' onclick='easy_select("Sample Types", "qPCR Reaction")'>qPCR Reaction</a> / <a href='#' onclick='easy_select("Containers", "96-well qPCR Reaction")'>96-well qPCR Reaction</a>

### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
def precondition(_op)
  true
end
```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
# frozen_string_literal: true

needs 'PCR Libs/PCRComposition'
needs 'PCR Libs/PCRProgram'
needs 'Thermocyclers/Thermocyclers'
needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'

# Protocol for loading samples into a qPCR thermocycler and running it
#
# @author Devin Strickland <strcklnd@uw.edu>
# @todo Decide whether this is actually qPCR specific
class Protocol
  include ThermocyclerHelper
  include PlanParams
  include Debug

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

    composition = PCRCompositionFactory.build(
      program_name: @job_params[:program_name]
    )
    program = PCRProgramFactory.build(
      program_name: @job_params[:program_name],
      volume: composition.volume
    )
    thermocycler = ThermocyclerFactory.build(
      model: @job_params[:thermocycler_model]
    )

    set_up_program(
      thermocycler: thermocycler,
      program: program,
      composition: composition,
      qpcr: @job_params[:qpcr]
    )

    load_plate_and_start_run(
      thermocycler: thermocycler,
      items: operations.map { |op| op.input(INPUT_REACTIONS).item },
      experiment_filename: experiment_filename
    )

    export_measurements(thermocycler: thermocycler)

    operations.store

    {}
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

```
