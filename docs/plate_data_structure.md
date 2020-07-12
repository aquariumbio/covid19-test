# Data Structure for Microtiter qPCR Plates

<img src="/docs/_images/primer_layout.png" alt="Primer layout for the CDC Protocol" width="500"/>

<img src="/docs/_images/sample_layout.png" alt="Sample layout for the CDC Protocol" width="500"/>

```
Collection
└── Part: An Item of SampleType qPCR Reaction
    └── DataAssociation
        ├── patient_sample: An Item of SampleType Respiratory Specimen or RNA
        ├── master_mix: An Item of SampleType Master Mix
        └── primer_probe_mix: An Item of SampleType Primer/Probe Mix
```
