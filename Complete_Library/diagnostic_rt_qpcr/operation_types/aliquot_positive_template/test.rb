# frozen_string_literal: true

class ProtocolTest < ProtocolTestBase
  def setup
    # add_random_operations(1)

    sample = Sample.find_by_name('nCoVPC')
    add_operation
      .with_input('Template', sample)
      .with_property(
        'Options',
        '{}'
      )
      .with_output('Template', sample)
  end

  def analyze
    log('Hello from Nemo')
    assert_equal(@backtrace.last[:operation], 'complete')
    # d = @backtrace[3] #find_display_by_title('Resuspend Positive Template')
    # log(d[:content].to_s)
  end
end