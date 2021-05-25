# typed: false
# frozen_string_literal: true

# This is a default, one-size-fits all protocol that shows how you can
# access the inputs and outputs of the operations associated with a job.
# Add specific instructions for this protocol!

needs 'Collection Management/CollectionDisplay'

class Protocol
  include CollectionDisplay

  def main
    collection = Collection.new_collection('96-well qPCR Plate')
    tbl = highlight_collection_rc(collection, [[0,0],[1,1],[2,2],[3,3],[4,4],[5,5],[6,6]])
    
    show do
      note collection.id.to_s
      note tbl[0][0].to_s
      table tbl
      table highlight_collection_rc(collection, [[0,0],[1,1],[2,2],[3,3],[4,4],[5,5],[6,6]], check: false)
    end
    
    m = [
          [ "A", "Very", "Nice", { content: "Table", style: {color: "white", "background-color"=>"red"} } ],
          [ { content: 1, check: false }, 2, 3, 4 ]
        ]
    show {
      title "A Table"
      table m
    }

  end
end