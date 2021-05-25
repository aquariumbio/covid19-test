# typed: false
# frozen_string_literal: true

# This is a default, one-size-fits all protocol that shows how you can
# access the inputs and outputs of the operations associated with a job.
# Add specific instructions for this protocol!

class Protocol

  def main
        collections = []
        sample_names = ['RP', '2019-nCoVPC_N2', '2019-nCoVPC_N2']
        
        specimen_names = [
            ['DNA Aliquot 0',
             'DNA Aliquot 50',
             'DNA Aliquot 100',
             'DNA Aliquot 1000'],
            ['RNA Aliquot 0',
             'RNA Aliquot 50',
             'RNA Aliquot 100',
             'RNA Aliquot 1000'],
            ['Virus Aliquot 0',
            'Virus Aliquot 50',
            'Virus Aliquot 100',
            'Virus Aliquot 1000'],
            ['DNA Aliquot 0',
             'DNA Aliquot 3000',
             'DNA Aliquot 7500'],
            ['RNA Aliquot 0',
             'RNA Aliquot 3000',
             'RNA Aliquot 7500'],
            ['Virus Aliquot 0',
            'Virus Aliquot 3000',
            'Virus Aliquot 7500']
        ]

    sample_names.each do |name|
        make_collection(name, collections)
    end
    
    specimen_names.each do |specimen_type|
      specimen_type.each do |name|
        3.times do
          make_collection(name, collections)
        end
      end
    end
    
    show do 
      note collections.length.to_s
      note "should have made #{specimen_names.flatten.length * 3 * 2 + sample_names.length * 2}"
    end
  end
  
              
    def make_collection(name, collections)
        collection = Collection.new_collection('8 Well Stripwell')
        samples = Array.new(collection.dimensions[1], Sample.find_by_name(name))
        collection.add_samples(samples)

        collection2 = Collection.new_collection('12 Well Stripwell')
        samples2 = Array.new(collection2.dimensions[1], Sample.find_by_name(name))
        collection2.add_samples(samples2)
                
        collections.push(collection, collection2)  
    end

end
