# Data Structure for Microtiter qPCR Plates

<img src="/docs/_images/primer_layout.png" alt="Primer layout for the CDC Protocol" width="600"/>

<img src="/docs/_images/sample_layout.png" alt="Sample layout for the CDC Protocol" width="600"/>

Plates such as the above are represented by the following data structure:

```
Collection: A 96-well plate or 8-12 well stripwell
└── Part: A sample from one well
    └── Metadata: JSON
```

Example JSON for one well:

```json
{
  "template": [
    {
      "name":"Template",
      "id":6336,
      "volume":{
        "qty":5.0,
        "units":"µl"
      }
    }
  ],
  "master_mix": [
    {
      "name": "Molecular Grade Water",
      "id": 6336,
      "volume": {
        "qty": 8.5,
        "units": "µl"
      }
    },
    {
      "name": "Combined Primer/Probe Mix",
      "id": 9046,
      "volume": {
        "qty": 1.5,
        "units": "µl"
      }
    },
    {
      "name": "Master Mix",
      "id": 3827,
      "volume": {
        "qty": 5,
        "units": "µl"
      }
    }
  ]
}
```

In this example the `master_mix` is a combination of Commercial 4X qPCR Master Mix, Combined Primer/Probe Mix, and Molecular Grade Water (Fig. 1, above), and the `template` is the patient sample or control sample (Fig. 2, above). 
