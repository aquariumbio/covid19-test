# Run qPCR

Documentation here. Start with a paragraph, not a heading or title, as in most views, the title will be supplied by the view.
### Inputs


- **qPCR Reactions** []  
  - <a href='#' onclick='easy_select("Sample Types", "qPCR Reaction")'>qPCR Reaction</a> / <a href='#' onclick='easy_select("Containers", "96-well qPCR Reaction")'>96-well qPCR Reaction</a>





### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
def precondition(_op)
  true
end
```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
needs "PCR Libs/PCRComposition"
needs "PCR Libs/PCRProgram"
needs "Thermocyclers/Thermocyclers"

class Protocol

  include ThermocyclerHelper

  def main

    operations.retrieve.make

    composition = PCRCompositionFactory.build(
      program_name: program_name
    )
    program = PCRProgramFactory.build(
      program_name: program_name, 
      volume: composition.volume
    )
    
    thermocycler = ThermocyclerFactory.build(
      model: TestThermocycler::MODEL
    )

    set_up_program(
      thermocycler: thermocycler, 
      program: program, 
      composition: composition
    )

    operations.store

    {}

  end

end

```
