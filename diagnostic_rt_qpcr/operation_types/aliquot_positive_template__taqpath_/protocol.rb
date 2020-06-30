# Aliquot TaqPath Positive Control Protocol
# Written By Rita Chen 2020-06-24

# Use this procedure if you extracted sample RNA using an original sample input
# volume of 200 μL, and the input volume of the qPCR Assay plate is 20 µL in a
# 384-well PCR plate.
# 1. If frozen, thaw the reagents on ice.
# 2. Gently vortex the reagents, then centrifuge briefly to collect
# liquid at the bottom of the tubes.
# 3. Dilute TaqPath™ COVID‑19 Control (1 × 10^4 copies/μL) to a working stock of
# 25 copies/μL:
# a. Pipet 98 μL of TaqPath™ COVID‑19 Control Dilution Buffer into a
# microcentrifuge tube, then add 2 μL of diluted TaqPath™ COVID‑19 Control to
# an intermediate stock of 200 copies/μL.
# Mix well, then centrifuge briefly.
# b. Pipet 87.5 μL of TaqPath™ COVID‑19 Control Dilution Buffer into a second
# microcentrifuge tube, then add 12.5 μL of the dilution created in
# substep 3a. Mix well, then centrifuge briefly.

needs "Standard Libs/LabwareNames"

class Protocol
  include Units
  include LabwareNames

  def default_job_params
    {
      output_items_num: 40,
      suspension_vol: 100,
      input_vol_1: 10,
      input_vol_2: 12.5,
      dilution_vol_1: 98*5,
      dilution_vol_2: 87.5,
      RNA_freezer: "M80P", # location wizard of RNA freezer at DAMPLab
    }
  end

  def main
    # 1. Get 41 1.5 mL tube for each operation
    get_tubes(count: operations.length)
    operations.retrieve

    # 2. Dilute TaqPath™ COVID‑19 Control (1 × 10^4 copies/μL) to a working
    # stock of 25 copies/μL, and store at -70C.
    save_output(operations)
    dilute_RNA_stock(operations)

    # Group the operations by the input reagent
    ops_by_input = operations.group_by {|op| op.input("Template").item}
    ops_by_input.each do |rna_stock, ops|
      make_aliquots(ops, rna_stock: rna_stock)
    end

    operations.store(interactive: true, io: "output", method: "boxes")
  end

  # Get 41 1.5 mL tubes per preparing positive control
  #
  # @param count [Integer] the number of operations
  def get_tubes(count:)
    show do
      title "Get new #{TUBE_MICROFUGE}"
      check "Please get #{count*(default_job_params[:output_items_num] + 1)}\
      #{TUBE_MICROFUGE}"
    end
  end

  # Label the tubes so that the same reagents have consecutive IDs
  # And move the output tubes to the right storage locations
  #
  # @param operations [OperationList] The list of operations
  def save_output(operations)
    operations.make

    #Declare references to output objects
    operations.each do |op|
      op.output("Template").item.associate :volume,\
      default_job_params[:suspension_vol]

      output_RNA = op.output("Template").sample
      for i in 0..38 # makes 39 additional aliquots per op
        new_aliquot = output_RNA.make_item("Purified RNA in 1.5 mL tube")
        new_aliquot.associate :volume, default_job_params[:suspension_vol]
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
      name: "Template",
      child_item_id: item.id,
      child_sample_id: sample.id,
      role: "output",
      parent_class: "Operation",
      parent_id: operation.id,
      field_type_id: operation.output("Template").field_type.id
    )
    fv.save
  end

  #Performs the resuspension protocol for a list of operations
  #that all use the given rna_stock input.
  #
  # @param dilute_RNA_stock [Item] the rna_stock
  # @param operations     [OperationList] the list of operations
  def dilute_RNA_stock(operations)

    show do
      title "Dilute Positive Template to Intermediate Concentration"
      warning "This reagent should be handled with caution in a dedicated\
      nucleic acid handling area to prevent possible contamination."
      warning "Freeze-thaw cycles should be avoided. Maintain on ice when\
      thawed."
      check "Transfer #{default_job_params[:input_vol_1]} #{MILLILITERS}\
       of Postive Control RNA into a microcentrifuge tube and label\
       the tubes as intermediate tube (IT)."
      check "Pipette in #{default_job_params[:dilution_vol_1]} #{MILLILITERS} \
      of COVID‑19 Control Dilution Buffer to achieve the proper intermediate\
       concentration."
      check "Gently vortex the solution and centrifuge the tube briefly."
    end
  end

  #Performs the aliquote protocol for a list of operations
  #that all use the given rna_stock input.
  #
  # @param make_aliquots [Item] the rna_stock
  # @param operations     [OperationList] the list of operations
  def make_aliquots(operations, rna_stock:)
    last_tube_id = "" # Empty string for storing item id of single use aliquot
    operations.each do |op|
      input_RNAs = Array.new(default_job_params[:output_items_num],\
        rna_stock.id)
      aliquot_tubes = op.outputs().map{|output| output.item.id}
      transfer_table = Table.new
              .add_column("RNA Stock", input_RNAs)
              .add_column("Output RNA Aliquot", aliquot_tubes)

      show do
        title "Dilute Positive Template to Working Stock of 25 copies/μL\
        and Aliquot Single Used Aliquot Positive Controls"
        warning "This reagent should be handled with caution in a dedicated\
        nucleic acid handling area to prevent possible contamination."
        warning "Freeze-thaw cycles should be avoided. Maintain on ice when\
        thawed."
        check "Make single use aliquot by transfering\
        #{default_job_params[:input_vol_2]} #{MICROLITERS} of the diluted\
        postive control (IT) into individual #{TUBE_MICROFUGE} and label it\
         with the proper item ID."
        check "Pipette in #{default_job_params[:dilution_vol_2]} #{MILLILITERS}\
         of COVID‑19 Control Dilution Buffer into individual #{TUBE_MICROFUGE}\
         to achieve the proper working concentration."
        check "Gently vortex the solutions, centrifuge all tubes briefly, and\
         store at -80C."
        check "Discard the empty input and intermediate tubes."
        table transfer_table
      end

      # Discard the input
      rna_stock.mark_as_deleted
    end
  end

end
