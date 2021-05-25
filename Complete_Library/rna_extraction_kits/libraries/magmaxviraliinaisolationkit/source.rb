# frozen_string_literal: true
# Written By Dany Fu 2020-05-18

needs 'Standard Libs/LabwareNames'

# MagMAX Viral/Pathogen II Nucleic Acid Isolation Kit
# 1) Suspend magnetic beads in buffer
# 2) Proteinase K digestion
# 3) Wash beads (3x)
# 4) Release RNA from beads
module MagMAXViralIINAIsolationKit
  include Units
  include LabwareNames

  NAME = 'MagMAX Viral/Pathogen II Nucleic Acid Isolation Kit'

  OVERAGE = 1.1 # additional 10%
  PLATE_SIZE = 96
  SPEED = 1050 # RPM
  TEMP = 65 # celcius
  TIME1 = 1 # 1 min
  TIME2 = 2 # 2 min
  TIME3 = 3 # 3 min
  TIME5 = 5 # 5 min
  TIME10 = 10 # 10 min
  VOL_BEADS_PER_WELL = 10.0
  VOL_BS_PER_WELL = 265.0
  VOL_CONICAL_TUBE_ML = 15
  VOL_ELUTION = { qty: 50, units: MICROLITERS }.freeze
  VOL_ETHANOL = { qty: 250, units: MICROLITERS }.freeze
  VOL_MS2 = { qty: 5, units: MICROLITERS }.freeze
  VOL_PROTEINASE_K = { qty: 5, units: MICROLITERS }.freeze
  VOL_SAMPLE = { qty: 200, units: MICROLITERS }.freeze
  VOL_WB = { qty: 500, units: MICROLITERS }.freeze # wash buffer

  # 265uL(buffer) + 10uL(beads)=275uL per well
  # Include 10% overage when making the Binding Bead Mix
  # for use with multiple reactions
  def prepare_materials
    total_beads = ((PLATE_SIZE * VOL_BEADS_PER_WELL * OVERAGE) / 1000).round(2)
    total_bs = ((PLATE_SIZE * VOL_BS_PER_WELL * OVERAGE) / 1000).round(2)
    total_vol = total_beads + total_bs
    num_tubes = { qty: (total_vol / VOL_CONICAL_TUBE_ML).round,
                  units: TUBE_15_ML_CONICAL }
    bs_per_tube = { qty: total_bs / num_tubes[:qty], units: MILLILITERS }
    beads_per_tube = { qty: total_beads / num_tubes[:qty], units: MILLILITERS }

    show do
      title 'Prepare Binding Bead Mix'
      check "Vortex the Total Nucleic Acid Magnetic Beads to ensure \
            that the bead mixture is homogeneous"
      check "Add #{qty_display(bs_per_tube)} Binding Solution per tube to \
            #{qty_display(num_tubes)}"
      check "Add #{qty_display(beads_per_tube)} Nucleic Acid Magnetic Beads \
            per tube to #{qty_display(num_tubes)}"
      check 'Mix well by inversion, leave at room temperature'
    end
  end

  def notes_on_handling; end

  def lyse_samples_constant_volume(sample_volume:, expert:)
    make_sample_plate(sample_volume: sample_volume)
    add_reagents_and_beads
    shake(time: TIME2, covered: true)
    incubate(time: TIME5)
    shake(time: TIME5, covered: true)
    collect_beads(time: TIME10)
  end

  def make_sample_plate(sample_volume: nil)
    sample_volume ||= VOL_SAMPLE
    operations.each do |op|
      input_plate = op.input('Specimen')
      show do
        title 'Add Samples to New Plate'
        check "Make a 96 deepwell plate according to the following table using \
              #{qty_display(sample_volume)} of sample"
        check "Add #{qty_display(sample_volume)} of water to the wells marked \
              by X as negative controls"
        check 'Mark the Negative Control well on the plate'

        title 'New Plate'
        table input_plate.collection.matrix
      end
    end
  end

  def add_reagents_and_beads
    show do
      title 'Add Reagents and Beads'
      check "Add #{qty_display(VOL_PROTEINASE_K)} of Proteinase K to each \
            well of deepwell 96 Plate"
      check "Invert the Binding Bead Mix 5 times gently to mix, then add \
            #{qty_display(VOL_PROTEINASE_K)} to each sample well and \
            Negative Control well"
      warning "Remix the Binding Bead Mix by inversion frequently during \
              pipetting to ensure even distribution of beads to all wells."
      warning "The Binding Bead Mix is viscous, so pipet slowly to ensure \
              that the correct amount is added"
      check "Add #{qty_display(VOL_MS2)} of MS2 Phage Control to each sample \
            well and to the Negative Control well."
      check 'Seal the plate with clear adhesive film'
    end
  end

  def shake(time:, covered:)
    cover = covered ? 'covered' : 'uncovered'
    show do
      title 'Shake Plate'
      check "Shake the <b>#{cover}</b> plate at #{SPEED} RPM for \
            #{time} #{MINUTES}"
      timer initial: { minutes: time }
    end
  end

  def incubate(time:)
    show do
      title 'Incubate Sealed Plate'
      note 'Ensure the bottom of the plate is uncovered'
      check "Incubate plate at #{TEMP} #{DEGREES_C}for #{time} #{MINUTES}"
      timer initial: { minutes: time }
    end
  end

  def collect_beads(time:)
    show do
      title 'Collect Beads on Magnetic Stand'
      check "Place the sealed plate on the magnetic stand for \
            #{time} #{MINUTES} or until all of the beads have collected"
    end
  end

  def bind_rna(operations:, sample_volume:, expert:); end

  def wash_rna(operations:, expert:)
    wash_beads(reagent: 'Wash Buffer', vol: VOL_WB[:qty])
    wash_beads(reagent: '80% Ethanol', vol: VOL_WB[:qty]) # same as wash buffer
    wash_beads(reagent: '80% Ethanol', vol: VOL_ETHANOL[:qty])
    shake(time: TIME2, covered: false) # dry beads
  end

  def wash_beads(reagent:, vol:)
    discard_supernant if reagent == 'Wash Buffer'
    wash(reagent: reagent, vol: vol)
    shake(time: TIME1, covered: true)
    collect_beads(time: TIME2)
    discard_supernant
  end

  def discard_supernant
    show do
      title 'Discard supernant'
      warning 'IMPORTANT! Avoid disturbing the beads'
      check "Keeping the plate on the magnet, carefully remove the cover, \
            then discard the supernatant from each well"
    end
  end

  def wash(reagent:, vol:)
    show do
      title 'Wash Beads'
      check "Remove the plate from the magnetic stand, then add \
            #{vol} #{MICROLITERS} of #{reagent} to each sample"
    end
  end

  def elute_rna(operations:, expert:)
    add_elution_solution
    shake(time: TIME5, covered: true)
    incubate(time: TIME10)
    shake(time: TIME5, covered: true)
    collect_beads(time: TIME3)
    make_qpcr_plate(ops: operations)
  end

  def add_elution_solution
    show do
      title 'Add Elution Solution'
      check "Remove the plate from the magnetic stand, then add \
            #{qty_display(VOL_ELUTION)} of Elution Solution to each sample"
      check 'Seal the plate with Clear Adhesive Film'
    end
  end

  def make_qpcr_plate(ops:)
    ops.make
    ops.each do |op|
      input_collection = op.input('Specimen').collection
      input_collection.mark_as_deleted
      output_collection = op.output('Specimen').collection
      output_collection.associate_matrix(input_collection.matrix)
    end
    show do
      title 'Make qPCR Plate'
      warning "Pay special attention to transfer liquid solution only. \
              Significant bead carry over may adversely impact qPCR performance"
      check 'Keeping the plate on the magnet, carefully remove the seal'
      check 'Transfer the eluates to a 96 well qPCR plate'
      check 'Mark the Negative Control well on the plate'
      check 'Seal the new plate with Clear Adhesive Film'
      check 'Place the plate on ice for immediate use in qPCR'
    end
  end
end
