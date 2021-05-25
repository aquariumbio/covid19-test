

needs 'Standard Libs/CommonInputOutputNames'
needs 'Standard Libs/AssociationManagement'
needs 'Standard Libs/Units'
needs 'Standard Libs/UploadHelper'
needs 'RNA_Seq/KeywordLib'
    
module DataHelper    
  include CommonInputOutputNames
  include Units
  include UploadHelper
  include AssociationManagement
  include KeywordLib


  # Gets the standards used and information about them from tech
  #
  # @param tries [Int] optional the number of tries the tech gets
  #   to input standard information
  # @return []  the standards used in plate reader measurement
  def get_standards(tries: 10)
    fluorescence = []
    standard = []

    tries.times do |laps|
      # TODO make this a table and not just a bunch of inputs
      response = show do
        title "Plate Reader Standards"
        note 'Please record the standards used and their fluorescence below'
        get "number", var: "stan_1", label: "Concentration 1 (ng/ul)", default: ""
        get "number", var: "flo_1", label: "Fluorescence 1", default: ""
        separator
        get "number", var: "stan_2", label: "Concentrationn 2 (ng/ul)", default: ""
        get "number", var: "flo_2", label: "Fluorescence 2", default: ""
      end
      # This is because in this case  the lower concentration should always be first
      # else slope will be negative.   Rather do it here than in the slope calculation
      # because the slope calulation may be used other places and thus needs to be able
      # to report a neg slope.
      if response[:stan_1] > response[:stan_2]
        point_two = [response[:flo_1], response[:stan_1]]
        point_one = [response[:flo_2], response[:stan_2]]
      else
        point_one = [response[:flo_1], response[:stan_1]]
        point_two = [response[:flo_2], response[:stan_2]]
      end
      
      return [point_one, point_two] unless point_two.include?("") || point_one.include?("")

      raise "Too many attempts to input Plate Reader Standards information" if laps > tries - 1
      show do 
        title "Plate Reader Standards not Entered Properly"
        warning "Please input valid Standard Values"
        note "Hit okay to try again" 
      end
    end
  end




  # Calculates the slope and intercept between two points
  #
  # @param point_one [Array<x,y>] the x,y coordinates of point one
  # @param point_two [Array<x,y>] the x,y coordinates of point two 
  def calculate_slope_intercept(point_one: standards[0], point_two: standards[1])
    x_1 = point_one[0]
    y_1 = point_one[1]
    x_2 = point_two[0]
    y_2 = point_two[1]
    
    slope = (y_2 - y_1).to_f/(x_2 - x_1)
    intercept = y_1 - (slope * x_1)
    [slope, intercept]
  end



  # calculates the concentrations of the samples from the slope, intercept, dilution factor
  # and the plate reader information.
  #
  # @param slope [Float] the slope of the calibration curve
  # @param intercept [Float] the intercept of the calibration curve
  # @param plate_csv [CSV] csv file partially parsed with plate reader values
  # @param dilution_map [Array<Array<r,c, dilution factor>>] the dilution factor map
  # @param concentration_map [Array<Array<r,c, concentration>>] map of concentrations
  def calculate_concentrations(slope:, intercept:, plate_csv:, dilution_map:)
    concentration_map = []
    dilution_map.each do |row, column, dilution|
      fluorescence = plate_csv[row][column].to_f
      concentration = ((fluorescence * slope + intercept)*dilution/1000).round(1)
      concentration_map.push([row,column,concentration])
    end
    concentration_map
  end




  # Generates a hash with the margin range and the data key.  To be passed to 
  # "asses_qc_values" method 
  def generate_data_range(key:, minimum:, maximum:, lower_margin: nil, upper_margin: nil)
    good_range = (minimum...maximum+1)
    margin = []

    #couldn't use unless since I needed if later
    if !lower_margin.nil? || !upper_margin.nil?
      margin = (lower_margin...upper_margin)
    elsif lower_margin.nil?
      margin = (minimum... upper_margin)
    else upper_margin.nil?
      margin = (lower_margin...maximum)
    end

    {'key': key, 'pass': good_range, 'margin': margin}
  end




  # Asses weather the data held in info array keys are within the 
  # margins given by the hash
  #
  # @param collection [Collection] the collection in question
  # @param info_array [Array<Hash{key, pass, margin}]
  def asses_qc_values(collection, info_array)
    data_map = []
    collection.parts.each do |part|
        overall_status = nil
        info_array.each do |info_hash|
          key = info_hash[:key]
          pass_array = info_hash[:pass]

          margin = info_hash[:margin]

          #data = get_associated_data(part, key).to_f
          data = part.get(key).to_f

          if pass_array.include?(data)
            point_status = 'pass'
          elsif margin.include?(data)
            point_status = 'margin'
          elsif data.nil?
            point_status = nil
          else
            point_status = 'fail'
          end

          change_arry = ['margin', 'fail']
          unless point_status == overall_status
            if overall_status.nil?
              overall_status = point_status
            elsif overall_status == 'pass' && change_arry.include?(point_status)
              overall_status = point_status
            end
          end

        end
        unless overall_status.nil?
          location = collection.find(part)
          location.push(overall_status)
          location.push(QC_STATUS)
          data_map.push(location)
        end
    end 
    associate_value_key_to_parts(plate: collection, data_map: data_map)
  end




  # Associates data back to the input samples based on the source determined from 
  # provenance.
  #
  # @param collection [Collection] the collection with items of question
  # @param array_of_keys [Array<string>] an array or keys for the associations
  #       that need to be back associated
  def associate_data_back_to_input(collection, array_of_keys, operations)
    input_io_fv = get_input_field_values(operations)
    collection.parts.each do |part|
      sources = part.get('source')
      sources.uniq! #so if multiple sources are the same item data
      # is transferred only once
      sources.each do |sample_source|
        unless sample_source.nil?
          field_value = input_io_fv.select{|io_fv| io_fv.part.id == sample_source[:id]}.first
          array_of_keys.each do |key|
            data_obj = part.get(key)
            field_value.associate(key, data_obj) unless data_obj.nil?
          end
        end
      end
    end
  end

  # Generates a standard dilution factor map.  Assumes that there was no dilution.
  #
  # @param working_plate [Collection] the collection that the map is being generated for
  # @return dilution_factor_map [Array<r,c,dilution_factor>] map of dilutions
  def generate_100_dilution_factor_map(working_plate)
    parts = working_plate.parts
    dilution_factor_map = []
    parts.each do |part|
      loc = working_plate.find(part).first
      loc.push(100)
      dilution_factor_map.push(loc)
    end
    dilution_factor_map
  end

end