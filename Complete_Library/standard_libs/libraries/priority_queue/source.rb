class PriorityQueue 
  def initialize
    @heap = Heap.new()
    @priority_map = Hash.new()
  end

  def empty?
    @heap.empty?
  end

  def has_key?(key)
    @priority_map.has_key?(key)
  end

  def push(key, priority)
    node = PriorityNode.new(value: key, priority: priority)
    @priority_map[key] = priority
    @heap.add!(node)
  end

  def each(&blk)
    @priority_map.each(&blk)
  end

  def min
    @heap.peek.to_pair
  end

  def min_key
    return nil if empty?

    @heap.peek.value
  end

  def min_priority
    return nil if empty?

    @heap.peek.priority
  end

  # remove min and return pair
  def delete_min
    return nil if empty?

    min_node = @heap.remove!
    @priority_map.delete(min_node.value)
    min_node.to_pair
  end

  # remove min and return key
  def delete_min_return_key
    return nil if empty?

    min_value = @heap.remove!.value
    @priority_map.delete(min_value)
    min_value
  end

  private

  class PriorityNode
    include Comparable
    attr_reader :value, :priority

    def initialize(value:, priority:)
      @value = value
      @priority = priority
    end

    def <=>(node)
      @priority <=> node.priority
    end

    def to_pair
      [@value, @priority]
    end
  end

end

# Based on https://cs.lmu.edu/~ray/notes/pqueues/
class Heap
  def initialize
    @heap = []
  end

  def add!(x)
    @heap.append(x)
    sift_up(@heap.length - 1)
    self
  end

  def empty?
    @heap.length == 0
  end

  def peek
    @heap[0]
  end

  def remove!
    return nil if empty?

    value = @heap[0]
    if @heap.length == 1
      @heap = []
    else
      @heap[0] = @heap.pop
      sift_down(0)
    end
    value
  end

  def to_s
    @heap.to_s
  end

  private

  # Sift up the element at index i
  def sift_up(i)
    parent = (i - 1) / 2
    if parent >= 0 and @heap[parent] > @heap[i]
      @heap[parent], @heap[i] = @heap[i], @heap[parent]
      sift_up(parent)
    end
  end

  # Sift down the element at index i
  def sift_down(i)
    child = (i * 2) + 1
    return if child >= @heap.length
    child += 1 if child + 1 < @heap.length and @heap[child] > @heap[child+1]
    if @heap[i] > @heap[child]
      @heap[child], @heap[i] = @heap[i], @heap[child]
      sift_down(child)
    end
  end
end