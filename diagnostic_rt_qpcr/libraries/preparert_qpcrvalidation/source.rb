# frozen_string_literal: true

module PrepareRT_qPCRValidation

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
        op.error(:IncompatibleInputsError, input_error.message)
      end

      unless valid_contents
        all_errors.push(op)
        content_errors.push({op: op, error: content_error})
        op.error(:InvalidContentsError, content_error.message)
      end
    end

    display_error(input_errors) unless input_errors.empty?
    display_error(content_errors) unless content_errors.empty?

    all_errors
  end

  def display_error(error_list)
    error_type = error_list.first[:error].class

    size = (error_type.length + 1) * 2
    slots = 1...size
    tab = slots.each_slice(2).map do |row|
      row.map do
        {class: 'td-empty-slot'}
      end
    end
    tab[0 , 0] = '<b>Operation</b>'
    tab[0 , 1] = '<b>Error Message</b>'
    error_type.each_with_index do |error_hash, idx|
      tab[idx + 1, 0] = error_hash[:op].id.to_s
      tab[idx + 1, 1] = error_hash[:error].message
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
    [true, nil]
  end

  class IncompatibleInputsError < ProtocolError; end
  class InvalidContentsError < ProtocolError; end

  
end