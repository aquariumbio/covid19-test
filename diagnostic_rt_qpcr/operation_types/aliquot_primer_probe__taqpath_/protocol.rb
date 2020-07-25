# Aliquot TaqPath Multiplex Primers/Probes Protocol
# Written By Rita Chen 2020-06-24

# Use this procedure if you extracted sample RNA using an original sample input
# volume of 200 µL, and the input volume of the qPCR Assay plate is 20 µL in a
# 384-well PCR plate.
# 1. If frozen, thaw the solution on ice.
# 2. Gently vortex the solution, then centrifuge briefly to collect liquid
# at the bottom of the tube.
# 3. Aliquot the COVID-19 real-time PCR assay multplex:
# a. Aliquot the single tube of 1500 µL COVID-19 real-time PCR assay multplex
# primers/probes into 15 microcentrifuge tubes of 100 µL COVID-19 real-time
# PCR assay multplex.
# b. Centrifuge briefly, and store at -20C.

needs "Standard Libs/LabwareNames"

class Protocol
  include Units
  include LabwareNames

  def default_job_params
    {
      output_items_num: 15,
      aliquot_vol: 100,
      RNA_freezer: "M20O", # location wizard of RNA freezer at DAMPLab
    }
  end

  def main
    # 1. Get 15 1.5 mL tube for each operation
    get_tubes(count: operations.length)
    operations.retrieve

    # 2. Aliquot the single tube of 1500 µL COVID-19 real-time PCR assay multplex
    # primers/probes into 15 microcentrifuge tubes of 100 µL COVID-19 real-time
    # PCR assay multplex. Centrifuge briefly, and store at -20C.
    save_output(operations)

    # Group the operations by the input reagent
    ops_by_input = operations.group_by {|op| op.input("Primer Set").item}
    ops_by_input.each do |primer, ops|
      make_aliquots(ops, primer: primer)
    end

    operations.store(interactive: true, io: "output", method: "boxes")
  end

  # Get 15 1.5 mL tubes per dried reagent
  # @param count [Integer] the number of operations currently running
  def get_tubes(count:)
    show do
      title "Get new #{TUBE_MICROFUGE}"
      check "Please get #{count*default_job_params[:output_items_num]}
      \ #{TUBE_MICROFUGE}"
    end
  end

  # Create and save multiple output Items per operation
  # @param operations [OperationList] List of operations
  def save_output(operations)
    operations.make

    operations.each do |op|
      op.output("Primer Set").item.associate :volume, default_job_params[:aliquot_vol]

      output_primer = op.output("Primer Set").sample
      for i in 0..13 # makes 14 additional aliquots per op
        new_aliquot = output_primer.make_item("Primer Mix Aliquot")
        new_aliquot.associate :volume, default_job_params[:aliquot_vol]
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
      name: "Primer Set",
      child_item_id: item.id,
      child_sample_id: sample.id,
      role: "output",
      parent_class: "Operation",
      parent_id: operation.id,
      field_type_id: operation.output("Primer Set").field_type.id
    )
    fv.save
  end

  # Make 15 aliquots for each primer
  # @param operations [OperationList] The list of operations (grouped by input primer)
  def make_aliquots(operations, primer: )
    operations.each do |op|
      input_primers = Array.new(default_job_params[:output_items_num], primer.id)
      aliquot_tubes = op.outputs().map{|output| output.item.id}
      transfer_table = Table.new
              .add_column("Primer Mix ID", input_primers)
              .add_column("Destination Tube ID", aliquot_tubes)

      show do
        title "Make Aliquots of Multiplex Primers and Probes Stock"
        warning "These reagents should only be handled in a clean area."
        warning "Freeze-thaw cycles should be avoided. Maintain on ice when thawed."
        check "Label destination tube IDs according to the table."
        check "If frozen, thaw the solution on ice."
        check "Gently vortex the solution and aliquot\
               #{default_job_params[:aliquot_vol]} #{MICROLITERS} of the\
               primer into each tube according to the table."
        check "Centrifuge all tubes briefly, and store at -20C."
        check "Discard the empty input tube."
        table transfer_table
      end

      primer.mark_as_deleted # discard the input
    end
  end

end
