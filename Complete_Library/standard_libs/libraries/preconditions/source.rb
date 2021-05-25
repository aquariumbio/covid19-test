module Preconditions
  
  # Returns true if the specified operation input was created more than delta_time in the past
  #   e.g., time_elapsed op, "Plasmid", hours: 1, minutes: 30
  def time_elapsed op, input_name, delta_time = {days: 1}
    op.input_array(input_name).each do |input|
      t1 = get_t1 input
      t2 = Time.zone.now
  
      num_seconds = (delta_time[:minutes] || 0) * 60 +
                    (delta_time[:hours] || 0) * 60 * 60 +
                    (delta_time[:days] || 0) * 60 * 60 * 24
                    
      return false if t2 - t1 <= num_seconds
    end
    
    return true
  end
  
  def get_t1 input_fv
    if input_fv.item
      return input_fv.item.created_at
    elsif input_fv.predecessors.any?
      return input_fv.predecessors.first.updated_at
    else
      return Time.zone.now
    end
  end

end