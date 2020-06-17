# frozen_string_literal: true

class ProtocolTest < ProtocolTestBase
  def setup
    op = add_operation
         .with_input('Template', Sample.find_by_name('NTC'))
         .with_input('Template', Sample.find_by_name('nCoVPC'))
         .with_property('Options', '{}')

    22.times do |i|
      op.with_input('Template', Sample.find_by_name("Test Respiratory Specimen #{i+1}"))
    end
  end

  def analyze
    log('Hello from Nemo')
    assert_equal(@backtrace.last[:operation], 'complete')
  end
end
