# frozen_string_literal: true

needs 'Diagnostic RT-qPCR/PrepareRT_qPCR_Plate'

# Protocol for setting up a plate with extracted RNA samples
#
# @author Devin Strickland <strcklnd@uw.edu>
# @author Cannon Mallory <malloc3@uw.edu>
class Protocol
  include PrepareRT_qPCR_Plate

  def default_job_params
    {
      max_inputs: 24,
      group_size: 3,
      method: 'sample_layout'.to_sym,
      controls: {
        negative_controls:{
          name: 'NTC',
          location: [0, 0]
        },
        positive_controls: {
          name: 'nCoVPC',
          location: [0, 11]
        }
      },
      recipe: {
        additional_inputs: [
          {
            name: 'mgH2O',
            container: '800ml Bottle',
            volume: {
              qty: 5,
              units: MICROLITERS
            }
          }
        ],
        negative_controls: {
        },
        positive_controls: {
          volume: {
            qty: 5,
            units: MICROLITERS
          },
          location: 'positive control station',
          components: []
        },
        standard_samples: {
          volume: {
            qty: 5,
            units: MICROLITERS
          },
          location: 'Human Sample Station',
          components: [
            {
              name: 'mgH2O',
              container: '800ml Bottle',
              volume: {
                qty: 5,
                units: MICROLITERS
              }
            }
          ]
        }
      }
    }
  end

  def default_operation_params
    {}
  end

  def main
    run_job(default_job_params: default_job_params,
            default_operation_params: default_operation_params,
            operations: operations)
  end
  
end
