#!/bin/bash

RED='\033[0;31m'
GRN='\033[0;32m'
NC='\033[0m' # No Color

cwd=$(pwd)

if [ -z "$1" ]; then
  echo "Usage: $0 <directory-containing-git-repos>"
  echo "No search directory provided"
  exit 1
fi

cd "$1" || { echo "Failed to cd into $1"; exit 1; }

# Check if the directory itself is a Git repo
if [ -e .git ]; then
  echo -n "Repo ($(pwd)) is on branch: "
  #git rev-parse --abbrev-ref HEAD
  echo -e "${GRN}$(git rev-parse --abbrev-ref HEAD)${NC}"
fi

for dir in */ ; do
  if [ -e "${dir}/.git" ]; then
    echo -n "Repo ($(realpath "$dir")) is on branch: "
    #(cd "$dir" && git rev-parse --abbrev-ref HEAD)
    (cd "$dir" && echo -e "${GRN}$(git rev-parse --abbrev-ref HEAD)${NC}")
  fi
done

cd "$cwd"
