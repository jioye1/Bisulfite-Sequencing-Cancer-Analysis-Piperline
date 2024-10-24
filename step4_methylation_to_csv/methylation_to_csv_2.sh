#!/bin/bash
#SBATCH --job-name=methylation_processing
#SBATCH --output=methylation_processing-%j.out
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --mail-user=sejacksony@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --account=def-jch
#SBATCH --chdir="/scratch/jacksony/bismark_output_2/"

# Load necessary modules
module load bedtools

# Directories
METHYLATION_DIR="/scratch/jacksony/bismark_output_2/methylation"
OUTPUT_DIR="/scratch/jacksony/methylation_csv"
BINS_FILE="/scratch/jacksony/CHM13_Genome/sorted_genome_100k_bins.bed"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Starting methylation data processing..."

# Loop over subdirectories
for SAMPLE_DIR in "$METHYLATION_DIR"/*/; do
    echo "Processing directory: $SAMPLE_DIR"
    
    # Get sample name from the directory
    SAMPLE_NAME=$(basename "$SAMPLE_DIR")
    
    # Find the .cov.gz file in the directory
    COV_GZ_FILE=$(find "$SAMPLE_DIR" -maxdepth 1 -name "${SAMPLE_NAME}_bismark_bt2_pe.deduplicated.bismark.cov.gz")
    
    if [ -z "$COV_GZ_FILE" ]; then
        echo "No .cov.gz file found in $SAMPLE_DIR. Skipping."
        continue
    fi
    
    echo "Found methylation file: $COV_GZ_FILE"
    
    # Unzip the .cov.gz file
    METHYLATION_FILE="${COV_GZ_FILE%.gz}"
    if [ -f "$METHYLATION_FILE" ]; then
        echo "Unzipped file $METHYLATION_FILE already exists. Skipping unzipping."
    else
        echo "Unzipping $COV_GZ_FILE..."
        gunzip -c "$COV_GZ_FILE" > "$METHYLATION_FILE"
    fi
    
    # Sort the methylation data file
    SORTED_METHYLATION_FILE="${METHYLATION_FILE%.cov}_sorted.cov"
    echo "Sorting methylation data file..."
    sort -k1,1 -k2,2n "$METHYLATION_FILE" > "$SORTED_METHYLATION_FILE"
    
    # Set output filenames
    BEDTOOLS_OUTPUT="$SAMPLE_DIR/${SAMPLE_NAME}_methylation_counts_per_bin.bed"
    FINAL_OUTPUT="$SAMPLE_DIR/${SAMPLE_NAME}_methylation_counts_per_bin_with_pct.bed"
    CSV_OUTPUT="$OUTPUT_DIR/${SAMPLE_NAME}_methylation_counts_per_bin_with_pct.csv"
    
    # Use bedtools to map methylation data onto bins
    echo "Mapping methylation data onto bins using bedtools..."
    bedtools map -a "$BINS_FILE" -b "$SORTED_METHYLATION_FILE" -c 5,6 -o sum,sum -null 0 > "$BEDTOOLS_OUTPUT"
    
    # Calculate percent methylation per bin using awk
    echo "Calculating percent methylation per bin..."
    awk 'BEGIN {OFS="\t"} { if ($4+$5 > 0) pct = ($4/($4+$5))*100; else pct = 0; print $1, $2, $3, $4, $5, pct }' "$BEDTOOLS_OUTPUT" > "$FINAL_OUTPUT"
    
    # Convert the output to CSV format
    echo "Converting output to CSV format..."
    echo -e "Chromosome,Start,End,Meth_Counts,Unmeth_Counts,Percent_Methylation" > "$CSV_OUTPUT"
    cat "$FINAL_OUTPUT" | tr '\t' ',' >> "$CSV_OUTPUT"
    
    echo "Finished processing $SAMPLE_NAME. Output saved to $CSV_OUTPUT"
    
    # Optionally, remove intermediate files to save space
    # Uncomment the following lines if you want to remove intermediate files
    # echo "Cleaning up intermediate files..."
    # rm "$METHYLATION_FILE" "$SORTED_METHYLATION_FILE" "$BEDTOOLS_OUTPUT" "$FINAL_OUTPUT"
done

echo "All samples processed."

