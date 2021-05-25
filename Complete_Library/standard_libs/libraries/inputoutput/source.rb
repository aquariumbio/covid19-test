module InputOutput
  def add_static_inputs ops, name, sample_name, container_name
    ops.each do |op|
      sample = Sample.find_by_name(sample_name)
      container = ObjectType.find_by_name(container_name)
      op.add_input name, sample, container
      op.input(name).set item: sample.in(container.name).first
    end
  end
  
  def get_inputs_checked input_name
    show do
      title "Gather the following item(s)"
       
      operations.each do |op|
        check "#{op.input(input_name).item.id}: #{op.input(input_name).sample.name} at <b>#{op.input(input_name).item.location}</b>"
      end
    end
  end
end