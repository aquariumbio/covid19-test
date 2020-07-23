# Library code here

needs 'Standard Libs/Debug'

module SetupPCRPlateDebug
  include Debug

  MULTI_SAMPLES = ['RP Test primer/probe 1', 'N1 Test primer/probe 2'].freeze
  SINGLE_SAMPLES = ['N2 Test primer/probe 3'].freeze
  ALL_SAMPLE = ['RP Test primer/probe 1',
                'N1 Test primer/probe 2',
                'N2 Test primer/probe 3']

  # Sets up test for debugging
  #
  # @param operations [OperationList] list of operations that need to be set up
  def setup_test(operations)
    operations.make
    arry = [MULTI_SAMPLES, SINGLE_SAMPLES, ALL_SAMPLE].sample
    operations.each do |op|
      rows = op.output('PCR Plate').collection.dimensions[0]
      op.set_input('Primer/Probe Mix', generate_stripwells(arry, rows))
    end
    inspect arry.to_s
  end

  # Generates fake populated strip wells
  #
  def generate_stripwells(sample_names, rows)
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
