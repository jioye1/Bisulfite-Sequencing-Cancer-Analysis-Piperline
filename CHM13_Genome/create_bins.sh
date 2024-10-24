#!/bin/bash

# Input files
FAI_FILE="hs1.fa.fai"
OUTPUT_FILE="genome_100k_bins.bed"

# Total number of bins desired
TOTAL_BINS=100000

# Calculate the total genome length
TOTAL_GENOME_SIZE=$(awk '{sum += $2} END {print sum}' $FAI_FILE)

# Calculate the bin size (in base pairs) for 100,000 bins
BIN_SIZE=$(echo "$TOTAL_GENOME_SIZE / $TOTAL_BINS" | bc)

# Clear output file if it exists
> $OUTPUT_FILE

# Loop through each chromosome in the .fai file
while read chr length offset linebases linewidth; do
    start=0
    while [ $start -lt $length ]; do
        end=$((start + BIN_SIZE))
        if [ $end -gt $length ]; then
            end=$length
        fi
        echo -e "$chr\t$start\t$end" >> $OUTPUT_FILE
        start=$end
    done
done < $FAI_FILE

echo "Bins of approximately $BIN_SIZE bp (for 100,000 total bins) have been generated and saved to $OUTPUT_FILE"

