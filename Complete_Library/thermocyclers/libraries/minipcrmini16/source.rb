# frozen_string_literal: true

needs 'Thermocyclers/AbstractThermocycler'

# miniPCR mini16
# minipcrbio.com
#
# @author Devin Strickland <strcklnd@uw.edu>
# @todo This is a complicated class because it is a software driven
#   thermocycler that can be run on a variety of desktop or mobile
#   platforms.
class MiniPCRMini16 < AbstractThermocycler
  # CONSTANTS that really shouldn't ever change
  MODEL = 'miniPCR mini16'

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
      image_path: 'Actions/MiniPCRMini16',
      dimensions: [2,8]
    }
  end

  ########## Language Methods
  # These methods are not very specific and will probably need to be overridden
  #   in the concrete classes.

  # Instructions for turning on the thermocycler
  #
  # @return [String]
  def turn_on
    format_show_array([
      'Connect the miniPCR thermal cycler via USB cable or Bluetooth',
      "Turn on the #{MODEL} using the on/off switch on the back of the unit"
    ])
  end

  # Instructions for placing a plate in the instrument
  #
  # @param plate [Collection]
  # @return [String]
  def place_plate_in_instrument(plate:)
    'Load the PCR tubes into the metal block'
  end

  # Instructions for confirming the orientation of a plate in the instrument
  #
  # @return [String]
  def confirm_plate_orientation
    ''
  end

  # Instructions for selecting the PCR program template
  #
  # @param program [PCRProgram]
  # @return [String]
  def select_program_template(program:)
    file = program_template_file(program: program)
    "Select the #{file} protocol from the Library"
  end

  # Instructions for opening the lid
  #
  # @return [String]
  def open_lid
    format_show_array([
      'Open the lid by pinching the side tabs on the front plate of the miniPCR',
      'Use your thumb and index fingers to pinch, and lift the lid with your other hand'
    ])
  end

  # Instructions for closing the lid
  #
  # @return [String]
  def close_lid
    format_show_array([
      'Fully untwist (counterclockwise) the adjustment knob',
      'Press the lid down until it clicks shut',
      'Tighten the adjustment knob (clockwise) until you feel light resistance from the tube caps',
      'Be careful not to over-tighten'
    ])
  end

  # Instructions for starting the run
  #
  # @return [String]
  def start_run
    format_show_array([
      'Click the <b>Run</b> button',
      'The run will automatically begin, signaled by the green LED turning on'
    ])
  end

  def setup_program_image; end
end
