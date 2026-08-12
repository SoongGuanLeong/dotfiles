#!/bin/sh
set -e

# Get all files in home/
files=$(find home -type f -o -type l)

# Load registry and skip list
registry=$(jq -r '.[].source' registry.json)
skip_list=$(jq -r '.[]' skip-list.json)

for file in $files; do
  # Check if the file is explicitly in the registry
  if echo "$registry" | grep -q "^$file$"; then
    continue
  fi

  # Check if the file is in the skip list
  if echo "$skip_list" | grep -q "^$file$"; then
    continue
  fi

  # Check if the file is part of a directory listed in the registry
  covered=false
  for reg_source in $registry; do
    # echo "Checking $file against $reg_source"
    if [ -d "$reg_source" ]; then
      if [ "${file#$reg_source}" != "$file" ]; then
        covered=true
        break
      fi
    fi
  done

  if [ "$covered" = true ]; then
    continue
  fi

  echo "File $file is not registered and not in skip-list."
  exit 1
done

echo "All files are covered."
