# frozen_string_literal: true

module PrepareRTqPCRValidation

  # Validates that all operations are as expected
  #
  # @param operations [OperationList] list of operations
  # @raise rescue will Error any operations that do not pass validation
  def validate(operations:)
    input_errors = []
    content_errors = []
    all_errors = []

    operations.each do |op|
      valid_input, input_error = validate_inputs(op)
      valid_contents, content_error = validate_contents(op)
      unless valid_input
        all_errors.push(op)
        input_errors.push({op: op, error: input_error})
        op.error(:IncompatibleInputsError, input_error)
      end

      unless valid_contents
        all_errors.push(op)
        content_errors.push({op: op, error: content_error})
        op.error(:InvalidContentsError, content_error)
      end
    end

    display_error(input_errors) unless input_errors.empty?
    display_error(content_errors) unless content_errors.empty?

    all_errors
  end

  def display_error(error_list)
    error_type = error_list.first[:error]
    tab = [['<b>Operation<b>', '<b>Error Message</b>']]
    error_list.each do |err|
      tab.push([err[:op].id, err[:error]])
    end

    show do
      title 'Operation Error'
      note "The following operations had #{error_type}"
      table tab
    end
  end

  def validate_contents(op)
    [true, nil]
  end

  def validate_inputs(op)
    #[failed/passed, message]
    [true, nil]
  end

  class IncompatibleInputsError < ProtocolError; end
  class InvalidContentsError < ProtocolError; end

  
end