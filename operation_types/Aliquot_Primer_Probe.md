# Aliquot Primer/Probe

Documentation here. Start with a paragraph, not a heading or title, as in most views, the title will be supplied by the view.
### Inputs


- **Primer Set** [P]  
  - <a href='#' onclick='easy_select("Sample Types", "Primer Mix")'>Primer Mix</a> / <a href='#' onclick='easy_select("Containers", "Lyophilized Primer Mix")'>Lyophilized Primer Mix</a>



### Outputs


- **Primer Set** [P]  
  - <a href='#' onclick='easy_select("Sample Types", "Primer Mix")'>Primer Mix</a> / <a href='#' onclick='easy_select("Containers", "Primer Mix Aliquot")'>Primer Mix Aliquot</a>

### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
def precondition(_op)
  true
end
```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
# frozen_string_literal: true

# This is a default, one-size-fits all protocol that shows how you can
# access the inputs and outputs of the operations associated with a job.
# Add specific instructions for this protocol!

class Protocol

  def main

    operations.retrieve.make

    tin  = operations.io_table 'input'
    tout = operations.io_table 'output'

    show do
      title 'Input Table'
      table tin.all.render
    end

    show do
      title 'Output Table'
      table tout.all.render
    end

    operations.store

    {}

  end

end

```
