# Aliquot Positive Template
# Written By Rita Chen 2020-05-04
# Updated by Dany Fu 2020-06-01

needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'

# 2019-nCoV Positive Control (nCoVPC) Preparation:
# 1) Precautions: This reagent should be handled with caution in a dedicated
# nucleic acid handling area to prevent possible contamination. Freeze-thaw
# cycles should be avoided. Maintain on ice when thawed.
# 2) Resuspend dried reagent in each tube in 1 mL of nuclease-free water to
# achieve the proper concentration. Make single use aliquots (approximately 30
# uL) and store at less than and equal to -70C.
# 3) Thaw a single aliquot of diluted positive control for each experiment and
# hold on ice until adding to plate. Discard any unused portion of the aliquot.
class Protocol
  include DiagnosticRTqPCRHelper

  VOL_WATER = { qty: 1, units: MILLILITERS }.freeze
  VOL_SUSPENSION = { qty: 30, units: MICROLITERS }.freeze
  OUTPUT_ITEMS_NUM = { qty: 33, units: TUBE_MICROFUGE }.freeze

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

    # 1. Get 33 1.5 mL tube for each operation
    get_tubes(count: operations.length)
    operations.retrieve

    # 2. For each Lyophilized Postive Control, resuspend in 1 mL of
    # nuclease-free waterand, aliquot 33 use aliquots (approximately
    # 30 uL) and store at less than and equal to -70C.
    save_output(ops: operations)

    suspend_lyophilized_RNA
    keep_tubes = [] # Empty array for storing single use aliquots

    # Group the operations by the input reagent
    ops_by_input = operations.group_by { |op| op.input(TEMPLATE).item }
    ops_by_input.each do |lyophilized_rna, ops|
      keep_tubes.push(make_aliquots(ops: ops, lyophilized_rna: lyophilized_rna))
    end

    prepare_plating(keep_tubes: keep_tubes)

    # 3. Thaw a single aliquot of diluted positive control for each
    # experiment and hold on ice until adding to plate.
    # Discard any unused portion of the aliquot.
    operations.store(interactive: true, io: 'output', method: 'boxes')
  end

  # Get 33 1.5 mL tubes per dried positive control
  #
  # @param count [Integer] the number of operations
  def get_tubes(count:)
    show do
      title "Get new #{TUBE_MICROFUGE}"
      check "Please get #{count * OUTPUT_ITEMS_NUM[:qty]} #{TUBE_MICROFUGE}"
    end
  end

  # Label the tubes so that the same reagents have consecutive IDs
  # And move the output tubes to the right storage locations
  # @param operations [OperationList] The list of operations
  def save_output(ops:)
    ops.make

    # Declare references to output objects
    ops.each do |op|
      op.output(TEMPLATE).item.associate :volume, VOL_SUSPENSION[:qty]

      output_RNA = op.output(TEMPLATE).sample
      # makes 32 additional aliquots per op
      (OUTPUT_ITEMS_NUM[:qty] - 1).times do
        new_aliquot = output_RNA.make_item('Purified RNA in 1.5 mL tube')
        new_aliquot.associate :volume, VOL_SUSPENSION[:qty]
        link_output_item(operation: op, sample: output_RNA, item: new_aliquot)
      end
    end
  end

  # Manually link the item to the operation as an output
  #
  # @param op [Operation] the operation that creates the items
  # @param sample [Sample] the sample of the item
  # @param item [Item] the item that is created
  def link_output_item(operation:, sample:, item:)
    fv = FieldValue.new(
      name: TEMPLATE,
      child_item_id: item.id,
      child_sample_id: sample.id,
      role: 'output',
      parent_class: 'Operation',
      parent_id: operation.id,
      field_type_id: operation.output(TEMPLATE).field_type.id
    )
    fv.save
  end

  # Performs the resuspension protocol for a list of operations
  # that all use the given lyophilized_RNA input.
  def suspend_lyophilized_RNA()
    show do
      title 'Resuspend Positive Template'
      warning "This reagent should be handled with caution in a dedicated \
      nucleic acid handling area to prevent possible contamination."
      warning "Freeze-thaw cycles should be avoided. Maintain on ice when \
      thawed."
      check "Resuspend dried Lyophilized Postive Control RNA in each tube in \
      #{qty_display(VOL_WATER)} of nuclease-free water to achieve the \
      proper concentration."
    end
  end

  # Performs the aliquote protocol for a list of operations
  # that all use the given lyophilized_RNA input.
  # @param make_aliquots [Item] the lyophilized_RNA
  # @param operations     [OperationList] the list of operations
  def make_aliquots(ops:, lyophilized_rna:)
    last_tube_id = '' # Empty string for storing item id of single use aliquot
    ops.each do |op|
      input_rnas = Array.new(OUTPUT_ITEMS_NUM[:qty], lyophilized_rna.id)
      aliquot_tubes = op.outputs.map{ |output| output.item.id }
      transfer_table = Table.new
                            .add_column('Lyophilized RNA', input_rnas)
                            .add_column('Output RNA Aliquot', aliquot_tubes)

      show do
        title 'Aliquot Single Used Aliquot Positive Template'
        check "Make single use aliquot by transfering \
        #{qty_display(VOL_SUSPENSION)} of the diluted postive control into \
        individual #{TUBE_MICROFUGE} and label it with the proper item ID."
        check 'Discard the empty input tube'
        table transfer_table
      end

      # Discard the input
      lyophilized_rna.mark_as_deleted

      # Retrieve the last item of the single use aliquot
      last_tube_id = aliquot_tubes[-1]
    end
    last_tube_id
  end

  # Prepare for plating protocol for a list of operations
  # that all use the given Purified RNA in 1.5 mL tube output.
  # @param keep_tubes [Item] Items to be kept on bench for immediate use
  def prepare_plating(keep_tubes:)
    show do
      title 'Preparation of Single Aliquot for Plating'
      warning "This reagent should be handled with caution in a dedicated\
      nucleic acid handling area to prevent possible contamination."
      warning 'Avoid freeze-thaw cycles. Maintain on ice when thawed.'
      # Retrieve the last item of the single use aliquot
      check "Thaw a single aliquot of diluted positive control #{keep_tubes} \
      for each experiment and hold on ice until adding to plate."
      check 'Discard any unused portion of the aliquot.'
    end

    # Don't store the single aliquot being used during plating
    keep_tubes.each do |id| Item.find(id).mark_as_deleted end
  end
end
