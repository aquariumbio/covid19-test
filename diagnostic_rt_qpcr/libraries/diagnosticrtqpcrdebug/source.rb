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
      program_name: 'CDC_TaqPath_CG',
      debug_primer: [5, 8, 9], # rp, n1, n2,
      debug_template: 'template',
      debug_items: [257,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256]
    }
  end

  def setup_test(operations)
    operations.each do |op|
      setup_test_plate(collection: op.input('PCR Plate').collection)
      op.set_input('Template', generate_samples(debug_parameters[:debug_items]))
    end
  end

  # Populate test plate with qPCR Reactions and one no template control (NTC)
  #
  def setup_test_plate(collection:)
    verbose = false
    key = TEMPLATE_KEY
    collection.associate(:program_name, debug_parameters[:program_name])
    collection.associate(:group_size, debug_parameters[:group_size])
    qpcr_reaction = Sample.find_by_name('Test qPCR Reaction')
    ntc_item = Item.find(258)
    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: debug_parameters[:group_size],
      method: :cdc_sample_layout
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

  def generate_samples(debug_item_ids)
    debug_items = []
    debug_item_ids.each do |id|
      debug_items.push(Item.find(id))
    end
    debug_items
  end

  def show_result(collection:)
    show do
      table highlight_non_empty(collection)
    end
  end

end



#   def setup_test(operations)
#     operations.each do |op|
#       op.input('PCR Plate').set(collection: generate_debug_container)
#       op.set_input('Template', generate_samples(debug_parameters[:debug_items]))
#     end
#   end

#   # TODO: this is pretty gross and hard coded yuck
#   def generate_debug_container
#     obj_type = ObjectType.find_by_name('96-well qPCR Plate')
#     collection = Collection.new_collection(obj_type)
#     collection.associate(:program_name, debug_parameters[:program_name])
#     collection.associate(:group_size, debug_parameters[:group_size])

#     add_primer_probe(collection)
#     add_neg_control(collection)

#     raise "the associations are #{collection.part(0,0).associations}"
#     collection
#   end

#   def add_primer_probe(collection)
#     debug_parameters[:debug_primer].each_with_index do |sample, idx|
#       sample = Sample.find(sample)
#       12.times do |col|
#         row1 = 0 + idx
#         row2 = 4 + idx
#         collection.set(row1, col, sample)
#         collection.set(row2, col, sample)
#       end
#     end
#   end

#   def add_neg_control(collection)
#     microtiter_plate = MicrotiterPlateFactory.build(
#       collection: collection,
#       group_size: debug_parameters[:group_size],
#       method: :sample_layout
#     )
#     item = Item.find(debug_parameters[:neg_control_sample])
#     neg_group = microtiter_plate.next_empty(key: TEMPLATE_KEY)

#     association_map = []
#     neg_group.each { |r, c| association_map.push({ to_loc: [r, c] }) }
#     transfer_from_item_to_collection(from_item: item,
#                                      to_collection: microtiter_plate.collection,
#                                      association_map: association_map,
#                                      transfer_vol: { qty: 5, units: 'ul'})
#     neg_group.each { |nxt| associate(index: nxt, key: TEMPLATE_KEY, data: item.id) }
#   end

#   def generate_samples(debug_item_ids)
#     debug_items = []
#     debug_item_ids.each do |id|
#       debug_items.push(Item.find(id))
#     end
#     debug_items
#   end
# end
