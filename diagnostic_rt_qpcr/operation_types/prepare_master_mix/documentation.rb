Creates a collection, typically a 96-well plate, filled with qPCR master mixes. 

#### Job Options
None

#### Operation Options
`program_name [String]` The protocol to be followed, based on the qPCR
master mix used. Defaults to CDC_TaqPath_CG. For other supported protocols, see
[this document](https://github.com/aquariumbio/pcr-models/blob/master/pcr_libs/libraries/pcrcompositiondefinitions/source.rb).

`group_size [Int]` The number of master mix samples to make and add for each 
input primer. Defaults to 24.

`layout_method [String]` The method to use in laying out the plate. Defaults to `cdc_primer_layout`.