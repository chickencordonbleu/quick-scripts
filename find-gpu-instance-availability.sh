#!/bin/bash

# Default instance types
default_instance_types=("p5" "p4" "p3" "p2" "g5" "g4dn")

# Use provided instance types or default if none are provided
instance_types=("${@:-${default_instance_types[@]}}")

# Get list of all regions
regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# Function to print a padded item
print_padded_item() {
    local item=$1
    local width=$2
    printf "%-${width}s" "$item"
}

# Find the maximum length of instance type names
max_itype_len=0
for itype in "${instance_types[@]}"; do
    [ ${#itype} -gt $max_itype_len ] && max_itype_len=${#itype}
done

# Find the maximum length of region names
max_region_len=0
for region in $regions; do
    [ ${#region} -gt $max_region_len ] && max_region_len=${#region}
done

# Header for the output
print_padded_item "Region" $((max_region_len + 1))
for itype in "${instance_types[@]}"; do
    print_padded_item ", $itype" $((max_itype_len + 2))
done
echo ", Score"

# Iterate through each region
for region in $regions
do
    # Print region name
    print_padded_item "$region" $((max_region_len + 1))
    score=0

    # Check each instance type in the current region
    for instance_type in "${instance_types[@]}"
    do
        available_types=$(aws ec2 describe-instance-types --region $region --filters "Name=instance-type,Values=$instance_type.*" --query "InstanceTypes[].InstanceType" --output text)
        
        # Print the instance type if available and increment score
        if [ -z "$available_types" ]; then
            print_padded_item ", -" $((max_itype_len + 2))
        else
            print_padded_item ", $instance_type" $((max_itype_len + 2))
            score=$((score + 1))
        fi
    done
    echo ", $score"
done
