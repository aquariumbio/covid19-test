# frozen_string_literal: true

needs 'RNA Extraction Kits/QiagenRNAExtractionHelper'

# Module for QIAamp DSP Viral RNA Mini Kit
#
# @author Devin Strickland <strcklnd@uw.edu>
module QIAampDSPViralRNAMiniKit
  include QiagenRNAExtractionHelper

  NAME = 'QIAamp DSP Viral RNA Mini Kit'

  COLUMN_LONG = 'QIAamp Mini spin column'

  MIN_SAMPLE_VOLUME =     { qty: 140, units: MICROLITERS }.freeze
  DEFAULT_SAMPLE_VOLUME = MIN_SAMPLE_VOLUME
  WASH_VOLUME =           { qty: 500, units: MICROLITERS }.freeze

  CENTRIFUGE_SPEED = { qty: 6000, units: TIMES_G }.freeze
  CENTRIFUGE_TIME = { qty: 1, units: MINUTES }.freeze

  def prepare_materials
    show do
      title 'Things to do before starting'
      bullet "Equilibrate samples to room temperature (15-25#{DEGREES_C})"
      bullet 'Equilibrate Buffer AVE to room temperature'
      # TODO: Need some way of indicating this has been done
      bullet 'Check that Buffer AW1 and Buffer AW2 have been prepared ' \
        'according to the instructions'
      # TODO: Need some way of indicating this has been done
      bullet 'Add carrier RNA reconstituted in Buffer AVE to Buffer AVL ' \
        'according to the instructions'
    end
  end

  def notes_on_handling
    qiagen_notes_on_handling
  end

  # @todo will we be working with a different sample volume for each operation?
  # @todo make use_operations do this^
  def lyse_samples_constant_volume(sample_volume: DEFAULT_SAMPLE_VOLUME,
                                   expert: false)
    # TODO: Move this logic up to the calling method
    if sample_volume[:qty] < MIN_SAMPLE_VOLUME[:qty]
      msg = "Sample volume must be > #{qty_display(MIN_SAMPLE_VOLUME)}"
      raise ProtocolError, msg
    end
    buffer_volume = lysis_buffer_volume(sample_volume: sample_volume)
    ethanol_volume = ethanol_volume(sample_volume: sample_volume)

    show do
      title 'Lyse Samples'

      # TODO: Add Pipettor module
      note "Pipet #{qty_display(buffer_volume)} of prepared Buffer AVL " \
        'containing carrier RNA into a lysis tube (LT).'
      # If the sample volume is larger than 140 ul, increase the amount of
      # Buffer AVL-carrier RNA proportionally (e.g., a 280 ul sample will
      # require 1120 ul Buffer AVL-carrier RNA) and use a larger tube.
      note "Add #{qty_display(sample_volume)} plasma, serum, urine, " \
        'cell-culture supernatant, or cell- free body fluid to the ' \
        'Buffer AVL-carrier RNA in the lysis tube (LT).'
      note "Mix by pulse-vortexing for 15 #{SECONDS}."
      warning 'To ensure efficient lysis, it is essential that the sample ' \
        'is mixed thoroughly with Buffer AVL to yield a homogeneous solution'
      # Frozen samples that have only been thawed once can also be used.
      note "Incubate at room temperature (15-25#{DEGREES_C}) for 10 #{MINUTES}"
    end

    show do
      title 'Add Ethanol'

      note 'Briefly centrifuge the lysis tube (LT) to remove drops from ' \
        'the inside of the lid.'
      note "Add #{qty_display(ethanol_volume)} ethanol (96-100%) to the " \
        'sample, and mix by pulse-vortexing for >15 seconds. ' \
        'After mixing, briefly centrifuge the tube to remove drops from ' \
        'inside the lid.'
      # Only ethanol should be used since other alcohols may result in
      # reduced RNA yield and purity. Do not use denatured alcohol, which
      # contains other substances such as methanol or methylethylketone.
      # If the sample volume is greater than 140 ul, increase the amount of
      # ethanol proportionally (e.g., a 280 ul sample will require
      # 1120 ul of ethanol). In order to ensure efficient binding, it is
      # essential that the sample is mixed thoroughly with the ethanol
      # to yield a homogeneous solution.
    end
  end

  def lyse_samples_variable_volume(operations:, expert: false)
    msg = 'Method lyse_samples_variable_volume is not supported for ' \
      'QIAamp DSP Viral RNA Mini Kit'
    raise ProtocolError, msg
  end

  def bind_rna(operations: [], sample_volume: DEFAULT_SAMPLE_VOLUME,
               expert: false)
    loading_volume, n_loads = loading_volume(sample_volume: sample_volume)

    show do
      title 'Add Samples to Columns'

      note "Carefully apply #{qty_display(loading_volume)} of the " \
        "sample solution to the #{COLUMN_LONG} (in a #{WASH_TUBE_LONG}) " \
        'without wetting the rim.'
      note "Close the cap, and centrifuge at #{CENTRIFUGE_SPEED} " \
        "for #{CENTRIFUGE_TIME}. Place the #{COLUMN_SHORT} into a clean" \
        "#{WASH_TUBE_SHORT}, and discard the old #{WASH_TUBE_SHORT} " \
        'containing the filtrate.'
      warning 'Close each spin column in order to avoid cross-contamination ' \
        'during centrifugation.'
      # Centrifugation is performed at approximately 6000 x g in order to limit
      # microcentrifuge noise. Centrifugation at full speed will not affect the
      # yield or purity of the viral RNA. If the solution has not completely
      # passed through the membrane, centrifuge again at a higher speed
      # until all of the solution has passed through.
      separator

      # Harmonize handling of repeats with RNeasy kit
      note "Carefully open the #{COLUMN_SHORT}, and repeat the loading until " \
        'all of the lysate has been loaded onto the spin column.'
    end
  end

  def wash_rna(operations: [], expert: false)
    show do
      title 'Wash with Buffer AW1'

      note "Carefully open the #{COLUMN_LONG}, and add " \
        "#{qty_display(WASH_VOLUME)} Buffer AW1."
      note 'Close the cap, and centrifuge at ' \
        "#{CENTRIFUGE_SPEED} for #{CENTRIFUGE_TIME}."
      note "Place the #{COLUMN_SHORT} in a clean #{WASH_TUBE_LONG}, " \
        "and discard the #{WASH_TUBE_SHORT} containing the filtrate."
      # It is not necessary to increase the volume of Buffer AW1 even if the
      # original sample volume was larger than 140 ul.
    end

    show do
      title 'Wash with Buffer AW2'

      note "Carefully open the #{COLUMN_LONG}, and add " \
        "#{qty_display(WASH_VOLUME)} Buffer AW2."
      # This centrifuge speed is meant to be different
      note 'Close the cap and centrifuge at full speed ' \
        "(approximately 20,000 #{TIMES_G}) for 3 #{MINUTES}."
      separator

      note "Place the #{COLUMN_SHORT} in a new #{WASH_TUBE_LONG}, " \
        "and discard the #{WASH_TUBE_SHORT} containing the filtrate."
      # This centrifuge speed is meant to be different
      note "Centrifuge at full speed for 1 #{MINUTES}."
    end
  end

  def elute_rna(operations: [], expert: false)
    show do
      title 'Elute RNA'

      note "Place the #{COLUMN_LONG} in a clean #{ELUTION_TUBE_LONG}."
      note 'Discard the wash tube containing the filtrate.'
      note "Carefully open the #{COLUMN_SHORT} and add " \
        "60 #{MICROLITERS} of Buffer AVE equilibrated to room temperature."
      note "Close the cap, and incubate at room temperature for >1 #{MINUTES}."
      note "Centrifuge at #{CENTRIFUGE_SPEED} " \
        "for #{CENTRIFUGE_TIME}."
    end
  end

  private

  def lysis_buffer_volume(sample_volume:)
    unless sample_volume[:units] == MICROLITERS
      raise ProtocolError, "Parameter :sample_volume must be in #{MICROLITERS}"
    end

    qty = sample_volume[:qty] * 560 / 140
    { qty: qty, units: MICROLITERS }
  end

  def ethanol_volume(sample_volume:)
    qty = lysis_buffer_volume(sample_volume: sample_volume)
    { qty: qty, units: MICROLITERS }
  end

  # TODO: Is this right?
  def loading_volume(sample_volume:)
    qty = 630
    n_loads = 2
    [{ qty: qty, units: MICROLITERS }, n_loads]
  end
end
