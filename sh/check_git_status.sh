#!/bin/bash

GRN='\033[0;32m'
NC='\033[0m' # No Color

cwd=$(pwd)

# Check if the input argument (directory) is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <directory-containing-git-repos>"
    echo "No search directory provided"
fi

# Navigate to the directory provided as an argument
cd "$1" || exit

# Check if the directory itself is a Git repo
if [ -e .git ]; then
  echo -n "Repo ($(pwd)) is on branch: "
  #git rev-parse --abbrev-ref HEAD && git status && git submodule status
  echo -e "${GRN}$(git rev-parse --abbrev-ref HEAD)${NC}" && git status && git submodule status
fi

# Loop through each subdirectory in the given directory
for dir in */ ; do
    # Check if the directory is a Git repository
    if [ -e "${dir}/.git" ]; then
        echo -n "Repo ($(realpath "$dir")) is on branch: "
        # Get the current Git branch for the repository
        #(cd "$dir" && git rev-parse --abbrev-ref HEAD && git status && git submodule status)
        (cd "$dir" && echo -e "${GRN}$(git rev-parse --abbrev-ref HEAD)${NC}" && git status && git submodule status)
        echo "------------------------"
    fi
done

cd $cwd

