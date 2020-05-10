# Aliquot Positive Template

Documentation here. Start with a paragraph, not a heading or title, as in most views, the title will be supplied by the view.
### Inputs


- **Template** [T]  
  - <a href='#' onclick='easy_select("Sample Types", "RNA")'>RNA</a> / <a href='#' onclick='easy_select("Containers", "Lyophilized RNA")'>Lyophilized RNA</a>



### Outputs


- **Template** [T]  
  - <a href='#' onclick='easy_select("Sample Types", "RNA")'>RNA</a> / <a href='#' onclick='easy_select("Containers", "Purified RNA in 1.5 mL tube")'>Purified RNA in 1.5 mL tube</a>

### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
def precondition(_op)
  true
end
```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
# Aliquot Positive Template Protocol
# Written By Rita Chen 2020-05-04

# 2019-nCoV Positive Control (nCoVPC) Preparation:
# 1) Precautions: This reagent should be handled with caution in a dedicated
# nucleic acid handling area to prevent possible contamination. Freeze-thaw
# cycles should be avoided. Maintain on ice when thawed.
# 2) Resuspend dried reagent in each tube in 1 mL of nuclease-free water to
# achieve the proper concentration. Make single use aliquots (approximately 30
# L) and store at less than and equal to -70C.
# 3) Thaw a single aliquot of diluted positive control for each experiment and
# hold on ice until adding to plate. Discard any unused portion of the aliquot.

class Protocol

  def main
    # 1. Get 33 1.5 mL tube for each operation
    get_tubes(operations.length)
    operations.retrieve

    # 2. For each Lyophilized Postive Control, resuspend in 1 mL of
    # nuclease-free waterand, aliquot 33 use aliquots (approximately
    # 30 L) and store at less than and equal to -70C.

    # Group the operations by the input reagent
    ops_by_input = operations.group_by {|op| op.input("Template").item}
    ops_by_input.each do |lyophilized_RNA, ops|
      label_and_locate_output(ops)
    end

    suspend_lyophilized_RNA(operations)
    keep_tubes = [] #Empty array for storing single use aliquots
    
    ops_by_input.each do |lyophilized_RNA, ops|
      keep_tubes.push(make_aliquots(ops))
    end
    
    prepare_plating(keep_tubes)
    
    # 3. Thaw a single aliquot of diluted positive control for each
    # experiment and hold on ice until adding to plate.
    # Discard any unused portion of the aliquot.
    operations.store(interactive: true, io: "output", method: "boxes")
  end

  # Get 33 1.5 mL tubes per dried positive control
  #
  # @param count [Integer] the number of operations
  def get_tubes(count)
    show do
      title "Get new 1.5 mL tubes"
      check "Please get #{count*33} 1.5 mL tubes"
    end
  end

  # Label the tubes so that the same reagents have consecutive IDs
  # And move the output tubes to the right storage locations
  #
  # @param operations [OperationList] The list of operations
  def label_and_locate_output(operations)
    operations.make

    #Declare references to output objects
    operations.each do |op|
      op.output("Template").item.associate :volume, 30
      op.output("Template").item.save
      
      output_RNA = op.output("Template").sample
      for i in 0..31
        new_aliquot = output_RNA.make_item("Purified RNA in 1.5 mL tube")
        new_aliquot.associate :volume, 30
        new_aliquot.save
        # Associated output RNA with a new location wizard for storage of
        # plasmids and fragments, M80P (for DAMP)
        link_output_item(op, output_RNA, new_aliquot)
      end
    end
  end
  
  # Manually link the item to the operation as an output
  #
  # @param op [Operation] the operation that creates the items
  # @param sample [Sample] the sample of the item
  # @param item [Item] the item that is created
  def link_output_item(op, sample, item)
    fv = FieldValue.new(
      name: "Template", 
      child_item_id: item.id,
      child_sample_id: sample.id, 
      role: "output",
      parent_class: "Operation", 
      parent_id: op.id,
      field_type_id: op.output("Template").field_type.id
    )
    fv.save
  end

  #Performs the resuspension protocol for a list of operations
  #that all use the given lyophilized_RNA input.
  #
  # @param suspend_lyophilized_RNA [Item] the lyophilized_RNA
  # @param operations     [OperationList] the list of operations
  def suspend_lyophilized_RNA(operations)
    operations.make

    show do 
      title "Resuspend Positive Template"
      warning "This reagent should be handled with caution in a dedicated\
      nucleic acid handling area to prevent possible contamination."
      warning "Freeze-thaw cycles should be avoided. Maintain on ice when\
      thawed."
      check "Resuspend dried Lyophilized Postive Control RNA in each tube\
      in 1 mL of nuclease-free water to achieve the proper concentration."
    end
  end

  #Performs the aliquote protocol for a list of operations
  #that all use the given lyophilized_RNA input.
  #
  # @param make_aliquots [Item] the lyophilized_RNA
  # @param operations     [OperationList] the list of operations
  def make_aliquots(operations)
    last_tube_id = "" #Empty string for storing item id of single use aliquot
    operations.each do |op|
      input_RNAs = Array.new(33, op.input("Template").item.id)
      aliquot_tubes = op.outputs().map{|output| output.item.id}
      transfer_table = Table.new
              .add_column("Lyophilized RNA", input_RNAs)
              .add_column("Output RNA Aliquot", aliquot_tubes)

      show do
        title "Aliquot Single Used Aliquot Positive Template"
        check "Make single use aliquot by transfering 30 L of the diluted\
        postive control into individual 1.5 mL tubes and label it with the\
        proper item ID."
        check "Discard the empty input tube."
        table transfer_table
      end
    
      # Discard the input
      op.input("Template").item.mark_as_deleted

      # Retrieve the last item of the single use aliquot
      last_tube_id = aliquot_tubes[-1]
    end
    return last_tube_id
  end
  
  #Prepare for plating protocol for a list of operations
  #that all use the given Purified RNA in 1.5 mL tube output.
  #
  # @param prepare_plating [Item] the lyophilized_RNA
  # @param operations     [OperationList] the list of operations
  def prepare_plating(keep_tubes)
    show do
      title "Preparation of Single Aliquot for Plating"
      warning "This reagent should be handled with caution in a dedicated\
      nucleic acid handling area to prevent possible contamination."
      warning "Freeze-thaw cycles should be avoided. Maintain on ice when\
      thawed."
      # Retrieve the last item of the single use aliquot
      check "Thaw a single aliquot of diluted positive control\
      #{keep_tubes} for each experiment and hold on ice until\
      adding to plate."
      check "Discard any unused portion of the aliquot."
    end
    
    # Don't store the single aliquot being used during plating
    keep_tubes.each do |id| Item.find(id).mark_as_deleted end
  end
end

```
