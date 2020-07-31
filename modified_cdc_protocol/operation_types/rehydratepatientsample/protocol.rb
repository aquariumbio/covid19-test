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

  def default_operation_params
    {
      media_volume_microliters: 1000,
    }
  end

  def default_job_params
    {
    }
  end

  def main
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )

    rnase_warning

    safety_warning

    attached_samples_warning

    operations.retrieve.make

    operations.each do |op|
      operation_params = op.temporary[:options]
      add_qty_display(operation_params)

      array_pass(op, SPECIMEN)

      item_list = op.input_array(SPECIMEN).map{ |fv| fv.item }
      media = op.input(MEDIA).item

      sample_rack = TubeRack.new(8, 12, name: "#{TUBE_MICROFUGE} rack")

      show_fetch_tube_rack(sample_rack)

      show_add_items(item_list, sample_rack)

      show_fill_reservoir(media,
                          operation_params[:media_volume_qty],
                          item_list.length)

      show_transfer_media_to_rack(tube_rack: sample_rack,
                                  media: media,
                                  volume: operation_params[:media_volume_qty],
                                  rc_list: sample_rack.find_multiple(item_list))
      vortex_samples(sample_rack: sample_rack,
                     rc_list: sample_rack.find_multiple(item_list))
    end
    operations.store

    {}
  end

  # Directions to vortex samples
  # @param sample_rack [SampleRack]
  # @param rc_list [Array<[r,c]>] list of all locations that need media
  def vortex_samples(sample_rack:, rc_list: nil)
    rc_list = sample_rack.get_non_empty if rc_list.nil?

    show do
      title 'Vortex Samples'
      note "Individually vortex each #{TUBE_MICROFUGE} tube in"\
           " <b>#{sample_rack.name}</b>"
      note "Be sure to return each #{TUBE_MICROFUGE}"\
           ' Tube to the correct location'
      table highlight_tube_rack_rc(sample_rack, rc_list) { |r, c|
        sample_rack.part(r, c).id
      }
    end
  end

  def array_pass(op, input_name, output_name = nil)
    input_fv_array = op.input_array(input_name)
    output_fv_array = op.output_array(output_name || input_name)

    input_fv_array.zip(output_fv_array).each do |fv_in, fv_out|
      fv_out.child_sample_id = fv_in.child_sample_id
      fv_out.child_item_id = fv_in.child_item_id
      fv_out.save
    end
  end

  def attached_samples_warning
    show do
      title 'Attached Items'
      note 'Some items may be physically attached together in stripwells'
      note 'Cut these items apart as needed'
      warning 'Be sure to return any unused items to their proper locations'
    end
  end
end
