#!/usr/bin/env bash
# Multi-UI Scripting
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

# get the directories
SCRIPT_DIALOG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURRENT_FILE="$(realpath -- "${BASH_SOURCE[0]}")"

# sources everything in folder, excludes current file
for src in ./*.sh
do
  [[ "$(realpath -- "$src")" == "$CURRENT_FILE" ]] && continue
  source "$src" || exit 1
  #echo "$src"
done

# execute told function
if declare -f "$1" >/dev/null; then
 "$1"
else
  echo "Function not found"
fi

# the rest goes there

