#!/bin/bash

# Define the path to the folder containing the podspecs
podspecs_folder="build/Podspecs"

# Define the repository name (replace with your actual repository name)
repo_name="bidon"

# Check if the podspecs folder exists
if [ ! -d "$podspecs_folder" ]; then
  echo "Podspecs folder does not exist: $podspecs_folder"
  exit 1
fi

# Get the list of all podspec files in the folder
podspec_files=$(ls "$podspecs_folder"/*.podspec.json 2> /dev/null)

# Check if there are any podspec files in the folder
if [ -z "$podspec_files" ]; then
  echo "No podspec files found in the folder: $podspecs_folder"
  exit 1
fi

# Loop through each podspec file and push it to the repo
for podspec_file in $podspec_files; do
  echo "Pushing $podspec_file to $repo_name..."
  if pod trunk push "$podspec_file"; then
    echo "Successfully pushed $podspec_file to $repo_name."
  else
    echo "Failed to push $podspec_file to $repo_name."
  fi
done

echo "All podspecs processed."
