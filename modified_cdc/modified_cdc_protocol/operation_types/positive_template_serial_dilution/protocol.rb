needs 'Modified CDC Protocol/Workspace'


class Protocol
  def main

    workspace = Workspace.new(protocol: self)
    workspace.prepare()

    ####################################################
    # PROTOCOL: Prepare a serial dilution of positive template
    ####################################################

    show do
      note "Grab 1 pack of 8 eppendorf tubes (prelabeled N, 1, 2, 3, 4, 5, 6) and 1 tube of 2mL nuclease-free water"
      note "Add 90uL to N, 1, 2, 3, 4, 5"
      note "Add 497.5 to tube 6"
    end

    # TODO: where did the cold rack come from?
    show do
      warning "Wear two layers of gloves"
      note "Grab an aliquot of RNA positive control stock from -80C and place on the cold rack."
      note "Remove outer layer of gloves"
      note "Place the 1.5 mL tubes on the cold rack"
      note "As soon as RNA positive control is thawed, take 2.5uL of the stock and add to the tube labeled 6"
      note "Close tubes of RNA controls and the tube labeled 6."
      note "Gently Vortex tube 6. Pulse centrifuge tube 6"
    end

    show do
      "Transfer 10uL of the Tube 6 to the Tube 5. Close both tubes. Gently vortex tube 5. Pulse centrifuge tube 5."
    end

    # ^^^ repeat for all tubes

    show do
      note "Change gloves"
    end

    # TODO: control n=3
    # TODO: control kit components

    # prepare NTC, n=3
    # tube N to columns 1, 2, 3
    show do
      note "On rack 1, 2, and 3, columns 1, 2, 3"
      note "Transfer 2uL of tube N to the above tubes"
    end

    # prepare n=3 for 100 c/rxn
    # tube 1 to columns 4, 5, 6
    show do
      note "On rack 1, 2, and 3, columns 4, 5, 6"
      note "Transfer 2uL of tube 1 to the above tubes"
    end


    # 10e3 c/rxn; tube 3 to 7, 8, 9
    # 10e4 c/rxn; tube 4 to 10, 11, 12
    # 10e5 c/rxn; tube 5 to 13, 14, 15
    # 10e6 c/rxn; tube 6
    # 10e7 c/rxn
    # 10e8 c/rxn; tube 7 

    show do
      note 'vortex the racks'
    end

    # rearrange stripwells
    show do

    end

    show do
      note 'discard all RNA dilution tubes'
    end

    workspace.cleanup()

    {}

  end

end
