

# ShortSeeker

[![Snakemake](https://img.shields.io/badge/snakemake-v8.27.1-brightgreen)](https://snakemake.bitbucket.io)
[![GitHub release](https://img.shields.io/github/v/release/rngoodman/ShortSeeker)](https://github.com/rngoodman/ShortSeeker/releases/)

ShortSeeker is a snakemake pipeline which assembles and analyses paired fastq short-read files. It also produces a html report with MLST sequence typing and acquired AMR genes for multiple genomes. 


# Contents 

- [Installation and usage](https://github.com/rngoodman/ShortSeeker/blob/main/README.md#installation-and-usage)
  - [Clone ShortSeeker repo](https://github.com/rngoodman/ShortSeeker/blob/main/README.md#1-clone-shortseeker-repo)
  - [Install snakemake](https://github.com/rngoodman/ShortSeeker/blob/main/README.md#2-install-snakemake)
  - [Load fastq.gz files into your current directory](https://github.com/rngoodman/ShortSeeker/blob/main/README.md#3-load-fastqgz-files-into-your-current-directory)
  - [Create a list of sample names](https://github.com/rngoodman/ShortSeeker/blob/main/README.md#4-create-a-list-of-sample-names)
  - [Run the snakemake pipeline](https://github.com/rngoodman/ShortSeeker/blob/main/README.md#5-run-the-snakemake-pipeline)
- [Software used](https://github.com/rngoodman/ShortSeeker/blob/main/README.md#third-party-software)
- [Alternatives](https://github.com/rngoodman/ShortSeeker/blob/main/README.md#alternative-tools)

# Installation and usage

## 1. Clone ShortSeeker repo

First clone the ShortSeeker repository into your current directory 

```bash
git clone https://github.com/rngoodman/ShortSeeker.git .
```
Once cloned, check you are in the ShortSeeker directory, it may require a `cd ShortSeeker` command.

## 2. Install snakemake

Make sure you have conda installed, if not see [here](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html).

```bash
conda create -n snakemake -y python=3.8

conda activate snakemake

conda install bioconda::snakemake
```

## 3. Load `fastq.gz` files into your current directory

This workflow works on any `fastq.gz` files in your current directory, whether you have:

(A) downloaded them from online databases or (B) sequenced the genomes yourself.

Either way you just need to make sure the `fastq.gz` files are in your directory 

If your files are in `fastq` format gzip them with the following command:

```bash
gzip *.fastq
```

### 3A. **Download files**

If you want to run the pipeline on sequence files downloaded from online databases this is an example you can follow.

In this example we will download some accessions from the [European Nucleotide Archive (ENA)](https://www.ebi.ac.uk/ena/browser/home).

We will choose 5 accessions from the DASSIM study which studied the drivers of acquisition and long term carriage of ESBL-E in sepsis survivors in Blantyre, Malawi. 

For more information and if you use these sequences please cite:

> Lewis JM, Mphasa M, Banda R, Beale MA, Mallewa J, Anscome C, Zuza A, Roberts AP, Heinz E, Thomson NR, Feasey NA. Genomic analysis of extended-spectrum beta-lactamase (ESBL) producing *Escherichia coli* colonising adults in Blantyre, Malawi reveals previously undescribed diversity. Microb Genom. 2023 Jun;9(6):mgen001035. doi: 10.1099/mgen.0.001035. PMID: 37314322; PMCID: PMC10327512.
> 

First use cat to create a `accessions.txt` file

```bash
cat > accessions.txt
```

Type your accessions directly into the terminal, or alternately copy and paste these to follow this example:

```bash
ERR3425991
ERR3425941
ERR3426046
ERR3865575
ERR3426041
```

Type `Ctrl` + `D` to save and exit 

You now have an `accessions.txt` containing the accessions you want to download. 

The `download_fastq.sh` file is included in the `scripts` repository and it will download any accessions you have in your `accessions.txt` file from the [European Nucleotide Archive (ENA)](https://www.ebi.ac.uk/ena/browser/home).

Once you are happy with the accessions in your  `accessions.txt` file, type the following command: 

```bash
bash scripts/download_fastq.sh
```

### **3B. Use your own sequencing files**

Copy your own sequencing files to your current directory 

For example if your reads are in the `Illumina/reads/` folder this will copy them to your current directory 

```bash
cp Illumina/reads/*.fastq.gz .
```

## 4. Create a list of sample names

Make sure your `fastq.gz` files are in your current directory then use the `ls` command to write your accession to a `samples.txt` file - this is essential for the snakemake pipeline to run. 
You can make your own `samples.txt` file just make sure they match to your file names before the `_1.fastq.gz` and `_2.fastq.gz`.

```bash
ls *_1.fastq.gz | sed 's/_1.fastq.gz//' > samples.txt
```

Check your list of samples:

```bash
cat samples.txt
```

## 5. Run the snakemake pipeline

The snakemake pipeline will run QC, assembly, MLST and AMR gene screening on the `fastq.gz` files in your current directory based on the list of samples in the `samples.txt` files. 

Therefore before continuing check the following:

- You have the `fastq.gz` files you want to assemble in your current directory (a simple `ls` command will confirm this)
- You have a `samples.txt` file which contains sample names which are identical to your `fastq.gz` files before the `_1.fastq.gz` and `_2.fastq.gz`
- You have cloned the ShortSeeker repository (see above)
- You have snakemake installed and accessible (type `snakemake` and check it’s there)

If you have all these things continue ahead.

First test with a dry run:

```bash
snakemake --cores 1 --directory .test/ --use-conda -n
```

Next run for real:

```bash
snakemake --cores 4 --use-conda
```

- `--use-conda` is essential and means that all the required packages will be downloaded and installed through conda without you having to do it yourself.
- `—cores` dictates the amount of threads or cores you want to give to the pipeline to run the task. This example uses a modest 4 but use more if your computer can take it. Generally the more cores you give the pipeline the less time it will take to complete. 

### Output

This will write lots of text throughout but it should take your fastq files all the way from `.fastq.gz` through to assembled `fasta` file and a `html` report.


# Third party software 

Please note that ShortSeeker is a pipeline which connects software written by others and is only possible with these other tools. If you use ShortSeeker please cite the following tools:

- [fastp](https://github.com/OpenGene/fastp) for quality control, Q score filtering and adapter trimming.
- [seqkit](https://github.com/shenwei356/seqkit) for quality control metrics
- [shovill](https://github.com/tseemann/shovill) for assembly and the assembler used e.g.[SPAdes](https://github.com/ablab/spades) 
- [mlst](https://github.com/tseemann/mlst) for multi-locus sequence typing and the [PubMLST database](https://pubmlst.org/)
- [abricate](https://github.com/tseemann/abricate) for screening assembled contigs for AMR genes and the [Resfinder database](doi:10.1093/jac/dks261).

# Alternative tools

- [Bactopia](https://github.com/bactopia/bactopia) uses Nextflow to create a flexible pipeline for the assembly and analysis of bacterial genomes.
- [ASA³P](https://github.com/oschwengers/asap) uses Netxflow to assemble, annotate and analyse genome data of closely related bacterial isolates. 
- [nullarbor](https://github.com/tseemann/nullarbor) is a pipeline using perl to generate public health microbiology reports from sequenced isolates.  








