# frozen_string_literal: true

needs 'PCR Libs/PCRCompositionDefinitions'
needs 'Collection Management/CollectionTransfer'
needs 'Standard Libs/WorkSpace'
needs 'Diagnostic RT-qPCR/DataAssociationKeys'

# Protocol methods for setting up plate withe extracted RNA Samples
#
# @author Devin Strickland <strklnd@uw.edu>
# @author Cannon Mallory <malloc3@uw.edu>
module PrepareqPCRPlateHelper

  include PCRCompositionDefinitions
  include CollectionTransfer
  include DataAssociationKeys

  attr_reader :template

  OPTIONS = 'options'
  INPUT_PLATE = 'PCR Plate'
  OUTPUT_PLATE = 'PCR Plate'
  ASSAY_TYPE = 'Assay Type'

  def add_inputs(collection:, samples:, volume:, station:)
    return if samples.empty?

    move_to_station(station)
    layout_materials(samples + [collection])

    samples.each do |item|
      association_map = to_association_map(collection: collection,
                                           item: item.sample)
      single_channel_item_to_collection(to_collection: collection,
                                        source: item.id,
                                        volume: volume,
                                        association_map: association_map)
    end
  end

  def update_parameters(operation:,
                        default_operation_params:,
                        default_job_params:)

    determine_default_job_params(operation: operation,
                                 default_job_params: default_job_params)
    opts = operation.plan.associations[:Options]
    default_job_params.update(update_plan_params(plan_params: default_operation_params,
                                                 opts: opts))
  end

  def determine_default_job_params(operation:, default_job_params:)
    input_plate = operation.input(INPUT_PLATE).collection
    default_job_params[:template] = get_composition_def(
      name: input_plate.get(COMPOSITION_NAME_KEY))[:template]
    @template = default_job_params[:template][:input_name]
    group_size = input_plate.get('group_size'.to_sym).to_i
    rows, columns = input_plate.dimensions
    default_job_params[:group_size] = group_size
    default_job_params[:max_inputs] = rows / group_size * columns
  end

  def setup_input_output_collections(input_collection:)
    output_collection = exact_copy(input_collection, label_plates: false)
    association_map = one_to_one_association_map(to_collection: output_collection,
                                                 from_collection: input_collection)

    associate_transfer_collection_to_collection(to_collection: output_collection,
                                                from_collection: input_collection,
                                                association_map: association_map)

    relabel_plate(from_collection: input_collection,
                  to_collection: output_collection)
    output_collection
  end

  def sort_inputs(negative_control:, positive_control:, operation_inputs:)
    remaining_inputs = []
    negative_controls = []
    positive_controls = []
    operation_inputs.each do |input|
      input_name = input.sample.name

      if input_name.include?(negative_control)
        negative_controls.push(input)
      elsif input_name.include?(positive_control)
        positive_controls.push(input)
      else
        remaining_inputs.push(input)
      end
    end
    {negative_control: negative_controls,
     positive_control: positive_controls,
     standard_sample: remaining_inputs}
  end

  def setup_samples(operation_inputs:,
                    collection:,
                    layout_generator:,
                    names_to_avoid: [],
                    column: nil)
    operation_inputs.each do |fv|
      job_params[:max_inputs].times do
        retry_group = true

        layout_group = layout_generator.next_group(column: column)

        layout_group.each do |r, c|
          existing_part = collection.part(r, c)
          raise "Part #{r} , #{c}, #{layout_group}" if existing_part.nil?

          break if avoid_name(existing_part.sample.name, names_to_avoid)

          collection.set(r, c, fv.sample)
          from_obj_to_obj_provenance(collection.part(r, c), existing_part)
          retry_group = false
        end

        column = layout_generator.iterate_column(column)
        break unless retry_group
      end
    end
  end

  def avoid_name(name, names_to_avoid)
    names_to_avoid.each do |avoid_name|
      return true if name.include?(avoid_name)
    end
    false
  end

  def move_to_station(station)
    show do
      title 'Move to Proper Area'
      note "Please move to the <b>#{station}</b> to complete the following steps"
    end
  end

end
