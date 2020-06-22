# frozen_string_literal: true

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/CommonInputOutputNames'
needs 'Standard Libs/Debug'
needs 'Standard Libs/InputOutput'
needs 'Standard Libs/Pipettors'
needs 'Standard Libs/Units'
needs 'Collection Management/CollectionActions'
needs 'Collection Management/CollectionDisplay'
needs 'Collection Management/CollectionTransfer'
# needs 'Collection Management/CollectionLocation'
needs 'Collection Management/CollectionData'
needs 'Microtiter Plates/PlateLayoutGenerator'

# Protocol methods for setting up plate withe extracted RNA Samples
#
# @author Devin Strickland <strklnd@uw.edu>
# @author Cannon Mallory <malloc3@uw.edu>
module PrepareqPCRPlateHelper
  include PlanParams
  include Debug
  include InputOutput
  include Pipettors
  include Units
  include CommonInputOutputNames
  include CollectionActions
  include CollectionDisplay
  include CollectionTransfer
  # include CollectionLocation
  include CollectionData

  attr_reader :job_params

  TEMPLATE = 'Template'
  OPTIONS = 'options'
  INPUT_PLATE = 'Input PCR Plate'
  OUTPUT_PLATE = 'Output PCR Plate'
  OUTPUT_C_TYPE = '96-well qPCR Reaction'

  # An assortment of items for debugging
  # Make sure these exist and are right item type
  # [Positive Control, human sample, human sample]
  DEBUG_ITEMS = [425, 8627, 262]
  DEBUG_CONTAINER = 18007  # Make sure that proper samples exist in plate (currently
                           # Validation steps rubber stamp everything)

  def run_job(default_job_params:, default_operation_params:, op:)
    @job_params = update_plan_params(plan_params: default_job_params,
                                     opts: default_operation_params)

    @job_params = update_plan_params(plan_params: job_params,
                                     opts: get_op_opts(op))

    input_collection = op.input(INPUT_PLATE).collection
    input_collection = Collection.find(DEBUG_CONTAINER) if debug
    output_collection = relabel_plate(input_collection)
    op.output(OUTPUT_PLATE).set(collection: output_collection)

    input_collection.mark_as_deleted unless debug

    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: job_params[:group_size],
      method: job_params[:method]
    )

    if debug
      operation_inputs = generate_samples
    else
      operation_inputs = op.input_array(TEMPLATE).map { |fv| fv.item }
    end

    sample_inputs, negative_controls, positive_controls =
      sort_inputs(neg_control: job_params[:negative_controls],
                  pos_control: job_params[:positive_controls],
                  operation_inputs: operation_inputs)

    setup_control_samples(operation_inputs: negative_controls,
                        collection: output_collection,
                        layout_generator: layout_generator,
                        controls: job_params[:negative_controls])

    setup_control_samples(operation_inputs: positive_controls,
                        collection: output_collection,
                        layout_generator: layout_generator,
                        controls: job_params[:positive_controls])

    setup_samples(operation_inputs: sample_inputs,
                           collection: output_collection,
                           layout_generator: layout_generator)

    associate_plate_to_plate(to_collection: output_collection,
                             from_collection: input_collection)


    add_additional_components(rc_list: make_sample_rc_list(output_collection,
                                                    operation_inputs),
                              collection: output_collection,
                              recipe_list: job_params[:additional_inputs],
                              operation: op)
    
    add_negative_controls(collection: output_collection, samples: negative_controls,
                          recipe: job_params[:negative_controls], operation: op)

    add_inputs(collection: output_collection, samples: sample_inputs,
               recipe: job_params[:standard_samples], operation: op)

    add_inputs(collection: output_collection, samples: positive_controls,
               recipe: job_params[:positive_controls], operation: op)

    {}
  end

  def add_negative_controls(collection:, samples:, recipe:, operation:)
    return if samples.length == 0

    show do
      title 'Adding Negative Controls'
      note 'It is <b>VERY</b> important to ensure that negative controls are not
             contaminated'
      note 'Take extra time to ensure proper sterile techniques are used'
    end

    add_inputs(collection: collection, samples: samples,
               recipe: recipe, operation: operation)

    show do
      title 'Cover Negative Control Wells'
      note 'Carefully cap control wells per table below'
      table highlight_collection_rc(collection,
            make_sample_rc_list(collection, samples)){ |r, c|
              convert_coordinates_to_location([r,c]) }
    end
  end

  def add_inputs(collection:, samples:, recipe:, operation:)
    unless recipe[:additional_inputs].nil?
      add_additional_components(rc_list: make_sample_rc_list(collection,
                                                             samples),
                                collection: collection,
                                recipe_list: recipe[:additional_inputs],
                                operation: operation)
    end

    return if samples.length == 0 

    move_to_station(recipe[:station])
    layout_materials(samples + [collection])

    samples.each do |item|
      add_to_plate(rc_list: make_sample_rc_list(collection, [item]),
                   collection: collection,
                   source: item,
                   volume: recipe[:volume])
    end
  end

  def add_additional_components(rc_list:, collection:, recipe_list:, operation:)
    recipe_list.each do |recipe|
      add_static_inputs([operation], recipe[:name],
                        recipe[:name], recipe[:container])
      item = operation.input(recipe[:name]).item

      move_to_station(recipe[:station])
      layout_materials([item, collection])

      add_to_plate(rc_list: rc_list, collection: collection, source: item,
                   volume: recipe[:volume])
    end
  end

  def add_to_plate(rc_list:, collection:, source:, volume:)
    show do
      title 'Pipette into Plate'
      note pipet(volume: volume, source: source,
                 destination: 'the highlighted wells below')
      table highlight_collection_rc(collection, rc_list) { |r, c|
        convert_coordinates_to_location([r,c])
      }
    end
  end

  def move_to_station(station)
    show do 
      title 'Move to Station'
      note "Please move to #{station} to complete the following steps"
    end
  end

  def layout_materials(materials)
    show do
      title 'Layout Materials'
      note 'Please set out the following items for easy access'
      table create_location_table(materials)
    end
  end

  def make_sample_rc_list(collection, inputs)
    rc_list = []
    inputs.each do |item|
      item = item.sample unless item.is_a? Sample
      rc_list += collection.find(item)
    end
    rc_list
  end


  def setup_control_samples(operation_inputs:, collection:,
                          layout_generator:, controls:)
    setup_samples(
      operation_inputs: operation_inputs,
      collection: collection,
      layout_generator: layout_generator,
      column: controls[:first_well][1]
    )
  end

  def generate_samples
    debug_items = []
    DEBUG_ITEMS.each do |id|
      debug_items.push(Item.find(id))
    end
    debug_items
  end

  def sort_inputs(neg_control:, pos_control:, operation_inputs:)
    remaining_inputs = []
    negative_controls = []
    positive_controls = []
    operation_inputs.each do |input|
      input_name = input.sample.name

      if input_name.include?(neg_control[:name])
        negative_controls.push(input)
      elsif input_name.include?(pos_control[:name])
        positive_controls.push(input)
      else
        remaining_inputs.push(input)
      end
    end
    [remaining_inputs, negative_controls, positive_controls]
  end

  def setup_samples(operation_inputs:, collection:, layout_generator:, column: nil)
    operation_inputs.each do |fv|

      job_params[:max_inputs].times do

        retry_group = true

        layout_group = layout_generator.next_group(column: column)

        layout_group.each do |r, c|
          existing_part = collection.part(r, c)

          if existing_part.sample.name.include?(job_params[:negative_controls][:name]); break; end
          if existing_part.sample.name.include?(job_params[:positive_controls][:name]); break; end

          collection.set(r, c, fv.sample)

          from_obj_to_obj_provenance(collection.part(r, c), existing_part)

          retry_group = false
        end

        column = layout_generator.iterate_column(column)
        break unless retry_group
      end
    end
  end

end