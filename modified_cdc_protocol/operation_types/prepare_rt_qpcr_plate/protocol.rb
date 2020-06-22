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

  PRIMER_SET = 'Primer Set'

  def default_rp_n2_params
    {
      primer_set: 'RP_N2',
      max_inputs: 48,
      group_size: 2,
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

  def default_n1_params
    {
      primer_set: 'N1',
      max_inputs: 96,
      group_size: 1,
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
      if op.input(PRIMER_SET).to_s == default_rp_n2_params[:primer_set]
        default_job_params = default_rp_n2_params
      elsif op.input(PRIMER_SET).to_s == default_n1_params[:primer_set]
        default_job_params = default_n1_params
      else
        message = 'Invalid Primer Set Parameter'
        op.error(:IncompatibleInputsError, message)
        display_error([{
          op: op,
          error: message
        }])
        next
      end

      run_job(default_job_params: default_job_params,
              default_operation_params: default_operation_params,
              op: op)
    end

    operations.store

    {}
  end
end
