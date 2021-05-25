# frozen_string_literal: true

needs 'Standard Libs/Units'
needs 'Standard Libs/CommonInputOutputNames'

# Provice composition definitions for PCR reactions
# @author Devin Strickland <strcklnd@uw.edu>
module PCRCompositionDefinitions
  include Units
  include CommonInputOutputNames

  POLYMERASE = 'Polymerase'
  DYE = 'Dye'
  WATER = 'Molecular Grade Water'
  MASTER_MIX = 'Master Mix'
  PRIMER_PROBE_MIX = 'Primer/Probe Mix'

  COMPONENTS = {
    # qPCR2: 2nd qPCR in NGS prep.
    'qPCR1' => {
      polymerase: {
        input_name: POLYMERASE,
        qty: 16, units: MICROLITERS,
        sample_name: 'Kapa HF Master Mix'
      },
      forward_primer: {
        input_name: FORWARD_PRIMER,
        qty: 0.16,  units: MICROLITERS
      },
      reverse_primer: {
        input_name: REVERSE_PRIMER,
        qty: 0.16,  units: MICROLITERS
      },
      dye: {
        input_name: DYE,
        qty: 1.6, units: MICROLITERS,
        sample_name: 'Eva Green'
      },
      water: {
        input_name: WATER,
        qty: 6.58, units: MICROLITERS
      },
      template: {
        input_name: TEMPLATE,
        qty: 7.5, units: MICROLITERS
      }
    },

    # qPCR2: 2nd qPCR in NGS prep.
    #   Reverse primer is indexed primer.
    'qPCR2' => {
      polymerase: {
        input_name: POLYMERASE,
        qty: 25, units: MICROLITERS,
        sample_name: 'Kapa HF Master Mix'
      },
      forward_primer: {
        input_name: FORWARD_PRIMER,
        qty: 2.5, units: MICROLITERS
      },
      reverse_primer: {
        input_name: REVERSE_PRIMER,
        qty: 2.5, units: MICROLITERS
      },
      dye: {
        input_name: DYE,
        qty: 2.5, units: MICROLITERS,
        sample_name: 'Eva Green'
      },
      water: {
        input_name: WATER,
        qty: 15.5, units: MICROLITERS
      },
      template: {
        input_name: TEMPLATE,
        qty: 2, units: MICROLITERS
      }
    },

    # LIBqPCR1: 1st qPCR in Libray prep.
    #   If sublibrary primers exist they are used here.
    'lib_qPCR1' => {
      polymerase: {
        input_name: POLYMERASE,
        qty: 12.5, units: MICROLITERS,
        sample_name: 'Kapa HF Master Mix'
      },
      forward_primer: {
        input_name: FORWARD_PRIMER,
        qty: 0.75, units: MICROLITERS
      },
      reverse_primer: {
        input_name: REVERSE_PRIMER,
        qty: 0.75, units: MICROLITERS
      },
      dye: {
        input_name: DYE,
        qty: 1.25, units: MICROLITERS,
        sample_name: 'Eva Green'
      },
      water: {
        input_name: WATER,
        qty: 8.75, units: MICROLITERS
      },
      template: {
        input_name: TEMPLATE,
        qty: 1, units: MICROLITERS
      }
    },

    # LIBqPCR2: 2nd qPCR in Libray prep.
    #   Overhangs compatible with cloning vector are added here.
    'lib_qPCR2' => {
      polymerase: {
        input_name: POLYMERASE,
        qty: 25, units: MICROLITERS,
        sample_name: 'Kapa HF Master Mix'
      },
      forward_primer: {
        input_name: FORWARD_PRIMER,
        qty: 1.5, units: MICROLITERS
      },
      reverse_primer: {
        input_name: REVERSE_PRIMER,
        qty: 1.5, units: MICROLITERS
      },
      dye: {
        input_name: DYE,
        qty: 2.5, units: MICROLITERS,
        sample_name: 'Eva Green'
      },
      water: {
        input_name: WATER,
        qty: 17.5, units: MICROLITERS
      },
      template: {
        input_name: TEMPLATE,
        qty: 2, units: MICROLITERS
      }
    },

    # CDC COVID-19 detection protocol
    'CDC_TaqPath_CG' => {
      water: {
        input_name: WATER,
        qty: 13.5, units: MICROLITERS
      },
      primer_probe_mix: {
        input_name: PRIMER_PROBE_MIX,
        qty: 1.5, units: MICROLITERS
      },
      master_mix: {
        input_name: MASTER_MIX,
        qty: 2.0, units: MICROLITERS,
        sample_name: 'TaqPath 1-Step RT-qPCR Master Mix (4x)'
      },
      template: {
        input_name: TEMPLATE,
        qty: 2.0, units: MICROLITERS
      }
    },

    # CDC COVID-19 detection protocol
    'CDC_qScript_XLT_ToughMix' => {
      water: {
        input_name: WATER,
        qty: 11.5, units: MICROLITERS
      },
      primer_probe_mix: {
        input_name: PRIMER_PROBE_MIX,
        qty: 1.5, units: MICROLITERS
      },
      master_mix: {
        input_name: MASTER_MIX,
        qty: 5.0, units: MICROLITERS,
        sample_name: 'qScript XLT One-Step RT-qPCR ToughMix (2X)'
      },
      template: {
        input_name: TEMPLATE,
        qty: 2.0, units: MICROLITERS
      }
    },

    # CDC COVID-19 detection protocol
    'CDC_UltraPlex_ToughMix' => {
      water: {
        input_name: WATER,
        qty: 11.5, units: MICROLITERS
      },
      primer_probe_mix: {
        input_name: PRIMER_PROBE_MIX,
        qty: 1.5, units: MICROLITERS
      },
      master_mix: {
        input_name: MASTER_MIX,
        qty: 5.0, units: MICROLITERS,
        sample_name: 'UltraPlex 1-Step ToughMix (4X)'
      },
      template: {
        input_name: TEMPLATE,
        qty: 2.0, units: MICROLITERS
      }
    },

    # CDC COVID-19 detection protocol
    'CDC_GoTaq_Probe_1-Step' => {
      water: {
        input_name: WATER,
        qty: 6.1, units: MICROLITERS
      },
      primer_probe_mix: {
        input_name: PRIMER_PROBE_MIX,
        qty: 1.5, units: MICROLITERS
      },
      master_mix: {
        input_name: MASTER_MIX,
        qty: 10, units: MICROLITERS,
        sample_name: 'GoTaq Probe qPCR Master Mix with dUTP'
      },
      rt_mix: {
        input_name: 'RT Mix',
        qty: 0.4, units: MICROLITERS,
        sample_name: 'Go Script RT Mix for 1-Step RT-qPCR'
      },
      template: {
        input_name: TEMPLATE,
        qty: 2.0, units: MICROLITERS
      }
    },
    # Modified CDC COVID-19 detection protocol
    'Modified_CDC_Exp_1' => {
      template: {
        input_name: TEMPLATE,
        qty: 2.0, units: MICROLITERS
      },
      primer_probe_mix: {
        input_name: PRIMER_PROBE_MIX,
        qty: 0.0, units: MICROLITERS
      },
      master_mix: {
          input_name: MASTER_MIX,
          qty: 18, units: MICROLITERS,
          sample_name: 'Rehydration Buffer'
      }
    },
    'Modified_CDC_Exp_3' => {
      template: {
        input_name: TEMPLATE,
        qty: 20.0, units: MICROLITERS
      },
      primer_probe_mix: {
        input_name: PRIMER_PROBE_MIX,
        qty: 0.0, units: MICROLITERS
      },
      master_mix: {
          input_name: MASTER_MIX,
          qty: 0.0, units: MICROLITERS,
          sample_name: 'Rehydration Buffer'
      }
    }
  }.freeze

  private_constant :COMPONENTS

  # Gets the Hash that defines the compostion for the given name
  #
  # @param name [String]
  # @return [Hash]
  def get_composition_def(name:)
    COMPONENTS[name]
  end
end
