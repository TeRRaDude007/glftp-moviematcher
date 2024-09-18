#!/bin/bash
#################################################
### TeRRaDuDe HDR (H265) Splitter v1.1   #####
#################################################
#################################################
#
# Wat?:
# - It extracts the core movie name and year by removing all unnecessary tags (HDR, resolution, encoding, etc.).
# - It detects if an HDR version of the movie is present.
# - If both HDR and non-HDR versions exist, the non-HDR version is moved to /tmp/dir.
# - SKIPS: BLURAY
# - Yes;... you'll get Y/N before moveing.
#
# How to Run:
#
# - Make it executable: chmod +x terra-X265_moviematcher.sh.
# - Run the script: ./terra-X265_moviematcher.sh.
#
#################################################
#############    CONFIG SETUP    ################
##################################################

# Source and destination directories
SRC_DIR="/glftpd/site/X265MOVIES"
DEST_DIR="/$SRC_DIR/tmp/dir"

# Ensure the destination directory exists
mkdir- m777 -p "$DEST_DIR"

# Function to extract movie name and year (ignoring HDR and other tags)
extract_movie_name() {
    local dir_name="$1"
    # Extract the movie name and year (ignores tags like HDR, 2160p, WEB, etc.)
    echo "$dir_name" | sed -E 's/\.(HDR|2160[Pp]|WEB|H265|H264|BluRay|BDRip|test123|SLOT|-|_)+//g' | sed -E 's/\.[0-9]{4}.*$//g'
}

# Function to check if a directory contains HDR
contains_hdr() {
    local dir_name="$1"
    echo "$dir_name" | grep -qE '\.HDR\.'
}

# Tags to skip entirely (case-insensitive)
SKIP_TAGS="BLURAY"

# Function to check if a directory contains skip tags
contains_skip_tags() {
    local dir_name="$1"
    echo "$dir_name" | grep -qiE "$SKIP_TAGS"
}

# Use associative arrays to store directories based on movie name and year
declare -A hdr_dirs
declare -A non_hdr_dirs
declare -a to_move_list  # Array to store non-HDR directories to be moved

# Scan all directories in the source folder
for dir in $(find "$SRC_DIR" -maxdepth 1 -type d); do
    # Skip the source directory itself
    if [ "$dir" == "$SRC_DIR" ]; then
        continue
    fi

    # Get the directory name
    dir_name=$(basename "$dir")

    # Skip directories containing the words PROPER, RERIP, BLURAY
    if contains_skip_tags "$dir_name"; then
        echo "Skipping directory (contains $SKIP_TAGS): $dir_name"
        continue
    fi

    # Extract the movie name and year (ignores tags like HDR, 2160P, etc.)
    base_name=$(extract_movie_name "$dir_name")

    # Check if it contains HDR or not
    if contains_hdr "$dir_name"; then
        hdr_dirs["$base_name"]="$dir_name"
    else
        non_hdr_dirs["$base_name"]="$dir_name"
    fi
done

# Compare directories with the same movie name and year base
for base_name in "${!hdr_dirs[@]}"; do
    if [[ -n "${non_hdr_dirs[$base_name]}" ]]; then
        # If a matching HDR and non-HDR directory exist, move the non-HDR directory
        echo "Match found for $base_name with HDR and non-HDR:"
        echo " - HDR directory: ${hdr_dirs[$base_name]}"
        echo " - non-HDR directory: ${non_hdr_dirs[$base_name]}"
        to_move_list+=("${non_hdr_dirs[$base_name]}")
    fi
done

# Move the collected non-HDR directories
if [ ${#to_move_list[@]} -gt 0 ]; then
    echo
    echo "The following non-HDR directories are ready to be moved to $DEST_DIR:"
    for non_hdr_dir in "${to_move_list[@]}"; do
        echo " - $non_hdr_dir"
    done
    echo
    read -p "Do you want to move all these non-HDR directories? (y/n): " confirm_all
    if [[ "$confirm_all" == "y" ]]; then
        for non_hdr_dir in "${to_move_list[@]}"; do
            echo "Moving non-HDR directory: $non_hdr_dir"
            mv "$SRC_DIR/$non_hdr_dir" "$DEST_DIR"
        done
        echo "All selected non-HDR directories have been moved."
    else
        echo "No directories were moved."
    fi
else
    echo "No matches found to move."
fi
# EOF
# !!!+++ This Script Comes Without any Support +++!!!
# ./Just enjoy it.
