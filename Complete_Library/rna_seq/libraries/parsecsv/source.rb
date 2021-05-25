needs 'Collection_Management/CollectionLocation'
needs 'RNA_Seq/KeywordLib'

module ParseCSV
  include CollectionLocation
  include KeywordLib
    
  # Parses a csv for data assuming headers fit certain format
  #  Header 1    Header 2    Header 3
  #    loc         data      data
  #    loc         data       data
  # 
  # @param csv [CSV] the csv file
  # @param data_header [String] the string name of the header containing the information of interest
  # @param alpha_num_header [String] optional the name of the header containing the 
  #               alpha numerical well location
  def parse_csv_for_data(csv, data_header:, alpha_num_header:)
    data_idx = csv.first.index(data_header)
    loc_idx = csv.first.index(alpha_num_header)
    data_map = []
    csv.drop(1).each do |row|
      alpha_loc = row[loc_idx]
      data = row[data_idx]
      rc_loc = convert_location_to_coordinates(alpha_loc)
      data_map.push(rc_loc.push(data))
    end
    data_map
  end
  
  
  
    # Does initial formatting and parseing of csv files
  #
  # @param csv_uploads [Upload] raw uploaded csv files
  # @return [Array<csv, Hash>] retunrs an array containg the semi parse csv
  #    and a hash of general plate reader run info.
  def pre_parse_plate_reader_data(csv_uploads)
    upload = csv_uploads.first
    csv = CSV.read(open(upload.url))
    plate_reader_info = {
      'repeats' => csv[1][1],
      'end_time' => csv[1][2],
      'start_temp'  => csv[1][3],
      'end_temp' => csv[1][4],
      'bar_code' => csv[1][5]
      }
    [csv, plate_reader_info]
  end
  
  
end