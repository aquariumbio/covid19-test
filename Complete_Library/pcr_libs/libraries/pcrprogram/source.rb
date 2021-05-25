# frozen_string_literal: true

needs 'PCR Libs/PCRProgramDefinitions'

# Factory class for instantiating `PCRProgram`
# @author Devin Strickland <strcklnd@uw.edu>
class PCRProgramFactory
  # Instantiates `PCRComposition`
  #
  # @param program_name [String] the name of one of the default program hashes
  # @param volume [Numeric] the reaction volume in MICROLITERS
  # @return [PCRProgram]
  def self.build(program_name:, volume: nil)
    PCRProgram.new(program_name: program_name, volume: volume)
  end
end

# Models a thermocycler program
# @author Devin Strickland <strcklnd@uw.edu>
class PCRProgram
  include PCRProgramDefinitions

  attr_reader :program_name, :program_template_name, :layout_template_name
  attr_reader :steps, :volume

  # Instantiates the class
  #
  # @param program_name [String] the name of one of the default program hashes
  # @param volume [Numeric] the reaction volume in MICROLITERS
  # @return [PCRProgram]
  def initialize(args = {})
    @program_name = args[:program_name]
    program = get_program_def(name: program_name)
    @program_template_name = program[:program_template_name]
    @name = @program_template
    @plate = program[:plate]
    @layout_template_name = program[:layout_template_name]
    @steps = {}
    program[:steps].each { |k, v| @steps[k] = PCRStep.create_from(v) }
    @volume = args[:volume] || program[:volume]
  end

  # @deprecated Use {#program_template_name}
  def name
    program_template_name
  end

  # @deprecated Use {#layout_template_name}
  def plate
    layout_template_name
  end

  # Renders the thermocycler program as a table for `show` blocks
  #
  # @return [Array<Array>]
  def table
    table = [%w[Step Temperature Duration]]
    steps.each do |k, v|
      row = [k.to_s] + v.display
      table.append(row)
    end
    table
  end

  # TODO: This needs to be responsive to the actual program parameters
  def final_step
    'the final step'
  end
end

# Models a step of a PCRProgram
# Really a factory class that retruns a concrete Step class
# @author Devin Strickland <strcklnd@uw.edu>
class PCRStep
  def self.create_from(temperature: nil, duration: nil, goto: nil, times: nil)
    if temperature && duration
      IncubationStep.new(temperature: temperature, duration: duration)
    elsif goto && times
      GotoStep.new(destination: goto, times: times)
    else
      raise ProtocolError, 'Expected either an incubation or goto step'
    end
  end
end

# Models an incubation step
# @author Devin Strickland <strcklnd@uw.edu>
class IncubationStep
  attr_reader :temperature, :duration

  def initialize(temperature:, duration:)
    @temperature = temperature
    @duration = duration
  end

  def display
    [temperature_display, duration_display]
  end

  def temperature_display
    Units.qty_display(temperature)
  end

  def duration_display
    Units.qty_display(duration)
  end
end

# Models a goto step
# @author Devin Strickland <strcklnd@uw.edu>
class GotoStep
  attr_reader :destination, :times

  def initialize(destination:, times:)
    @destination = destination
    @times = times
  end

  def display
    [goto_display, times_display]
  end

  def goto_display
    "goto step #{destination}"
  end

  def times_display
    "#{times} times"
  end
end
