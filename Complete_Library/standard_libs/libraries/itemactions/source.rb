# frozen_string_literal: true

# Assists with basic actions of items (eg trashing, moving, etc)

module ItemActions
  # Store all items used in input operations
  # Assumes all inputs are non nil
  #
  # @param operations [OperationList] the list of operations
  # @param location [String] the storage location
  # @param type [String] the type of items to be stored('item', 'collection')
  def store_inputs(operations, location: nil, type: nil)
    store_io(operations, role: 'input', location: location, type: type)
  end

  # Stores all items used in output operations
  # Assumes all outputs are non nil
  #
  # @param operations [OperationList] the operation list where all
  #     output collections should be stored
  # @param location [String] the storage location
  # @param type [String] the type of items to be stored ('item', 'collection')
  def store_outputs(operations, location: nil, type: nil)
    store_io(operations, role: 'output', location: location, type: type)
  end

  # Stores all items of a certain role in the operations list
  # Creates instructions to store items as well
  #
  # @param operations [OperationList] list of Operations
  # @param role [String] whether material to be stored is an input or an output
  # @param location [String] the location to store the material
  # @param all_items [Boolean] an option to store all items not just collections
  # @param type [String] the type of items to be stored ('item', 'collection')
  def store_io(operations, role: 'all', location: nil, type: nil)
    items = Set[]; role.downcase!; type.downcase!
    operations.each do |op|
      field_values = if role == 'input'
                       yield op.inputs
                     elsif role == 'output'
                       yield op.outputs
                     else
                       yield (op.outputs + op.inputs)
                     end

      unless type.nil?
        if type == 'collection'
          field_values.reject! { |fv| fv.object_type.handler == 'collection' }
        elsif type == 'item'
          field_values.select! { |fv| fv.object_type.handler == 'collection' }
        end
      end

      items.concat(field_values.map(&:item))
    end
    store_items(items, location: location)
  end

  # Instructions to store a specific item
  # TODO have them move the items first then move location in AQ
  #
  # @param items [Array<items>] the things to be stored
  # @param location [String] Sets the location of the items if included
  def store_items(items, location: nil)
    set_locations(items, location) unless location.nil?
    tab = create_location_table(items)
    show do
      title 'Put Away the Following Items'
      table tab
    end
  end

  # Sets the location of all objects in array to some given locations
  #
  # @param items Array[Collection] or Array[Items] an array of any objects
  # that extend class Item
  # @param location [String] the location to move object to
  # (String or Wizard if Wizard exists)
  def set_locations(items, location)
    items.each do |item|
      item.move_to(location)
      item.save
    end
  end

  # Directions to layout materials for easy use
  #
  # @materials [Array<items>]
  def layout_materials(materials)
    show do
      title 'Layout Materials'
      note 'Please set out the following items for easy access'
      table create_location_table(materials)
    end
  end

  # Directions to retrieve materials
  #
  # @materials [Array<items>]
  def retrieve_materials(materials)
    show do
      title 'Retrieve Materials'
      note 'Please get the following items'
      table create_location_table(materials)
    end
  end

  # Creates table directing technician on where to store materials
  #
  # @param collection [Collection] the materials that are to be put away
  # @return location_table [Array<Array>] of Collections and their locations
  def create_location_table(items)
    location_table = [['ID', 'Object Type', 'Location']]
    items.each do |item|
      location_table.push([item.id, item.object_type.name, item.location])
    end
    location_table
  end

  # Gives directions to throw away objects (collection or item)
  #
  # @param items [Array<items>] Items to be trashed
  # @param hazardous [boolean] if hazardous then true
  def trash_object(items, waste_container: 'Biohazard Waste')
    set_locations(items, location: waste_container)
    tab = create_location_table(items)
    show do
      title 'Properly Dispose of the following items:'
      table tab
    end
    items.each { |item| item.mark_as_deleted }
  end

  # Instructions to fill media reservoir
  # TODO: Not sure this belongs here
  #
  # @param media (item)
  # @param volume [Volume]
  def show_fill_reservoir(media, unit_volume, number_items)
    total_vol = { units: unit_volume[:units], qty: calculate_volume_extra(unit_volume, number_items) }
    show do
      title 'Fill Media Reservoir'
      check 'Get a media reservoir'
      check pipet(volume: total_vol,
                  source: "<b>#{media.id}</b>",
                  destination: '<b>Media Reservoir</b>')
    end
  end

  def calculate_volume_extra(unit_volume, number_items)
    raw_vol = (unit_volume[:qty] * number_items)
    addition = raw_vol * 0.15 #15% more volume
    (raw_vol + addition).ceil
  end
end
