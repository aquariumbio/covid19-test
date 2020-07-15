# typed: false
# frozen_string_literal: true

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'
needs 'Standard Libs/Pipettors'
needs 'Standard Libs/Units'
needs 'Standard Libs/AssociationManagement'
needs 'Standard Libs/LabwareNames'

needs 'Collection Management/CollectionDisplay'

needs 'Diagnostic RT-qPCR/DiagnosticRTqPCRHelper'

needs 'Tube Rack/TubeRack'
needs 'Tube Rack/TubeRackHelper'

needs 'Modified CDC Protocol/RehydratePatientSampleDebug'

TEMPLATE = 'Template'
MEDIA = 'Media'

class Protocol
  # Standard Libs
  include PlanParams
  include Debug
  include Pipettors
  include Units
  include LabwareNames
  include AssociationManagement
  include PartProvenance

  #Collection Management
  include CollectionDisplay

  #Diagnostic RT-qPCR
  include DiagnosticRTqPCRHelper

  #TubeRack
  include TubeRackHelper

  #Modified CDC Protocol
  include RehydratePatientSampleDebug

  def default_operation_params
    {
      media_volume_microliters: 300,
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
      add_qty_display(operation_params)

      op.pass(TEMPLATE)

      item_list = op.input_array(TEMPLATE).map do |fv|
        fv.item.collection? ? fv.collection : fv.item
      end

      item_list.uniq!

      sample_rack = TubeRackFactory.build(item_list: item_list,
                                  object_type:'96 Well Strip Well Tube Rack')

      show_fetch_tube_rack(sample_rack)

      show_add_items(item_list, sample_rack)

      transfer_media_to_rack(sample_rack: sample_rack,
                                   media: op.input(MEDIA).item,
                                   volume: operation_params[:media_volume_qty],
                                   rc_list: sample_rack.get_non_empty)
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
      note "Individually vortex each #{TUBE_MICROFUGE} tube in"\
           " <b>#{sample_rack.object_type}-#{sample_rack.id}</b>"
      note "Be sure to return each #{TUBE_MICROFUGE}"\
           ' Tube to the correct location'
      table highlight_collection_rc(sample_rack.collection, rc_list) { |r, c|
        sample_rack.part(r, c).id
      }
    end
  end
end
