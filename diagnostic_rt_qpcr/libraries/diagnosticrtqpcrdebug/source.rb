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
      program_name: 'CDC_TaqPath_CG',
      debug_template: 'template',
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
      group_size: 24,
      method: :cdc_primer_layout
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

    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: debug_parameters[:group_size],
      method: :cdc_sample_layout
    )
    layout_group = layout_generator.next_group
    layout_group.each do |r, c|
      part = collection.part(r, c)
      part.associate(TEMPLATE_KEY, 'added')
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
