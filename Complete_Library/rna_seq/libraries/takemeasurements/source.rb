needs 'Standard Libs/AssociationManagement'
needs 'Collection_Management/CollectionData'
needs 'RNA_Seq/ParseCSV'
needs 'RNA_Seq/WorkflowValidation'
needs 'RNA_Seq/DataHelper'
needs 'RNA_Seq/KeywordLib'
    
    
    
module TakeMeasurements
  include CollectionData
  include AssociationManagement
  include DataHelper
  include ParseCSV
  include KeywordLib

  # Sets up and take Bioanalyzer measurements and associates the information back to 
  # the items in the working plate
  #
  # @param working_plate [Collection] the working plate
  # @param bio_headers, [Array<String>] the headers that should be in the excel sheet
  # @param bio_location [String] the location of the file that comes from the plate reader
  # @param data_key [String] the key that teh data should be associated to
  # @param loc_col [Int] the column in the csv that the well location is listed
  # @param data_col [Int] the column in the csv that the data is located in
  def setup_ad_take_bioanalizer_measurements(working_plate, bio_headers, bio_location, 
    data_key, loc_col, data_col)
    if data_key = RIN_KEY
      measurement_type = 'rna'
    elsif data_key = AVE_SIZE_KEY
      measurement_type = 'library'
    else
      measurement_type = data_key
    end

    bio_csv = take_bioanalizer_measurement(working_plate, bio_headers, bio_location,
          measurement_type: measurement_type)

    data_map = parse_csv_for_data(bio_csv, data_header: bio_headers[data_col], alpha_num_header: bio_headers[loc_col])
    associate_value_to_parts(plate: working_plate, data_map: data_map, key: data_key)
  end
    
  # Sets up and take plate reader measurements and associates the information back to 
  # the items in the working plate
  #
  # @param working_plate [Collection] the working plate
  # @param plate_headers, [Array<String>] the headers that should be in the excel sheet
  # @param plate_location [String] the location of the file that comes from the plate reader    
  def setup_and_take_plate_reader_measurements(working_plate, plate_headers, plate_location)
    dilution_factor_map = get_dilution_factors(working_plate)
    associate_value_to_parts(plate: working_plate, data_map: dilution_factor_map, key: DILUTION_FACTOR)

    plate_reader_csv, standards = take_duke_plate_reader_measurement(working_plate, plate_headers, plate_location)
    slope, intercept = calculate_slope_intercept(point_one: standards[0], point_two: standards[1])

    concentration_map = calculate_concentrations(slope: slope, intercept: intercept, 
                plate_csv: plate_reader_csv, dilution_map: dilution_factor_map)
    associate_value_to_parts(plate: working_plate, data_map: concentration_map, key: CON_KEY)
  end

  # TODO
  # Gets the dilution factors used in the plate reader measurements
  # Need some guidance on how this is determined.  I expect that this is something
  # that can automatically be generated within aquarium.  But also may require
  # some user input?   For now leave it open for change
  #
  # @return dilution_factor_map [Array<r,c,x>] a map of dilution factors and location
  def get_dilution_factors(working_plate)
    show do 
      title "Dilution Factor"
      note "Need to determine how this is decided.  For now dilution is assumed to be
        100."
      note "A user input may be needed or further understanding and control of,
              the transfer step may be required..."
    end
    generate_100_dilution_factor_map(working_plate)
  end


  # Instructions for taking the QC Plate Reader measurements
  # 
  #
  # @param working_plate [Collection] the plate of samples needing measurements
  # @return parsable csv file map of fluorescence values
  def take_duke_plate_reader_measurement(working_plate, csv_headers, csv_location)
    standards = get_standards

    show do
      title "Load Plate #{working_plate.id} on Plate Reader"
      note 'Load plate on plate reader and take measurements'
      note 'Save output data as CSV and upload on next page'
    end

    detailed_instructions = "Upload Plate Reader measurement files"
    csv_uploads = get_validated_uploads(working_plate.parts.length,
      csv_headers, false, file_location: csv_location, detailed_instructions: detailed_instructions)

    csv, plate_reader_info = pre_parse_plate_reader_data(csv_uploads)

    associate_data(working_plate, PLATE_READER_DATA_KEY, plate_reader_info)
    [csv.drop(6), standards]
  end


  # Instructions for taking Duke Bioanalyzer measurements 
  # 
  #
  # @param working_plate [Collection] the plate of samples needing measurements
  # @return parsable csv file map of fluorescence values
  def take_bioanalizer_measurement(working_plate, csv_headers, csv_location, measurement_type: nil)
    if measurement_type == 'library'
      description = 'Library DNA'
    elsif measurement_type == 'rna'
      description = 'RNA'
    else
      description = measurement_type
    end
    
    show do
      title "Load Plate #{working_plate.id} onto the Bioanalyzer"
      note "Load plate onto the Bioanalyzer and take <b>#{description}</b> measurements"
      note 'Save output data as CSV and upload on next page'
    end

    detailed_instructions = "Upload Bioanalyzer #{description} measurement files"
    csv_uploads = get_validated_uploads(working_plate.parts.length,
      csv_headers, false, file_location: csv_location, detailed_instructions: detailed_instructions)

    upload = csv_uploads.first
    csv = CSV.read(open(upload.url))

    associate_data(working_plate, BIOANALYZER_KEY, csv)
    csv
  end
end