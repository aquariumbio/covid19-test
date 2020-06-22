# frozen_string_literal: true

class ProtocolTest < ProtocolTestBase
  def setup
    add_operation
      .with_input('Specimen', Sample.find_by_name('Test Respiratory Specimen 1'))
      .with_property(
        'Options',
        '{ "rna_extraction_kit": "Qiagen RNeasy Mini Kit", "expert": false }'
      )
      # .with_output('Specimen', Sample.find_by_name('Test RNA'))
  end

  def analyze
    log('Hello from Nemo')
    assert_equal(@backtrace.last[:operation], 'complete')
  end
end
