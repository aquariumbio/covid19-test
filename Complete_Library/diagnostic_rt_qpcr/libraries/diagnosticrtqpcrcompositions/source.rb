# typed: false
# frozen_string_literal: true

needs 'PCR Libs/PCRComposition'

# Module for working with PCRCompositions used in Diagnostic RT qPCR
#
# @author Devin Strickland <strcklnd@uw.edu>
module DiagnosticRTqPCRCompositions
  include PCRCompositionDefinitions

  PRIMER_PROBE_MIX = 'Primer/Probe Mix'
  TEMPLATE = 'Template'

  # Initialize all `PCRComposition`s for each operation stripwell
  #
  # @param operations [OperationList]
  # @return [void]
  def build_stripwell_primer_probe_compositions(operations:)
    operations.each do |op|
      options = op.temporary[:options]
      program_name = options[:program_name]
      given_stripwells = options[:stripwell_id]
      stripwells = []
      if given_stripwells
        stripwells = Collection.find(given_stripwells)
      else
        stripwells = find_stripwells(sample_names: options[:sample_names],
                                     stripwell_ot: options[:object_type],
                                     rows: op.temporary[:microtiter_plate]
                                             .collection.dimensions[0],
                                     num_stripwells: options[:num_stripwells])
      end
      if stripwells.any?(&:blank?)
        op.error(ProtocolError, 'Not enough parts in inventory')
        next
      end

      compositions = setup_composition_parts(parts_by_row: stripwells.map(&:parts),
                                             program_name: program_name)
      op.temporary[:compositions] = compositions
    end
  end

  # Sets up the compositions to be created
  #
  # @param parts_by_row [Array<Array<Item>>]
  # @param program_name [String]
  def setup_composition_parts(parts_by_row:, program_name:)
    compositions = []
    parts_by_row.each do |parts|
      parts.each do |item|
        compositions.push(
          build_primer_probe_composition(item: item,
                                         program_name: program_name)
        )
      end
    end
    compositions
  end

  # Orders sample names properly and repeats to fill the number of rows
  #
  # @param sample_names [Array<'Strings'>] names of samples
  # @param stripwell_ot [String] the name of the object type/container 
  # @param rows [Int] the number of rows
  def find_stripwells(sample_names:, stripwell_ot:, rows:, num_stripwells: nil)
    num_stripwells ||= rows
    num_stripwells /= sample_names.length
    ordered_sample_names = Array.new(num_stripwells, sample_names).flatten
    find_collection(sample_names: ordered_sample_names,
                    object_type: stripwell_ot)
  end

  # Finds array of collections containing the Sample Names. Of the
  # right object type. TODO move somewhere else (Collection Management?)
  #
  # @param sample_names [Array<'Strings'>] names of samples
  # @param objet_type [String] the name of the object type/container
  def find_collection(sample_names:, object_type:)
    stripwells = []
    sample_names.each do |name|
      possible_items_id = Item.where(sample: Sample.find_by_name(name))
                           .to_ary
                           .reject(&:deleted?)
                           .select(&:is_part)
                           .map(&:containing_collection)
                           .uniq
                           .select { |col| col.object_type.name == object_type }
                           .reject { |item| item.get('Provisioned') == 'Provisioned' }
                           .map(&:id)
      unless possible_items_id.present?
        stripwells.push(nil)
        next 
      end

      stripwell = Collection.find(possible_items_id.first)
      stripwell.associate('Provisioned', 'Provisioned')
      stripwells.push(stripwell)
    end
    stripwells
  end

  # Initialize a `PCRComposition` for a given primer mix and program
  # stripwell
  #
  # @param primer_mix [Item]
  # @param program_name [String]
  # @return [PCRComposition]
  def build_primer_probe_composition(item:, program_name:)
    composition = PCRCompositionFactory.build(program_name: program_name)
    composition.primer_probe_mix.item = item
    composition
  end

  # Initialize all `PCRComposition`s for each operation
  #
  # @param operations [OperationList]
  # @return [void]
  def build_master_mix_compositions(operations:)
    operations.each do |operation|
      primer_mixes = operation.input_array(PRIMER_PROBE_MIX).map(&:item)

      compositions = []

      primer_mixes.each do |primer_mix|
        composition = build_master_mix_composition(
          primer_mix: primer_mix,
          program_name: operation.temporary[:options][:program_name]
        )
        compositions.append(composition)
      end

      operation.temporary[:compositions] = compositions
    end
  end

  # Initialize a `PCRComposition` for a given primer mix and program
  #
  # @param primer_mix [Item]
  # @param program_name [String]
  # @return [PCRComposition]
  def build_master_mix_composition(primer_mix:, program_name:)
    composition = PCRCompositionFactory.build(program_name: program_name)
    mm_item = master_mix_item(sample: composition.master_mix.sample)
    composition.master_mix.item = mm_item
    composition.primer_probe_mix.item = primer_mix
    composition.water.item = water_item
    composition
  end

  # Initialize all `PCRComposition`s for each operation
  #
  # @param operations [OperationList]
  # @return [void]
  def build_template_compositions(operations:)
    operations.each do |operation|
      template_fvs = operation.input_array(TEMPLATE)
      templates = []
      if template_fvs.first.item.collection?
        template_fvs.group_by{ |fv| fv.collection }.each do |collection, _fv_arry|
          templates.push(collection.parts)
        end
      else
        templates= template_fvs.map!(&:item) 
      end
      compositions = []
      
      templates.flatten!
      
      templates.each do |template|
        composition = build_template_composition(
          template: template,
          program_name: operation.temporary[:options][:program_name]
        )
        compositions.append(composition)
      end
      operation.temporary[:compositions] = compositions
    end
  end

  # Initialize all `PCRComposition`s for each operation
  #
  # @param operations [OperationList]
  # @return [void]
  def build_ntc_compositions(operations:)
    operations.each do |operation|
      composition = build_template_composition(
        template: no_template_control_item,
        program_name: operation.temporary[:options][:program_name]
      )
      operation.temporary[:compositions] = [composition]
    end
  end

  # Initialize a `PCRComposition` for the given program
  #
  # @param program_name [String]
  # @return [PCRComposition]
  def build_template_composition(template:, program_name:)
    composition = PCRCompositionFactory.build(program_name: program_name)
    composition.template.item = template
    composition
  end

  # Retrieve `Item`s required for the protocol based on what's in
  #   the compositions that are attached to the operations
  #
  # @param operations [OperationList]
  # @return [void]
  def retrieve_by_compositions(operations:)
    compositions = operations.map { |op| op.temporary[:compositions] }.flatten
    items = compositions.map(&:items).flatten.compact
    items.map!{ |item| item.is_part ? item.containing_collection : item }
    items.uniq
    items = items.sort_by(&:object_type_id)
    take(items.uniq, interactive: true)
  end

  # Build the data structure that documents the provenance of a
  #   master mix
  #
  # @param primer_mix [Item]
  # @param composition [PCRComposition]
  # @return [Hash] a data structure that documents the provenance of a
  #   master mix
  def added_component_data(composition:)
    composition.added_components.map { |component| collect_data(component) }
  end

  # Reduce a `ReactionComponent` (part of a `PCRComposition`) to a simplified
  #   Hash of selected attributes
  #
  # @param component [ReactionComponent]
  # @return [Hash]
  def collect_data(component)
    {
      name: component.input_name,
      item: component.item,
      volume: component.volume_hash
    }
  end

end
