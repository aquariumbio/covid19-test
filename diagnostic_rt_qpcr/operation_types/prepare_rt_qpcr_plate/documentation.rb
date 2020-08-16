  # Default parameters that are applied equally to all operations.
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_job_params
    {
      max_inputs: 24
    }
  end

  # Default parameters that are applied to individual operations.
  #   Can be overridden by:
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_operation_params
    {
      negative_template_control: nil,
      negative_template_location: nil,
      positive_template_control: 'nCoVPC',
      positive_template_location: [0, 7],
      program_name: 'Modified_CDC',
      group_size: 3,
      layout_method: 'modified_sample_layout'
    }
  end