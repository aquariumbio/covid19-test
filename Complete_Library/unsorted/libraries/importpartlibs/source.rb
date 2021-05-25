needs 'Standard Libs/Debug'

module ImportPartLibs
  include Debug
  
  
def attatch_labels(created_parts:, experiment_number:)
    kit_warning
    created_parts.each do |sample_type, parts_array|
      grouped_by_kit = parts_array.flatten.group_by { |item| item.get('kit_number') }
      grouped_by_kit.each do |kit_number, items|
        show do
          title 'Attatch labels to kit'
          note "Get the <b>#{sample_type}</b> foil packs from <b>#{experiment_number} Kit #{kit_number}</b>"
          note "<b> Keep Part on ice!</b>"
          note "Using a pair of scissors carefully open foil packs"
          separator
          note "Attach the following labels to the proper kit parts"
          note "It doesn't matter if which one the number goes to.  Just make sure the names match (e.g. DNA = DNA or RP = RP)"
          items.each do |item|
            note get_label(item).to_s
          end
        end
        show do
          title 'Return items to the freezer'
          note 'Return all items to the freezer'
          items.each do |item|
            note "#{get_label(item)} at #{item.location}"
          end
        end
      end
    end
  end
  
  def create_multiple_items(samples:, experiment_number:, kit_number:, object_type:, concentrations:)
    sample_array = []
    samples.each do |name|
       concentrations.each do |conc|
          sample_array.push("#{name} #{conc}") 
       end
    end

    items = []
    sample_array.each do |sample|
      items.push(create_items(sample_info: { sample: sample, object_type: object_type},
                   experiment_number: experiment_number,
                   kit_number: kit_number))
    end
    items
  end
  
  def create_labels(parts_hash:)
    show do
      title 'Create labels'
      note 'Get a roll of tape and a marker'
      note 'Create the following labels and stick them to the edge of your work bench'
      note 'We will use thes labels later so be sure not to lose them!'
    end
    parts_hash.each do |key, items|
      next unless items.present?
      show do
        title 'Create labels'
        note "Create #{key} labels"
        note 'Tear off a small piece of tape and write the following labels'
        separator
        items.flatten.each do |item|
          note get_label(item)
        end
      end
    end
  end
  
  def get_label(item)
    if item.collection?
      name = item.parts.first.sample.name
      if name.include?('N1') || name.include?('N2')
        name = name.partition('_').last
      else
        name = name.partition(' ').first
      end
      "#{item.id}-#{name}"
    elsif item.sample.name.include? 'Rehydration'
      "#{item.id}-buffer"
    else
      name = item.sample.name.partition(' ')
      "#{item.id}-#{name.first} #{name.last.partition(' ').last}"
    end
  end
  
  def create_items(sample_info:, experiment_number:, kit_number:)
    return [[]] if sample_info.nil?
    sample = Sample.find_by_name(sample_info[:sample])
    item = sample.make_item(sample_info[:object_type])
    add_metadata(item: item, experiment_number: experiment_number,
                 kit_number: kit_number)
    item.move_to('M20')
    [[item]]
  end
  
  def create_sample_stripwells(sample_names:,
                                     kit_number:,
                                     object_type_name:,
                                     experiment_number:,
                                     concentrations:)

    object_type = ObjectType.find_by_name(object_type_name)
    columns = object_type.columns
    
    sample_array = []
    sample_names.each do |name|
       sub_names = []
       concentrations.each do |conc|
          sub_names.push("#{name} #{conc}") 
       end
       sample_array.push(sub_names)
    end
    create_stripwells(object_type: object_type,
                      array_names: sample_array,
                      experiment_number: experiment_number,
                      kit_number: kit_number,
                      location: 'M80')
  end
  
  def create_primer_probe_stripwells(sample_names:,
                                     kit_number:,
                                     repeat_number:,
                                     object_type_name:,
                                     experiment_number:)
    object_type = ObjectType.find_by_name(object_type_name)
    columns = object_type.columns
    primer_probe_array = []
    sample_names.each do |name|
      repeat_number.times do
        primer_probe_array.push(Array.new(columns, name))
      end
    end
    create_stripwells(object_type: object_type,
                      array_names: primer_probe_array,
                      experiment_number: experiment_number,
                      kit_number: kit_number,
                      location: 'M20')
  end

  def create_stripwells(object_type:,
                      array_names:,
                      experiment_number:,
                      kit_number:,
                      location:)
    collections = []
    array_names.each do |names|
      collection = Collection.new_collection(object_type)
      collection.move_to(location)
      collections.push(collection)
      add_metadata(item: collection,
                   experiment_number: experiment_number,
                   kit_number: kit_number)
      collection.add_samples(names.map { |name| Sample.find_by_name(name) } )
    end
    if debug
        collections.each { |col| inspect col.parts.map { |item| item.sample.id }.to_s }
    end
    collections
  end

  def add_metadata(item:, experiment_number:, kit_number:)
    item.associate('experiment_number', experiment_number)
    item.associate('kit_number', kit_number)
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

  def get_contents(kit_number:, possible_kits:)
    possible_kits[get_kit_key(kit_number: kit_number)]
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

  def get_num_kits(experiment_number)
    num_kits = show do
      title 'Number of Kits'
      note "How many #{experiment_number} kits are you ingesting?"
      warning "This protocol only works for #{experiment_number} kits"
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
      note 'Work quickly and keep all parts on ICE'
      note 'Return parts to freezer <b>IMMEDIATELY</b> after use'
    end
  end

end