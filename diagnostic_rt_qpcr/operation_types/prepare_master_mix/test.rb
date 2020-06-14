# frozen_string_literal: true

class ProtocolTest < ProtocolTestBase
  def setup
    add_random_operations(1)

  #   mm = Sample.find_by_name('TaqPath 1-Step RT-qPCR Master Mix')
  #   p1 = Sample.find_by_name('2019-nCoV_N1')
  #   p2 = Sample.find_by_name('2019-nCoV_N2')
  #   p3 = Sample.find_by_name('RNase P')

  #   add_operation
  #     .with_property("Options", '{ "magic_number": 24, "foo": "baz" }')
  #     .with_input('Enzyme Master Mix', mm)
  #     .with_input('Primer/Probe Mix', p1)
  #     .with_input('Primer/Probe Mix', p2)
  #     .with_input('Primer/Probe Mix', p3)
  end

  def analyze
    log('Hello from Nemo')
    assert_equal(@backtrace.last[:operation], 'complete')
  end
end