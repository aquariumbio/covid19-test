# Library code here

needs 'Standard Libs/Debug'

module SetupPCRPlateDebug
  include Debug

  # Sets up test for debugging
  #
  # @param operations [OperationList] list of operations that need to be set up
  def setup_test(operations)
    operations.make
    operations.each do |op|
      rows = op.output('PCR Plate').collection.dimensions[0]
      op.set_input('Primer/Probe Mix', generate_stripwells(op.input_array('Primer/Probe Mix'), rows))
    end
  end

  # Generates fake populated strip wells
  #
  def generate_stripwells(sampl_fv, rows)
    samples = sampl_fv.map { |fv| fv.sample }
    strip_wells = []
    (rows/samples.length).times do
      samples.each do |sample|
        strip_well = Collection.new_collection('Stripwell')
        sample_array = Array.new(strip_well.capacity, sample)
        strip_well.add_samples(sample_array)
        strip_wells.push(strip_well)
      end
    end
    strip_wells
  end
end
