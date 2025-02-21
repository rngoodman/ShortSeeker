# Snakefile
# Define samples
SAMPLES = [line.strip() for line in open("samples.txt")]  # samples.txt is required

# Define directories for output files
READ_QC_DIR    = "results/read_qc"
ASSEMBLY_DIR   = "results/assembly"
ASSEMBLY_QC_DIR= "results/assembly_qc"
MLST_DIR       = "results/mlst"
AMR_DIR        = "results/amr"
REPORT_DIR     = "results/report"


# The final output files for the pipeline.
rule all:
    input:
        f"{ASSEMBLY_QC_DIR}/assembly_stats.csv",
        f"{MLST_DIR}/mlst_summary.csv",
        f"{AMR_DIR}/abricate_samples.csv",
        f"{AMR_DIR}/abricate_summary.csv",
        f"{REPORT_DIR}/summary.html"

rule mkdir:
    shell:
        """
        mkdir -p {REPORT_DIR}
        mkdir -p {ASSEMBLY_QC_DIR}
        mkdir -p {MLST_DIR}
        mkdir -p {AMR_DIR}
        """



##############################################
# 1. QC of fastq with fastq including trimming
###############################################


rule fastp:
    input:
        r1="{sample}_1.fastq.gz",
        r2="{sample}_2.fastq.gz"
    output:
        r1_filtered=f"{READ_QC_DIR}/{{sample}}_1_filtered.fastq.gz",
        r2_filtered=f"{READ_QC_DIR}/{{sample}}_2_filtered.fastq.gz",
        html=f"{READ_QC_DIR}/{{sample}}_fastp.html"
    conda: "envs/fastp.yaml"
    shell:
        "fastp -i {input.r1} -I {input.r2} -q 20 -o {output.r1_filtered} -O {output.r2_filtered} --html {output.html}"


##############################################
# 2. QC of reads with seqkit 
###############################################


# (Optional) Run seqkit stats on fastp output to get quality summaries
rule seqkit_stats_fastp:
    input:
        r1 = rules.fastp.output.r1_filtered,
        r2 = rules.fastp.output.r2_filtered
    conda:
        "envs/seqkit.yaml"
    output:
        stats = f"{READ_QC_DIR}/{{sample}}_seqkit_stats.txt"
    shell:
        """
        seqkit stats {input.r1} {input.r2} > {output.stats}
        """


###############################################
# 3. Genome assembly with Shovill
###############################################
rule shovill_assembly:
    input:
        r1= rules.fastp.output.r1_filtered,
        r2= rules.fastp.output.r2_filtered
    output:
        fasta = f"{ASSEMBLY_DIR}/{{sample}}.fasta"
    params:
        # Adjust shovill parameters as needed.
        outdir = lambda wildcards: f"{ASSEMBLY_DIR}/{wildcards.sample}_assembly"
    threads: 4
    conda:
        "envs/shovill.yaml"
    shell:
        """
        shovill --R1 {input.r1} --R2 {input.r2} \
                 --outdir {params.outdir} \
                 --cpus {threads} --gsize 4.6M
        # Move the assembly result to the desired location.
        mv {params.outdir}/contigs.fa {output.fasta}
        """


###############################################
# 4. QC of fasta files with seqkit
#    (contig lengths, N50, GC %)
###############################################
rule seqkit_stats_all:
    input:
        fasta_files = expand(f"{ASSEMBLY_DIR}/{{sample}}.fasta", sample=SAMPLES)
    output:
        stats = f"{ASSEMBLY_QC_DIR}/assembly_stats.csv"
    conda:
        "envs/seqkit.yaml"
    shell:
        """
        seqkit stats -a {input.fasta_files} > {output.stats}
        """

###############################################
# 5. MLST with mlst
###############################################
rule mlst_all:
    input:
        fasta_files = expand(f"{ASSEMBLY_DIR}/{{sample}}.fasta", sample=SAMPLES)
    output:
        table = f"{MLST_DIR}/mlst_summary.csv"
    conda:
        "envs/mlst.yaml"
    shell:
        """
        mlst {input.fasta_files} > {output.table}
        """

###############################################
# 6. AMR genes with abricate using resfinder database
###############################################
rule abricate_all:
    input:
        fasta_files = expand(f"{ASSEMBLY_DIR}/{{sample}}.fasta", sample=SAMPLES)
    output:
        table = f"{AMR_DIR}/abricate_samples.csv",
        sum_table = f"{AMR_DIR}/abricate_summary.csv"
    params:
        db = "resfinder"
    conda:
        "envs/abricate.yaml"
    shell:
        """
        abricate --db {params.db} --csv {input.fasta_files} > {output.table}
        abricate --summary {output.table} > {output.sum_table}
        """


###############################################
# 8. Summary report
###############################################
rule summary_report:
    input:
        qc = f"{ASSEMBLY_QC_DIR}/assembly_stats.csv",
        mlst = f"{MLST_DIR}/mlst_summary.csv",
        amr = f"{AMR_DIR}/abricate_samples.csv"
    output:
        report = f"{REPORT_DIR}/summary.html"
    conda:
        "envs/report.yaml"  # Use a Python environment with Jinja2 installed
    script:
        "scripts/create_summary.py"