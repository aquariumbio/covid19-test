# frozen_string_literal: true

module PrepareRTqPCRValidation

  # Validates that all operations are as expected
  #
  # @param operations [OperationList] list of operations
  # @raise rescue will Error any operations that do not pass validation
  def validate(operation:, job_params:)
    valid_op = true

    valid_input, input_error = validate_inputs(operation, job_params)
    valid_contents, content_error = validate_contents(operation, job_params)
    unless valid_input
      valid_op = false
      operation.error(:IncompatibleInputsError, input_error)
      display_error([{ op: operation, error: content_error }])
    end

    unless valid_contents
      valid_op = false
      operation.error(:InvalidContentsError, content_error)
      display_error([{ op: operation, error: content_error }])
    end

    valid_op
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

  def validate_contents(op, job_params)
    [true, nil]
  end

  def validate_inputs(op, job_params)
    [true, nil]
  end

  class IncompatibleInputsError < ProtocolError; end
  class InvalidContentsError < ProtocolError; end

end
