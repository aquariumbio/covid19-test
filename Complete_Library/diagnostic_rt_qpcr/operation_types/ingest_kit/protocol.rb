# typed: false
# frozen_string_literal: true

# This is a default, one-size-fits all protocol that shows how you can
# access the inputs and outputs of the operations associated with a job.
# Add specific instructions for this protocol!

needs 'Standard Libs/Debug'

class Protocol
  include Debug

  CONCENTRATION_A = [0,0,0,50,50,50,100,100,100,1000,1000,1000].freeze
  CONCENTRATION_B = [0,0,50,50,50,100,100,100,1000,1000].freeze
  CONCENTRATION_C = [0,0,3000,3000,7500,7500].freeze

  def kit_contents
    {
      experiment_1: {
        kit_1_8: {
          columns: 12,
          samples: [
            { sample: 'DNA Aliquot', row: 1, concentration: CONCENTRATION_A },
            { sample: 'RNA Aliquot', row: 3, concentration: CONCENTRATION_A },
            { sample: 'Virus Aliquot', row: 5, concentration: CONCENTRATION_A }
          ],
          primer_probes: [
            { sample: 'RP', row: 1 },
            { sample: 'RP', row: 3 },
            { sample: 'RP', row: 5 },
            { sample: '2019-nCoVPC_N1', row: 1 },
            { sample: '2019-nCoVPC_N1', row: 3 },
            { sample: '2019-nCoVPC_N1', row: 5 },
            { sample: '2019-nCoVPC_N2', row: 1 },
            { sample: '2019-nCoVPC_N2', row: 3 },
            { sample: '2019-nCoVPC_N2', row: 5 }
          ],
          other: [
            { sample: 'Rehydration Buffer', object_type: '5ml Bottle' }
          ]
        },
        kit_13_18: {
          columns: 12,
          samples: [
            { sample: 'DNA Aliquot', row: 1, concentration: CONCENTRATION_A },
            { sample: 'RNA Aliquot', row: 3, concentration: CONCENTRATION_A }
          ],
          primer_probes: [
            { sample: 'RP', row: 1 },
            { sample: 'RP', row: 3 },
            { sample: '2019-nCoVPC_N1', row: 1 },
            { sample: '2019-nCoVPC_N1', row: 3 },
            { sample: '2019-nCoVPC_N2', row: 1 },
            { sample: '2019-nCoVPC_N2', row: 3 }
          ],
          other: [
            { sample: 'Rehydration Buffer', object_type: '5ml Bottle' }
          ]
        }
      },
      experiment_2: {
        kit_1_8: {
          columns: 12,
          samples: [
            { sample: 'DNA Aliquot', row: 1, concentration: CONCENTRATION_B },
            { sample: 'RNA Aliquot', row: 3, concentration: CONCENTRATION_B }
          ],
          primer_probes: [],
          other: []
        },
        kit_13_18: {
          columns: 12,
          samples: [
            { sample: 'DNA Aliquot', row: 1, concentration: CONCENTRATION_B },
            { sample: 'RNA Aliquot', row: 3, concentration: CONCENTRATION_B }
          ],
          primer_probes: [],
          other: []
        }
      },
      experiment_3: {
        kit_1_8: {
          columns: 8,
          samples: [
            { sample: 'DNA Aliquot', row: 1, concentration: CONCENTRATION_C, swab: true },
            { sample: 'RNA Aliquot', row: 3, concentration: CONCENTRATION_C, swab: true },
            { sample: 'Virus Aliquot', row: 5, concentration: CONCENTRATION_C, swab: true }
          ],
          primer_probes: [
            { sample: 'RP', row: 1 },
            { sample: 'RP', row: 3 },
            { sample: 'RP', row: 5 },
            { sample: '2019-nCoVPC_N1', row: 1 },
            { sample: '2019-nCoVPC_N1', row: 3 },
            { sample: '2019-nCoVPC_N1', row: 5 },
            { sample: '2019-nCoVPC_N2', row: 1 },
            { sample: '2019-nCoVPC_N2', row: 3 },
            { sample: '2019-nCoVPC_N2', row: 5 }
          ],
          other: [
            { sample: 'Rehydration Buffer', object_type: '5ml Bottle' }
          ]
        },
        kit_13_18: {
          columns: 8,
          samples: [
            { sample: 'DNA Aliquot', row: 1, concentration: CONCENTRATION_C, swab: true },
            { sample: 'RNA Aliquot', row: 3, concentration: CONCENTRATION_C, swab: true }
          ],
          primer_probes: [
            { sample: 'RP', row: 1 },
            { sample: 'RP', row: 3 },
            { sample: '2019-nCoVPC_N1', row: 1 },
            { sample: '2019-nCoVPC_N1', row: 3 },
            { sample: '2019-nCoVPC_N2', row: 1 },
            { sample: '2019-nCoVPC_N2', row: 3 }
          ],
          other: [
            { sample: 'Rehydration Buffer', object_type: '5ml Bottle' }
          ]
        }
      },
      experiment_4: {
        kit_1_8: {
          columns: 12,
          samples: [
            { sample: 'Virus Aliquot', row: 1, concentration: CONCENTRATION_C, swab: true }
          ],
          primer_probes: [],
          other: []
        },
        kit_13_18: {
          columns: 12,
          samples: [
            { sample: 'DNA Aliquot', row: 1, concentration: CONCENTRATION_C, swab: true }
          ],
          primer_probes: [],
          other: []
        }
      }
    }
  end

  def main
    kit_warning

    get_num_kits.times do
      kit_number = get_kit_number
      experiment_number = get_experiment_number

      kit_contents = get_contents(kit_number: kit_number,
                                  experiment_number: experiment_number)
      num_columns = kit_contents[:columns]

      inspect kit_contents if debug

      create_and_label_stripwells(parts: kit_contents[:primer_probes],
                                  num_columns: num_columns,
                                  kit_number: kit_number,
                                  experiment_number: experiment_number)

      create_and_label_samples(parts: kit_contents[:samples],
                               kit_number: kit_number,
                               experiment_number: experiment_number)
      create_and_label_buffer(parts: kit_contents[:other],
                              kit_number: kit_number,
                              experiment_number: experiment_number)
    end

    {}
  end

  def create_and_label_buffer(parts:, kit_number:, experiment_number:)
    parts.each do |part|
      sample = Sample.find_by_name(part[:sample])
      item = Item.make({ quantity: 1, inuse: 0 }, sample: sample, object_type: ObjectType.find_by(name: part[:object_type]))

      show do
        title 'Label Item'
        note "#{sample.name} from kit #{experiment_number} #{kit_number}"
        note "Using a small piece of tape label with ID: #{item.id}"
        note "Return to kit"
      end
    end
  end

  def create_and_label_samples(parts:, kit_number:, experiment_number:)
    parts.each do |part|
      sample_name_prefix = part[:sample]
      row = part[:row]
      part[:concentration].each_with_index do |concentration, column|
        item = create_item(sample_name_prefix: sample_name_prefix,
                           concentration: concentration,
                           swab: part[:swab])
        add_metadata(item: item, kit_number: kit_number,
                     experiment_number: experiment_number)
        label_item(item: item,
                   row_location: row,
                   column: column,
                   kit_number: kit_number,
                   experiment_number: experiment_number)
      end
    end
  end

  def create_item(sample_name_prefix:, concentration:, swab:)
    samp = Sample.find_by_name(sample_name_prefix + ' ' + concentration.to_s)

    object_type_name = if swab
      'Nasopharyngeal Swab'
    elsif sample_name_prefix.include? 'DNA'
      'Purified DNA in 1.5 ml Tube'
    elsif sample_name_prefix.include? 'RNA'
      'Purified RNA in 1.5 ml Tube'
    elsif sample_name_prefix.include? 'Virus'
      'Virus Aliquot'
    else
      raise "Invalid sample type name prefix #{sample_name_prefix}"
    end

    samp.make_item(object_type_name)
  end

  def create_and_label_stripwells(parts:, num_columns:,
                                  kit_number:, experiment_number:)
    parts.each do |part|
      sample_name = part[:sample]
      row_location = part[:row]
      stripwell = create_stripwell(sample_name, num_columns)
      add_metadata(item: stripwell, experiment_number: experiment_number, kit_number: kit_number)
      label_item(item: stripwell,
                 row_location: row_location,
                 kit_number: kit_number,
                 experiment_number: experiment_number)
    end
  end

  def add_metadata(item:, experiment_number:, kit_number:)
    item.associate('experiment_number', experiment_number)
    item.associate('kit_number', kit_number)
  end

  def label_item(item:, row_location:, kit_number:, experiment_number:, column: nil)
    item = item.collection? ? item.parts.first : item
    sample_name = item.sample.name
    column = 'ANYWHERE' unless column

    show do
      title 'Create Label'
      note "On a small piece of tape write #{item.id}"
    end

    show do
      title 'Preview of the Next Step'
      note 'This is a preview of the next page.'
      note 'The next steps should be done as quickly as possible!'
      note '1) Pull the correct stripwell from the freezer'
      note '2) Stick label on the stripwell at the indicated well'
      note '3) Put Stripwell back in freezer'
      separator
      note 'Remember label should NEVER go on the lids'
    end

    show do
      title 'Label Part'
      note "Kit: <b>Experiment #{experiment_number}  Kit #{kit_number}</b>"
      note "Plate: <b>#{sample_name}</b>"
      note "Row: <b>#{row_location}</b>"
      note "Column: <b>#{column}</b>"
      separator
      note "Attach label #{item.id}"
      note 'Return stripwell to freezer!'
    end
  end

  def create_stripwell(sample_name, num_columns)
    samples = Array.new(num_columns, Sample.find_by_name(sample_name))
    stripwell = Collection.new_collection(ObjectType.find_by_name("#{num_columns} Well Stripwell"))
    stripwell.add_samples(samples)
    stripwell
  end

  def get_kit_number
    exp_num = show do
      title 'Get Kit Number'
      get('number',
        var: 'kit_num',
        label: "Record Kit Number",
        default: 0)
    end
    return [1,2,3,4,5,6,7,8,13,14,15,16,17,18].sample if debug
    exp_num[:kit_num]
  end

  def get_experiment_number
    exp_num = show do
      title 'Get Experiment number'
      note 'Record the Kit Experiment Number'
      select [1,2,3,4], var: 'exp_num', default: 0
    end
    return [1,2,3,4].sample if debug
    exp_num[:exp_num]
  end

  def get_contents(kit_number:, experiment_number:)
    experiment_key = "experiment_#{experiment_number}".to_sym
    kit_key = get_kit_key(kit_number: kit_number)
    kit_contents[experiment_key][kit_key]
  end

  def get_kit_key(kit_number:)
    if (1...9).to_a.include? kit_number
      return 'kit_1_8'.to_sym
    elsif (13...19).to_a.include? kit_number
      return 'kit_13_18'.to_sym
    else
      raise 'invalid kit number'
    end
  end

  def get_num_kits
    num_kits = show do
      title 'Number of Kits'
      note 'How many kits are you ingesting?'
      get('number',
          var: 'num_kits',
          label: "Number of Kits",
          default: 0)
    end
    return operations.length if debug
    num_kits[:num_kits]
  end

  def kit_warning
    show do
      title 'Avoid Freeze Thaw Cycles'
      warning 'Kits contain RNA, DNA, and/or Simulated Virus'
      note 'Avoid thawing any part of the kits.  Work quickly and avoid thawing kit parts'
    end
  end

end
