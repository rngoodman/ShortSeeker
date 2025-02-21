#!/bin/bash

# Define the base URL
BASE_URL="ftp://ftp.sra.ebi.ac.uk/vol1/fastq"

# Loop through each accession number in the file
while read -r accession; do
    # Extract prefix for directory structure (first 6 characters)
    prefix=${accession:0:6}
    
    # Extract last digit of the accession
    last_digit=${accession: -1}

    # Construct correct subfolder path (00X)
    subfolder="00${last_digit}"

    # Construct and download both paired-end files
    wget "$BASE_URL/$prefix/$subfolder/$accession/${accession}_1.fastq.gz"
    wget "$BASE_URL/$prefix/$subfolder/$accession/${accession}_2.fastq.gz"

done < accessions.txt