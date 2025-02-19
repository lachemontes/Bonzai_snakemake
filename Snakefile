import os

# ==============================
# 🔹 CONFIGURACIÓN Y VARIABLES
# ==============================
configfile: "config.yaml"

# Variables desde config.yaml
FORWARD_TAG = config["forward_tag"]
REVERSE_TAG = config["reverse_tag"]
ADAPTERS_FILE = config["adapters_file"]

# Directorios principales
RESULTS_DIR = "results"
RAW_DATA_DIR = "raw_data"
QC_DIR = os.path.join(RESULTS_DIR, "01_QC")
CLEAN_DATA_DIR = os.path.join(RESULTS_DIR, "02_CLEAN_DATA")
ASSEMBLY_DIR = os.path.join(RESULTS_DIR, "02_ASSEMBLY")
MAPPING_DIR = os.path.join(RESULTS_DIR, "03_MAPPING")
TRANSCRIPTOME_ASSEMBLY_DIR = os.path.join(RESULTS_DIR, "04_TRANSCRIPTOME_ASSEMBLY")
ANNOTATION_DIR = os.path.join(RESULTS_DIR, "05_ANNOTATION")
EXPRESSION_DIR = os.path.join(RESULTS_DIR, "06_GENE_EXPRESSION")

# Lista de directorios a crear
directories = [
    RESULTS_DIR, RAW_DATA_DIR, QC_DIR, CLEAN_DATA_DIR, ASSEMBLY_DIR,
    MAPPING_DIR, TRANSCRIPTOME_ASSEMBLY_DIR, ANNOTATION_DIR, EXPRESSION_DIR
]

# Crear directorios si no existen
for directory in directories:
    os.makedirs(directory, exist_ok=True)

print("✅ Directorios creados/verificados correctamente")

# Detectar muestras
SAMPLES, = glob_wildcards(os.path.join(RAW_DATA_DIR, "{sample}_" + FORWARD_TAG + ".fastq.gz"))
SAMPLES = sorted(set(SAMPLES))

# ==============================
# 🔹 REGLA PRINCIPAL (ALL)
# ==============================
rule all:
    input:
        expand(QC_DIR + "/{sample}_fastqc.html", sample=SAMPLES),
        expand(QC_DIR + "/preQC_illumina_report.html"),
        expand(QC_DIR + "/postQC_illumina_report.html")

# ==============================
# 🔹 REGLAS DE CONTROL DE CALIDAD
# ==============================

rule countReads_gz:
    input:
        fastq=RAW_DATA_DIR + "/{sample}_" + FORWARD_TAG + ".fastq.gz"
    output:
        counts=RAW_DATA_DIR + "/{sample}_" + FORWARD_TAG + "_read_count.txt"
    message:
        "📊 Counting reads in {input.fastq}"
    conda:
        "env/QC.yaml"
    shell:
        """
        echo $(( $(zgrep -Ec "$" {input.fastq}) / 4 )) > {output.counts}
        """

rule fastQC_pre:
    input:
        raw_fastq=RAW_DATA_DIR + "/{sample}_" + FORWARD_TAG + ".fastq.gz"
    output:
        html=QC_DIR + "/{sample}_fastqc.html",
        zipped=QC_DIR + "/{sample}_fastqc.zip"
    message:
        "🧪 Running FastQC on raw reads for {wildcards.sample}"
    conda:
        "env/QC.yaml"
    shell:
        """
        fastqc {input.raw_fastq} -o {QC_DIR}
        """

rule fastQC_post:
    input:
        cleaned_fastq=CLEAN_DATA_DIR + "/{sample}_forward_paired.fastq.gz"
    output:
        html=QC_DIR + "/{sample}_fastqc_post.html",
        zipped=QC_DIR + "/{sample}_fastqc_post.zip"
    message:
        "🧪 Running FastQC on cleaned reads for {wildcards.sample}"
    conda:
        "env/QC.yaml"
    shell:
        """
        fastqc {input.cleaned_fastq} -o {QC_DIR}
        """

rule preMultiQC:
    input:
        expand(QC_DIR + "/{sample}_fastqc.zip", sample=SAMPLES)
    output:
        multiqc=QC_DIR + "/preQC_illumina_report.html"
    message:
        "📊 Generating MultiQC report for pre-QC data"
    conda:
        "env/QC.yaml"
    shell:
        """
        multiqc {QC_DIR} -o {QC_DIR} -n preQC_illumina_report.html
        """

rule postMultiQC:
    input:
        expand(QC_DIR + "/{sample}_fastqc_post.zip", sample=SAMPLES)
    output:
        multiqc=QC_DIR + "/postQC_illumina_report.html"
    message:
        "📊 Generating MultiQC report for post-QC data"
    conda:
        "env/QC.yaml"
    shell:
        """
        multiqc {QC_DIR} -o {QC_DIR} -n postQC_illumina_report.html
        """

# ==============================
# 🔹 REGLA PARA TRIMMOMATIC
# ==============================
rule trim_adapters_quality:
    input:
        forward_file=RAW_DATA_DIR + "/{sample}_" + FORWARD_TAG + ".fastq.gz",
        reverse_file=RAW_DATA_DIR + "/{sample}_" + REVERSE_TAG + ".fastq.gz",
        adapters=ADAPTERS_FILE
    output:
        forward_paired=CLEAN_DATA_DIR + "/{sample}_forward_paired.fastq.gz",
        reverse_paired=CLEAN_DATA_DIR + "/{sample}_reverse_paired.fastq.gz"
    message:
        "✂️ Trimming adapters for {wildcards.sample}"
    conda:
        "env/QC.yaml"
    shell:
        """
        trimmomatic PE -threads 8 -phred33 \
            {input.forward_file} {input.reverse_file} \
            {output.forward_paired} /dev/null \
            {output.reverse_paired} /dev/null \
            ILLUMINACLIP:{input.adapters}:2:30:10:1:true \
            LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
        """
