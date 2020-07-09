# typed: false
# frozen_string_literal: true
needs 'Collection Management/CollectionTransfer'
needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'
needs 'Diagnostic RT-qPCR/DataAssociationKeys'

module DiagnosticRTqPCRDebug
  include CollectionTransfer
  include DiagnosticRTqPCRHelper
  include DataAssociationKeys

  VERBOSE = false

  def debug_parameters
    {
      group_size: 3,
      method: :cdc_sample_layout,
      program_name: 'CDC_TaqPath_CG',
      debug_primer: [5, 8, 9], # rp, n1, n2,
      debug_template: 'template',
      debug_sample_names: ['nCovPC',
                           'Test Patient 01',
                           'Test Patient 02'],
      debug_object_type: 'Purified RNA in 1.5 ml Tube'
    }
  end

  def setup_test(operations)
    operations.each do |op|
      setup_test_plate(collection: op.input('PCR Plate').collection)
      op.set_input('Template',
                   generate_samples(debug_parameters[:debug_sample_names],
                                    debug_parameters[:debug_object_type]))
    end
  end

  # Populate test plate with qPCR Reactions and one no template control (NTC)
  #
  def setup_test_plate(collection:)
    verbose = false
    key = TEMPLATE_KEY
    collection.associate(COMPOSITION_NAME_KEY, debug_parameters[:program_name])
    collection.associate(SAMPLE_GROUP_SIZE_KEY, debug_parameters[:group_size])
    collection.associate(SAMPLE_METHOD_KEY, debug_parameters[:method])
    qpcr_reaction = Sample.find_by_name('Generic qPCR Reaction')
    ntc_item = 'Molecular Grade Water'
    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: debug_parameters[:group_size],
      method: debug_parameters[:method]
    )
    i = 0
    loop do
      layout_group = layout_generator.next_group
      break unless layout_group.present?
      layout_group.each do |r, c|
        collection.set(r, c, qpcr_reaction)
        next if i.positive?
        part = collection.part(r, c)
        inspect part, "part at #{[r, c]}" if verbose
        part.associate(key, ntc_item)
        inspect part.associations, "#{key} at #{[r, c]}" if verbose
      end
      i += 1
    end
    show_result(collection: collection) if verbose
    inspect collection.parts.to_s if verbose
  end

  def generate_samples(debug_sample_names, object_type)
    debug_items = []
    debug_sample_names.each do |sample_name|
      item = Sample.find_by_name(sample_name).make_item(object_type)
      item.mark_as_deleted
      debug_items.push(item)
    end
    debug_items
  end

  def show_result(collection:)
    show do
      table highlight_non_empty(collection)
    end
  end

end
