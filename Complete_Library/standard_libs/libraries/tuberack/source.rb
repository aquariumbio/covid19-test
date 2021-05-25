# frozen_string_literal: true

module TubeRack
  require 'matrix'

  class BasicRack
    EMPTY = -1

    def initialize(rows:, columns:)
      @rows = rows
      @columns = columns
      @matrix = make_matrix
    end

    def add_one( x, options = {} )
      opts = { reverse: false }.merge(options)
      r = nil
      c = nil
      if opts[:reverse]
        r, c = get_empty.last
      else
        r, c = get_empty.first
      end
      return nil if r.nil? || c.nil?

      set(r, c, x)
      [r, c, x]
    end

    def set(row, column, object)
      if row > @row || column > @column
        raise "Dimensions incompatible row: #{row}, column: #{column}"
      end
      @rack[row][column] = object
    end

    def add_samples(samples, options = {})
      opts = { reverse: false }.merge(options)
      empties = get_empty
      empties.reverse! if opts[:reverse]
      remaining = []
      samples.zip(empties).each do |s, rc|
        if rc.nil?
          remaining << s
        else
          r, c = rc
          set(r, c, s)
        end
      end
      remaining
    end

    def capacity
      d = dimensions
      d[0] * d[1]
    end

    def dimensions
      [@rows, @columns]
    end

    def empty?
      get_non_empty #.length.positive?
    end

    def full?
      !get_empty.length.positive?
    end

    def get_empty
      @matrix.select { |x| x == EMPTY }
    end

    def get_non_empty
      @matrix.select { |x| x != EMPTY}
    end

    private

    def make_matrix
      rack = []
      @rows.times do
        rack.push(Array.new(@columns, EMPTY))
      end
      Matrix[rack]
    end

  end
end
