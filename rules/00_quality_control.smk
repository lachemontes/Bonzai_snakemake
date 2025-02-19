# ================================
# 📌 REGLA: Conteo de Lecturas
# ================================
rule countReads_gz:
    input:
        fastq=dirs_dict["RAW_DATA_DIR"] + "/{sample}_" + config["forward_tag"] + ".fastq.gz"
    output:
        counts=dirs_dict["RAW_DATA_DIR"] + "/{sample}_" + config["forward_tag"] + "_read_count.txt"
    message:
        "📊 Contando lecturas en {input.fastq}"
    conda:
        dirs_dict["ENVS_DIR"] + "/QC.yaml"
    shell:
        """
        echo $(( $(zgrep -Ec "$" {input.fastq}) / 4 )) > {output.counts}
        """

# ================================
# 📌 REGLA: FastQC Pre-Limpieza
# ================================
rule fastQC_pre:
    input:
        raw_fastq=dirs_dict["RAW_DATA_DIR"] + "/{sample}_" + config["forward_tag"] + ".fastq.gz"
    output:
        html=dirs_dict["QC_DIR"] + "/{sample}_fastqc_pre.html",  # Cambié el nombre de salida
        zipped=dirs_dict["QC_DIR"] + "/{sample}_fastqc_pre.zip"  # Cambié el nombre de salida
    message:
        "🔍 Ejecutando FastQC en {input.raw_fastq}"
    conda:
        dirs_dict["ENVS_DIR"] + "/QC.yaml"
    benchmark:
        dirs_dict["BENCHMARKS"] + "/01_QC/{sample}_pre_qc.tsv"
    shell:
        """
        fastqc {input.raw_fastq} -o {dirs_dict["QC_DIR"]}
        """

# ================================
# 📌 REGLA: MultiQC Pre-Limpieza
# ================================
rule preMultiQC:
    input:
        zipped=expand(dirs_dict["QC_DIR"] + "/{sample}_fastqc_pre.zip", sample=SAMPLES)  # Cambié a fastqc_pre
    output:
        multiqc=dirs_dict["QC_DIR"] + "/preQC_illumina_report.html"
    params:
        fastqc_dir=dirs_dict["QC_DIR"],
        html_name="preQC_illumina_report.html",
        multiqc_dir=dirs_dict["QC_DIR"]
    message:
        "📊 Generando MultiQC para Pre-Limpieza"
    conda:
        dirs_dict["ENVS_DIR"] + "/QC.yaml"
    benchmark:
        dirs_dict["BENCHMARKS"] + "/01_QC/multiqc_pre.tsv"
    shell:
        """
        multiqc {params.fastqc_dir} -o {params.multiqc_dir} -n {params.html_name}
        """

# ================================
# 📌 REGLA: FastQC Post-Limpieza
# ================================
rule fastQC_post:
    input:
        raw_fastq=dirs_dict["CLEAN_DATA_DIR"] + "/{sample}_forward_paired.fastq.gz"
    output:
        html=dirs_dict["QC_DIR"] + "/{sample}_fastqc_post.html",  # Cambié el nombre de salida
        zipped=dirs_dict["QC_DIR"] + "/{sample}_fastqc_post.zip"  # Cambié el nombre de salida
    message:
        "🔍 Ejecutando FastQC en {input.raw_fastq} después de limpieza"
    conda:
        dirs_dict["ENVS_DIR"] + "/QC.yaml"
    benchmark:
        dirs_dict["BENCHMARKS"] + "/01_QC/{sample}_post_qc.tsv"
    shell:
        """
        fastqc {input.raw_fastq} -o {dirs_dict["QC_DIR"]}
        """

# ================================
# 📌 REGLA: MultiQC Post-Limpieza
# ================================
rule postMultiQC:
    input:
        zipped=expand(dirs_dict["QC_DIR"] + "/{sample}_fastqc_post.zip", sample=SAMPLES)  # Cambié a fastqc_post
    output:
        multiqc=dirs_dict["QC_DIR"] + "/postQC_illumina_report.html"
    params:
        fastqc_dir=dirs_dict["QC_DIR"],
        html_name="postQC_illumina_report.html",
        multiqc_dir=dirs_dict["QC_DIR"]
    message:
        "📊 Generando MultiQC para Post-Limpieza"
    conda:
        dirs_dict["ENVS_DIR"] + "/QC.yaml"
    benchmark:
        dirs_dict["BENCHMARKS"] + "/01_QC/multiqc_post.tsv"
    shell:
        """
        multiqc {params.fastqc_dir} -o {params.multiqc_dir} -n {params.html_name}
        """
