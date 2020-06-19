# frozen_string_literal: true

needs 'Diagnostic RT-qPCR/PrepareRTqPCRValidation'
needs 'Diagnostic RT-qPCR/PrepareqPCRPlateHelper'

# Protocol for setting up a plate with extracted RNA samples
#
# @author Devin Strickland <strcklnd@uw.edu>
# @author Cannon Mallory <malloc3@uw.edu>
class Protocol
  include PrepareqPCRPlateHelper
  include PrepareRTqPCRValidation

  def default_job_params
    {
      primer_set: 'RP_N2',
      max_inputs: 24,
      group_size: 3,
      method: 'sample_layout'.to_sym, 
      additional_inputs: [
        # {
        #   name: nil,
        #   container: nil,
        #   station: 'bench'
        #   volume{
        #       qty: nil,
        #       units: MIROLITERS
        # }
      ],
      negative_controls: {
        name: 'NTC',
        first_well: [0, 0],
        station: 'negative_control station',
        volume: {
          qty: 5,
          units: MICROLITERS
        },
        additional_inputs: [
          # {
          #   name: nil,
          #   container: nil,
          #   station: nil,
          #   volume{
          #        qty: nil,
          #        units: MIROLITERS
          #   }
          # }
        ]
      },
      positive_controls:{
        name: 'nCoVPC',
        first_well: [0, 11],
        station: 'positive control station',
        volume: {
          qty: 5,
          units: MICROLITERS
        },
        additional_inputs: [
          # {
          #   name: nil,
          #   container: nil,
          #   station: nil,
          #   volume{
          #        qty: nil,
          #        units: MIROLITERS
          #   }
          # }
        ]
      },
      standard_samples: {
        station: 'sample handling station',
        volume: {
          qty: 5,
          units: MICROLITERS
        },
        additional_inputs: [
          # {
          #   name: nil,
          #   container: nil,
          #   station: nil,
          #   volume{
          #        qty: nil,
          #        units: MIROLITERS
          #   }
          # }
        ]
      }
    }
  end

  def default_operation_params
    {}
  end

  def main
    operations.reject!{ |op| validate(operations: operations).include?(op) }
    return {} if operations.empty?

    operations.retrieve

    operations.each do |op|
      run_job(default_job_params: default_job_params,
              default_operation_params: default_operation_params,
              op: op)
    end

    operations.store

    {}

  end
end
