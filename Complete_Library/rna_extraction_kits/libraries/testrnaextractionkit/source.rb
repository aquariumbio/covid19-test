# frozen_string_literal: true

needs 'Standard Libs/Units'

# Minimal RNA Extraction Kit Module for testing
#
# @author Devin Strickland <strcklnd@uw.edu>
module TestRNAExtractionKit
  include Units

  NAME = 'Test RNA Extraction Kit'

  MIN_SAMPLE_VOLUME =     { qty: 140, units: MICROLITERS }.freeze
  DEFAULT_SAMPLE_VOLUME = MIN_SAMPLE_VOLUME

  def prepare_materials
    show do
      title 'Things to do before starting'
    end
  end

  def notes_on_handling
    show do
      title 'Handling Materials'
    end
  end

  def lyse_samples_constant_volume(sample_volume:, expert: false)
    show do
      title 'Lyse Samples Constant Volume'

      note "Sample volume: #{qty_display(sample_volume)}"
    end
  end

  def lyse_samples_variable_volume(operations:, expert: false)
    show do
      title 'Lyse Samples Variable Volume'

      operations.each { |op| note "Sample volume: #{sample_volume(op)}" }
    end
  end

  def bind_rna(operations: [], sample_volume: DEFAULT_SAMPLE_VOLUME,
               expert: false)
    show do
      title 'Add Samples to Columns'
    end
  end

  def wash_rna(operations: [], expert: false)
    show do
      title 'Wash with Buffer'
    end
  end

  def elute_rna(operations: [], expert: false)
    show do
      title 'Elute RNA'
    end
  end
end
