# Aliquot Primer Probe
# Written By Dany Fu 2020-05-05

needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'


# 1) Upon receipt, store dried primers and probes at 2-8C.
# 2) Precautions: These reagents should only be handled in a clean area and
# stored at appropriate temperatures (see below) in the dark. Freeze-thaw cycles
# should be avoided. Maintain cold when thawed.
# 3) Using aseptic technique, suspend dried reagents in 1.5 mL of nuclease-free
# water (50X working concentration) and allow to rehydrate for 15 min at room
# temperature in the dark.
# 4) Mix gently and aliquot primers/probe in 300 uL volumes into 5 pre-labeled
# tubes. Store a single aliquot of primers/probe at 2-8oC in the dark. Do not
# refreeze (stable for up to 4 months). Store remaining aliquots at <= -20oC
# in a non-frost-free freezer.
class Protocol
  include DiagnosticRTqPCRHelper

  OUTPUT_ITEMS_NUM = { qty: 5, units: TUBE_MICROFUGE }.freeze
  TIME_REHYDRATE = { qty: 15, units: MINUTES }.freeze
  VOL_WATER = { qty: 1.5, units: MILLILITERS }.freeze
  VOL_SUSPENSION = { qty: 300, units: MICROLITERS }.freeze

  COLD_ROOM = 'M4'.freeze

  ########## DEFAULT PARAMS ##########

  # Default parameters that are applied equally to all operations.
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_job_params
    {}
  end

  # Default parameters that are applied to individual operations.
  #   Can be overridden by:
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_operation_params
    {}
  end

  ########## MAIN ##########

  def main
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )
    return {} if operations.errored.any?

    update_operation_params(
      operations: operations,
      default_operation_params: default_operation_params
    )

    get_tubes(count: operations.length)
    operations.retrieve

    save_output(operations)
    suspend_primer_mix

    # Group the operations by the input reagent
    ops_by_input = operations.group_by { |op| op.input(PRIMER_MIX).item }
    ops_by_input.each do |primer, ops|
      make_aliquots(ops: ops, primer: primer)
    end

    operations.store(interactive: true, io: 'output', method: 'boxes')
    
    protocol_survey(operations)
    
  end

  # Get 5 1.5 mL tubes per dried reagent
  # @param count [Integer] the number of operations currently running
  def get_tubes(count:)
    show do
      title "Get new #{TUBE_MICROFUGE}"
      check "Please get #{count * OUTPUT_ITEMS_NUM[:qty]} #{TUBE_MICROFUGE}"
    end
  end

  # Create and save multiple output Items per operation
  # @param operations [OperationList] List of operations
  def save_output(operations)
    operations.make

    operations.each do |op|
      op.output(PRIMER_MIX).item.associate :volume, VOL_SUSPENSION[:qty]

      output_primer = op.output(PRIMER_MIX).sample
      # makes 4 additional aliquots per op
      (OUTPUT_ITEMS_NUM[:qty] - 1).times do
        new_aliquot = output_primer.make_item(op.output(PRIMER_MIX).item.object_type.name)
        new_aliquot.associate :volume, VOL_SUSPENSION[:qty]
        link_output_item(operation: op, sample: output_primer, item: new_aliquot)
      end
    end
  end

  # Manually link the item to the operation as an output
  # @param op [Operation] the operation that creates the items
  # @param sample [Sample] the sample of the item
  # @param item [Item] the item that is created
  def link_output_item(operation:, sample:, item:)
    fv = FieldValue.new(
      name: PRIMER_MIX,
      child_item_id: item.id,
      child_sample_id: sample.id,
      role: 'output',
      parent_class: 'Operation',
      parent_id: operation.id,
      field_type_id: operation.output(PRIMER_MIX).field_type.id
    )
    fv.save
  end

  # Instructions for suspending dried reagents
  def suspend_primer_mix
    show do
      title 'Suspend Primer Mix'
      warning 'These reagents should only be handled in a clean area.'
      warning 'Avoid reeze-thaw cycles. Maintain on ice when thawed.'
      check "Using aseptic technique, suspend each dried primer in \
             #{qty_display(VOL_WATER)} of nuclease-free water."
      check "Rehydrate for #{qty_display(TIME_REHYDRATE)} at room temperature \
            in the dark."
      timer initial: { minutes: TIME_REHYDRATE[:qty] }
    end
  end

  # Make 5 aliquots for each primer
  # @param operations [OperationList] Array of operations grouped by primer
  def make_aliquots(ops:, primer:)
    # last_tube_id = '' # keep one of each primer
    ops.each do |op|
      input_primers = Array.new(OUTPUT_ITEMS_NUM[:qty], primer)
      aliquot_items = op.outputs.map(&:item)
      table = Table.new
                   .add_column('Primer Mix ID', input_primers.map(&:to_s))
                   .add_column('Destination Tube ID', aliquot_items.map(&:to_s))

      show do
        title 'Make Aliquots'
        check 'Label destination tube IDs according to the table.'
        check "Mix solution gently and aliquot #{qty_display(VOL_SUSPENSION)} \
              of rehydrated primer into each tube according to the table."
        table table
      end

      add_aliquot_provenance(stock_item: primer, aliquot_items: aliquot_items)

      primer.mark_as_deleted

      if debug
        aliquot = aliquot_items.last
        inspect(primer.associations, primer.id)
        inspect(aliquot.associations, aliquot.id)
      end
    end

    # One aliquot of each primer mix should be stored in the cold room instead
    # of freezer. However, this code doesn't actually work as one ObjectType
    # can only be associated with one location.
    # Leaving this here for completeness.
    # last_tube = Item.find(last_tube_id)
    # last_tube.move(COLD_ROOM)
    # last_tube.store
  end
end
