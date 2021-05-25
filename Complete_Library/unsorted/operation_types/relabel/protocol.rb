# typed: false
# frozen_string_literal: true

# This is a default, one-size-fits all protocol that shows how you can
# access the inputs and outputs of the operations associated with a job.
# Add specific instructions for this protocol!
needs 'Standard Libs/Debug'
class Protocol
    include Debug

  def main
    ids = (2014...2095).to_a
    ids.each do |id|
      item = Item.find(id)
      if item.object_type.name = 'Nasopharyngeal Swab' && item.get('experiment_number').include?(' 3')
        item.associate('experiment_number', 'Experiment 4')
      end
    end

    {}

  end

end
