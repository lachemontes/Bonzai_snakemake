import os

# =====================================================
# Configuración del workflow
# =====================================================
configfile: "config.yaml"

# Definir directorios principales
RAW_DATA_DIR = config["input_dir"].rstrip("/")
RESULTS_DIR = config["results_dir"].rstrip("/")
CLEAN_DATA_DIR = os.path.join(RESULTS_DIR, "02_CLEAN_DATA")
QC_DIR = os.path.join(RESULTS_DIR, "01_QC")

# Crear estructura de directorios
for d in [RESULTS_DIR, QC_DIR, CLEAN_DATA_DIR]:
    os.makedirs(d, exist_ok=True)

# Detectar muestras en el directorio de entrada
SAMPLES, = glob_wildcards(RAW_DATA_DIR + "/{sample}_" + config["reverse_tag"] + ".fastq.gz")
SAMPLES = sorted(set(SAMPLES))

if not SAMPLES:
    print("⚠️ No se encontraron muestras en", RAW_DATA_DIR)
else:
    print(f"✅ {len(SAMPLES)} muestras detectadas: {', '.join(SAMPLES)}")

# =====================================================
# Reglas del workflow
# =====================================================
rule all:
    input:
        expand(QC_DIR + "/preQC_illumina_report.html"),
        expand(QC_DIR + "/postQC_illumina_report.html"),
        expand(CLEAN_DATA_DIR + "/{sample}_kraken_report.txt", sample=SAMPLES)

# ---------------------------------
# 1️⃣ Conteo de reads en archivos FASTQ
# ---------------------------------
rule countReads_gz:
    input:
        fastq=RAW_DATA_DIR + "/{sample}_" + config["forward_tag"] + ".fastq.gz"
    output:
        counts=RAW_DATA_DIR + "/{sample}_" + config["forward_tag"] + "_read_count.txt"
    conda:
        "envs/QC.yaml"
    shell:
        """
        echo $(( $(zgrep -Ec "$" {input.fastq}) / 4 )) > {output.counts}
        """

# ---------------------------------
# 2️⃣ FastQC Pre-Trimado
# ---------------------------------
rule fastQC_pre:
    input:
        fastq=RAW_DATA_DIR + "/{sample}_" + config["forward_tag"] + ".fastq.gz"
    output:
        html=temp(QC_DIR + "/{sample}_fastqc.html"),
        zipped=QC_DIR + "/{sample}_fastqc.zip"
    conda:
        "envs/QC.yaml"
    shell:
        """
        fastqc {input.fastq} -o {QC_DIR}
        """

# ---------------------------------
# 3️⃣ Trimmomatic (Recorte de adaptadores y calidad)
# ---------------------------------
rule trim_adapters:
    input:
        forward=RAW_DATA_DIR + "/{sample}_" + config["forward_tag"] + ".fastq.gz",
        reverse=RAW_DATA_DIR + "/{sample}_" + config["reverse_tag"] + ".fastq.gz",
        adapters=config["adapters_file"]
    output:
        forward_paired=temp(CLEAN_DATA_DIR + "/{sample}_forward_paired.fastq.gz"),
        reverse_paired=temp(CLEAN_DATA_DIR + "/{sample}_reverse_paired.fastq.gz")
    conda:
        "envs/trimmomatic.yaml"
    shell:
        """
        trimmomatic PE -threads 4 -phred33 \
            {input.forward} {input.reverse} \
            {output.forward_paired} {output.reverse_paired} \
            ILLUMINACLIP:{input.adapters}:2:30:10:1:true \
            LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
        """

# ---------------------------------
# 4️⃣ FastQC Post-Trimado
# ---------------------------------
rule fastQC_post:
    input:
        fastq=CLEAN_DATA_DIR + "/{sample}_forward_paired.fastq.gz"
    output:
        html=temp(QC_DIR + "/{sample}_fastqc.html"),
        zipped=QC_DIR + "/{sample}_fastqc.zip"
    conda:
        "envs/QC.yaml"
    shell:
        """
        fastqc {input.fastq} -o {QC_DIR}
        """

# ---------------------------------
# 5️⃣ MultiQC para reportes globales
# ---------------------------------
rule preMultiQC:
    input:
        expand(QC_DIR + "/{sample}_fastqc.zip", sample=SAMPLES)
    output:
        multiqc=QC_DIR + "/preQC_illumina_report.html"
    conda:
        "envs/QC.yaml"
    shell:
        """
        multiqc {QC_DIR} -o {QC_DIR} -n preQC_illumina_report.html
        """

rule postMultiQC:
    input:
        expand(QC_DIR + "/{sample}_fastqc.zip", sample=SAMPLES)
    output:
        multiqc=QC_DIR + "/postQC_illumina_report.html"
    conda:
        "envs/QC.yaml"
    shell:
        """
        multiqc {QC_DIR} -o {QC_DIR} -n postQC_illumina_report.html
        """

# ---------------------------------
# 6️⃣ Kraken2 para detección de contaminación
# ---------------------------------
rule contaminants_KRAKEN:
    input:
        forward_paired=CLEAN_DATA_DIR + "/{sample}_forward_paired.fastq.gz",
        reverse_paired=CLEAN_DATA_DIR + "/{sample}_reverse_paired.fastq.gz"
    output:
        kraken_report=CLEAN_DATA_DIR + "/{sample}_kraken_report.txt"
    conda:
        "envs/kraken.yaml"
    shell:
        """
        kraken2 --db {config["kraken_db"]} --threads 4 \
            --paired {input.forward_paired} {input.reverse_paired} \
            --report {output.kraken_report}
        """
