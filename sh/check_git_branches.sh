#!/bin/bash

cwd=$(pwd)

# Check if the input argument (directory) is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <directory-containing-git-repos>"
    echo "No search directory provided"
fi

# Navigate to the directory provided as an argument
cd "$1" || exit

# Loop through each subdirectory in the given directory
for dir in */ ; do
    # Check if the directory is a Git repository
    if [ -d "${dir}/.git" ]; then
        echo -n "Repo $dir is on branch: "
        # Get the current Git branch for the repository
        (cd "$dir" && git rev-parse --abbrev-ref HEAD)
    fi
done

cd $cwd

