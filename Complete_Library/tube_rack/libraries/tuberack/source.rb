# frozen_string_literal: true

class TubeRack
  TRUE_ITEM = 'true_item'.to_sym

  attr_reader :matrix, :name, :columns, :rows

  def initialize(rows, columns, name: 'Tube Rack')
    @columns = columns
    @rows = rows
    @matrix = build_matrix
    @name = name
  end

  def id
    name
  end

  def dimensions
    [rows, columns]
  end

  def get_empty
    empty = []
    matrix.each_with_index do |row, row_idx|
      row.each_with_index do |column, col_idx|
        empty.push([row_idx, col_idx]) if part(row_idx, col_idx).nil?
      end
    end
    empty
  end

  def get_non_empty
    non_empty = []
    matrix.each_with_index do |row, row_idx|
      row.each_with_index do |column, col_idx|
        non_empty.push([row_idx, col_idx]) unless part(row_idx, col_idx).nil?
      end
    end
    non_empty
  end

  def add_item(item)
    r, c = next_empty_slot
    set(item, r, c)
  end

  def add_items(items)
    items.each do |item|
      add_item(item)
    end
  end

  def next_empty_slot
    matrix.each_with_index do |row, row_idx|
      row.each_with_index do |column, col_idx|
        return [row_idx, col_idx] if part(row_idx, col_idx).nil?
      end
    end
  end
  
  def next_empty_row
    matrix.each_with_index do |row, row_idx|
      to_row = []
      empty_row = true
      row.each_with_index do |column, col_idx|
        empty_row = false if part(row_idx, col_idx).present? 
        to_row.push([row_idx, col_idx])
      end
      return to_row if empty_row
    end
    raise 'no empty rows were found'
  end

  def next_empty_column
    column = []
    matrix.first.length.times do |col_idx|
      empty_column = true
      matrix.each_with_index do |_row, row_idx|
        empty_column = false if part(row_idx, col_idx).present?
        column.push([row_idx, col_idx])
      end
      return column if empty_column
      column = []
    end
    raise 'no empty columns were found'
  end

  def set(item, row, column)
    matrix[row][column] = item
  end

  def find(item)
    get_non_empty.each do |r, c|
      return [r, c] if part(r, c).id == item.id
    end
  end
  
  def find_collection_parts(item)
    get_non_empty.each do |r, c|
      return [r,c] if part(r,c).containing_collection.id == item.id 
    end
  end

  def find_multiple(items)
    locations = []
    items.each do |item|
      locations.push(find(item))
    end
    locations
  end

  def part(row, column)
    matrix[row][column]
  end

  private

  def build_matrix
    Array.new(rows) { Array.new(columns) }
  end

end

class IncompatibleDimensions < ProtocolError; end
class NoEmptyRows < ProtocolError; end
class IncompatibleObjectType < ProtocolError; end
