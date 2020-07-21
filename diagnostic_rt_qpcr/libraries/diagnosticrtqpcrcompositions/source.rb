# typed: false
# frozen_string_literal: true

needs 'PCR Libs/PCRComposition'

# Module for working with PCRCompositions used in Diagnostic RT qPCR
#
# @author Devin Strickland <strcklnd@uw.edu>
module DiagnosticRTqPCRCompositions
  PRIMER_MIX = 'Primer/Probe Mix'
  TEMPLATE = 'Template'

  # Initialize all `PCRComposition`s for each operation
  #
  # @param operations [OperationList]
  # @return [void]
  def build_master_mix_compositions(operations:)
    operations.each do |operation|
      primer_mixes = operation.input_array(PRIMER_MIX).map(&:item)
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
