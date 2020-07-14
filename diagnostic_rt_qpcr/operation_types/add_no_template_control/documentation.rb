Adds no-template control (NTC) samples to the input collection,
typically a 96-well plate. For example, according to the CDC protocol, pipettes 
5 uL of nuclease-free water into the NTC sample wells (the first column of sample wells).

#### Job Options
None

#### Operation Options
`program_name [String]` The protocol to be followed, based on the qPCR
master mix used. Defaults to CDC_TaqPath_CG. For other supported protocols, see
[this document](https://github.com/aquariumbio/pcr-models/blob/master/pcr_libs/libraries/pcrcompositiondefinitions/source.rb).

`group_size [Int]` The number of NTC samples to add for each primer group.
Defaults to 3.

`layout_method [String]` The method to use in laying out the plate. Defaults to `cdc_sample_layout`.
