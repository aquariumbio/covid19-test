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
    {
      prepare_plating: false
    }
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
    operations.retrieve
    water = water_item
    take([water], interactive: true)

    # 2. For each Lyophilized Postive Control, resuspend in 1 mL of
    # nuclease-free waterand, aliquot 33 use aliquots (approximately
    # 30 uL) and store at less than and equal to -70C.
    save_output(ops: operations)

    suspend_lyophilized_rna(water: water, vol_water: VOL_WATER)
    keep_tubes = [] # Empty array for storing single use aliquots

    # Group the operations by the input reagent
    ops_by_input = operations.group_by { |op| op.input(TEMPLATE).item }
    ops_by_input.each do |lyophilized_rna, ops|
      kt = make_aliquots(
        ops: ops,
        lyophilized_rna: lyophilized_rna,
        water: water
      )
      keep_tubes.push(kt)
    end

    prepare_plating(keep_tubes: keep_tubes) if @job_params[:prepare_plating]

    # 3. Thaw a single aliquot of diluted positive control for each
    # experiment and hold on ice until adding to plate.
    # Discard any unused portion of the aliquot.
    operations.store(interactive: true, io: 'output', method: 'boxes')
  end

  # Label the tubes so that the same reagents have consecutive IDs
  # And move the output tubes to the right storage locations
  # @param operations [OperationList] The list of operations
  def save_output(ops:)
    ops.make

    # Declare references to output objects
    ops.each do |op|
      out_ob_type = op.output(TEMPLATE).item.object_type.name
      op.output(TEMPLATE).item.associate :volume, VOL_SUSPENSION[:qty]

      output_rna = op.output(TEMPLATE).sample
      # makes 32 additional aliquots per op
      (OUTPUT_ITEMS_NUM[:qty] - 1).times do
        new_aliquot = output_rna.make_item(out_ob_type)
        new_aliquot.associate :volume, VOL_SUSPENSION[:qty]
        link_output_item(operation: op, sample: output_rna, item: new_aliquot)
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
  # that all use the given lyophilized_rna input.
  def suspend_lyophilized_rna(water:, vol_water:)
    show_suspend_lyophilized_rna(water: water, vol_water: vol_water)
  end

  def show_suspend_lyophilized_rna(water:, vol_water:)
    show do
      title 'Resuspend Positive Template'
      warning "This reagent should be handled with caution in a dedicated \
      nucleic acid handling area to prevent possible contamination."
      warning "Freeze-thaw cycles should be avoided. Maintain on ice when \
      thawed."
      check "Resuspend dried Lyophilized Postive Control RNA in each tube in \
      #{qty_display(vol_water)} of nuclease-free water #{water}."
    end
  end

  # Performs the aliquote protocol for a list of operations
  # that all use the given lyophilized_rna input.
  # @param make_aliquots [Item] the lyophilized_rna
  # @param operations     [OperationList] the list of operations
  def make_aliquots(ops:, lyophilized_rna:, water:)
    last_tube = nil

    ops.each do |op|
      aliquot_items = op.outputs.map(&:item)
      id_ranges = id_ranges_display(items: aliquot_items)
      tubes = TUBE_MICROFUGE.pluralize(aliquot_items.length)

      show do
        title 'Aliquot Positive Template'

        check "Get #{aliquot_items.length} #{tubes}."
        check "Label the tubes #{id_ranges}"
        check "Pipet #{qty_display(VOL_SUSPENSION)} of the resuspended postive \
        control into each of the #{tubes}."
        check "Discard the empty positive control tube #{lyophilized_rna}."
      end

      add_aliquot_provenance(
        stock_item: water,
        aliquot_items: aliquot_items
      )

      add_aliquot_provenance(
        stock_item: lyophilized_rna,
        aliquot_items: aliquot_items
      )

      lyophilized_rna.mark_as_deleted

      if debug
        aliquot = aliquot_items.last
        inspect(lyophilized_rna.associations, lyophilized_rna.id)
        inspect(aliquot.associations, aliquot.id)
      end

      # Retrieve the last item of the single use aliquot
      last_tube = aliquot_items.last
    end
    last_tube.id
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
