# Bisulfite-Sequencing-Cancer-Analysis-Piperline

End-to-end WGBS/cfDNA methylation pipeline for **cancer classification**:  
1) fetch public data, 2) convert to FASTQ, 3) align & extract methylation with **Bismark**,  
4) bin counts & compute percent methylation, and 5) train/evaluate ML models (XGBoost/CNN/MLP).

> Designed and tested on **Compute Canada** (SLURM). Adapt paths, modules, and accessions for your environment.

---

## 🔎 Overview

SRA accessions ──► (step1) prefetch ──► .sra
.sra ──► (step2) fastq-dump ──► paired FASTQ
FASTQ ──► (step3) Bismark align+dedup ──► BAM + methylation calls (.cov.gz) + HTML QC
.cov.gz ──► (step4) bedtools map ──► binned counts + percent methylation (CSV)
CSV ──► (notebooks) ML training ──► metrics (acc/AUC), ROC curves, feature importance

markdown
Copy code

**Key directories**

CHM13_Bismark_Genome/ # Bismark genome index (e.g., T2T-CHM13)
CHM13_Genome/ # Reference FASTA index + bins (hs1.fa.fai, sorted_genome_100k_bins.bed)
Cancer Prediction Models/ # Jupyter notebooks for ML models
step1_sra_batch_download.sh
step2_fastq_conversion.sh
step3_bismark_pipeline/ # multiple bismark_pipeline_.sh variants
step4_methylation_to_csv/ # methylation_to_csv_.sh scripts

markdown
Copy code

---

## 🧰 Requirements

- **SLURM** environment (e.g., Compute Canada)
- Tools:
  - `sra-toolkit` (prefetch, fastq-dump)
  - `bismark` + `bowtie2`
  - `bedtools`
  - `python` (recommended: `pandas`, `numpy`, `scikit-learn`, `xgboost`, `matplotlib`, `jupyter`)
- Reference genome & bins:
  - `CHM13_Bismark_Genome/` (created via `bismark_genome_preparation`)
  - `CHM13_Genome/hs1.fa.fai` (FAI index)
  - `CHM13_Genome/sorted_genome_100k_bins.bed` (genome tiled into 100 kb windows)

> ⚠️ **Accession types:** `prefetch` usually expects **SRR/SRX/SRP**. If using **SAMN** IDs, convert to SRR list or adapt the script.

---

## 🚀 Quickstart (SLURM)

### 0) Configure
- Edit paths inside scripts to match your `$SCRATCH`/work dir.
- Add accessions (one per line) to `srr_list.txt`.

### 1) Download SRA
```bash
sbatch step1_sra_batch_download.sh
Outputs: sra_files/*.sra

2) Convert to FASTQ
bash
Copy code
sbatch step2_fastq_conversion.sh
Outputs: fastq_files/*_1.fastq, *_2.fastq

3) Bismark alignment, deduplication, methylation extraction
Pick a script in step3_bismark_pipeline/ (adjust FASTQ_DIR, GENOME_DIR, etc.):

bash
Copy code
sbatch step3_bismark_pipeline/bismark_pipeline_1.sh
Outputs:

aligned/*.bam

methylation/<sample>/*.cov.gz

Reports in html_files/

4) Bin methylation and export CSV
bash
Copy code
sbatch step4_methylation_to_csv/methylation_to_csv_1.sh
Outputs per-sample CSV with columns:

sql
Copy code
Chromosome,Start,End,Meth_Counts,Unmeth_Counts,Percent_Methylation
📒 Modeling (Jupyter Notebooks)
Located in Cancer Prediction Models/:

Cancer_1000bins_XGBoost.ipynb

Cancer_1000bins_RF.ipynb, ..._MLP.ipynb, ..._CNN.ipynb

Generate Complete ROC.ipynb

Example scaffold (Python):

python
Copy code
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, roc_auc_score
from xgboost import XGBClassifier

X_train, X_temp, y_train, y_temp = train_test_split(X, y, test_size=0.4, random_state=42)
X_val, X_test, y_val, y_test = train_test_split(X_temp, y_temp, test_size=0.5, random_state=42)

clf = XGBClassifier(n_estimators=200, max_depth=3, learning_rate=0.2, random_state=42)
clf.fit(X_train, y_train, eval_set=[(X_val, y_val)], verbose=True)

y_pred  = clf.predict(X_test)
y_proba = clf.predict_proba(X_test)[:, 1]

print("Test accuracy:", accuracy_score(y_test, y_pred))
print("Test ROC-AUC:", roc_auc_score(y_test, y_proba))
🗂️ Input/Output Conventions
FASTQ suffixes: _1.fastq, _2.fastq

Bismark outputs: *.bismark.cov.gz

Binning: default 100 kb (sorted_genome_100k_bins.bed)

CSV schema: Meth_Counts, Unmeth_Counts, Percent_Methylation

⚙️ Configuration Tips
Modules (Compute Canada):

bash
Copy code
module load sra-toolkit
module load bismark
module load bowtie2
module load bedtools
module load python
Bismark genome:

bash
Copy code
bismark_genome_preparation /path/to/CHM13_Bismark_Genome
Performance tuning:

Adjust --cpus-per-task, --mem, --time in SLURM

Tune Bismark flags: --multicore, --maxins, --score_min

Use xargs parallelism carefully

