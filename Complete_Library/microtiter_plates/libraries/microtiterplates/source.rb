# typed: false
# frozen_string_literal: true

needs 'Standard Libs/AssociationManagement'
needs 'Microtiter Plates/PlateLayoutGenerator'

module MicrotiterPlates
  # Convert a letter to the corresponding array index
  #
  # @param letter [String] the letter (usually of a row)
  # @return Fixnum
  def letter_to_index(letter)
    alphabet_array.index(letter.upcase)
  end

  # Convert an array index to the corresponding letter of the alphabet
  #
  # @param index [Fixnum] the index (usually of a row)
  # @return String
  def index_to_letter(index)
    alphabet_array[index]
  end

  # Array of all letters of the alphablet in uppercase
  #
  # @return Array<String>
  def alphabet_array
    ('A'..'Z').to_a
  end

  # Get the alpha component of an alphanumumeric coordinate
  #
  # @param alphanum [String]
  # @return [String, nil] the first contiguous run of letters or nil if no
  #   letters are found
  def alpha_component(alphanum)
    mtch = alphanum.match(/[[:alpha:]]+/)
    return mtch[0] if mtch
  end

  # Get the numeric component of an alphanumumeric coordinate
  #
  # @param alphanum [String]
  # @return [Fixnum, nil] the first contiguous run of digits or nil if no
  #   digits are found
  def numeric_component(alphanum)
    mtch = alphanum.match(/\d+/)
    return mtch[0].to_i if mtch
  end
end

# Factory class for building `MicrotiterPlate`s
# @author Devin Strickland <strcklnd@uw.edu>
#
class MicrotiterPlateFactory
  # Builds a new `MicrotiterPlate`
  #
  # @param collection [Collection] the `Collection` that is to be managed
  # @param group_size [Fixnum] the size of groups of wells, e.g., corresponding
  #   to replicates (see `PlateLayoutGenerator`)
  # @param method [String] the method for creating a new `PlateLayoutGenerator`
  # @return [MicrotiterPlate]
  def self.build(collection:, group_size:, method:)
    MicrotiterPlate.new(
      collection: collection,
      group_size: group_size,
      method: method
    )
  end
end

