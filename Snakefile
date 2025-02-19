import os
import glob

# ==============================
# 🔹 CONFIGURACIÓN Y VARIABLES
# ==============================
configfile: "config.yaml"

# Variables desde config.yaml
FORWARD_TAG = config["forward_tag"]
REVERSE_TAG = config["reverse_tag"]
ADAPTERS_FILE = config["adapters_file"]

# Directorios principales (📂 Organizados correctamente)
RESULTS_DIR = "results"
RAW_DATA_DIR = "../00_RAW_DATA"  # ✅ Ruta corregida
QC_DIR = os.path.join(RESULTS_DIR, "01_QC")
CLEAN_DATA_DIR = os.path.join(RESULTS_DIR, "02_CLEAN_DATA")
ASSEMBLY_DIR = os.path.join(RESULTS_DIR, "03_ASSEMBLY")
MAPPING_DIR = os.path.join(RESULTS_DIR, "04_MAPPING")
TRANSCRIPTOME_ASSEMBLY_DIR = os.path.join(RESULTS_DIR, "05_TRANSCRIPTOME_ASSEMBLY")
ANNOTATION_DIR = os.path.join(RESULTS_DIR, "06_ANNOTATION")
EXPRESSION_DIR = os.path.join(RESULTS_DIR, "07_GENE_EXPRESSION")

# ✅ Lista de directorios ordenados sin repeticiones
directories = [
    RESULTS_DIR, QC_DIR, CLEAN_DATA_DIR, ASSEMBLY_DIR,
    MAPPING_DIR, TRANSCRIPTOME_ASSEMBLY_DIR, ANNOTATION_DIR, EXPRESSION_DIR
]

# ✅ Crear directorios si no existen
for directory in directories:
    os.makedirs(directory, exist_ok=True)

print("✅ Directorios creados/verificados correctamente")

# ==============================
# 🔹 DETECCIÓN DE MUESTRAS
# ==============================
SAMPLES, = glob_wildcards(os.path.join(RAW_DATA_DIR, "{sample}_" + FORWARD_TAG + ".fastq.gz"))
SAMPLES = sorted(set(SAMPLES))

if not SAMPLES:
    raise ValueError("🚨 No se encontraron muestras en 00_RAW_DATA. Verifica que los archivos existan.")

print(f"✅ {len(SAMPLES)} muestras detectadas: {', '.join(SAMPLES)}")

# ==============================
# 🔹 REGLA PRINCIPAL (ALL)
# ==============================
rule all:
    input:
        expand(QC_DIR + "/{sample}_fastqc.html", sample=SAMPLES),
        QC_DIR + "/preQC_illumina_report.html",
        QC_DIR + "/postQC_illumina_report.html"
