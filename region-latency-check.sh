#!/bin/bash

# Get list of all AWS regions
regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# Function to check latency
check_latency() {
    local region=$1
    local endpoint="ec2.$region.amazonaws.com"

    echo "Checking latency to $region ($endpoint)..."
    ping -c 4 $endpoint | tail -1 | awk -F '/' '{print "Average Latency: " $5 " ms"}'
}

# Check latency for each AWS region
for region in $regions; do
    check_latency "$region"
done