# Class for modeling the addition of samples to a microtiter (e.g, 96-well)
#   plate
# @author Devin Strickland <strcklnd@uw.edu>
#
class MicrotiterPlate
  include AssociationManagement
  include PartProvenance

  attr_reader :collection

  # Instantiates `MicrotiterPlate`
  #
  # @param collection [Collection] the `Collection` that is to be managed
  # @param group_size [Fixnum] the size of groups of wells, e.g., correspionding
  #   to replicates (see `PlateLayoutGenerator`)
  # @param method [String] the method for creating a new `PlateLayoutGenerator`
  # @return [MicrotiterPlate]
  def initialize(collection:, group_size:, method:)
    @collection = collection
    @plate_layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: group_size,
      method: method,
      dimensions: @collection.dimensions
    )
  end

  # Associates the provided data to the next `PlateLayoutGenerator` index
  #   that does not point to a `Part` that already has a `DataAssociation`
  #   for `key` and returns the index
  #
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param data [serializable object]  the data for the association
  # @param column [Fixnum] an alternative column index to start with
  # @return [Array<Fixnum>]
  def associate_next_empty(key:, data:, column: nil)
    nxt = next_empty(key: key, column: column)
    associate(index: nxt, key: key, data: data)
    nxt
  end

  # Associates the provided data to the next `PlateLayoutGenerator` group
  #   that does not point to any `Part` that already has a `DataAssociation`
  #   for `key` and returns the group
  #
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param data [serializable object]  the data for the association
  # @param column [Fixnum] an alternative column index to start with
  # @return [Array<Array<Fixnum>>]
  def associate_next_empty_group(key:, data:, column: nil)
    nxt_grp = next_empty_group(key: key, column: column)
    associate_group(group: nxt_grp, key: key, data: data)
    nxt_grp
  end

  # Uses `PartProvenance` to associate the the provided provenance data to
  #   the next `PlateLayoutGenerator` index that does not point to a `Part`
  #   that already has a `DataAssociation` for `key` and returns the index
  #
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param data [Array<Hash>] the data for the association; each Hash must
  #   include an `item: Item` pair
  # @param column [Fixnum] an alternative column index to start with
  # @return [Array<Fixnum>]
  def associate_provenance_next_empty(key:, data:, column: nil)
    nxt = next_empty(key: key, column: column)
    associate_provenance(index: nxt, key: key, data: data)
    nxt
  end

  # Uses `PartProvenance` to associate the the provided provenance data to
  #   the next `PlateLayoutGenerator` group that does not point to any `Part`
  #    that already has a `DataAssociation` for `key` and returns the group
  #
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param data [Array<Hash>] the data for the association; each Hash must
  #   include an `item: Item` pair
  # @param column [Fixnum] an alternative column index to start with
  # @return [Array<Array<Fixnum>>]
  def associate_provenance_next_empty_group(key:, data:, column: nil)
    nxt_grp = next_empty_group(key: key, column: column)
    associate_provenance_group(group: nxt_grp, key: key, data: data)
    nxt_grp
  end

  # Returns the next `PlateLayoutGenerator` index that does not point to a
  #   `Part` that already has a `DataAssociation` for `key`
  #
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param column [Fixnum] an alternative column index to start with
  # @return [Array<Fixnum>]
  def next_empty(key:, column: nil)
    nxt = nil
    loop do
      nxt = @plate_layout_generator.next(column: column)
      prt = @collection.part(nxt[0], nxt[1])
      break unless prt.associations[key].present?
    end
    nxt
  end

  # Returns the next `PlateLayoutGenerator` group that does not point to any
  #   `Part` that already has a `DataAssociation` for `key`
  #
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param column [Fixnum] an alternative column index to start with
  # @return [Array<Array<Fixnum>>]
  def next_empty_group(key:, column: nil)
    nxt_grp = nil
    loop do
      present = false
      nxt_grp = @plate_layout_generator.next_group(column: column)
      nxt_grp.each do |nxt|
        prt = @collection.part(nxt[0], nxt[1])

        present = true if prt.associations[key].present?
      end
      break unless present
    end
    nxt_grp
  end

  # Associates the provided data to indices of the provided group
  #
  # @param group [Array<Array<Fixnum>>]
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param data [serializable object]  the data for the association
  # @return [void]
  def associate_group(group:, key:, data:)
    group.each { |i| associate(index: i, key: key, data: data) }
  end

  # Uses `PartProvenance` to associate the provided provenance data to
  #   indices of the provided group
  #
  # @param group [Array<Array<Fixnum>>]
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param data [Array<Hash>] the data for the association; each Hash must
  #   include an `item: Item` pair
  # @return [void]
  def associate_provenance_group(group:, key:, data:)
    group.each { |i| associate_provenance(index: i, key: key, data: data) }
  end

  # Make a simple data association on a part
  #
  # @param index [Array<Fixnum>] the row, column pair pointing to the part
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param data [serializable object]  the data for the association
  # @return [void]
  def associate(index:, key:, data:)
    part = @collection.part(index[0], index[1])
    part.associate(key, data)
  end

  # Uses `PartProvenance` to associate the provided provenance data to
  #   a part
  #
  # @param index [Array<Fixnum>] the row, column pair pointing to the part
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param data [serializable object] the data for the association; Hash must
  #   include an `item: Item` pair
  # @return [void]
  def associate_provenance(index:, key:, data:)
    to_item = @collection.part(index[0], index[1])
    data.each do |datum|
      # Make sure you aren't modifying a shared data structure
      datum = datum.dup
      from_item = datum.delete(:item)
      next unless from_item

      add_one_to_one_provenance(
        from_item: from_item,
        to_item: to_item,
        additional_relation_data: datum
      )
    end
    associate(index: index, key: key, data: 'added')
  end

  private

  # Add provenance data to a source-destination pair of items
  #
  # @param from_item [Item]
  # @param to_item [Item]
  # @param additional_relation_data [serializable object] additional data that
  #   will be added to the provenace association
  # @return [void]
  def add_one_to_one_provenance(from_item:, to_item:,
                                additional_relation_data: nil)
    from_map = AssociationMap.new(from_item)
    to_map = AssociationMap.new(to_item)

    add_provenance(
      from: from_item, from_map: from_map,
      to: to_item, to_map: to_map,
      additional_relation_data: additional_relation_data
    )
    from_map.save
    to_map.save
  end
end
