#!/bin/bash

# Get list of all AWS regions
regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# Function to check latency
check_latency() {
    local region=$1
    local endpoint="ec2.$region.amazonaws.com"

    local latency
    latency=$(ping -c 4 $endpoint | tail -1 | awk -F '/' '{print $5}')
    
    # Output region and latency
    echo "$region $latency"
}

# Function to categorize region by continent
get_continent() {
    case $1 in
        eu-*) echo "Europe" ;;
        us-*) echo "North America" ;;
        ap-*) echo "Asia Pacific" ;;
        sa-*) echo "South America" ;;
        af-*) echo "Africa" ;;
        me-*) echo "Middle East" ;;
        *) echo "Other" ;;
    esac
}

# Temporary file for results
results_file=$(mktemp)

# Check latency for each region in parallel
for region in $regions; do
    (check_latency "$region" >> "$results_file") &
done

# Wait for all background processes to finish
wait

# Read results and sort
while read -r region latency; do
    continent=$(get_continent "$region")
    printf "%-15s %-20s %s\n" "$continent" "$region" "$latency"
done < "$results_file" | sort -k1,1 -k3,3n

# Clean up
rm "$results_file"
