# typed: false
# frozen_string_literal: true

# This is a default, one-size-fits all protocol that shows how you can
# access the inputs and outputs of the operations associated with a job.
# Add specific instructions for this protocol!

class Protocol

  def main
      
    item = Collection.find(769)
    show do
      title "all the associations"
      item.parts.each do |part|
        note part.associations.to_s 
        separator
      end
   end

  end

end
