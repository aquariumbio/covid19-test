needs 'Modified CDC Protocol/Workspace'



class Protocol
    
  def main

    workspace = Workspace.new(protocol: self)
    workspace.prepare()
    
    ####################################################
    # PROTOCOL: Prepare qPCR plate
    ####################################################

    # so far this looks like we cannot do more than one plate at a time

    get_samples_and_start_plate(operations)

    """
    Note: Samples may come in one rack (if we use 1.1.mL tubes) OR 2 rackes (ea. contains 24 5mL-tubes)
    For run #2, the same will start with S045D and end with S090D with 2 positive and 2 negative controls
    """
    
    workspace.move(to: "PCR Chamber")

    add_swab_elution_buffer(operations)

    workspace.clean_hood()

    lysis(operations)

    # basically repeat above for the next set

    show do
      note "Change gloves"
      note "Put the RNAse ZAP on your gloves"
    end
    
    workspace.cleanup()

  end
  
  def get_samples_and_start_plate(ops)
    ops.each_with_index { |op, idx| 
        show do
            title "Open package #{idx}"
            note "Take S001 to S024D and place the rack"
            # skip a row in between
            note "Reseal the package tightly."
            warning "Dry reagents are sensitive to humidity so the bag needs to stay tightly sealed"
            note "Return part #{idx} to the freezer"
        end
    }
  end
  
    def add_swab_elution_buffer(ops)
        # in "PCR chamber"
        # TODO: what reservoir if we did not open package 2
        # TODO: this requires a multichannel pipette apparently
        # TODO: this should have two different versions, one for multichannel and one for normal pipettes
        ops.each_with_index { |op, idx|
            show do
                title "Add swab elution buffer to #{idx}"
                note "In the PCR chamber, open the reservoir"
                note "Pour the contents of the swab elution buffer into the reservoir"
                note "Open a strip one row at a time. Discard the cap."
                note "Use a multichannel pipette to add 300uL of elution buffer into the first row"
                note "Close the cap with the new set of caps provided"
                note "Complete the steps with the next rows until finished"
                note "Vortex the whole rack, 5 seconds, three times."
                note "Set the rack of samples aside in the pre-PCR hood."
            end
        }
    end
    
    def lysis(ops)
        # retrieve lyophilized reagent bags N1, N2, N3 from the fridge
        show do
            title "Retrieve lyophilized reagents"
            note "Pick up lyophilized reagent bags N1, N2, and N3 from the fridge"
            note "Change gloves (in case door knob is dirty)"
        end
    
        # open the package
        show do
            title "Open packages"
            note "Open the package"
            note "Take N1 001 - N1 024 and place on plastic rack #1 (skip one row between the strip tubes). Seal the foild pouch bag tightly."
            note "Take N2 001 - N1 024 and place on plastic rack #1 (skip one row between the strip tubes). Seal the foild pouch bag tightly."
            note "Take R1 001 - N1 024 and place on plastic rack #1 (skip one row between the strip tubes). Seal the foild pouch bag tightly."
            note "Return all the sealed foil pouches back to the fridge"
        end
    
        # transfer sample to N1, N2, and RP
        show do 
            title "Transfer samples"
            note "Aligh the rack from left to right: Sample, Rack#1, Rack#2, Rack#3"
            note "Carefully open the stip tubes in the first row (S001 - S008). Discard the strip."
            note "Open N1 001 - N1 008; N2 001 - N2 008; RO 001 - RP 008"
            note "Use multichannel pipette to transfer S001D - S008D to N1 001 - N1 008. Close the cap of N1 001 - N1 008"
            note "Use multichannel pipette to transfer S001D - S008D to N2 001 - N2 008. Close the cap of N2 001 - N2 008"
            note "Use multichannel pipette to transfer S001D - S008D to N2 001 - N2 008. Close the cap of RP 001 - RP 008"
            note "Close S001D and S008D with the new cap"
        end    
    end
    
end
