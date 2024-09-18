#!/bin/bash
#################################################
### TeRRaDuDe BluRay (X264) Splitter v1.1   #####
#################################################
#################################################
#
# Wat?:
#
# - The script checks all directories within the source folder that are older than 7 days.
# - It distinguishes between directories containing high-priority tags (BluRay) and those with low-priority tags (WEB).
# - If both a BluRay and a WEB version of the same movie (based on extracted movie name and year) are found, the WEB version is considered for moving.
# - Yes;... you'll get Y/N before moveing.
#
# How to Run:
#
# - Make it executable: chmod +x terra-X264_moviematcher.sh.
# - Run the script: ./terra-X264_moviematcher.sh.
#
#################################################
#############    CONFIG SETUP    ################
#################################################

# Source and destination directories
SRC_DIR="/glftpd/site/X264MOVIES"
DEST_DIR="$SRC_DIR/_Better_quality_allready_on_site"

#################################################
###### END OF CONFIG ## DONT EDIT BELOW #########
#################################################

# Ensure the WEB destination directory exists
mkdir -m777 -p "$DEST_DIR"

# Function to extract movie name and year (up to the format resolution)
extract_movie_name() {
    local dir_name="$1"
    echo "$dir_name" | sed -E 's/^(.*[0-9]{4}).*$/\1/'
}

# Tags to prioritize and skip
PRIORITY_TAGS="\.BluRay|\.BDRip|\.X264"
LOW_PRIORITY_TAGS="\.WEB|\.WEBRip|\.H264"

# Tags to skip entirely (case-insensitive)
SKIP_TAGS="PROPER|REPACK|NFOFIX|REMASTERED|RERIP"

# Function to check if a directory contains the priority tags
contains_priority_tags() {
    local dir_name="$1"
    echo "$dir_name" | grep -qE "$PRIORITY_TAGS"
}

# Function to check if a directory contains low-priority tags
contains_low_priority_tags() {
    local dir_name="$1"
    echo "$dir_name" | grep -qE "$LOW_PRIORITY_TAGS"
}

# Function to check if a directory contains skip tags
contains_skip_tags() {
    local dir_name="$1"
    echo "$dir_name" | grep -qiE "$SKIP_TAGS"
}

# Use associative arrays to store directories based on movie name and year
declare -A web_dirs
declare -A bluray_dirs
declare -a to_move_list  # Array to store low-priority directories to be moved

# Scan all directories in the source folder that are older than 7 days
for dir in $(find "$SRC_DIR" -maxdepth 1 -type d -mtime +7); do
    # Skip the source directory itself
    if [ "$dir" == "$SRC_DIR" ]; then
        continue
    fi

    # Get the directory name
    dir_name=$(basename "$dir")

    # Skip directories containing the words PROPER, REPACK, NFOFIX
    if contains_skip_tags "$dir_name"; then
        echo "Skipping directory (contains $SKIP_TAGS): $dir_name"
        continue
    fi

    # Extract the movie name and year
    base_name=$(extract_movie_name "$dir_name")

    # Check for priority and low-priority tags
    if contains_priority_tags "$dir_name"; then
        bluray_dirs["$base_name"]="$dir_name"
    elif contains_low_priority_tags "$dir_name"; then
        web_dirs["$base_name"]="$dir_name"
    fi
done

# Compare directories with the same movie name and year base
for base_name in "${!bluray_dirs[@]}"; do
    if [[ -n "${web_dirs[$base_name]}" ]]; then
        # If a matching BluRay directory exists for this movie, move the WEB directory
        echo "Match found for $base_name with BluRay and WEB:"
        echo " - BluRay directory: ${bluray_dirs[$base_name]}"
        echo " - WEB directory: ${web_dirs[$base_name]}"
        to_move_list+=("${web_dirs[$base_name]}")
    fi
done

# After collecting all moves, confirm them all at once
if [ ${#to_move_list[@]} -gt 0 ]; then
    echo
    echo "The following WEB directories, older than 7 days, are ready to be moved to $DEST_DIR:"
    for web_dir in "${to_move_list[@]}"; do
        echo " - $web_dir"
    done
    echo
    read -p "Do you want to move all these WEB directories? (y/n): " confirm_all
    if [[ "$confirm_all" == "y" ]]; then
        for web_dir in "${to_move_list[@]}"; do
            echo "Moving WEB directory: $web_dir"
            mv "$SRC_DIR/$web_dir" "$DEST_DIR"
        done
        echo "All selected WEB directories have been moved."
    else
        echo "No directories were moved."
    fi
else
    echo "No matches found to move."
fi
# EOF
# !!!+++ This Script Comes Without any Support +++!!!
# ./Just enjoy it.
