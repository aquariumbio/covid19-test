# Library code here

module SetupPCRPlateDebug

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
end
