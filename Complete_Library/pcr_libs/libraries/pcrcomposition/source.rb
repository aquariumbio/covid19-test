# frozen_string_literal: true

needs 'PCR Libs/PCRCompositionDefinitions'

# Factory class for instantiating `PCRComposition`
# @author Devin Strickland <strcklnd@uw.edu>
class PCRCompositionFactory
  # Instantiates `PCRComposition`
  # Either `component_data` or `program_name` must be passed
  #
  # @param component_data [Hash] a hash enumerating the components
  # @param program_name [String] the name of one of the default
  #   component hashes
  # @return [PCRComposition]
  def self.build(component_data: nil, program_name: nil)
    PCRComposition.new(
      component_data: component_data,
      program_name: program_name
    )
  end
end

# Models the composition of a polymerase chain reaction
# @author Devin Strickland <strcklnd@uw.edu>
# @note As much as possible, Protocols using this class should draw
#   input names from `CommonInputOutputNames`
class PCRComposition
  include PCRCompositionDefinitions

  attr_accessor :components

  # Instantiates the class
  # Either `component_data` or `program_name` must be passed
  #
  # @param component_data [Hash] a hash enumerating the components
  # @param program_name [String] the name of one of the default
  #   component hashes
  # @return [PCRComposition]
  def initialize(component_data: nil, program_name: nil)
    if component_data.blank? && program_name.blank?
      msg = 'Unable to initialize PCRComposition.' \
        ' Either `component_data` or `program_name` is required.'
      raise ProtocolError, msg
    elsif program_name.present?
      component_data = get_composition_def(name: program_name)
    end

    @components = []
    component_data.each { |_, c| components.append(ReactionComponent.new(c)) }
  end

  # Specifications for the dye component
  # @return (see #input)
  def dye
    input(DYE)
  end

  # Specifications for the polymerase component
  # @return (see #input)
  def polymerase
    input(POLYMERASE)
  end

  # Specifications for the master mix component
  # @return (see #input)
  def master_mix
    input(MASTER_MIX)
  end

  # Specifications for the forward primer component
  # @return (see #input)
  def forward_primer
    input(FORWARD_PRIMER)
  end

  # Specifications for the reverse primer component
  # @return (see #input)
  def reverse_primer
    input(REVERSE_PRIMER)
  end

  # Specifications for the primer/probe component
  # @return (see #input)
  def primer_probe_mix
    input(PRIMER_PROBE_MIX)
  end

  # Specifications for the template component
  # @return [ReactionComponent]
  def template
    input(TEMPLATE)
  end

  # Specifications for the water component
  # @return (see #input)
  def water
    input(WATER)
  end

  # Retrieves components by input name
  # Generally the named methods should be used.
  # However, this method can be convenient in loops, especially when
  #   the Protocol draws input names from `CommonInputOutputNames`
  #
  # @param input_name [String] the name of the component to be retrieved
  # @return [ReactionComponent]
  def input(input_name)
    components.find { |c| c.input_name == input_name }
  end

  # Displays the total reaction volume with units
  #
  # @todo Make this work better with units other than microliters
  # @return [String]
  def qty_display
    Units.qty_display({ qty: volume, units: MICROLITERS })
  end

  # The total reaction volume
  # @note Rounds to one decimal place
  # @return [Float]
  def volume
    sum_components
  end

  # The total reaction volume
  # @param round [Fixnum] the number of decimal places to round to
  # @return [Float]
  def sum_components(round = 1)
    components.map(&:qty).reduce(:+).round(round)
  end

  # The total volume of all components that have been added
  # @param (see #sum_components)
  # @return (see #sum_components)
  def sum_added_components(round = 1)
    added_components.map(&:qty).reduce(:+).round(round)
  end

  # Gets the components that have been added
  # @return [Array<ReactionComponent>]
  def added_components
    components.select(&:added?)
  end

  # Gets the `Item`s from `ReactionComponent`s and returns them as an array
  # @return [Array<Item>]
  def items
    components.map(&:item)
  end
end

# Models a component of a biochemical reaction
# @author Devin Strickland <strcklnd@uw.edu>
class ReactionComponent
  include Units

  attr_reader :input_name, :qty, :units, :sample, :item
  attr_accessor :added

  # Instantiates the class
  #
  # @param input_name [String] the name of the component
  # @param qty [Numeric] the quantity of this component to be added to
  #   a single reaction
  # @param units [String] the units of `qty`
  # @param sample_name [String] the name of the Aquarium Sample to be
  #   used for this component
  # @param object_name [String] the ObjectType (Container) that this
  #   component should be found in
  def initialize(input_name:, qty:, units:, sample_name: nil)
    @input_name = input_name
    @qty = qty
    @units = units
    @sample = sample_name ? Sample.find_by_name(sample_name) : nil
    @item = nil
    @added = false
  end

  # Sets `item`
  #
  # @param item [Item]
  def item=(item)
    if sample
      raise ProtocolError, "Item / Sample mismatch, #{item.sample.name}, #{sample.name}" unless sample == item.sample
    else
      @sample = item.sample
    end
    @item = item
  end

  # The input name, formatted for display in protocols
  # @return [String]
  def display_name
    input_name
  end

  # The volume as a qty, units hash
  #
  # @return [Hash]
  def volume_hash
    { qty: qty, units: units }
  end

  # Displays the volume (`qty`) with units
  #
  # @return [String]
  def qty_display(round = 1)
    Units.qty_display({ qty: qty.round(round), units: units })
  end

  # Adjusts the qty by a given factor and, if needed, makes it checkable
  #   in a table
  #
  # @param mult [Float] the factor to multiply `qty` by
  # @param round [FixNum] the number of places to round the result to
  # @param checkable [Boolean] whether to make the result checkable
  #   in a table
  # @return [Numeric, Hash]
  def adjusted_qty(mult = 1.0, round = 1, checkable = true)
    adj_qty = (qty * mult).round(round)
    adj_qty = { content: adj_qty, check: true } if checkable
    adj_qty
  end

  # provides the `qty` for display in a table, and markes it as `added`
  #
  # @param (see #adjusted_qty)
  # @return (see #adjusted_qty)
  def add_in_table(mult = 1.0, round = 1, checkable = true)
    @added = true
    adjusted_qty(mult, round, checkable)
  end

  # Checks if `self` has been added
  # @return [Boolean]
  def added?
    added
  end
end
