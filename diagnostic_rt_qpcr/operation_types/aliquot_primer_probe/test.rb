# frozen_string_literal: true

class ProtocolTest < ProtocolTestBase
  def setup
    # add_random_operations(1)

    samples = [
      Sample.find_by_name('2019-nCoV_N1'),
      Sample.find_by_name('2019-nCoV_N2'),
      Sample.find_by_name('RP')
    ]

    samples.each do |sample|
      add_operation
        .with_input('Primer/Probe Mix', sample)
        .with_property(
          'Options',
          '{}'
        )
        .with_output('Primer/Probe Mix', sample)
    end
  end

  def analyze
    log('Hello from Nemo')
    assert_equal(@backtrace.last[:operation], 'complete')
  end
end