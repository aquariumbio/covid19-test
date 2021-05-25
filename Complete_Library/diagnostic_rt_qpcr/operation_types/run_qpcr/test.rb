# frozen_string_literal: true

class ProtocolTest < ProtocolTestBase
  def setup
    add_random_operations(1)
    # [1..3].each do |i|
    #   s = Sample.find_by_name("Test qPCR Reaction #{i}")
    #   add_operation
    #     .with_input('qPCR Reactions', s)
    #     .with_property('Options', '{"thermocycler_model": "BioRad CFX96", "program_name": "CDC_qScript_XLT_ToughMix"}')
    #     .with_output('qPCR Reactions', s)
    # end
  end

  def analyze
    log('Hello from Nemo')
    assert_equal(@backtrace.last[:operation], 'complete')
  end
end
