module ProvenanceFinder
    # Finds output FieldValues for a given Item id.
    #
    # @param item_id [int] id of an Item
    # @return [ActiveRecord::Relation] FieldValues
    def output_fvs(item_id)
        FieldValue.where(role: 'output', child_item_id: item_id) || []
    end

    # Finds input FieldValues for a given Item id.
    #
    # @param item_id [int] id of an Item
    # @return [ActiveRecord::Relation] FieldValues
    def input_fvs(item_id)
        FieldValue.where(role: 'input', child_item_id: item_id) || []
    end

    # Finds Operations for which a given Item is an output.
    #
    # @param item_id [int] id of an Item
    # @return [Array] Operations that produced this item
    def predecessor_ops(item_id)
        output_fvs(item_id).map { |fv| fv.operation }
    end

    # Finds Operations for which a given Item is an input.
    #
    # @param item_id [int] id of an Item
    # @return [Array] Operations that used this item as input
    def successor_ops(item_id)
        input_fvs(item_id).map { |fv| fv.operation }
    end

    # Recursively finds the Operation backchain for a given item.
    # Goes back to a specified OperationType, then stops.
    #
    # @param stop_at [string] name of the OperationType of the Operation to stop at
    # @param item_id [int] id of an Item
    # @param row [string] the row location if the Item is a collection
    # @param column [string] the column location if the Item is a collection
    # @param ops [Array] the list of operations to be returned
    # @return [Array] the Operation backchain
    def walk_back(stop_at, item_id, row=nil, col=nil, ops=nil)
        ops ||= []

        pred_fvs = output_fvs(item_id)
        pred_fvs = pred_fvs.select { |fv| fv.row == row and fv.column == col }

        return ops unless pred_fvs.present?

        op_ids = ops.flatten.map { |op| op.id }
        pred_op_fvs = pred_fvs.select { |fv| fv.parent_class == "Operation" && ! op_ids.include?(fv.parent_id) }
        pred_op_ids = pred_op_fvs.map { |fv| fv.parent_id }
        pred_ops = Operation.where(id: pred_op_ids)
        # It's not clear to me why this should happen
        return ops unless pred_ops.present?

        pred_op = pred_ops.sort_by { |op| job_completed(op) }.first
        ops.append(pred_op)

        return ops if pred_op.operation_type.name == stop_at

        begin
            input_fv = get_input_fv(pred_op, item_id)

        rescue InputNotFoundError => e
            puts e.message
            return ops
        end

        if input_fv.field_type.array == true
            branches = []
            pred_op.input_array(input_fv.name).each do |fv|
                branches.append(walk_back(stop_at, fv.child_item_id, fv.row, fv.column))
            end
            ops.append(branches)
        end

        return walk_back(stop_at, input_fv.child_item_id, input_fv.row, input_fv.column, ops)
    end

    # Gets the completion date for the most recent Job for a given Operation.
    #
    # @param op [Operation]
    # @return [DateTime]
    def job_completed(op)
        jobs = op.jobs.sort_by { |job| job.updated_at }
        jobs.last.updated_at
    end

    # Determines the most likely input FieldValue for a given Operation and output Item.
    #
    # @param op [Operation] the Operation to search within
    # @param output_item_id [int] the id of the output Item
    # @return [FieldValue] the most likely input
    def get_input_fv(op, output_item_id)
        # If only one input, then the answer is obvious
        inputs = op.inputs
        return inputs[0] if inputs.length == 1

        # If more than one input, then it attempts to use routing
        routing_matches = get_routing_matches(op, output_item_id)
        return routing_matches[0] if routing_matches.present?

        # If no routing (bad developer!) then it attempts to match Sample name
        sample_name_matches = get_sample_name_matches(op, output_item_id)
        return sample_name_matches[0] if sample_name_matches.present?

        # Gives up
        raise InputNotFoundError.new(
            "No input for output item #{output_item_id} in operation #{op.id}."
        )
    end

    # Returns input FieldValues for the given Operation with the same routing as the given output Item
    #
    # @param op [Operation]
    # @param output_item_id [int]
    # @return [Array] input FieldValues that have the same routing as the output
    def get_routing_matches(op, output_item_id)
        fvs = FieldValue.where(
            role: 'output',
            parent_id: op.id,
            parent_class: 'Operation',
            child_item_id: output_item_id
        )

        fv = fvs.last
        op.inputs.select { |i| i.field_type && i.field_type.routing == fv.field_type.routing }
    end

    # Returns input FieldValues for the given Operation with the same Sample name as the given output Item
    #
    # @param op [Operation]
    # @param output_item_id [int]
    # @return [Array] input FieldValues that have the same sample name as the output
    def get_sample_name_matches(op, output_item_id)
        sn = Item.find(output_item_id).sample.name
        return op.inputs.select { |i| i.sample && i.sample.name == sn }
    end
end

class InputNotFoundError < StandardError
    def message
        "Could not find an input for this operation"
    end
end

class NoPredecessorsError < StandardError
    def message
        "No predecessor was found where one was expected"
    end
end