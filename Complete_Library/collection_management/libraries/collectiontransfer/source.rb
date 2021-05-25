# Cannon Mallory
# malloc3@uw.edu
#
# Methods for transferring items into and out of collections

needs 'Standard Libs/Units'
needs 'Standard Libs/AssociationManagement'
needs 'Standard Libs/Pipettors'
needs 'Collection Management/CollectionLocation'
needs 'Collection Management/CollectionData'

module CollectionTransfer
  include Units
  include AssociationManagement
  include CollectionLocation
  include CollectionData
  include Pipettors

  VOL_TRANSFER = 'Volume Transferred'.to_sym

  def to_association_map(collection:, item:)
    association_map = []
    locations = collection.find(item)
    locations.each do |loc|
      association_map.push( { to_loc: loc } )
    end
    association_map
  end

  def from_association_map(collection:, item:)
    association_map = []
    locations = collection.find(item)
    locations.each do |loc|
      association_map.push( { from_loc: loc } )
    end
    association_map
  end

  # Direction to use multichannel pipettor to pipet from an item
  # into a collection
  #
  # @param to_collection [Collection]
  # @param source [String] the source of the media etc
  # @param volume [Volume] volume class volume being transferred
  # @param association_map [Array<{ to_loc: [row,col] }>] all the
  #        coordinate of where stuff is to go
  def multichannel_item_to_collection(to_collection:,
                                      source:,
                                      volume:,
                                      association_map:)
    pipettor = get_multi_channel_pipettor(volume: volume)
    channels = pipettor.channels
    map_by_row = association_map.group_by { |map| map[:to_loc][0] }
    map_by_row.each do |_row, association_map|
      association_map.each_slice(channels).each do |rc_slice|
        pipet_into_collection(to_collection: to_collection,
                              source: source,
                              pipettor: pipettor,
                              volume: volume,
                              association_map: rc_slice)
      end
    end
  end

  # Direction to use single channel pipettor to pipet from an item
  # into a collection
  #
  # @param to_collection [Collection]
  # @param source [String] the source of the media etc
  # @param volume [Volume] volume class volume being transferred
  # @param association_map [Array<{ to_loc: [row,col] }>] all the
  #        coordinate of where stuff is to go
  def single_channel_item_to_collection(to_collection:,
                                        source:,
                                        volume:,
                                        association_map:)
    pipettor = get_single_channel_pipettor(volume: volume)
    pipet_into_collection(to_collection: to_collection,
                          source: source,
                          volume: volume,
                          association_map: association_map,
                          pipettor: pipettor)
  end

  # Direction to use single channel pipettor to pipet from
  # a collection into a collection
  #
  # @param to_collection [Collection]
  # @param from_collection [Collection]
  # @param volume [Volume] volume class volume being transferred
  # @param association_map [Array<{ to_loc: [row,col], from_loc: {row, col} }>]
  #     all the coordinate of where parts are
  def single_channel_collection_to_collection(to_collection:,
                                              from_collection:,
                                              volume:,
                                              association_map:)
    pipettor = get_single_channel_pipettor(volume)
    association_map.each do |loc_hash|
      pipet_collection_to_collection(to_collection: to_collection,
                                     from_collection: from_collection,
                                     pipettor: pipettor,
                                     volume: volume,
                                     association_map: [loc_hash])
    end
  end

  # Direction to use single channel pipettor to pipet from
  # a collection into a collection
  #
  # @param to_collection [Collection]
  # @param from_collection [Collection]
  # @param volume [Volume] volume class volume being transferred
  # @param association_map [Array<{ to_loc: [row,col], from_loc: {row, col} }>]
  #     all the coordinate of where parts are
  def multichannel_collection_to_collection(to_collection:,
                                            from_collection:,
                                            volume:,
                                            association_map:)
    pipettor = get_multi_channel_pipettor(volume: volume)
    association_map.each_slice(pipettor.channels).to_a.each do |map_slice|
      pipet_collection_to_collection(to_collection: to_collection,
                                     from_collection: from_collection,
                                     pipettor: pipettor,
                                     volume: volume,
                                     association_map: map_slice)
    end
  end

  # Directions to use pipet to transfer from a collection to a collection
  #
  # @param to_collection [Collection]
  # @param from_collection [Collection]
  # @param volume [Volume] volume class volume being transferred
  # @param association_map [Array<{ to_loc: [row,col], from_loc: {row, col} }>]
  #     all the coordinate of where parts are
  # @param pipettor [Pipettor] the pipettor to be used
  def pipet_collection_to_collection(to_collection:,
                                     from_collection:,
                                     pipettor:,
                                     volume:,
                                     association_map:)
    to_rc_list = []
    from_rc_list = []
    association_map.each do |loc_hash|
      to_rc_list.push(loc_hash[:to_loc])
      from_rc_list.push(loc_hash[:from_loc])
    end
    show do
      title 'Pipet from Collection to Wells'
      note pipettor.pipet(volume: volume,
                          source: from_collection.id,
                          destination: "<b>#{to_collection.id}</b> as noted below}")
      note '</b>From Collection:</b>'
      table highlight_collection_rc(from_collection, from_rc_list, check: false) { |r, c|
        convert_coordinates_to_location([r, c])
      }
      separator
      
      note '</b>To Collection:</b>'
      table highlight_collection_rc(to_collection, to_rc_list, check: false) { |r, c|
        convert_coordinates_to_location([r, c])
      }
    end
  end

  def pipet_into_collection(to_collection:,
                            source:,
                            pipettor:,
                            volume:,
                            association_map:)
    rc_list = association_map.map { |hash| hash[:to_loc] }
    show do
      title "Pipet from #{source} to Wells"
      note pipettor.pipet(volume: volume,
                          source: source,
                          destination: "the highlighted wells noted below")
      table highlight_collection_rc(to_collection, rc_list, check: false)
    end
  end

  # Instructions to tech to relabel plate
  #
  # @param from_collection [Collection]
  # @param to_collection [Collection]
  def relabel_plate(from_collection:, to_collection:)
    show do
      title 'Rename Plate'
      note "Relabel plate <b>#{from_collection.id}</b> with
                        <b>#{to_collection.id}</b>"
    end
  end

  # Transfers items from one collection to another per the association map
  #
  # @param from_collection [Collection]
  # @param to_collection [Collection]
  # @param association_map [Array<{ to_loc: [r,c], from_loc: [r,c] }]
  # @param transfer_vol [{qty: int, units: string}]
  def transfer_from_collection_to_collection(from_collection:,
                                             to_collection:,
                                             association_map:,
                                             transfer_vol: nil)
    association_map.each do |loc_hash|
      to_loc = loc_hash[:to_loc]
      from_loc = loc_hash[:from_loc]

      from_part = from_collection.part(from_loc[0], from_loc[1])
      to_collection.set(to_loc[0], to_loc[1], from_part)
    end
    associate_transfer_collection_to_collection(from_collection: from_collection,
                                                to_collection: to_collection,
                                                association_map: association_map,
                                                transfer_vol: transfer_vol)
  end

  # Transfers from item to well in collection
  #
  # @param from_item [item]
  # @param to_collection [Collection]
  # @param association_map [Array<{ to_loc: [r,c], from_loc: [r,c] }]
  # @param transfer_vol [{qty: int, units: string}]
  def transfer_from_item_to_collection(from_item:,
                                       to_collection:,
                                       association_map:,
                                       transfer_vol: nil)
    association_map.each do |loc_hash|
      to_loc = loc_hash[:to_loc]
      to_collection.set(to_loc[0], to_loc[1], from_item)
    end
    associate_transfer_item_to_collection(from_item: from_item,
                                          to_collection: to_collection,
                                          association_map: association_map,
                                          transfer_vol: transfer_vol)
  end

  # Associates/adds provenance for a transfer from a collection to
  # a collection.   It does NOT replace the item in the 'to_collection'
  #
  # @param from_collection [Collection]
  # @param to_collection [Collection]
  # @param association_map [Array<{ to_loc: [r,c], from_loc: [r,c] }]
  # @param transfer_vol [{qty: int, units: string}]
  def associate_transfer_collection_to_collection(from_collection:,
                                                  to_collection:,
                                                  association_map:,
                                                  transfer_vol: nil)
    association_map.each do |loc_hash|
      from_part = from_collection.part(loc_hash[:from_loc][0],
                                       loc_hash[:from_loc][1])
      to_part = to_collection.part(loc_hash[:to_loc][0],
                                   loc_hash[:to_loc][1])
      unless transfer_vol.nil?
        associate_transfer_vol(transfer_vol, VOL_TRANSFER, to_part: to_part,
                                                           from_part: from_part)
      end
      from_obj_to_obj_provenance(to_part, from_part)
    end
  end

  # Associates/adds provenance for a transfer from an item to
  # a collection.   It does NOT replace the item in the 'to_collection'
  #
  # @param from_Item [item]
  # @param to_collection [Collection]
  # @param association_map [Array<{ to_loc: [r,c], from_loc: [r,c] }]
  # @param transfer_vol [{qty: int, units: string}]
  def associate_transfer_item_to_collection(from_item:,
                                            to_collection:,
                                            association_map:,
                                            transfer_vol: nil)
    association_map.each do |loc_hash|
      to_part = to_collection.part(loc_hash[:to_loc][0],
                                   loc_hash[:to_loc][1])
      unless transfer_vol.nil?
        associate_transfer_vol(transfer_vol, VOL_TRANSFER, to_part: to_part,
                                                           from_part: from_item)
      end
      from_obj_to_obj_provenance(to_part, from_item)
    end
  end

  # Associates/adds provenance for a transfer from a collection to
  # an item.
  #
  # @param from_collection [Collection]
  # @param to_item [item]
  # @param association_map [Array<{ to_loc: [r,c], from_loc: [r,c] }]
  # @param transfer_vol [{qty: int, units: string}]
  def associate_transfer_collection_to_item(from_collection:,
                                            to_item:,
                                            association_map:,
                                            transfer_vol: nil)
    association_map.each do |loc_hash|
      from_part = from_collection.part(loc_hash[:from_loc][0],
                                       loc_hash[:from_loc][1])
      unless transfer_vol.nil?
        associate_transfer_vol(transfer_vol, VOL_TRANSFER, to_part: to_item,
                                                           from_part: from_part)
      end
      from_obj_to_obj_provenance(to_item, from_part)
    end
  end

  # Records the volume transferred
  #
  # @param transfer_vol [{qty: int, units: string}]
  # @param to_part: part that is being transferred to
  # @param from_part: part that is being transferred from
  def associate_transfer_vol(vol, key, to_part:, from_part:)
    vol_transfer_array = get_associated_data(to_part, key)
    vol_transfer_array = [] if vol_transfer_array.nil?
    vol_transfer_array.push([from_part.id, vol])
    associate_data(to_part, key, vol_transfer_array)
  end

  # Creates a one to one association map
  #
  # @param to_collection [Collection] the to collection
  # @param from_collection [Collection] the from collection
  def one_to_one_association_map(from_collection:, to_collection: nil)
    rows, cols = from_collection.dimensions
    association_map = []
    rows.times do |row|
      cols.times do |col|
        next unless to_collection.nil? || !to_collection.part(row, col).nil?
        next if from_collection.part(row, col).nil?

        loc = [row, col]
        association_map.push({ to_loc: loc, from_loc: loc })
      end
    end
    association_map
  end
end
