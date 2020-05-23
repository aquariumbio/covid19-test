# Extract RNA

Documentation here. Start with a paragraph, not a heading or title, as in most views, the title will be supplied by the view.
### Inputs


- **Specimen** [S]  
  - <a href='#' onclick='easy_select("Sample Types", "Respiratory Specimen")'>Respiratory Specimen</a> / <a href='#' onclick='easy_select("Containers", "Nasopharyngeal Swab")'>Nasopharyngeal Swab</a>

### Parameters

- **Method** [QIAamp DSP Viral RNA Mini Kit,Alternative Method]
- **Options** 

### Outputs


- **Specimen** [T]  
  - <a href='#' onclick='easy_select("Sample Types", "RNA")'>RNA</a> / <a href='#' onclick='easy_select("Containers", "Purified RNA in 1.5 mL tube")'>Purified RNA in 1.5 mL tube</a>

### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
def precondition(_op)
  true
end
```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
# frozen_string_literal: true

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Units'
needs 'Standard Libs/Debug'
needs 'RNAExtractionKits/RNAExtractionKits'

# Extract RNA Protocol
#
# @author Devin Strickland <strcklnd@uw.edu>
class Protocol
  include PlanParams
  include Units
  include Debug
  include RNAExtractionKits

  ########## DEFAULT PARAMS ##########

  # Default parameters that are applied equally to all operations.
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_job_params
    {
      rna_extraction_kit: TestRNAExtractionKit::NAME
    }
  end

  # Default parameters that are applied to individual operations.
  #   Can be overridden by:
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_operation_params
    {
      sample_volume: { qty: 100, units: MICROLITERS }
    }
  end

  ########## MAIN ##########

  def main
    setup_test_options(operations: operations) if debug

    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )
    return {} if operations.errored.any?

    operations.retrieve.make

    set_kit(name: @job_params[:rna_extraction_kit])

    sample_volumes = get_options(operations: operations, key: :sample_volume)
    if sample_volumes.uniq.length == 1
      run_rna_extraction_kit(
        operations: operations,
        sample_volume: sample_volumes.first
      )
    else
      run_rna_extraction_kit(
        operations: operations,
        use_operations: true
      )
    end

    operations.store

    {}
  end
end

```
