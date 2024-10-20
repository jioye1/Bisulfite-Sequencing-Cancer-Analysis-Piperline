#!/bin/bash
#SBATCH --job-name=step1_job              # Job name
#SBATCH --output=step1_job-%j.out         # Output file (%j = job ID)
#SBATCH --time=2-00:00                    # Time limit (D-HH:MM)
#SBATCH --ntasks=1                        # Number of tasks
#SBATCH --cpus-per-task=8                 # Number of CPU cores
#SBATCH --mem=64G                         # Memory required
#SBATCH --mail-user=sejacksony@gmail.com  # Email notifications
#SBATCH --mail-type=ALL                   # Send notifications at start, end, and on failure
#SBATCH --account=def-jch                 # Use your Compute Canada account
#SBATCH --chdir="/scratch/jacksony/Data Analysis Cedar/"

# Path to the file containing SAMN (Biosample) accession names
samn_file="/scratch/jacksony/Data Analysis Cedar/biosample_numbers.txt"

# Output directory for SRA files (prefetch output)
output_dir="/scratch/jacksony/sra_files"

# Ensure the output directory exists
if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
fi

# Function to download a single SAMN
download_sra() {
    samn=$1
    sra_file="$output_dir/$samn.sra"
    if [ -f "$sra_file" ]; then
        echo "SRA file for $samn already exists. Skipping."
    else
        echo "Processing $samn..."
        prefetch "$samn" --output-directory "$output_dir"
        if [ $? -eq 0 ]; then
            echo "Completed download of $samn"
            # Move .sra files out of subdirectories to the main output_dir
            find "$output_dir" -name "*.sra" -exec mv {} "$output_dir" \;
            # Remove empty subdirectories
            find "$output_dir" -type d -empty -delete
        else
            echo "Error occurred during download of $samn"
        fi
    fi
}

# Export the function so it can be used by xargs
export -f download_sra
export output_dir

# Download in parallel (adjust the number of parallel jobs based on CPU cores)
cat "$samn_file" | xargs -n 1 -P 8 bash -c 'download_sra "$@"' _

