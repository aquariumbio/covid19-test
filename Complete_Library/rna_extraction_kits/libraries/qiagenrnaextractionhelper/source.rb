# frozen_string_literal: true

needs 'Standard Libs/Units'

# Module for common methods and constants in Qiagen RNA extraction kits
#
# @author Devin Strickland <strcklnd@uw.edu>
module QiagenRNAExtractionHelper
  include Units

  COLUMN_LONG = 'Qiagen spin column'
  COLUMN_SHORT = 'spin column'

  LYSIS_TUBE_LONG = 'lysis tube (LT)'
  LYSIS_TUBE_SHORT = 'LT'

  WASH_TUBE_LONG = "2 #{MILLILITERS} wash tube (WT)"
  WASH_TUBE_SHORT = 'WT'

  ELUTION_TUBE_LONG = 'elution tube (ET)'
  ELUTION_TUBE_SHORT = 'ET'

  # @note adapted from QIAamp DSP Viral RNA Mini Kit
  # @todo determine how much of the detail to keep or change
  def qiagen_notes_on_handling
    show do
      title "Handling of #{COLUMN_LONG.pluralize}"

      note 'Due to the sensitivity of nucleic acid amplification ' \
        'technologies, the following precautions are necessary when handling ' \
        "#{COLUMN_LONG.pluralize} to avoid cross contamination between " \
        'sample preparations:'
      bullet "Carefully apply the sample or solution to the #{COLUMN_SHORT}. " \
        "Pipet the sample into the #{COLUMN_SHORT} " \
        'without wetting the rim of the column.'
      bullet 'Always change pipet tips between liquid transfers. ' \
        'We recommend the use of aerosol-barrier pipet tips.'
      bullet "Avoid touching the #{COLUMN_SHORT} membrane with " \
        'the pipet tip.'
      bullet 'After all pulse-vortexing steps, briefly centrifuge the ' \
       'microcentrifuge tubes to remove drops from the inside of the lids.'
      bullet "Open only one #{COLUMN_SHORT} at a time, and take care " \
        'to avoid generating aerosols.'
      bullet 'Wear gloves throughout the entire procedure. In case of ' \
        'contact between gloves and sample, change gloves immediately.'
    end
  end
end
