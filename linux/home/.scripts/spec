#!/usr/bin/env bash

# Created By: srdusr
# Created On: Wed 18 Oct 2023 20:19:03 CAT
# Project: Create Spectrograms of audio files

# Dependencies: sox

# Define the timestamp function
timestamp() {
    date +%Y%m%d%H%M%S
}

spec() {

    if [[ $# -eq 0 ]]; then
        echo "No audio files provided."
        return
    fi

    local outdir

    if [[ -d "$HOME/pictures" ]]; then
        outdir="$HOME/pictures/spectrograms"
    elif [[ -d "$HOME/Pictures" ]]; then
        outdir="$HOME/Pictures/Spectrograms"
    elif [[ -d "$HOME/Images" ]]; then
        outdir="$HOME/Images/Spectrograms"
    else
        outdir="./spectrograms" # Save to the current directory if none of the expected directories exist
    fi

    for file in "$@"; do
        if [[ -f "$file" ]]; then
            local filename
            filename=$(basename "$file")
            local filename_no_extension="${filename%.*}"
            local target_dir="$outdir"
            local outname="$target_dir/sox-spec-$(timestamp)-${filename_no_extension}.png"

            if [[ ! -d "$target_dir" ]]; then
                mkdir -p "$target_dir" # Create the directory if it doesn't exist
            fi

            sox "$file" -S -n spectrogram -o "$outname"

            # Add the generated spectrogram file name to the array
            spectrogram_files+=("$outname")
        else
            echo "File not found: $file"
        fi
    done

    if [[ ${#} -gt 0 ]]; then
        read -p "Do you want to open the spectrogram(s)? (y/n): " open_choice
        case "$open_choice" in
        [Yy])
            for file in "${spectrogram_files[@]}"; do
                xdg-open "$file" # Open the spectrogram images generated from the provided audio files
            done
            ;;
        [Nn])
            echo "Not opening the spectrogram(s)."
            ;;
        *)
            echo "Invalid choice. Not opening the spectrogram(s)."
            ;;
        esac
    fi
}

# Call the spec function with provided arguments
spec "$@"
