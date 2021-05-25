# frozen_string_literal: true

needs 'Thermocyclers/AbstractThermocycler'

# Template for making new qPCR thermocycler classes
#
# @author Devin Strickland <strcklnd@uw.edu>
class ThermocyclerTemplate < AbstractThermocycler
  # CONSTANTS that really shouldn't ever change
  MODEL = ''
  PROGRAM_EXT = ''
  LAYOUT_EXT =  ''
  SOFTWARE_NAME = ''

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
      image_path: 'Actions/ThermocyclerTemplate',
      dimensions: nil
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

  # # Instructions for opening the software that controls the thermocycler
  # #
  # # @return [String]
  # def open_software()
  #   "Open #{software_name}"
  # end

  # # Instructions for setting the dye channel on a qPCR thermocycler
  # #
  # # @param composition [PCRComposition]
  # # @param dye_name [String] can be supplied instead of a `PCRComposition`
  # # @return [String]
  # # @todo should be moved to MixIn
  # def set_dye(composition: nil, dye_name: nil)
  #   dye_name = composition.dye.try(:input_name) || dye_name
  #   "Choose <b>#{dye_name}</b> as the dye"
  # end

  # # Instructions for selecting the PCR program template in the software
  # #
  # # @param program [PCRProgram]
  # # @return [String]
  # def select_program_template(program:)
  #   file = program_template_file(program: program)
  #   "Choose the program template <b>#{file}</b>"
  # end

  # # Instructions for selecting the plate layout template in the software
  # #
  # # @param program [PCRProgram]
  # # @return [String]
  # def select_layout_template(program:)
  #   file = layout_template_file(program: program)
  #   "Choose the layout template <b>#{file}</b>"
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

  # # Instructions for saving an experiment file
  # #
  # # @param filename [String] the name of the file (without the full path)
  # # @return [String]
  # def save_experiment_file(filename:)
  #   "Save the experiment as #{filename} in #{params[:experiment_filepath]}"
  # end

  # # Instructions for exporting measurements from a qPCR run
  # #
  # # @return [String]
  # def export_measurements()
  #   "Click <b>Export</b><br>" +
  #   "Select <b>Export All Data Sheets</b><br>" +
  #   "Export all sheets as CSV<br>" +
  #   "Save files to the #{params[:export_filepath]} directory"
  # end
end
