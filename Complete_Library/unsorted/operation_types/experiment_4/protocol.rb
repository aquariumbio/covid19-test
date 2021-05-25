# typed: false
# frozen_string_literal: true

# This is a default, one-size-fits all protocol that shows how you can
# access the inputs and outputs of the operations associated with a job.
# Add specific instructions for this protocol!

needs 'Standard Libs/Debug'
needs 'Unsorted/ImportPartLibs'

class Protocol
  include Debug
  include ImportPartLibs

  CONCENTRATION = [0,0,3000,3000,3000, 7500, 7500, 7500].freeze
  STRIPWELL = '8 Well Stripwell'
  EXPERIMENT = "Experiment 4"

  def kit_contents
    {
      kit_1_8:{
        samples: ['DNA Aliquot', 'RNA Aliquot', 'Virus Aliquot'],
        primer_probes: [],
        rehydration_buffer: { sample: 'Molecular Grade Water', object_type: 'Reagent Bottle' }
      },
      kit_13_18: {
        samples: ['DNA Aliquot', 'RNA Aliquot'],
        primer_probes: [],
        rehydration_buffer: { sample: 'Molecular Grade Water', object_type: 'Reagent Bottle' }
      }
    }
  end

  def main
    kit_warning
    
    kit_numbers = []
    get_num_kits(EXPERIMENT).times { kit_numbers.push(get_kit_number) }
    
    contents_array = []
    kit_numbers.each do |kit_number|
        contents_array.push(
            { kit_number: kit_number,
              contents: get_contents(kit_number: kit_number, possible_kits: kit_contents)
            }
        )
    end
    
    created_parts = {primer_probe: [], sample: [], buffer: []}
    contents_array.each do |contents|
      kit_number = contents[:kit_number]
      created_parts[:sample] = create_multiple_items(samples: contents[:contents][:samples],
                                            experiment_number: EXPERIMENT,
                                            kit_number: kit_number,
                                            object_type: 'Nasopharyngeal Swab',
                                            concentrations: CONCENTRATION)

    end
    
    create_labels(parts_hash: created_parts)
    
    attatch_labels(created_parts: created_parts, experiment_number: EXPERIMENT)

    {}
  end
  
end