# typed: false
# frozen_string_literal: true

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'
needs 'Standard Libs/Pipettors'
needs 'Standard Libs/Units'
needs 'Standard Libs/AssociationManagement'

needs 'Collection Management/CollectionDisplay'
needs 'Collection Management/CollectionTransfer'

needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'

needs 'Tube Rack/TubeRack'

needs 'Modified CDC Protocol/RehydratePatientSampleDebug'

TEMPLATE = 'Template'
MEDIA = 'Media'

EPP_LABEL = 'Eppendorf Tube'

class Protocol
  # Standard Libs
  include PlanParams
  include Debug
  include Pipettors
  include Units
  include AssociationManagement
  include PartProvenance

  #Collection Management
  include CollectionDisplay
  include CollectionTransfer

  #Diagnostic RT-qPCR
  include DiagnosticRTqPCRHelper

  #TubeRack
  include TubeRackHelper

  #Modified CDC Protocol
  include RehydratePatientSampleDebug

  attr_reader :job_params, :operation_params, :media_volume
  def default_operation_params
    {
      media_volume: 300,
      media_units: MICROLITERS,
    }
  end

  def default_job_params
    {
    }
  end

  def main
    setup_test(operations)
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )

    rnase_warning

    safety_warning

    operations.retrieve.make

    operations.each do |op|
      operation_params = op.temporary[:options]
      media_volume = {
        qty: operation_params[:media_volume],
        units: operation_params[:media_units]
      }

      op.pass(TEMPLATE)

      item_list = op.input_array(TEMPLATE).map do |fv|
        fv.item.collection? ? fv.collection : fv.item
      end

      if item_list.first.collection?
        item_list.uniq
        sample_rack = StripWellRack.new(rack_type: '96 Well Strip Well Tube Rack')
      else
        sample_rack = TubeRack.new(rack_type: '96 Well Strip Well Tube Rack')
      end

      fetch_tube_rack(sample_rack)

      add_items(item_list, sample_rack)

      transfer_media_to_collection(sample_rack: sample_rack,
                                   media: op.input(MEDIA).item,
                                   volume: media_volume,
                                   rc_list: sample_rack.collection.get_non_empty)
      vortex_samples(sample_rack: sample_rack)
    end
    operations.store

    {}
  end
    
  # Directions to vortex samples
  # @aparam sample_rack [SampleRack]
  # @param rc_list [Array<[r,c]>] list of all locations that need media
  def vortex_samples(sample_rack:, rc_list: nil)
    rc_list = sample_rack.collection.get_non_empty if rc_list.nil?

    show do
      title 'Vortex Samples'
      note "Individually vortex each eppendorf tube in <b>#{sample_rack.rack_type}"\
           "-#{sample_rack.id}</b>"
      note 'Be sure to return each Eppendorf Tube to the correct location'
      table highlight_collection_rc(sample_rack.collection, rc_list) { |r, c|
        sample_rack.part(r, c).id
      }
    end
  end
  
  # Directions to transfer media to the collection
  # @param sample_rack [SampleRack]
  # @param media [Item]
  # @param volume [Volume]
  # @param rc_list [Array<[r,c]>] list of all locations that need media
  def transfer_media_to_collection(sample_rack:, media:, volume:, rc_list:)
    total_vol = { units: volume[:units], qty: (volume[:qty] * rc_list.length) }
    fill_reservoir(media, total_vol)

    rc_list.group_by { |loc| loc.first }.values.each do |rc_row|
      association_map = []
      rc_row.each { |r, c| association_map.push({ to_loc: [r, c] }) }
      track_provenance(sample_rack: sample_rack, media: media, rc_list: rc_list)
      multichannel_item_to_collection(to_collection: sample_rack.collection,
                                      source: "media reservoir",
                                      volume: volume,
                                      association_map: association_map)
    end
  end
  
  # TODO: This doesn't properly track provenence I dont think
  def track_provenance(sample_rack:, media:, rc_list:)
    rc_list.each do |r, c|
      to_obj = sample_rack.part(r, c)
      from_obj_map = AssociationMap.new(media)
      to_obj_map = AssociationMap.new(to_obj)
      add_provenance(from: media, from_map: from_obj_map,
                     to: to_obj, to_map: to_obj_map)
      from_obj_map.save
      to_obj_map.save
    end
  end
    
  # Instructions to fill media reservoir
  #
  # @param media (item)
  # @param volume [Volume]
  def fill_reservoir(media, volume)
    show do
      title 'Fill Media Reservoir'
      check 'Get a media reservoir'
      check pipet(volume: volume,
                  source: "<b>#{media.id}</b>",
                  destination: '<b>Media Reservoir</b>')
    end
  end
end
