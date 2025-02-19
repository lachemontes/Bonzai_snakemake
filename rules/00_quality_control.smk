# ================================
# 📌 REGLA: FastQC Pre-Limpieza
# ================================
rule fastQC_pre:
    input:
        forward=RAW_DATA_DIR + "/{sample}_" + FORWARD_TAG + ".fastq.gz",
        reverse=RAW_DATA_DIR + "/{sample}_" + REVERSE_TAG + ".fastq.gz"
    output:
        forward_html=QC_DIR + "/{sample}_fastqc_pre_forward.html",
        forward_zip=QC_DIR + "/{sample}_fastqc_pre_forward.zip",
        reverse_html=QC_DIR + "/{sample}_fastqc_pre_reverse.html",
        reverse_zip=QC_DIR + "/{sample}_fastqc_pre_reverse.zip"
    message:
        "🔍 Ejecutando FastQC en {wildcards.sample}"
    conda:
        "env/QC.yaml"
    shell:
        """
        fastqc {input.forward} -o {QC_DIR}
        fastqc {input.reverse} -o {QC_DIR}
        """

# ================================
# 📌 REGLA: MultiQC Pre-Limpieza
# ================================
rule preMultiQC:
    input:
        expand(QC_DIR + "/{sample}_fastqc_pre_forward.zip", sample=SAMPLES),
        expand(QC_DIR + "/{sample}_fastqc_pre_reverse.zip", sample=SAMPLES)
    output:
        multiqc=QC_DIR + "/preQC_illumina_report.html"
    message:
        "📊 Generando MultiQC para Pre-Limpieza"
    conda:
        "env/QC.yaml"
    shell:
        """
        multiqc {QC_DIR} -o {QC_DIR} -n preQC_illumina_report.html
        """

# ================================
# 📌 REGLA: FastQC Post-Limpieza
# ================================
rule fastQC_post:
    input:
        forward=CLEAN_DATA_DIR + "/{sample}_forward_paired.fastq.gz",
        reverse=CLEAN_DATA_DIR + "/{sample}_reverse_paired.fastq.gz"
    output:
        forward_html=QC_DIR + "/{sample}_fastqc_post_forward.html",
        forward_zip=QC_DIR + "/{sample}_fastqc_post_forward.zip",
        reverse_html=QC_DIR + "/{sample}_fastqc_post_reverse.html",
        reverse_zip=QC_DIR + "/{sample}_fastqc_post_reverse.zip"
    message:
        "🔍 Ejecutando FastQC en {wildcards.sample} después de limpieza"
    conda:
        "env/QC.yaml"
    shell:
        """
        fastqc {input.forward} -o {QC_DIR}
        fastqc {input.reverse} -o {QC_DIR}
        """

# ================================
# 📌 REGLA: MultiQC Post-Limpieza
# ================================
rule postMultiQC:
    input:
        expand(QC_DIR + "/{sample}_fastqc_post_forward.zip", sample=SAMPLES),
        expand(QC_DIR + "/{sample}_fastqc_post_reverse.zip", sample=SAMPLES)
    output:
        multiqc=QC_DIR + "/postQC_illumina_report.html"
    message:
        "📊 Generando MultiQC para Post-Limpieza"
    conda:
        "env/QC.yaml"
    shell:
        """
        multiqc {QC_DIR} -o {QC_DIR} -n postQC_illumina_report.html
        """
