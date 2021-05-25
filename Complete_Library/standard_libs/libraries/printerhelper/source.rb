# SG
# module for label printer
module PrinterHelper
    
    #------------------------------------------
    # print labels for samples
    # inputs:
    # ioStrs - array of strings, output items
    #------------------------------------------
    def printLabels(ioStrs)

        min_id=Float::INFINITY
        max_id=0 
        
        if(!ioStrs.kind_of?(Array)) # make sure input is an array
            ioStrs=[ioStrs]
        end
        
        show do
            title "Use label printer to label new 1.5 mL tubes with the following numbers:"
            operations.each { |op|
                ioStrs.each { |ioStr|
                    note "#{op.output(ioStr).item}"
                    min_id=[op.output(ioStr).item.id, min_id].min
                    max_id=[op.output(ioStr).item.id, max_id].max
                }
            }
            check "Ensure that the B33-143-492 labels are loaded in the printer. This number should be displayed on the printer. If not, check with a lab manager."
            check "Open the LabelMark 6 software."
            check "Select <b>Open </b> --> <b>File</b> --> <b>Serialized data top labels</b>"
            note "If an error about the printer appears, press <b>Okay</b>"
            check "Select the first label graphic, and click on the number in the middle of the label graphic."
            check "On the toolbar on the left, select <b>Edit serialized data</b>"
            if(max_id-min_id+1 == operations.length*ioStrs.length) # consecutive numbers
                check "Enter <b>#{min_id}</b> for the Start number and <b>#{operations.length*ioStrs.length}</b> for the Total number, and select <b>Finish</b>"
            else
                check "Enter the listed numbers manually and select <b>Finish</b>"
            end
            check "Select <b>File</b> --> <b>Print</b> and select <b>BBP33</b> as the printer option."
            check "Press <b>Print</b> and collect the labels."
            image "purify_gel_edit_serialized_data"
            image "Actions/purify_gel/purify_gel_sequential"
        end
    end # def
    
end # module