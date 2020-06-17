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
needs 'Diagnostic RT-qPCR/PrepareRT_qPCRValidation'

module PrepareRT_qPCR_Plate
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
  include PrepareRT_qPCRValidation
  
  attr_reader :job_params
  
  TEMPLATE = 'Template'
  OPTIONS = 'options'
  INPUT_PLATE = 'Input PCR Plate'
  OUTPUT_PLATE = 'Output PCR Plate'
  OUTPUT_C_TYPE = '96-well qPCR Reaction'
  
  # An assortment of items for debugging
  # Make sure these exist and are right item type
  # [Positive Control, human sample, human sample]
  DEBUG_ITEMS = [425, 8628, 8627]
  
  def run_job(default_job_params:, default_operation_params:, operations:)
    @job_params = update_plan_params(plan_params: default_job_params,
                                     opts: default_operation_params)

    operations.reject!{ |op| validate(operations: operations).include?(op) }
    return {} if operations.empty?

    operations.retrieve

    operations.each do |op|
      @job_params = update_plan_params(plan_params: job_params,
                                       opts: get_op_opts(op))

      input_collection = op.input(INPUT_PLATE).collection
      input_collection = Collection.find(4653) if debug
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
        sort_inputs(neg_control: job_params[:controls][:negative_controls],
                    pos_control: job_params[:controls][:positive_controls],
                    operation_inputs: operation_inputs)

      add_control_samples(operation_inputs: negative_controls,
                          collection: output_collection,
                          layout_generator: layout_generator,
                          controls: job_params[:controls][:negative_controls])

      add_control_samples(operation_inputs: positive_controls,
                          collection: output_collection,
                          layout_generator: layout_generator,
                          controls: job_params[:controls][:positive_controls])

      add_diagnostic_samples(
        operation_inputs: sample_inputs,
        collection: output_collection,
        layout_generator: layout_generator
      )

      associate_plate_to_plate(to_collection: output_collection,
                               from_collection: input_collection)

      rc_list = make_sample_rc_list(operation_inputs, output_collection)
      add_additional_components(rc_list: rc_list, collection: output_collection,
                                recipe_list: job_params[:recipe][:additional_inputs],
                                operation: op)
      add_inputs(collection: output_collection, samples: sample_inputs,
                 recipe: job_params[:recipe][:standard_samples], operation: op)
      add_inputs(collection: output_collection, samples: negative_controls,
                 recipe: job_params[:recipe][:negative_controls], operation: op)
      add_inputs(collection: output_collection, samples: positive_controls,
                 recipe: job_params[:recipe][:positive_controls], operation: op)
    end

    operations.store

    {}
  end

  def add_inputs(collection:, samples:, recipe:, operation:)
    unless recipe[:components].nil?
      add_additional_components(rc_list: make_sample_rc_list(samples, collection),
                                collection: collection,
                                recipe_list: recipe[:components],
                                operation: operation)
    end

    return if samples.length == 0 

    show do
      title 'Get Samples'
      note 'Please set out the following items for easy access'
      table create_location_table(samples)
    end

    samples.each do |item|
      add_to_plate(rc_list: make_sample_rc_list([item], collection),
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

      show do
        title 'Get Additional Items'
        note 'Please get items listed below'
        table create_location_table([item])
      end

      add_to_plate(rc_list: rc_list, collection: collection, source: item,
                   volume: recipe[:volume])
    end
  end

  def add_to_plate(rc_list:, collection:, source:, volume:)
    show do
      title 'Pipette into Plate'
      note pipet(volume: volume, source: source,
                 destination: 'the highlighted wells below')
      note "Collection #{collection.id}"
      table highlight_collection_rc(collection, rc_list) { |r, c|
        convert_coordinates_to_location([r,c])
      }
    end
  end

  def make_sample_rc_list(inputs, collection)
    rc_list = []
    inputs.each do |item|
      item = item.sample unless item.is_a? Sample
      rc_list += collection.find(item)
    end
    rc_list
  end


  def add_control_samples(operation_inputs:, collection:,
                          layout_generator:, controls:)
    add_samples(
      operation_inputs: operation_inputs,
      collection: collection,
      layout_generator: layout_generator,
      column: controls[:location][1]
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

  def add_diagnostic_samples(operation_inputs:, collection:, layout_generator:)
    add_samples(
      operation_inputs: operation_inputs,
      collection: collection,
      layout_generator: layout_generator
    )
  end

  def add_samples(operation_inputs:, collection:, layout_generator:, column: nil)
    operation_inputs.each do |fv|

      job_params[:max_inputs].times do

        retry_group = true

        layout_group = layout_generator.next_group(column: column)

        layout_group.each do |r, c|
          existing_part = collection.part(r, c)

          if existing_part.sample.name.include?(job_params[:controls][:negative_controls][:name]); break; end
          if existing_part.sample.name.include?(job_params[:controls][:positive_controls][:name]); break; end

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
