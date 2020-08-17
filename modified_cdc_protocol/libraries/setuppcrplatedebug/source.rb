# Library code here

needs 'Diagnostic RT-qPCR/DataAssociationKeys'

module SetupPCRPlateDebug
    
  include DataAssociationKeys

  # Sets up test for debugging
  #
  # @param operations [OperationList] list of operations that need to be set up
  def setup_test(operations, ot_type_name)
      operations.make
      operations.each do |op|
        output_collection = op.output('PCR Plate').collection
        rows = output_collection.dimensions[0]
        sample_names = ['RP', '2019-nCoVPC_N1', '2019-nCoVPC_N2']
        (rows/(sample_names.length)).times do
            sample_names.each do |name|
                collection = Collection.new_collection(ot_type_name)
                samples = Array.new(collection.dimensions[0], Sample.find_by_name(name))
                collection.add_samples(samples)
            end
        end
      end
  end
  
  
  
  def setup_stripwell_plates(operations:)
    operations.each do |op|
      options = op.temporary[:options]
      setup_stripwell_plate(collection: op.input('PCR Plate').collection,
                            method: options[:layout_method],
                            program_name: options[:program_name],
                            group_size: options[:group_size])
    end
  end
  
  # Populate a collection with qPCR Reactions
  #
  # @param collection [Collection]
  # @param method [String]
  # @return [void]
  def setup_stripwell_plate(collection:, method:, program_name:, group_size:)
    collection.associate(:program_name, program_name)
    collection.associate(:group_size, group_size)
    qpcr_reaction = Sample.find_by_name('Test qPCR Reaction')

    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: group_size,
      method: method,
      dimensions: collection.dimensions
    )

    loop do
      layout_group = layout_generator.next_group
      break unless layout_group.present?

      layout_group.each do |r, c|
        collection.set(r, c, qpcr_reaction)
        part = collection.part(r, c)
        part.associate(PRIMER_PROBE_MIX_KEY, 'added')
      end
    end

    show_result(collection: collection)
  end
end
