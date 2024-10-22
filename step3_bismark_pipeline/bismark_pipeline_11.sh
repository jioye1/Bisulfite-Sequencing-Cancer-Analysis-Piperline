#!/bin/bash
#SBATCH --job-name=bismark_pipeline_11
#SBATCH --output=bismark_pipeline_11-%j.out
#SBATCH --time=2-00:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --mail-user=sejacksony@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --account=def-jch
#SBATCH --chdir="/scratch/jacksony/Data Analysis Cedar/"

module load bismark
module load bowtie2

FASTQ_DIR="/scratch/jacksony/fastq_files"
GENOME_DIR="/scratch/jacksony/CHM13_Bismark_Genome"
ALIGN_DIR="/scratch/jacksony/bismark_output_11/aligned"  # Adjusted to bismark_output_11
DEDUP_DIR="/scratch/jacksony/bismark_output_11/deduplicated"  # Adjusted to bismark_output_11
METH_DIR="/scratch/jacksony/bismark_output_11/methylation"  # Adjusted to bismark_output_11
HTML_DIR="/scratch/jacksony/bismark_output_11/html_files"  # Adjusted to bismark_output_11

mkdir -p $ALIGN_DIR $DEDUP_DIR $METH_DIR $HTML_DIR

for i in $(seq 23280258 23280274); do  # Adjusted range for the last batch of SRRs
    R1="$FASTQ_DIR/SRR${i}_1.fastq"
    R2="$FASTQ_DIR/SRR${i}_2.fastq"
    
    if [ -f "$R1" ] && [ -f "$R2" ]; then
        BASENAME="SRR${i}"

        echo "Aligning $BASENAME with Bismark..."
        bismark --genome $GENOME_DIR -1 $R1 -2 $R2 --bowtie2 --multicore 8 --score_min L,0,-0.6 --maxins 1000 -o $ALIGN_DIR

        BAM_FILE="$ALIGN_DIR/${BASENAME}_1_bismark_bt2_pe.bam"
        if [ -f "$BAM_FILE" ]; then
            echo "Deduplicating $BAM_FILE..."
            deduplicate_bismark --bam $BAM_FILE --paired --output_dir $DEDUP_DIR

            DEDUP_BAM="$DEDUP_DIR/${BASENAME}_1_bismark_bt2_pe.deduplicated.bam"
            if [ -f "$DEDUP_BAM" ]; then
                METH_SUBDIR="$METH_DIR/${BASENAME}_1"
                mkdir -p $METH_SUBDIR
                echo "Extracting methylation data from $DEDUP_BAM..."
                bismark_methylation_extractor --bedGraph --gzip --multicore 8 --paired --output $METH_SUBDIR $DEDUP_BAM

                echo "Generating Bismark HTML report for $BASENAME..."
                bismark2report --alignment_report $ALIGN_DIR/${BASENAME}_1_bismark_bt2_PE_report.txt \
                               --dedup_report $DEDUP_DIR/${BASENAME}_1_bismark_bt2_pe.deduplication_report.txt \
                               --splitting_report $METH_SUBDIR/${BASENAME}_1_bismark_bt2_pe.deduplicated_splitting_report.txt \
                               --mbias_report $METH_SUBDIR/${BASENAME}_1_bismark_bt2_pe.deduplicated.M-bias.txt \
                               --dir $METH_SUBDIR

                echo "Moving HTML report to the html_files directory..."
                mv $METH_SUBDIR/${BASENAME}_1_bismark_bt2_PE_report.html $HTML_DIR/
            fi
        fi
    fi
done

echo "Bismark pipeline complete."

