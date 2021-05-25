# frozen_string_literal: true

class ProtocolTest < ProtocolTestBase
  def setup
    # add_random_operations(1)

    samples = [
      Sample.find_by_name('Patient Sample 111'),
      Sample.find_by_name('Patient Sample 222'),
      Sample.find_by_name('Patient Sample 333')
    ]

    samples.each do |sample|
      add_operation
        .with_input('Specimen', sample)
        .with_property(
          'Options',
          '{}'
        )
        .with_output('Specimen', sample)
    end
  end

  def analyze
    log('Hello from Nemo')
    assert_equal(@backtrace.last[:operation], 'complete')
  end
end
