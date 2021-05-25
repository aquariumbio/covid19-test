# Module containing WellMatrix Class
#
module MatrixTools
  require 'matrix'
  # Defines a wrapper for a 2D array containing data for each of the wells of a
  # 24 or 96 well plate.
  #
  # A WellMatrix object can be easily converted to or from a ruby Matrix as
  # needed to allow the use of matrix operations.
  #
  class WellMatrix
    # Initializes a WellMatrix object using an array of rows.
    #
    # @param rows [Array<Array<Object>>]  the rows of the matrix
    # @raises [WellMatrixInvalidDimensionsError]
    #              if `rows` is not size 24 or 96
    #              or if `rows` does not have consistent column size
    def initialize(rows)
      @rows = rows
      check_rep
    end

    # Returns a new WellMatrix as a copy of the given Matrix.
    #
    # @param matr [Matrix]  the Matrix from which to construct a new WellMatrix
    # @returns [WellMatrix]  new WellMatrix object with identical elements
    #          as the passed in Matrix
    # @raises [WellMatrixInvalidDimensionsError]  if `matrix`
    #                                       is not size 24 or 96
    def self.from_matrix(matrix)
      WellMatrix.new(matrix.to_a)
    end

    # Returns a new WellMatrix as a copy of the given 2D Array.
    #
    # @param array_2D [Array<Array<Object>>]  the 2D array which will be used
    #              to construct a new WellMatrix
    # @returns [WellMatrix]  new WellMatrix with identical elements
    #          to the passed in 2D Array
    # @raises [WellMatrixInvalidDimensionsError]
    #                        if `array_2D` is not size 24 or 96
    #                        or if `array_2D` does not have consistent column size
    def self.from_array(array_2D)
      # copy input array (1 level deep)
      rows = Array.new(array_2D.size) do |i|
        Array.new(array_2D[i].size) { |j| array_2D[i][j] }
      end
      # return new WellMatrix created from copy of given array
      WellMatrix.new(rows)
    end

    # Returns a new 'empty' WellMatrix of the given plate size.
    #
    # @param size [Integer]  the size of the plate for which the
    #             matrix is built. 24 or 96 only
    # @param initial [Object] the initial value of all elements in
    #                the 2D array, default is nil
    # @returns [WellMatrix]  a new WellMatrix of the correct dimensions
    #          for the given plate size,
    #          initially populated with default elements
    # @raises [WellMatrixInvalidDimensionsError]  if `size` is not 24 or 96
    def self.create_empty(size, initial = nil)
      if size == 24
        rows = Array.new(4) { Array.new(6, initial) }
      elsif size == 96
        rows = Array.new(8) { Array.new(12, initial) }
      else
        raise WellMatrixInvalidDimensionsError.new,
              'Size of matrix is not 24 or 96'
      end
      WellMatrix.new(rows)
    end

    # Returns the number of rows of the matrix.
    #
    # @return [Integer]  the number of rows in this WellMatrix
    def row_count
      @rows.size
    end

    # Returns the number of columns of the matrix.
    #
    # @return [Integer]  the number of columns in this  WellMatrix
    def column_count
      @rows[0].size
    end

    # Gets an element from the matrix using numeric coordinates.
    #
    # @param i [Integer]  the 0-based row of the desired element
    # @param j [Integer]  the 0-based column of the desired element
    # @return [Object]  the element of the matrix at index `i`, `j`
    # @raises  [WellMatrixIndexOutOfBoundsError]  if the given index is out of bounds
    def [](i, j)
      if in_bounds?(i, j)
        @rows[i][j]
      else
        raise WellMatrixIndexOutOfBoundsError.new,
              "index #{i},#{j} is out of bounds "\
              "0,0...#{row_count},#{column_count}"
      end
    end

    # Gets an element from the matrix using alphanumeric coordinates.
    #
    # @param alpha_coord [String]  the row column pair of the desired element,
    #                     encoded as an alphanumeric coordinate
    # @return [Object]  the element of the matrix at the
    #                   index specified by `alpha_coord`
    def get(alpha_coord)
      coord = WellMatrix.numeric_coordinate(alpha_coord)
      self[coord[0], coord[1]]
    end

    # Sets an element of the matrix using numeric coordinates.
    #
    # @param i [Integer]  the 0-based row of the element to set
    # @param j [Integer]  the 0-based column of the element to set
    # @param value [Object]  the element to put in the specified index
    # @effect  sets element of the matrix at index `i`, `j` to `value`
    # @raises  [WellMatrixIndexOutOfBoundsError]  if the given index is out of bounds
    def []=(i, j, value)
      if in_bounds?(i, j)
        @rows[i][j] = value
      else
        raise WellMatrixIndexOutOfBoundsError.new,
              "index #{i},#{j} is out of bounds "\
              "0,0...#{row_count},#{column_count}"
      end
    end

    # Sets element of the matrix using alphanumeric coordinates.
    #
    # @param alpha_coord [String]  the row column pair of the element to set,
    #                    encoded as an alpha numeric coordinate
    # @param value [Object]  what to put in the specified index
    # @effect  sets element of the matrix at the index specified
    #          by `alpha_coord` to `value`
    def set(alpha_coord, value)
      coord = WellMatrix.numeric_coordinate(alpha_coord)
      self[coord[0], coord[1]] = value
    end

    # Return a copy of the matrix formatted as a 2D Array.
    #
    # @return [Array<Array<Object>>]  copy of this WellMatrix as basic 2D Array
    def to_array
      # defensive copying required
      # walk through, copy columns, retain element references
      Array.new(row_count) do |i|
        Array.new(column_count) { |j| @rows[i][j] }
      end
    end

    alias to_a to_array

    # Return a copy of the matrix formatted as a ruby Matrix.
    #
    # @return [Matrix]  copy of this WellMatrix as Matrix
    def to_matrix
      Matrix.rows(@rows)
    end

    alias to_m to_matrix

    # Return a copy of the matrix.
    #
    # @return [WellMatrix]  copy of this WellMatrix
    def clone
      arr = to_array
      from_array(arr)
    end

    # Creates a 2d array copy of the given WellMatrix for display with the `table` command.
    # This display table highlights cells in purple based on a custom condition.
    # The resulting table only displays the positions of the WellMatrix, not the elements themselves.
    #
    # @param [&block]  the condition evaluated on each element in the matrix which decides
    #           whether a particular cell is highlighted
    # @return [Array]  an array copy of the WellMatrix, augmented with colors, and without original data
    def display_position_table
      new_table = to_array
      row_count.times do |rr|
        column_count.times do |cc|
          rr_well = 'A'.ord.to_i + rr # ascii value for A-H, use .chr to convert to ascii character
          cc_well = cc + 1 # number
          if yield(self[rr, cc])
            new_table[rr][cc] = { content: "#{rr_well.chr}#{cc_well}", style: { background: '#e6e6ff' } } # purple
          else
            new_table[rr][cc] = { content: "#{rr_well.chr}#{cc_well}", style: { background: '#000000' } } # black
          end
        end
      end
      new_table
    end

    # Creates a 2d array copy of the given WellMatrix for display with the `table` command.
    # This display table highlights cells in purple based on a custom condition.
    # Allows the tech to view the contents of each element in the WellMatrix.
    #
    # @param [&block]  the condition evaluated on each element in the matrix which decides
    #           whether a particular cell is highlighted
    # @return [Array]  an array copy of the WellMatrix augmented with colors
    def display_table
      new_table = to_array
      row_count.times do |rr|
        column_count.times do |cc|
          if yield(self[rr, cc])
            new_table[rr][cc] = { content: self[rr, cc].to_s, style: { background: '#e6e6ff' } } # purple
          else
            new_table[rr][cc] = { content: self[rr, cc].to_s, style: { background: '#000000' } } # black
          end
        end
      end
      new_table
    end

    # Convert alphanumeric well coordinate to 0-based integer coordinate pair
    # Alphanumeric coordinate has a single uppercase letter representing the
    # row, and a 1-based number representing a column
    # So, "A01" is the well in the upper left
    #
    # @param alpha_num_coordinate [String]  the input alphanumeric coordinate
    # @return [Array<Integer>]  the coordinate converted to a size 2
    #          for the numeric 0-based row and column pair
    def self.numeric_coordinate(alpha_num_coordinate)
      mymatch = /(?<myrow>[A-Z]{1,1})(?<mycol>[0-9]{1,2})/
                .match(alpha_num_coordinate)
      # subtract ascii value of "A" from A-H to get row integer 0-6
      rr = mymatch[:myrow].ord.to_i - 'A'.ord
      cc = mymatch[:mycol].to_i - 1
      [rr, cc]
    end

    # Returns true if the given coordinate is in the bounds of this matrix,
    # false otherwise.
    #
    # @param i [Integer]  the 0-based row of the target element
    # @param j [Integer]  the 0-based column of the target element
    # @return [Boolean]  truth value of whether the `i`, `j` corresponds
    #         to a coherent location in this WellMatrix
    private def in_bounds?(i, j)
      if i >= row_count || j >= column_count || i < 0 || j < 0
        false
      else
        true
      end
    end

    # Throws errors if this WellMatrix is not of the correct internal structure.
    #
    # @raises [WellMatrixInvalidDimensionsError]  when the dimensions of this
    #         WellMatrix are incorrect
    private def check_rep
      num_rows = row_count
      num_cols = column_count
      if @rows.map(&:size).uniq.size > 1
        raise WellMatrixInvalidDimensionsError.new,
              'Row sizes are not consistent'
      end
      unless (num_rows == 4 && num_cols == 6) ||
             (num_rows == 8 && num_cols == 12)
        raise WellMatrixInvalidDimensionsError.new,
              'Size of matrix is not 24 or 96'
      end
    end
  end

  # Error indicating that the dimensions of a WellMatrix do not correspond
  # to the expected dimensions of a 24 or 96 well plate.
  #
  class WellMatrixInvalidDimensionsError < StandardError; end

  # Error indicating that there was an attempted access at an impossible index
  # in a WellMatrix
  #
  class WellMatrixIndexOutOfBoundsError < IndexError; end
end
