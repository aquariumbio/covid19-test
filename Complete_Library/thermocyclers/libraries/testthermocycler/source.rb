# frozen_string_literal: true

needs 'Thermocyclers/AbstractThermocycler'

# Class to use as a generic qPCR thermocycler for testing
#
# @author Devin Strickland <strcklnd@uw.edu>
class TestThermocycler < AbstractThermocycler
  include QPCRMixIn

  # CONSTANTS that really shouldn't ever change
  MODEL = 'Test Model'
  PROGRAM_EXT = '.abc'
  LAYOUT_EXT =  'xyz' # Intentionally missing leading dot for test
  SOFTWARE_NAME = 'Test Software'

  # Instantiates the class
  #
  # @return [TestThermocycler]
  def initialize
    super()
  end

  # Lab-specific, user-defined parameters
  #
  # @return [Hash]
  def user_defined_params
    {
      experiment_filepath: 'Desktop/test_experiment_path',
      export_filepath: 'Desktop/test_export_path',
      image_path: 'Actions/TestThermocycler',
      dimensions: [8,12]
    }
  end

  def say_hello
    "Hello, my name is #{MODEL}"
  end
end
