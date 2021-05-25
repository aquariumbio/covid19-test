# frozen_string_literal: true

needs 'Thermocyclers/AbstractThermocycler'

# Template for making new thermocycler classes
#   If you intend to make a new qPCR thermocycler class,
#   use `QPCRThermocyclerTemplate`
#
# @author Devin Strickland <strcklnd@uw.edu>
class ThermocyclerTemplate < AbstractThermocycler
  # CONSTANTS that really shouldn't ever change
  MODEL = ''

  # Instantiates the class
  #
  # @return [ThermocyclerTemplate]
  def initialize
    super()
  end

  # Lab-specific, user-defined parameters
  #
  # @return [Hash]
  def user_defined_params
    {
      experiment_filepath: 'Desktop/my_experiment_path',
      export_filepath: 'Desktop/my_export_path',
      image_path: 'Actions/ThermocyclerTemplate'
    }
  end

  ########## Language Methods
  # These methods are not very specific and will probably need to be overridden
  #   in the concrete classes.

  # # Instructions for turning on the thermocycler
  # #
  # # @return [String]
  # def turn_on()
  #   "Turn on the #{model}"
  # end

  # # Instructions for placing a plate in the instrument
  # #
  # # @param plate [Collection]
  # # @return [String]
  # def place_plate_in_instrument(plate:)
  #   "Place plate #{plate} in the thermocycler"
  # end

  # # Instructions for confirming the orientation of a plate in the instrument
  # #
  # # @return [String]
  # def confirm_plate_orientation()
  #   "MAKE SURE THAT THE PLATE IS IN THE CORRECT ORIENTATION"
  # end

  # # Instructions for opening the lid
  # #
  # # @return [String]
  # def open_lid()
  #   "Click the <b>Open Lid</b> button"
  # end

  # # Instructions for closing the lid
  # #
  # # @return [String]
  # def close_lid()
  #   "Click the <b>Close Lid</b> button"
  # end

  # # Instructions for starting the run
  # #
  # # @return [String]
  # def start_run()
  #   "Click the <b>Start Run</b> button"
  # end
end
