# frozen_string_literal: true

needs 'Standard Libs/Units'

# Provide program definitions for PCR
# @author Devin Strickland <strcklnd@uw.edu>
module PCRProgramDefinitions
  include Units

  PROGRAMS = {
    'qPCR1' => {
      program_template_name: 'NGS_qPCR1',
      layout_template_name: 'NGS_qPCR1',
      volume: 32,
      steps: {
        step1: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 3, units: MINUTES }
        },
        step2: {
          temperature: { qty: 98, units: DEGREES_C },
          duration: { qty: 15, units: SECONDS }
        },
        step3: {
          temperature: { qty: 62, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step4: {
          temperature: { qty: 72, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step5: { goto: 2, times: 34 },
        step6: {
          temperature: { qty: 12, units: DEGREES_C },
          duration: { qty: 'forever', units: '' }
        }
      }
    },

    'qPCR2' => {
      program_template_name: 'NGS_qPCR2',
      layout_template_name: 'NGS_qPCR1',
      volume: 50,
      steps: {
        step1: {
          temperature: { qty: 98, units: DEGREES_C },
          duration: { qty: 3, units: MINUTES }
        },
        step2: {
          temperature: { qty: 98, units: DEGREES_C },
          duration: { qty: 15, units: SECONDS }
        },
        step3: {
          temperature: { qty: 64, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step4: {
          temperature: { qty: 72, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step5: { goto: 2, times: 29 },
        step6: {
          temperature: { qty: 72, units: DEGREES_C },
          duration: { qty: 5, units: MINUTES }
        },
        step7: {
          temperature: { qty: 12, units: DEGREES_C },
          duration: { qty: 'forever', units: '' }
        }
      }
    },

    'lib_qPCR1' => {
      program_template_name: 'LIB_qPCR1',
      layout_template_name: 'LIB_qPCR',
      volume: 25,
      steps: {
        step1: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 3, units: MINUTES }
        },
        step2: {
          temperature: { qty: 98, units: DEGREES_C },
          duration: { qty: 15, units: SECONDS }
        },
        step3: {
          temperature: { qty: 65, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step4: {
          temperature: { qty: 72, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step5: { goto: 2, times: 34 },
        step6: {
          temperature: { qty: 72, units: DEGREES_C },
          duration: { qty: 5, units: MINUTES }
        },
        step7: {
          temperature: { qty: 12, units: DEGREES_C },
          duration: { qty: 'forever', units: '' }
        }
      }
    },

    'lib_qPCR2' => {
      program_template_name: 'LIB_qPCR2',
      layout_template_name: 'LIB_qPCR',
      volume: 50,
      steps: {
        step1: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 3, units: MINUTES }
        },
        step2: {
          temperature: { qty: 98, units: DEGREES_C },
          duration: { qty: 15, units: SECONDS }
        },
        step3: {
          temperature: { qty: 65, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step4: {
          temperature: { qty: 72, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step5: { goto: 2, times: 34 },
        step6: {
          temperature: { qty: 72, units: DEGREES_C },
          duration: { qty: 5, units: MINUTES }
        },
        step7: {
          temperature: { qty: 12, units: DEGREES_C },
          duration: { qty: 'forever', units: '' }
        }
      }
    },

    'illumina_qPCR_quantification' => {
      program_template_name: 'illumina_qPCR_quantification_v1',
      layout_template_name: 'illumina_qPCR_plate_layout_v1'
    },

    'CDC_TaqPath_CG' => {
      program_template_name: 'CDC_TaqPath_CG',
      layout_template_name: 'CDC_TaqPath_CG',
      volume: 20,
      steps: {
        step1: {
          temperature: { qty: 25, units: DEGREES_C },
          duration: { qty: 2, units: MINUTES }
        },
        step2: {
          temperature: { qty: 50, units: DEGREES_C },
          duration: { qty: 15, units: MINUTES }
        },
        step3: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 2, units: MINUTES }
        },
        step4: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 3, units: SECONDS }
        },
        step5: {
          temperature: { qty: 55, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step6: { goto: 4, times: 44 }
      }
    },

    'CDC_qScript_XLT_ToughMix' => {
      program_template_name: 'CDC_qScript_XLT_ToughMix',
      layout_template_name: 'CDC_qScript_XLT_ToughMix',
      volume: 20,
      steps:{
        step1: {
          temperature: { qty: 50, units: DEGREES_C },
          duration: { qty: 10, units: MINUTES }
        },
        step2: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 3, units: MINUTES }
        },
        step3: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 3, units: SECONDS }
        },
        step4: {
          temperature: { qty: 55, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step5: { goto: 3, times: 44 }
      }
    },

    'CDC_UltraPlex_ToughMix' => {
      program_template_name: 'CDC_UltraPlex_ToughMix',
      layout_template_name: 'CDC_UltraPlex_ToughMix',
      volume: 20,
      steps: {
        step1: {
          temperature: { qty: 50, units: DEGREES_C },
          duration: { qty: 10, units: MINUTES }
        },
        step2: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 3, units: MINUTES }
        },
        step3: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 3, units: SECONDS }
        },
        step4: {
          temperature: { qty: 55, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step5: { goto: 3, times: 44 }
      }
    },

    'CDC_GoTaq_Probe_1-Step' => {
      program_template_name: 'CDC_GoTaq_Probe_1-Step',
      layout_template_name: 'CDC_GoTaq_Probe_1-Step',
      volume: 20,
      steps: {
        step1: {
          temperature: { qty: 45, units: DEGREES_C },
          duration: { qty: 15, units: MINUTES }
        },
        step2: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 2, units: MINUTES }
        },
        step3: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 3, units: SECONDS }
        },
        step4: {
          temperature: { qty: 55, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step5: { goto: 3, times: 44 }
      }
    },
    
    'Modified_CDC_Exp_1' => {
      program_template_name: 'Modified_CDC',
      layout_template_name: 'Modified_CDC',
      volume: 20,
      steps: {
        step1: {
          temperature: { qty: 55, units: DEGREES_C },
          duration: { qty: 10, units: MINUTES }
        },
        step2: {
          temperature: { qty: 94, units: DEGREES_C },
          duration: { qty: 1, units: MINUTES }
        },
        step3: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 5, units: SECONDS }
        },
        step4: {
          temperature: { qty: 57, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step5: { 
          goto: 3, times: 50 
        }
      }
    },
    'Modified_CDC_Exp_3' => {
      program_template_name: 'Modified_CDC',
      layout_template_name: 'Modified_CDC',
      volume: 20,
      steps: {
        step1: {
          temperature: { qty: 55, units: DEGREES_C },
          duration: { qty: 10, units: MINUTES }
        },
        step2: {
          temperature: { qty: 94, units: DEGREES_C },
          duration: { qty: 1, units: MINUTES }
        },
        step3: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 5, units: SECONDS }
        },
        step4: {
          temperature: { qty: 57, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step5: { 
          goto: 3, times: 50 
        }
      }
    }
  }.freeze

  private_constant :PROGRAMS

  # Gets the Hash that defines the program for the given name
  #
  # @param name [String]
  # @return [Hash]
  def get_program_def(name:)
    PROGRAMS[name]
  end
end
