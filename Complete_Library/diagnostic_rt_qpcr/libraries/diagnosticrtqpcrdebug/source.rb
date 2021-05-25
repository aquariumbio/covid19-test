# typed: false
# frozen_string_literal: true

needs 'Collection Management/CollectionTransfer'
needs 'Diagnostic RT-qPCR/DataAssociationKeys'

module DiagnosticRTqPCRDebug
  include CollectionTransfer
  include DataAssociationKeys

  VERBOSE = false
  PLATE = 'PCR Plate'

  def debug_parameters
    {
      group_size: 3,
      program_name: 'Modified_CDC',
      debug_template: 'template',
      method: :skip_sample_layout
    }
  end

  # Populate all input plates with qPCR Reactions
  #
  # @param operations [OperationList]
  # @param method [String]
  # @return [void]
  def setup_test_plates(operations:, method: nil)
    operations.each do |op|
      setup_test_plate(collection: op.input(PLATE).collection, method: method)
    end
  end

  # Populate a collection with qPCR Reactions
  #
  # @param collection [Collection]
  # @param method [String]
  # @return [void]
  def setup_test_plate(collection:, method:)
    collection.associate(:program_name, debug_parameters[:program_name])
    collection.associate(:group_size, debug_parameters[:group_size])
    qpcr_reaction = Sample.find_by_name('Test qPCR Reaction')

    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: debug_parameters[:group_size],
      method: debug_parameters[:method],
      dimensions: collection.dimensions
    )

    loop do
      layout_group = layout_generator.next_group
      break unless layout_group.present?

      layout_group.each do |r, c|
        collection.set(r, c, qpcr_reaction)
        part = collection.part(r, c)
        part.associate(MASTER_MIX_KEY, 'added')
      end
    end

    if method == :master_mix
      show_result(collection: collection) if VERBOSE
      inspect_data_associations(collection: collection) if VERBOSE
      return
    end

    unless debug_parameters[:program_name] == 'Modified_CDC'
      layout_generator = PlateLayoutGeneratorFactory.build(
        group_size: debug_parameters[:group_size],
        method: debug_parameters[:method]
      )
      layout_group = layout_generator.next_group
      layout_group.each do |r, c|
        part = collection.part(r, c)
        part.associate(TEMPLATE_KEY, 'added')
      end
    end

    show_result(collection: collection) if VERBOSE
    inspect_data_associations(collection: collection) if VERBOSE
  end

  # Show all the non-empty wells of the test plate
  # @todo figure out what you really want to show here
  #
  # @param collection [Collection]
  # @return [void]
  def show_result(collection:)
    show do
      title 'Test Plate Setup'
      table highlight_non_empty(collection)
    end
  end
  
  def setup_input_stripwells(operations:, array_key:)
    return unless operations.first.input_array(array_key).first.collection.collection?
    operations.each do |op|
      stripwells = []
      input_parts = op.input_array(array_key)
      input_parts.each do |fv|
        inspect fv.collection.object_type.name.to_s
        stripwell = Collection.new_collection(fv.collection.object_type.name)
        num_parts = stripwell.get_empty.length
        stripwell.add_samples(Array.new(num_parts, fv.sample))
        stripwells.push(stripwell)
      end
      op.input_array(array_key).zip(stripwells).each do |fv, stripwell|
        fv.set(item: stripwell)
      end
    end
  end

  # Inspect a subset of the parts and their data associations
  #
  # @param collection [Collection]
  # @return [void]
  def inspect_data_associations(collection:)
    [[0, 0], [0, 3], [0, 8]].each do |r, c|
      part = collection.part(r, c)
      inspect part, "part at #{[r, c]}"
      inspect part.associations, "data at #{[r, c]}"
    end
  end
end