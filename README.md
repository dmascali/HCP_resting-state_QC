# A quality-control database for the resting-state young-adult human connectome project
*HCP_resting-state_QC* is a repository of code for extracting a quality control database for the human connectome project resting-state scans.

The [*human connectome project*](https://www.humanconnectome.org/study/hcp-young-adult/data-releases) collected resting-state data from over 1000 healthy young-adult subjects. Looking beyond its original purpose, this
huge database represents a valuable resource for benchmarking denoising pipelines. Unfortunately, quality control data for selecting scans with opposite
noise characteristics, such as scans with extremely low or high head motion, are not publicly available. Here, we explored the entire resting-state human
connectome project to provide researchers with a database of quality control (QC) metrics. We also provided code to construct samples with extreme noise characteristics, which are suitable for benchmarking purposes.

## The quality control database
The QC database is in matlab table format and can be found in */results/QC_database.mat* along with an excel file with variable descriptions.
