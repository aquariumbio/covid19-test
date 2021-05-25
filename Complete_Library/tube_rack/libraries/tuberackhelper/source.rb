# frozen_string_literal: true

needs 'Collection Management/CollectionDisplay'

module TubeRackHelper
  include CollectionTransfer
  include CollectionDisplay

  def show_fetch_tube_rack(tube_rack)
    show do
      title 'Get Tube Rack'
      note 'To help stay organized please get a'\
           " <b>#{tube_rack.name}</b>"
      note "Make sure that the rack has <b>at least</b> #{tube_rack.rows}"\
           " rows and #{tube_rack.columns} columns"
    end
  end

  def show_add_items(item_list, tube_rack)
    if item_list.first.is_a? Collection
      show_add_stripwells(item_list, tube_rack)
    else
      show_add_single_items(item_list, tube_rack)
    end
  end
  
  def show_add_stripwells(item_list, tube_rack)
    all_parts = item_list.map{ |stripwell| stripwell.parts }
    all_parts.flatten!
    tube_rack.add_items(all_parts)
    item_list.each do |stripwell|
      chunk = stripwell.parts.map{ |item| tube_rack.find(item) }
      show_add_stripwell(location: chunk,
                         stripwell: stripwell,
                         tube_rack: tube_rack)
    end 
  end
  
    # Show instructions to place stripwell in rack
  # @param layout_group [Array<[r,c]>]
  # @param stripwell [Collection]
  # @param collection [Collection] the collection of the microtiter plate
  def show_add_stripwell(location:, stripwell:, tube_rack:)
    row = location.first[0] == location.last[0] ? true : false
    show do
      title 'Add Stripwell to Rack'
      note "Please place stripwell #{stripwell.id} in"\
        " rack #{tube_rack.id} per table below"
      note 'Make sure column 1 of the stripwell lines up the noted 1 of the rack'
      table highlight_tube_rack_rc(tube_rack, location){ |r, c| row ? c + 1 : r + 1 }
    end
  end
  
  def show_add_single_items(item_list, tube_rack)
    tube_rack.add_items(item_list)
    item_list.each_slice(3).to_a.each do |chunk|
      chunk.map! { |item| tube_rack.find(item) }
      show do
        title 'Place Samples into Tube Rack'
        note "Place samples tubes in the <b>#{tube_rack.name}</b>"\
            ' per the table below'
        table highlight_tube_rack_rc(tube_rack, chunk, check: false) { |r, c|
          tube_rack.part(r, c).id
        }
      end
    end 
  end
  
  # TODO make this use collection Transfer 
  # Directions to transfer media to the collection
  # @param tube_rack [SampleRack]
  # @param media [Item]
  # @param volume [Volume]
  # @param rc_list [Array<[r,c]>] list of all locations that need media
  def show_transfer_media_to_rack(tube_rack:, media:, volume:, rc_list:)
    association_map = rc_list.map{ |loc| { to_loc: loc } }
    
    associate_transfer_item_to_collection(from_item: media,
                                         to_collection: tube_rack,
                                         association_map: association_map,
                                         transfer_vol: volume)

    multichannel_item_to_collection(to_collection: tube_rack,
      source: 'Media Reservoir',
      volume: volume,
      association_map: association_map 
    )
  end

  # Instructions to fill media reservoir
  # TODO: Not sure this belongs here
  #
  # @param media (item)
  # @param volume [Volume]
  def show_fill_reservoir(media, unit_volume: nil, number_items: nil, pour: false)
    unless pour
        total_vol = { units: unit_volume[:units], qty: (unit_volume[:qty] * number_items) }
    end
    show do
      title 'Fill Media Reservoir'
      check 'Get a media reservoir'
      if pour
        check "Carefully pour all contents from #{media.id} into media reservoir"
      else
        check pipet(volume: total_vol,
                    source: "<b>#{media.id}</b>",
                    destination: '<b>Media Reservoir</b>')
      end
    end
  end

  # TODO: This doesn't properly track provenence I dont think
  # Not sure this is belongs here either
  def track_provenance(tube_rack:, media:, rc_list:)
    rc_list.each do |r, c|
      to_obj = tube_rack.part(r, c)
      from_obj_map = AssociationMap.new(media)
      to_obj_map = AssociationMap.new(to_obj)
      add_provenance(from: media, from_map: from_obj_map,
                     to: to_obj, to_map: to_obj_map)
      from_obj_map.save
      to_obj_map.save
    end
  end


  def highlight_tube_rack_rc(tube_rack, rc_list, check: false, &_rc_block)
    rcx_list = rc_list.map { |r, c|
      block_given? ? [r, c, yield(r, c)] : [r, c, '']
    }
    highlight_collection_rcx(tube_rack, rcx_list, check: check)
  end

end
