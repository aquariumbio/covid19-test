# A library for all the parts of this workflow that are repeated between
# multiple operations however do not neatly fit in any other library

needs 'Standard Libs/CommonInputOutputNames'
needs 'Collection_Management/CollectionDisplay'
needs 'Collection_Management/CollectionTransfer'
needs 'Collection_Management/CollectionActions'
needs 'RNA_Seq/KeywordLib'
    
    
    
module MiscMethods
  include CollectionActions
  include CollectionDisplay
  include CollectionTransfer
  include KeywordLib
  include CommonInputOutputNames

  
  # Sets up the job and manages transfers etc all that jazz
  #
  # @param operations [OperationList] list of operations
  # @param transfer_vol [Int or Float] the volume that is to be transferred
  def setup_job(operations, transfer_vol, qc_step: false)
    operations.retrieve
    working_plate = transfer_steps(operations, transfer_vol, qc_step: qc_step)

    if false #qc_step
      #this is so if the protocol fails we don't end up with a bunch of 
      # plates in inventory that actually don't exist. 
      working_plate.mark_as_deleted
      working_plate.save
    end

    store_inputs(operations)
    working_plate
  end

  
    
  # Handles the transfers for the two qc steps
  #
  # @param operations [OperationList] list of operations
  # @param working_plate [collection] the plate being transferred to
  # @transfer_vol [Int or Float] the volume being transferred
  def transfer_steps(operations, transfer_vol, qc_step: false)
    input_field_value_array = []
    output_fv_array = []
    operations.each do |op|
      input_field_value_array += op.input_array(INPUT_ARRAY)
      output_fv_array += op.output_array(OUTPUT_ARRAY) unless qc_step
    end

    plates = transfer_subsamples_to_working_plate(input_field_value_array, collection_type: COLLECTION_TYPE, 
                                                                    transfer_vol: transfer_vol,
                                                                    add_column_wise: true)

    associate_field_values_to_plate(output_fv_array, plates) unless qc_step

    if plates.length > 1
      raise 'Too many items'
    end
    plates.first
  end


    # Gets all input field values from all input operations
  #
  # @param operations [OperationList] list of operations
  # @return [Array<io_field_values>]
  def get_input_field_values(operations)
    io_field_values  = []
    operations.each do |op|
      io_field_values += op.input_array(INPUT_ARRAY)
    end
    io_field_values
  end


  # Shows key associated data in the collection based on
  # the array of keys in the data keys list
  #
  # @param collection [Collection] the collection
  # @param data_keys [Array<Keys>] keys can be string or
  #     anything that data associator can use
  def show_key_associated_data(collection, data_keys)
    show do
      title "Measured Data"
      note "Listed below are the data collected"
      note "(Concentration (ng/ul), RIN Number)"
      table display_data(collection, data_keys)
      #  TODO add in feature for tech to change QC Status
    end
  end
    
end