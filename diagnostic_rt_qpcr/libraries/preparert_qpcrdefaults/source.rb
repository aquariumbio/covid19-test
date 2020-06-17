# frozen_string_literal: true

module PrepareRT_qPCRDefaults

  OUTPUT_PLATE = 'PCR Plate'
  TEMPLATE = 'Template'
  OPTIONS = 'options'
  RESP_SAMPLE = 'Respiratory Sample'
  METHOD = 'Method'
  INPUT_PLATE = 'Input PCR Plate'

  # Default parameters that are applied equally to all operations.
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  def default_job_params
    {
      negative_template_location: 'NTC',
      negative_template_location: [0, 0],
      positive_template_control: 'nCoVPC',
      positive_template_location: [0, 11]
    }
  end


  def default_operation_params
    {
      'modified_rp_n2':{
        'max_inputs': 48,
        'group_size': 2,
        'parameters': {
          RESP_SAMPLE.to_sym{
              'parameter_name': RESP_SAMPLE,
              'input_output': 'input',
              'sample_type':[
                'Respiratory Specimen',
                'Simulated Respiratory Sample'
              ],
              'container':[
                'Rehydrated Nasopharyngeal Swab',
                'Spiked Simulated Sample'
              ]
          },
          INPUT_PLATE.to_sym {
            'parameter_name': INPUT_PLATE,
            'input_output': 'input',
            'sample_type':[
              'Lyophilized Primer Probe'
            ],
            'container':[
              'RP N2 Lyophilized PCR Plate'
            ]
          },
          output_plate.to_sym {
            'parameter_name': OUTPUT_PLATE,
            'input_output': 'output',
            'sample_type':[
              'Respiratory Specimen'
            ],
            'container':[
              '96-well qPCR Reaction'
            ]
          }
        }
      },
      'modified_n1':{
        'max_inputs': 48,
        'group_size': 1,
        'parameters': [
          {
            'parameter_name': RESP_SAMPLE,
            'input_output': 'input',
            'sample_type':[
              'Respiratory Specimen',
              'Simulated Respiratory Sample'
            ],
            'container':[
              'Rehydrated Nasopharyngeal Swab',
              'Spiked Simulated Sample'
            ]
          },
          {
            'parameter_name': INPUT_PLATE,
            'input_output': 'input',
            'sample_type':[
              'Lyophilized Primer Probe'
            ],
            'container':[
              'N1 Lyophilized PCR Plate'
            ]
          },
          {
            'parameter_name': OUTPUT_PLATE,
            'input_output': 'output',
            'sample_type':[
              'Simulated Respiratory Sample'
            ],
            'container':[
              '96-well qPCR Reaction'
            ]
          }
        ]
      },
      'standard':{
        'max_inputs': 24,
        'group_size': 3,
        'parameters': [
          {
            'parameter_name': RESP_SAMPLE,
            'input_output': 'input',
            'sample_type':[
              'RNA'
            ],
            'container':[
              'Purified RNA in 1.5 mL tube'
            ]
          },
          {
            'parameter_name': INPUT_PLATE,
            'input_output': 'input',
            'sample_type':[
              'qPCR Reaction'
            ],
            'container':[
              'Prepped 96 Well qPCR Plate'
            ]
          },
          {
            'parameter_name': OUTPUT_PLATE,
            'input_output': 'output',
            'sample_type':[
              'qPCR Reaction'
            ],
            'container':[
              '96-well qPCR Reaction'
            ]
          }
        ]
      }
    }
  end
end

# Checks that the inputs and outputs match proper format based on 
  # input parameters.
  #
  # @param operations [OperationList] list of operations
  # @raise rescue will Error any operations that do not pass
  # def validate_inputs(operations:)
  #   errored_operations = []
  #   operations.each do |op|
  #     method_parameters = get_parameters(operation: op)
      
  #     if op.input_array(RESP_SAMPLE).length +
  #        op.input_array(TEMPLATE).length >
  #        method_parameters[:max_inputs]

  #       errored_operations.push(op)
  #       raise IncompatibleInputsError, 'Too Many Inputs'
  #     end

  #     method_parameters[:parameters].each do |hash|
  #       fv = nil
  #       if hash[:input_output] == 'input'
  #         fv = op.input(hash[:parameter_name])
  #       else
  #         fv = op.output(hash[:parameter_name])
  #       end
  #       fv_sample_type = fv.sample_type.name
  #       fv_container = fv.object_type.name
  #       unless hash[:sample_type].include?(fv_sample_type) &&
  #              hash[:container].include?(fv_container)
  #         errored_operations.push(op)
  #         raise IncompatibleInputsError, 'Improper Inputs and outputs'
  #       end
  #     end
  #   end
  #   errored_operations
  # rescue IncompatibleInputsError => e
  #   error_operations(operations: errored_operations, err: e)
  #   errored_operations
  # end

  # def get_parameters(operation: op)
  #   method = operation.input(METHOD).to_s.downcase
  #   # TODO 2 pull operation_params not from default operations
  #   #    lookback to 'TODO 1'
  #   default_operation_params[method.to_sym]
  # end