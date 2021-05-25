# frozen_string_literal: true

# Abstract PCR thermocycler
#
# @author Devin Strickland <strcklnd@uw.edu>
class AbstractThermocycler
  # CONSTANTS that really shouldn't ever change
  # Should be overriden in concrete class
  MODEL = ''
  PROGRAM_EXT = ''

  private_constant :MODEL, :PROGRAM_EXT

  attr_reader :params

  # Instantiates the class and sets the `@params` insteance variable
  #
  # @return [Thermocycler]
  def initialize
    @params = default_params.update(user_defined_params)
  end

  # Lab-specific, user-defined parameters
  #
  # @note Should be overriden in concrete class
  # @return [Hash]
  def user_defined_params
    {}
  end

  ########## Language Methods
  # These methods are not very specific and will probably need to be overridden
  #   in the concrete classes.

  # Instructions for turning on the thermocycler
  #
  # @return [String]
  def turn_on
    "Turn on the #{model}"
  end

  # Instructions for placing a plate in the instrument
  #
  # @param plate [Collection]
  # @return [String]
  def place_plate_in_instrument(plate:)
    "Place plate #{plate} in the thermocycler"
  end

  # Instructions for confirming the orientation of a plate in the instrument
  #
  # @return [String]
  def confirm_plate_orientation
    'MAKE SURE THAT THE PLATE IS IN THE CORRECT ORIENTATION'
  end

  # Instructions for selecting the PCR program template
  #
  # @param program [PCRProgram]
  # @return [String]
  def select_program_template(program:)
    file = program_template_file(program: program)
    "Choose the program template <b>#{file}</b>"
  end

  # Instructions for opening the lid
  #
  # @return [String]
  def open_lid
    'Click the <b>Open Lid</b> button'
  end

  # Instructions for closing the lid
  #
  # @return [String]
  def close_lid
    'Click the <b>Close Lid</b> button'
  end

  # Instructions for starting the run
  #
  # @return [String]
  def start_run
    'Click the <b>Start Run</b> button'
  end

  ########## Image Methods
  # These probably should NOT be overridden in the concrete classes

  # Image for opening the lid
  #
  # @return [String]
  def open_lid_image
    image_path(image_name: params[:open_lid_image])
  end

  # Image for closing the lid
  #
  # @return [String]
  def close_lid_image
    image_path(image_name: params[:close_lid_image])
  end

  # Image for selecting the PCR program template in the software
  #
  # @return [String]
  def setup_program_image
    image_path(image_name: params[:setup_program_image])
  end

  # Image for starting the run
  #
  # @return [String]
  def start_run_image
    image_path(image_name: params[:start_run_image])
  end

  ########## Template File Methods
  # These probably should NOT be overridden in the concrete classes

  def program_template_file(program:)
    template_file(
      template_name: program.program_template_name,
      extension: :PROGRAM_EXT
    )
  end

  ########## Getter Methods
  # These should NOT be overridden in the concrete classes

  # The model of the thermocycler
  #
  # @return [String]
  def model
    self.class.const_get(:MODEL)
  end

  private

  def default_params
    params = {
      experiment_filepath: '',
      export_filepath: '',
      image_path: '',
      setup_program_image: 'setup_program.png',
      open_lid_image: 'open_lid.png',
      close_lid_image: 'close_lid.png',
      start_run_image: 'start_run.png'
    }
    params.update(default_qpcr_params)
    params
  end

  def default_qpcr_params
    {
      # This space intentionally left blank
    }
  end

  def image_path(image_name:)
    File.join(params[:image_path], image_name)
  end

  def template_file(template_name:, extension:)
    ext = self.class.const_get(extension)
    if extension.present?
      (template_name + '.' + ext).gsub(/\.+/, '.')
    else
      template_name
    end
  end

  def format_show_array(ary)
    ary.join('<br>')
  end
end

# Module that provides qPCR-specific methods for thermocyclers
#
# @author Devin Strickland <strcklnd@uw.edu>
module QPCRMixIn
  # CONSTANTS that really shouldn't ever change
  # Should be overriden in concrete class
  LAYOUT_EXT =  ''
  SOFTWARE_NAME = 'thermocycler software'

  private_constant :LAYOUT_EXT, :SOFTWARE_NAME

  ########## Language Methods
  # These methods are not very specific and will probably need to be overridden
  #   in the concrete classes.

  # Instructions for opening the software that controls the thermocycler
  #
  # @return [String]
  def open_software
    "Open #{software_name}"
  end

  # Instructions for setting the dye channel on a qPCR thermocycler
  #
  # @param composition [PCRComposition]
  # @param dye_name [String] can be supplied instead of a `PCRComposition`
  # @return [String]
  def set_dye(composition: nil, dye_name: nil)
    dye_name = composition.dye.try(:input_name) || dye_name
    "Choose <b>#{dye_name}</b> as the dye"
  end

  # Instructions for selecting the plate layout template in the software
  #
  # @param program [PCRProgram]
  # @return [String]
  def select_layout_template(program:)
    file = layout_template_file(program: program)
    "Choose the layout template <b>#{file}</b>"
  end

  # Instructions for saving an experiment file
  #
  # @param filename [String] the name of the file (without the full path)
  # @return [String]
  def save_experiment_file(filename:)
    "Save the experiment as #{filename} in #{params[:experiment_filepath]}"
  end

  # Instructions for exporting measurements from a qPCR run
  #
  # @return [String]
  def export_measurements
    'Click <b>Export</b><br>' \
      'Select <b>Export All Data Sheets</b><br>' \
      'Export all sheets as CSV<br>' \
      "Save files to the #{params[:export_filepath]} directory"
  end

  ########## Image Methods
  # These probably should NOT be overridden in the concrete classes

  # Image for launching the software that controls the thermocycler
  #
  # @return [String]
  def open_software_image
    image_path(image_name: params[:open_software_image])
  end

  # Image for setting up the software workspace
  #
  # @return [String]
  def setup_workspace_image
    image_path(image_name: params[:setup_workspace_image])
  end

  # Image for selecting the plate layout template in the software
  #
  # @return [String]
  def setup_plate_layout_image
    image_path(image_name: params[:setup_plate_layout_image])
  end

  # Image for exporting measurements from a qPCR run
  #
  # @return [String]
  def export_measurements_image
    image_path(image_name: params[:export_measurements_image])
  end

  ########## Template File Methods
  # These probably should NOT be overridden in the concrete classes

  def layout_template_file(program:)
    template_file(
      template_name: program.layout_template_name,
      extension: :LAYOUT_EXT
    )
  end

  ########## Getter Methods
  # These should NOT be overridden in the concrete classes

  # The name of the software that controls the thermocycler
  #
  # @return [String]
  def software_name
    self.class.const_get(:SOFTWARE_NAME)
  end

  private

  def default_qpcr_params
    {
      open_software_image: 'open_software.png',
      setup_workspace_image: 'setup_workspace.png',
      setup_plate_layout_image: 'setup_plate_layout.png',
      export_measurements_image: 'export_measurements.png'
    }
  end
end
