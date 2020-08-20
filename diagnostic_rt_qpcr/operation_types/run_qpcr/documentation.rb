   Default parameters that are applied equally to all operations.
     Can be overridden by:
     * Associating a JSON-formatted list of key, value pairs to the `Plan`.
     * Adding a JSON-formatted list of key, value pairs to an `Operation`
       input of type JSON and named `Options`.
  
  def default_job_params
    {
    }
  end

   Default parameters that are applied to individual operations.
     Can be overridden by:
     * Adding a JSON-formatted list of key, value pairs to an `Operation`
       input of type JSON and named `Options`.
  
  def default_operation_params
    {
      thermocycler_model: TestThermocycler::MODEL,
      program_name: 'CDC_TaqPath_CG',
      qpcr: true
    }
  end