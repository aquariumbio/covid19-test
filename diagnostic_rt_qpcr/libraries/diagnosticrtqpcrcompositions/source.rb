# typed: false
# frozen_string_literal: true

needs 'PCR Libs/PCRComposition'

# Not sure I like that this knows of PCRCompositionDefinitions
#   need some place to store some inforamtion that I can access
#   prior to creating a composition
needs 'PCR Libs/PCRCompositionDefinitions'

# Module for working with PCRCompositions used in Diagnostic RT qPCR
#
# @author Devin Strickland <strcklnd@uw.edu>
module DiagnosticRTqPCRCompositions
  include PCRCompositionDefinitions
  
  PRIMER_PROBE_MIX = 'Primer/Probe Mix' # Should converge with PRIMER_PROBE_MIX
      # in PCRCOmpositionDefinitions
  TEMPLATE = 'Template'

  # Initialize all `PCRComposition`s for each operation stripwell
  #
  # @param operations [OperationList]
  # @return [void]
  def build_stripwell_primer_probe_compositions(operations:)
    all_inputs = []
    operations.each do |op|
      options = op.temporary[:options]
      program_name = options[:program_name]
      
      stripwells = find_stripwells(sample_names: options[:sample_names],
                                   stripwell_ot: options[:object_type],
                                   dimensions: op.temporary[:microtiter_plate].collection.dimensions,
                                   all_inputs: all_inputs)
      unless stripwells.present?
        op.error(ProtocolError, 'No enough parts in inventory')
        next
      end
      
      parts_by_row = convert_to_parts_by_row(stripwells: stripwells)
      
      compositions = setup_composition_parts(parts_by_row: parts_by_row,
                                             program_name: program_name)
      op.temporary[:compositions] = compositions
      all_inputs.push(stripwells.flatten)
    end
    all_inputs.flatten
  end
  
  # Converts to parts by row format.  Mostly to allow for easy conversion
  # if the primer probes ever start coming in as individual parts and
  # not stripwells
  def convert_to_parts_by_row(stripwells: stripwells)
    stripwells.map { |stripwell| stripwell.parts }
  end
  
  def setup_composition_parts(parts_by_row:, program_name:)
    compositions = []
    parts_by_row.each do |parts|
      parts.each do |part|
        compositions.push(build_primer_probe_compositions(part: part,
                                        program_name: program_name))
      end
    end
    compositions
  end
  
  def find_stripwells(sample_names:, stripwell_ot:, dimensions:, all_inputs:)
    ordered_sample_names = Array.new(dimensions[0]/(sample_names.length), sample_names).flatten
    stripwells = []
    ordered_sample_names.each do |name|
      possible_items = Item.where(sample: Sample.find_by_name(name))
                           .to_ary
                           .reject{ |part| part unless part.is_part}
                           .map(&:containing_collection)
                           .uniq
                           .reject { |col| col unless col.object_type.name == stripwell_ot }
                           .map(&:id)
      unused_items = (possible_items - stripwells.map(&:id)) - all_inputs.map(&:id)
      return nil if unused_items.empty?
      stripwells.push(Collection.find(unused_items.first))
    end
    stripwells
  end

  # Initialize a `PCRComposition` for a given primer mix and program
  # stripwell
  #
  # @param primer_mix [Item]
  # @param program_name [String]
  # @return [PCRComposition]
  def build_primer_probe_compositions(part:, program_name:)
    composition = PCRCompositionFactory.build(program_name: program_name)
    composition.primer_probe_mix.item = part
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
      templates = operation.input_array(TEMPLATE).map(&:item)
      compositions = []

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
    items = compositions.map(&:items).flatten.compact.uniq
    items = items.sort_by(&:object_type_id)
    take(items, interactive: true)
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