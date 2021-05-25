# Library for handling temporary tube labels used during operations.
#
# Assigns simplified labes to the OUTPUT Item of each operation.
# The basic method labels them as `[1,2,3,...]`, but this can be overridden.
module TemporaryTubeLabels
    def txfr_tube_labels(op, in_handle, out_handle)
        op.output(out_handle).item.associate :sample_tube_label, op.input(in_handle).item.associations[:sample_tube_label]
    end

    def sample_tube_label(obj, handle=nil)
        tube_label(obj, 'sample', handle)
    end

    def treatment_tube_label(obj, handle=nil)
        tube_label(obj, 'treatment', handle)
    end

    def tube_label(obj, type, handle=nil)
        item = handle ? obj.output(handle).item : obj
        item.associations["#{type}_tube_label".to_sym]
    end

    def tube_label_display(type, handle)
      labels = operations.map { |op| tube_label(op, type, handle) }
      case labels.length
      when 1
        labels[0]
      when 2..5
        labels.join(", ")
      else
        "#{labels.min}-#{labels.max}"
      end
    end

    def associate_sample_tube_labels(handle)
        associate_tube_labels('sample', handle)
    end

    # Assigns an incremental tube number for each output
    #
    def associate_tube_labels(type, handle)
        operations.each_with_index do |op, i|
            op.output(handle).item.associate("#{type}_tube_label".to_sym, "#{i + 1}")
        end
    end
end