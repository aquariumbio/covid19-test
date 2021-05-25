module AddOutput
    
## Example
        # operations.each do |op|
        #     add_output op,"Media", "YEB medium", ObjectType"200 mL Liquid"
        # end
        #operations.make

    def add_output operation, output_name, sample, container
    ft = FieldType.new(
                name: output_name,
                ftype: "sample",
                parent_class: "OperationType",
                parent_id: nil
            )
            ft.save
        
            aft = AllowableFieldType.new({
                field_type_id: ft.id,
                sample_type_id: sample.sample_type.id,
                object_type_id: ObjectType.find_by_name(container).id
            })
            aft.save
            
            fv = FieldValue.new(
                name: "Media",
                child_item_id: nil,
                child_sample_id: sample.id,
                role: 'output',
                parent_class: "Operation",
                parent_id: operation.id,
                field_type_id: ft.id)
            fv.allowable_field_type_id = aft.id
            fv.save
        
    end

end