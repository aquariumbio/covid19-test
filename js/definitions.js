var config = {

  tagline: "The Laboratory</br>Operating System",
  documentation_url: "http://localhost:4000/aquarium",
  title: "Aquarium COVID-19 Detection",
  navigation: [

    {
      category: "Overview",
      contents: [
        { name: "Introduction", type: "local-md", path: "README.md" },
        { name: "About this Workflow", type: "local-md", path: "ABOUT.md" },
        { name: "License", type: "local-md", path: "LICENSE.md" },
        { name: "Issues", type: "external-link", path: 'https://github.com/klavinslab/aq-covid19-test/issues' }
      ]
    },

    

      {

        category: "Operation Types",

        contents: [

          
            {
              name: 'Aliquot Positive Template',
              path: 'operation_types/Aliquot_Positive_Template' + '.md',
              type: "local-md"
            },
          
            {
              name: 'Aliquot Primer/Probe',
              path: 'operation_types/Aliquot_Primer_Probe' + '.md',
              type: "local-md"
            },
          
            {
              name: 'Extract RNA',
              path: 'operation_types/Extract_RNA' + '.md',
              type: "local-md"
            },
          
            {
              name: 'Prepare RT-qPCR Plate',
              path: 'operation_types/Prepare_RT-qPCR_Plate' + '.md',
              type: "local-md"
            },
          
            {
              name: 'Run qPCR',
              path: 'operation_types/Run_qPCR' + '.md',
              type: "local-md"
            },
          

        ]

      },

    

    

    
      { category: "Sample Types",
        contents: [
          
            {
              name: 'Primer Mix',
              path: 'sample_types/Primer_Mix'  + '.md',
              type: "local-md"
            },
          
            {
              name: 'RNA',
              path: 'sample_types/RNA'  + '.md',
              type: "local-md"
            },
          
            {
              name: 'Respiratory Specimen',
              path: 'sample_types/Respiratory_Specimen'  + '.md',
              type: "local-md"
            },
          
            {
              name: 'qPCR Reaction',
              path: 'sample_types/qPCR_Reaction'  + '.md',
              type: "local-md"
            },
          
        ]
      },
      { category: "Containers",
        contents: [
          
            {
              name: '96-well qPCR Reaction',
              path: 'object_types/96-well_qPCR_Reaction'  + '.md',
              type: "local-md"
            },
          
            {
              name: 'Lyophilized Primer Mix',
              path: 'object_types/Lyophilized_Primer_Mix'  + '.md',
              type: "local-md"
            },
          
            {
              name: 'Lyophilized RNA',
              path: 'object_types/Lyophilized_RNA'  + '.md',
              type: "local-md"
            },
          
            {
              name: 'Nasopharyngeal Swab',
              path: 'object_types/Nasopharyngeal_Swab'  + '.md',
              type: "local-md"
            },
          
            {
              name: 'Primer Mix Aliquot',
              path: 'object_types/Primer_Mix_Aliquot'  + '.md',
              type: "local-md"
            },
          
            {
              name: 'Purified RNA in 1.5 mL tube',
              path: 'object_types/Purified_RNA_in_1.5_mL_tube'  + '.md',
              type: "local-md"
            },
          
        ]
      }
    

  ]

};
