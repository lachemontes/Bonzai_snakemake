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
        forward=dirs_dict["RAW_DATA_DIR"] + "/{sample}_" + config["forward_tag"] + ".fastq.gz",
        reverse=dirs_dict["RAW_DATA_DIR"] + "/{sample}_" + config["reverse_tag"] + ".fastq.gz"
    output:
        forward_html=dirs_dict["QC_DIR"] + "/{sample}_fastqc_pre_forward.html",
        reverse_html=dirs_dict["QC_DIR"] + "/{sample}_fastqc_pre_reverse.html",
        forward_zip=dirs_dict["QC_DIR"] + "/{sample}_fastqc_pre_forward.zip",
        reverse_zip=dirs_dict["QC_DIR"] + "/{sample}_fastqc_pre_reverse.zip"
    message:
        "🔍 Ejecutando FastQC en {input.forward} y {input.reverse}"
    conda:
        dirs_dict["ENVS_DIR"] + "/QC.yaml"
    shell:
        """
        fastqc {input.forward} -o {dirs_dict["QC_DIR"]}
        fastqc {input.reverse} -o {dirs_dict["QC_DIR"]}
        """

# ================================
# 📌 REGLA: MultiQC Pre-Limpieza
# ================================
rule preMultiQC:
    input:
        expand(dirs_dict["QC_DIR"] + "/{sample}_fastqc_pre_forward.zip", sample=SAMPLES),
        expand(dirs_dict["QC_DIR"] + "/{sample}_fastqc_pre_reverse.zip", sample=SAMPLES)
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
    shell:
        """
        multiqc {params.fastqc_dir} -o {params.multiqc_dir} -n {params.html_name}
        """

# ================================
# 📌 REGLA: FastQC Post-Limpieza
# ================================
rule fastQC_post:
    input:
        forward=dirs_dict["CLEAN_DATA_DIR"] + "/{sample}_forward_paired.fastq.gz",
        reverse=dirs_dict["CLEAN_DATA_DIR"] + "/{sample}_reverse_paired.fastq.gz"
    output:
        forward_html=dirs_dict["QC_DIR"] + "/{sample}_fastqc_post_forward.html",
        reverse_html=dirs_dict["QC_DIR"] + "/{sample}_fastqc_post_reverse.html",
        forward_zip=dirs_dict["QC_DIR"] + "/{sample}_fastqc_post_forward.zip",
        reverse_zip=dirs_dict["QC_DIR"] + "/{sample}_fastqc_post_reverse.zip"
    message:
        "🔍 Ejecutando FastQC después de limpieza en {input.forward} y {input.reverse}"
    conda:
        dirs_dict["ENVS_DIR"] + "/QC.yaml"
    shell:
        """
        fastqc {input.forward} -o {dirs_dict["QC_DIR"]}
        fastqc {input.reverse} -o {dirs_dict["QC_DIR"]}
        """

# ================================
# 📌 REGLA: MultiQC Post-Limpieza
# ================================
rule postMultiQC:
    input:
        expand(dirs_dict["QC_DIR"] + "/{sample}_fastqc_post_forward.zip", sample=SAMPLES),
        expand(dirs_dict["QC_DIR"] + "/{sample}_fastqc_post_reverse.zip", sample=SAMPLES)
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
    shell:
        """
        multiqc {params.fastqc_dir} -o {params.multiqc_dir} -n {params.html_name}
        """
