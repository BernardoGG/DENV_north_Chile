# Likelihood of the establishment of Dengue virus in northern Chile

Bernardo Gutierrez<sup>1,2</sup>, Rhys P.D. Inward<sup>1</sup>, Simon Busch-Moreno<sup>1</sup>, Moritz U.G. Kraemer<sup>1,3,†</sup>

1.	Department of Biology, University of Oxford, Oxford, UK
2.	Colegio de Ciencias Biologicas y Ambientales, Universidad San Francisco de Quito USFQ, Quito, Ecuador
3.	Pandemic Sciences Institute, University of Oxford, Oxford, UK

This repository contains material for the exploratory analysis of human mobility from Chile and Dengue virus (DENV) genome data from South America to describe the historical patterns of viral spread, summarise the connectivity of the Arica and Tarapacá regions of Chile with other regional and global destinations, and explore likely drivers of the potential for sustained DENV transmission in north Chile.

## Repository structure and general notes
The structure of this repository is shown below.  

This repository contains various data types from South America and Chile specifically. Aggregted monthly estimates of incoming travellers to Chile, split by ports of entry (land border crossings, maritime ports, airports), can be founf under [`data/human_mobility`](data/human_mobility) with the relevant script for their analyses included (all scripts are found on the main directory).

A general phylogeographic analyses has been performed following the pipeline developed by [`Rhys P.D. Inward`](https://github.com/rhysinward) and available [`here`](https://github.com/rhysinward/dengue_pipeline.git). It retrieved complete genomes and E gene sequences from publicly available data bases (namely GenBank), prepares the data and accompanying metadata, and stages a phylodynamic analysis pipeline resulting in time-calibrated Maximum Likelihood phylogenies for each DENV serotype in the Americas.

```
DENV_north_Chile/
├── data
│   ├── human_mobility
│   └── opendengue
├── analyses
├── plots
├── Human_mobility_north_CL.R
└── README.md
```