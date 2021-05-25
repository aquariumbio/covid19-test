# frozen_string_literal: true

# Cannon Mallory
# malloc3@uw.edu
#
# Module that validates workflow parameters at run time
needs 'Standard Libs/AssociationManagement'
needs 'Standard Libs/CommonInputOutputNames'
needs 'RNA_Seq/KeywordLib'

module WorkflowValidation
  include AssociationManagement
  include CommonInputOutputNames
  include KeywordLib

  # Validates that total inputs (from all operations)
  # are within the acceptable range
  # 
  # @param operations [OperationList] list of all operations in the job
  # @param inputs_match_outputs [Boolean] check if number of inputs matches number of outputs
  # @return cancel_job [Boolean] true if job should be canceled/ended now
  def validate_inputs(operations, inputs_match_outputs: false)
    total_inputs = []
    total_outputs = []
    operations.each do |op|
      total_inputs += op.input_array(INPUT_ARRAY).map! { |fv| fv.sample }
      total_outputs += op.output_array(OUTPUT_ARRAY).map! { |fv| fv.sample }
    end


    a = total_inputs.detect{ |item| total_inputs.count(item) > 1}
    message = ''
    message += "Item #{a.id} has been included multiple times in this job," if a != nil
    message += 'The number of Input Items and Output
            Items do not match,' if total_inputs.length != total_outputs.length && inputs_match_outputs
    message += 'Too many Items for this job. Please re-launch 
            job with fewer Items,' if total_inputs.length > MAX_INPUTS
    message += 'There are no Items for this job.' if total_inputs.length <= 0
    return end_job(operations, message: message) unless message == ''
    false
  end

  # Displays all erred operations and items that failed QC
  # Walks through all validation fails.
  #
  # @param failed_ops [Hash] Key: Operation ID, Value: Array[Items]
  def show_erred_operations(failed_ops)
    show do 
      title "Some Operations have failed QC"
      note "<b>#{failed_ops.length}</b> Operations have Items that failed QC"
      note "The next few pages will show which Operations and Items
              are at fault"
    end

    failed_ops.each do |op, erred_items|
      show do
        title "Failed Operation and Items"
        note "Operation <b>#{op.id}</b> from Plan <b>#{op.plan.id}</b>"
        erred_items.each do |item|
          note "Item <b>#{item.id}</b>"
        end
      end
    end
  end

  
  # Validates that operations have passed QC
  #
  # @param operations [OperationList] list of operations
  def validate_qc(operations)
    failed_ops = get_qc_fails(operations)
    manage_failed_ops(operations, failed_ops)
  end




  # Get all the operation that did not pass QC
  #
  # @param operations [OperationList] list of all operations
  # @return failed_ops [OperationList] list of all failed operations
  def get_qc_fails(operations)
    failed_ops = Hash.new
    operations.each do |op|
      failed_items = []
      op.input_array(INPUT_ARRAY).each do |fv|
        if get_associated_data(fv, QC_STATUS) == 'fail'
          failed_items.push(fv)
        end
      end
      failed_ops[op] = failed_items
    end
    failed_ops
  end




  # Manages failed ops.  Coordinates what needs to happen with failed operations
  # Can return remove all items from the operation list Operations
  # this is useful for certain fail criteria but must be careful else
  # things will act very oddly
  #
  # @param operations [OperationList] lis of operations
  # @param failed_ops [Hash] list of failed operations (OperationList okay too)
  # @param interactive [Boolean] if true then is interactive.  Else will automatically
  #     fail failed ops but continue good ops
  # @return cancel_job [Boolean] true if job should be canceled
  def manage_failed_ops(operations, failed_ops, interactive: true, 
      error_failed: false, delay_similar_ops: true)
    unless failed_ops.empty?
      this_job = operations.first.jobs.last

      #must remove all ops from the job that are in the same plan as the failed ops
      removed_ops = get_removed_ops(operations, failed_ops)

      #get the total number of items that were removed from the job
      num_items_removed = get_num_items(failed_ops)
      num_items_removed += get_num_items(removed_ops) if delay_similar_ops 

      #get total number of items originally in th job
      total_items = get_num_items(operations)

      #get the number of items still in the job
      num_items_left = total_items - num_items_removed

      cancel_ops_and_pause_plans(operations, failed_ops, additional_ops: removed_ops, 
        error_failed: error_failed, delay_similar_ops: delay_similar_ops)
      
      cancel_job = false
      if operations.empty?
        cancel_job = true
      elsif interactive
        cancel_job = get_cancel_feedback(total_items, num_items_removed, num_items_left)
        show_erred_operations(failed_ops)
      end

      return end_job(operations) if cancel_job
      false
    end
  end


  
  # cancels the job.  Sets all operations passed to pending
  # and returns true.   Assumes that in protocol code there
  # exists a case statement if true will skip the rest of 
  # protocol and end protocol (without error)
  #
  # Will also display a message (that can be customized) about
  # canceling the job
  #
  # operations [Array<Operation>] an array (or OperationList)of ops
  # message [String] optional sting for canceled message
  def end_job(operations, message: nil)
    set_to_pending(operations)
    show do
      title "Job Ended"
      unless message.nil?
        note "#{message}"
      else
        note "This job has been ended"
      end
    end
    true
  end




  # sets the operations in the list given to pending
  #
  # operations [Array<Operation>] an array (or OperationList)of ops
  def set_to_pending(operations)
    operations.each do |op|
      op.set_status_recursively('pending')
    end
  end


  # gets feed back from the tech on weather they want to continue with
  # the job or to cancel and re batch.
  #
  # @param total_items [Int] the total number of items in the job
  # @param num_failed [Int] number of failed items
  # @param num_left [Int] number of items left in job
  # @return cancel [Boolean] true if the job should be canceled
  def get_cancel_feedback(total_items, num_failed, num_left, num_tries: 10)
    cancel = nil
    num_tries.times do 
      feedback_one = show do 
        title "Some Items in this Job failed QC"
        separator
        warning "Warning"
        separator
        note "<b>#{num_failed}</b> out of <b>#{total_items}</b> items were 
              removed from this job"
        note "Do you want to continue this job with the remaining <b>#{num_left}</b> items"
        select ["Yes", "No"], var: "continue".to_sym, label: "Continue?", default: 1
      end

      if feedback_one[:continue] == "No"
        feedback_two = show do
          title "Are You Sure?"
          note "Are you sure you want to cancel the whole job?"
          select ["Yes", "No"], var: "cancel".to_sym, label: "Cancel?", default: 1
        end
        if feedback_two[:cancel] == "Yes"
          return true
        end
      else
        return false
      end
    end
    raise "Job Canceled, answer was not consistent.  All Operations erred"
  end

  # get all the operations that may be in the same plan that should be removed
  # from the job but should not be canceled or erred.
  #
  # @param operations [OperationList] list of operations
  # @param failed_ops [Hash] hash of key op: value Array[Items]
  # @return removed_ops [Array] list of operations that should be removed
  def get_removed_ops(operations, failed_ops)
    removed_ops = []
    failed_ops.each do |failed_op, erred_items|
      plan = failed_op.plan
      operations.each do |op|
        unless failed_ops.keys.include?(op) || removed_ops.include?(op) || op.plan != plan
          removed_ops.push(op)
        end
      end
    end
    removed_ops
  end



  # cancels all failed ops and removes from operations list
  # sets all like ops in same plans as failed ops to 'delayed'
  # Can return remove all items from the operationlist Operations
  # this is useful for certain fail criteria but must be careful else
  # things will act very oddly
  #
  # @param operations [OperationList] list of operations
  # @param failed_ops [Hash] list of failed operations
  # @param removed_ops [Array] list of ops that did not fail but need to be removed from plan
  def cancel_ops_and_pause_plans(operations, failed_ops, additional_ops: nil, 
            error_failed: false, delay_similar_ops: true)
    cancel_ops(operations, failed_ops, error_op: error_failed)
    cancel_ops(operations, additional_ops) if delay_similar_ops && !additional_ops.nil?
    pause_like_ops(failed_ops) if delay_similar_ops
  end


  # 'delay' all like ops in plans that contained failed_ops
  #
  # @param operations [OperationList] list of operations
  # @param failed_ops [Hash] list of failed operations
  def pause_like_ops(failed_ops)
    failed_ops.keys.each do |failed_op|
      plan = failed_op.plan
      pause_ops_of_type(plan, failed_op.operation_type.name)
    end
  end

  # moves all operations in a plan of a certain object type to delayed
  # @param plan [Plan] the plan
  # @param operation_type [String] the name of the operation type
  # @param exclude [Array<operation>] an array of operations to 
  #    be excluded
  def pause_ops_of_type(plan, operation_type, exclude: [])
    ops = plan.operations.select{|op| op.operation_type.name == operation_type}
    ops.each do |op|
      op.set_status_recursively('delayed') unless exclude.include?(op)
    end
  end

  # cancels all failed ops and removes them from operations list
  #
  # @param remove_ops [Array] or [Hash] list of failed operations
  def cancel_ops(operations, remove_ops, error_op: false)

    if remove_ops.is_a?(Hash)
      remove_ops = remove_ops.keys
    end

    remove_ops.each do |op|
      if error_op
        op.set_status_recursively('error')
      else
        op.set_status_recursively('delayed')
      end
      operations.delete(op)
    end
    operations
  end

  # gets the number of input items in the input array of each op in list
  #
  # @param ops [Array] Operation List is acceptable of operations
  # @return num_items [Int] the number of input items (Hash is acceptable)
  def get_num_items(ops)

    if ops.is_a?(Hash)
      ops = ops.keys
    end

    num_items = 0
    ops.each do |op|
      num_items += op.input_array(INPUT_ARRAY).length
    end
    num_items
  end


    # Goes through and stops all failed ops and moves them to error
  # Calls method that will also pause all plans of the same type
  #
  # @param operations [OperationList] list of operations
  # @param downstream_operation_type [String] the name of the operation to be delayed
  # @return cancel_job [Boolean] true if the job should be ended now
  def stop_qc_failed_operations(operations, downstream_operation_type)
    # get a list of operations that did fail qc
    failed_ops = get_qc_fails(operations)
    failed_ops.each do |op, failed_items|
      plan = op.plan
      pause_ops_of_type(plan, downstream_operation_type)
    end
    manage_failed_ops(operations, failed_ops, interactive: false, 
      error_failed: true, delay_similar_ops: false)
  end
end
