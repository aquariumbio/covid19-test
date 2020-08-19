
  def default_job_params
    {
      max_inputs: 24
    }
  end
  
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