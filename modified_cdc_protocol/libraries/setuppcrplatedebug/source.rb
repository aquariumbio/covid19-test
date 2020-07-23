# Library code here

needs 'Standard Libs/Debug'

module SetupPCRPlateDebug
  include Debug

  MULTI_SAMPLES = ['RP Test primer/probe 1', 'N1 Test primer/probe 2']
  SINGLE_SAMPLES = ['N2 Test primer/probe 3'].freeze

  # Sets up test for debugging
  #
  # @param operations [OperationList] list of operations that need to be set up
  def setup_test(operations)
    operations.make
    arry = nil
    debug_method = nil
    if [true, false].sample #to randomly select RP/N1 set or N2 only set
      arry = MULTI_SAMPLES
      debug_method = 'modified_primer_layout_two'
    else
      arry = SINGLE_SAMPLES
      debug_method = 'modified_primer_layout_one'
    end
    operations.each do |op|
      rows = op.output('PCR Plate').collection.dimensions[0]
      op.set_input('Primer/Probe Mix', generate_strip_wells(arry, rows))
    end
    inspect debug_method
    debug_method
  end

  # Generates fake populated strip wells
  #
  def generate_strip_wells(sample_names, rows)
    samples = sample_names.map { |sample_name| Sample.find_by_name(sample_name) }
    strip_wells = []
    (rows/samples.length).times do
      samples.each do |sample|
        strip_well = Collection.new_collection('Strip Well')
        sample_array = Array.new(strip_well.capacity, sample)
        strip_well.add_samples(sample_array)
        strip_wells.push(strip_well)
      end
    end
    strip_wells
  end
end
