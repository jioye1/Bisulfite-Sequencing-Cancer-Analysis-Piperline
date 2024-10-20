#!/bin/bash
#SBATCH --job-name=step2_job              # Job name
#SBATCH --output=step2_job-%j.out         # Output file (%j = job ID)
#SBATCH --time=2-00:00:00                 # Time limit (2 days)
#SBATCH --ntasks=1                        # Number of tasks
#SBATCH --cpus-per-task=8                 # Number of CPU cores
#SBATCH --mem=64G                         # Memory required (64G for 500 files)
#SBATCH --mail-user=sejacksony@gmail.com  # Email notifications
#SBATCH --mail-type=ALL                   # Send notifications at start, end, and on failure
#SBATCH --account=def-jch                 # Use your Compute Canada account
#SBATCH --chdir="/scratch/jacksony/Data Analysis Cedar/"  # Working directory

# Load the sratoolkit module (required for fastq-dump)
module load sra-toolkit

# Directory where the SRA files are stored (real dataset)
sra_dir="/scratch/jacksony/sra_files"  # Change to the real dataset directory
output_dir="/scratch/jacksony/fastq_files"  # Change to the real output directory

# Ensure the output directory exists
if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
fi

# Loop through each SRA file in the sra_dir
for file in "$sra_dir"/*.sra; do
    srr_path="$file"
    output_file_1="$output_dir/$(basename "$file" .sra)_1.fastq"
    output_file_2="$output_dir/$(basename "$file" .sra)_2.fastq"

    # Check if both FASTQ files already exist
    if [ -f "$output_file_1" ] && [ -f "$output_file_2" ]; then
        echo "Files already exist for $(basename "$file"). Skipping."
    else
        # Run fastq-dump to convert the SRA file
        echo "Processing $(basename "$file")..."
        fastq-dump --split-files -N 1 -X 1000000 "$srr_path" -O "$output_dir"
        
        # Check if the conversion was successful
        if [ $? -eq 0 ]; then
            echo "Completed conversion of $(basename "$file")"
        else
            echo "Error occurred during conversion of $(basename "$file")"
        fi
    fi
done

