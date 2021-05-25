# frozen_string_literal: true

# Warnings for working with BSL2 Hazards,
# Take word for word from OLA-Simple, Vector Graphics have been removed
# for simplicity.
module WorkSpace
  def rnase_warning
    show do
      title 'RNase degrades RNA'
      note 'RNA is prone to degradation by RNase present in our eyes, skin, and breath.'
      note 'Avoid opening tubes outside the Biosafety Cabinet (BSC).'
      bullet 'Change gloves whenever you suspect potential RNAse contamination'
    end
  end

  def safety_warning
    show do
      title 'Review Safety Warnings'
      note '<b>Always</b> pay attention to orange warning blocks throughout the protocol.'
      warning '<b>INFECTIOUS MATERIALS</b>'
      note 'You will be working with infectious materials.'
      note 'Do <b>ALL</b> work in a biosafety cabinet (BSC).'
      note '<b>PPE is required</b>'
      check 'Put on lab coat.'
      check 'Put on 2 layers of gloves.'
      bullet 'Make sure to use tight gloves. Tight gloves reduce the chance of the gloves getting caught on the tubes when closing their lids.'
      bullet 'Change outer layer of gloves after handling infectious sample and before touching surfaces outside of the BSC (such as a refrigerator door handle).'
    end
  end
end
